const express = require('express');
const { WebSocketServer } = require('ws');
const { spawn, execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const http = require('http');

const app = express();
const PORT = 3000;

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const server = http.createServer(app);
const wss = new WebSocketServer({ server });

// ─── State ───────────────────────────────────────────────────────────
let state = {
  status: 'idle', // idle | fetching | downloading | converting | paused | done | error
  playlistUrl: '',
  playlistTitle: '',
  totalVideos: 0,
  currentIndex: 0,
  currentTitle: '',
  currentProgress: 0,
  downloaded: 0,
  failed: 0,
  skipped: 0,
  speed: '',
  eta: '',
  logs: [],
  failedVideos: [],
  startTime: null,
  outputDir: __dirname,
};

let activeProcess = null;
let archiveFile = '';
let logFile = '';

const MAX_LOGS = 2000;

// ─── Settings ────────────────────────────────────────────────────────
let settings = {
  downloadDir: path.join(require('os').homedir(), 'Downloads', 'YTSync')
};

function loadSettings() {
  try {
    const dataDir = path.join(__dirname, '.yt-mp3-data');
    if (!fs.existsSync(dataDir)) fs.mkdirSync(dataDir, { recursive: true });
    const file = path.join(dataDir, 'settings.json');
    if (fs.existsSync(file)) {
      settings = { ...settings, ...JSON.parse(fs.readFileSync(file, 'utf-8')) };
    }
  } catch(e) {}
}
function saveSettings() {
  try {
    const file = path.join(__dirname, '.yt-mp3-data', 'settings.json');
    fs.writeFileSync(file, JSON.stringify(settings, null, 2));
  } catch(e) {}
}
loadSettings();

function addLog(line, type = 'info') {
  const entry = { time: new Date().toISOString(), text: line, type };
  state.logs.push(entry);
  if (state.logs.length > MAX_LOGS) state.logs = state.logs.slice(-MAX_LOGS);
  broadcast({ event: 'log', data: entry });
}

function broadcastState() {
  const { logs, ...rest } = state;
  broadcast({ event: 'state', data: rest });
}

function broadcast(msg) {
  const json = JSON.stringify(msg);
  wss.clients.forEach(c => { if (c.readyState === 1) c.send(json); });
}

function getPlaylistId(url) {
  const m = url.match(/list=([A-Za-z0-9_-]+)/);
  return m ? m[1] : 'unknown';
}

function getArchiveCount() {
  try {
    if (fs.existsSync(archiveFile)) {
      return fs.readFileSync(archiveFile, 'utf-8').trim().split('\n').filter(Boolean).length;
    }
  } catch {}
  return 0;
}

// ─── API Routes ──────────────────────────────────────────────────────

// Fetch playlist info without downloading
app.post('/api/fetch-info', async (req, res) => {
  const { url } = req.body;
  if (!url) return res.status(400).json({ error: 'URL required' });

  state.status = 'fetching';
  state.playlistUrl = url;
  broadcastState();
  addLog(`Fetching playlist info for: ${url}`, 'step');

  try {
    const result = require('child_process').spawnSync(
      'yt-dlp',
      ['--flat-playlist', '-J', url],
      { timeout: 60000, maxBuffer: 50 * 1024 * 1024 }
    ).stdout.toString();
    const data = JSON.parse(result);

    const playlistId = getPlaylistId(url);
    const dataDir = path.join(__dirname, '.yt-mp3-data');
    if (!fs.existsSync(dataDir)) fs.mkdirSync(dataDir, { recursive: true });
    archiveFile = path.join(dataDir, `${playlistId}_archive.txt`);
    logFile = path.join(dataDir, `${playlistId}_download.log`);

    const alreadyDownloaded = getArchiveCount();

    state.playlistTitle = data.title || 'Unknown Playlist';
    state.totalVideos = data.playlist_count || (data.entries ? data.entries.length : 0);
    state.downloaded = alreadyDownloaded;
    state.skipped = alreadyDownloaded;
    state.status = 'idle';

    broadcastState();
    addLog(`Playlist: "${state.playlistTitle}" — ${state.totalVideos} videos (${alreadyDownloaded} already downloaded)`, 'success');

    res.json({
      title: state.playlistTitle,
      total: state.totalVideos,
      alreadyDownloaded,
      entries: (data.entries || []).slice(0, 20).map((e, i) => ({
        index: i + 1,
        title: e.title,
        duration: e.duration,
        url: e.url,
      })),
    });
  } catch (err) {
    state.status = 'error';
    broadcastState();
    addLog(`Error fetching playlist: ${err.message}`, 'error');
    res.status(500).json({ error: err.message });
  }
});

// Start downloading
app.post('/api/start', (req, res) => {
  if (activeProcess) {
    return res.status(409).json({ error: 'Download already in progress' });
  }

  const { url, startRange, endRange, quality, rateLimit, browserCookie } = req.body;
  if (!url) return res.status(400).json({ error: 'URL required' });

  const playlistId = getPlaylistId(url);
  const dataDir = path.join(__dirname, '.yt-mp3-data');
  if (!fs.existsSync(dataDir)) fs.mkdirSync(dataDir, { recursive: true });
  archiveFile = path.join(dataDir, `${playlistId}_archive.txt`);
  logFile = path.join(dataDir, `${playlistId}_download.log`);

  state.playlistUrl = url;
  state.status = 'downloading';
  state.currentIndex = 0;
  state.currentTitle = '';
  state.currentProgress = 0;
  state.failed = 0;
  state.failedVideos = [];
  state.speed = '';
  state.eta = '';
  state.startTime = Date.now();
  state.downloaded = getArchiveCount();
  state.skipped = state.downloaded;

  const dlQuality = (quality !== undefined) ? quality : (settings.audioQuality || 0);
  const dlRate = (rateLimit !== undefined) ? rateLimit : (settings.speedLimit || '2M');
  const concurrent = settings.concurrent || 4;
  const sleepMin = settings.sleepMin || 3;
  const sleepMax = settings.sleepMax || 8;

  const args = [
    '-f', 'bestaudio',
    '-x', '--audio-format', 'mp3',
    '--audio-quality', String(dlQuality),
    '--yes-playlist',
    '--no-abort-on-error',
    '--concurrent-fragments', String(concurrent)
  ];

  if (dlRate && dlRate !== '0' && Number(dlRate.replace('M','')) > 0) {
    args.push('--limit-rate', dlRate);
  }

  if (browserCookie && browserCookie !== 'none') {
    args.push('--cookies-from-browser', browserCookie);
  }

  args.push(
    '--sleep-interval', String(sleepMin),
    '--max-sleep-interval', String(sleepMax),
    '--sleep-requests', '1',
    '--download-archive', archiveFile,
    '--socket-timeout', '30',
    '--retries', '10',
    '--fragment-retries', '10',
    '--extractor-retries', '5',
    '--no-overwrites',
    '--add-metadata',
    '--parse-metadata', '%(title)s:%(meta_title)s',
    '--parse-metadata', '%(uploader)s:%(meta_artist)s',
    '--progress',
    '--newline',
    '-o', path.join(settings.downloadDir, '%(playlist_title)s/%(playlist_index)s - %(title)s.%(ext)s')
  );

  if (startRange) args.push('--playlist-start', String(startRange));
  if (endRange) args.push('--playlist-end', String(endRange));
  args.push(url);

  addLog(`Starting download: yt-dlp ${args.join(' ')}`, 'step');

  const proc = spawn('yt-dlp', args, {
    cwd: __dirname,
    env: { ...process.env },
  });

  activeProcess = proc;

  proc.stdout.on('data', (chunk) => {
    const lines = chunk.toString().split('\n').filter(Boolean);
    lines.forEach(line => parseLine(line));
  });

  proc.stderr.on('data', (chunk) => {
    const lines = chunk.toString().split('\n').filter(Boolean);
    lines.forEach(line => parseLine(line));
  });

  proc.on('close', (code) => {
    activeProcess = null;
    state.downloaded = getArchiveCount();

    if (state.status === 'paused') {
      addLog('Download paused by user.', 'warn');
    } else if (code === 0 || code === null) {
      state.status = 'done';
      addLog(`Download complete! ${state.downloaded} videos archived.`, 'success');
    } else {
      state.status = 'done';
      addLog(`Download finished with exit code ${code}. ${state.downloaded} videos archived, ${state.failed} failed.`, 'warn');
    }
    state.currentProgress = 0;
    state.speed = '';
    state.eta = '';
    broadcastState();
  });

  proc.on('error', (err) => {
    activeProcess = null;
    state.status = 'error';
    addLog(`Process error: ${err.message}`, 'error');
    broadcastState();
  });

  res.json({ ok: true });
});

// Stop download
app.post('/api/stop', (req, res) => {
  if (!activeProcess) return res.status(400).json({ error: 'No active download' });
  state.status = 'paused';
  broadcastState();
  activeProcess.kill('SIGTERM');
  res.json({ ok: true });
});

// Clear Cache Endpoint
app.delete('/api/cache', (req, res) => {
  if (activeProcess) {
    return res.status(400).json({ error: 'Cannot clear cache while a download is running.' });
  }

  // Reset core tracking state
  state = {
    status: 'idle',
    playlistUrl: '',
    playlistTitle: '',
    totalVideos: 0,
    currentIndex: 0,
    currentTitle: '',
    currentProgress: 0,
    downloaded: 0,
    failed: 0,
    skipped: 0,
    speed: '',
    eta: '',
    logs: [],
    failedVideos: [],
    startTime: null,
  };
  
  archiveFile = '';
  logFile = '';
  broadcastState();

  // Clear tracking files (.txt, .log) on disk, preserving settings.json
  try {
    const dataDir = path.join(__dirname, '.yt-mp3-data');
    if (fs.existsSync(dataDir)) {
      const files = fs.readdirSync(dataDir);
      for (const file of files) {
        if (file !== 'settings.json') {
          fs.unlinkSync(path.join(dataDir, file));
        }
      }
    }
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get state
app.get('/api/state', (req, res) => {
  const { logs, ...rest } = state;
  res.json(rest);
});

// Get logs
app.get('/api/logs', (req, res) => {
  const count = Math.min(parseInt(req.query.count) || 100, MAX_LOGS);
  res.json(state.logs.slice(-count));
});

// Settings
app.get('/api/settings', (req, res) => res.json(settings));
app.post('/api/settings', (req, res) => {
  if (req.body.downloadDir) {
    settings.downloadDir = req.body.downloadDir;
    try {
      if (!fs.existsSync(settings.downloadDir)) fs.mkdirSync(settings.downloadDir, { recursive: true });
    } catch (e) {
      return res.status(400).json({ error: 'Failed to create directory: ' + e.message });
    }
  }
  saveSettings();
  res.json({ ok: true });
});

// Native Folder Picker (macOS & Windows)
app.post('/api/pick-folder', (req, res) => {
  try {
    let result = '';
    if (process.platform === 'darwin') {
      const script = `osascript -e 'POSIX path of (choose folder with prompt "Select YTSync Download Directory")'`;
      result = execSync(script, { encoding: 'utf-8' }).trim();
    } else if (process.platform === 'win32') {
      const psScript = `Add-Type -AssemblyName System.windows.forms; $f = New-Object System.Windows.Forms.FolderBrowserDialog; $f.Description = "Select YTSync Download Directory"; $f.ShowNewFolderButton = $true; if($f.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){ $f.SelectedPath }`;
      result = execSync(`powershell -Sta -NoProfile -Command "${psScript}"`, { encoding: 'utf-8' }).trim();
    } else {
      return res.status(400).json({ error: 'Native folder picker only supported on macOS and Windows.' });
    }

    if (result) {
      settings.downloadDir = result;
      saveSettings();
      res.json({ downloadDir: result });
    } else {
      res.status(400).json({ error: 'Selection cancelled' });
    }
  } catch (err) {
    res.status(400).json({ error: 'Selection cancelled or unsupported' });
  }
});

// List downloaded MP3 files (grouped by playlist folder)
app.get('/api/files', (req, res) => {
  const folders = {}; 
  
  function walkDir(dir, playlistName = '') {
    try {
      const entries = fs.readdirSync(dir, { withFileTypes: true });
      for (const entry of entries) {
        const full = path.join(dir, entry.name);
        if (entry.isDirectory() && !entry.name.startsWith('.')) {
          // Top level folders inside downloadDir are treated as playlists
          const pName = playlistName || entry.name;
          walkDir(full, pName);
        } else if (entry.isFile() && entry.name.endsWith('.mp3')) {
          const stat = fs.statSync(full);
          const pName = playlistName || 'Uncategorized';
          if (!folders[pName]) folders[pName] = { name: pName, files: [] };
          folders[pName].files.push({
            name: entry.name,
            path: full,
            size: stat.size,
            modified: stat.mtime.toISOString(),
          });
        }
      }
    } catch {}
  }
  
  try {
    if (!fs.existsSync(settings.downloadDir)) fs.mkdirSync(settings.downloadDir, { recursive: true });
    walkDir(settings.downloadDir);
  } catch (e) {}

  // Sort files in each folder alphabetically (track number)
  const result = Object.values(folders);
  result.forEach(f => f.files.sort((a,b) => a.name.localeCompare(b.name)));
  // Sort folders alphabetically
  result.sort((a,b) => a.name.localeCompare(b.name));
  
  res.json(result);
});

// ─── Parse yt-dlp Output ─────────────────────────────────────────────

function parseLine(line) {
  // [download] Downloading item 3 of 532
  const itemMatch = line.match(/Downloading item (\d+) of (\d+)/i);
  if (itemMatch) {
    state.currentIndex = parseInt(itemMatch[1]);
    state.totalVideos = Math.max(state.totalVideos, parseInt(itemMatch[2]));
    addLog(line, 'step');
    broadcastState();
    return;
  }

  // [download]  45.2% of ~  5.36MiB at  1.23MiB/s ETA 00:03
  const progressMatch = line.match(/(\d+\.?\d*)%\s+of\s+~?\s*([\d.]+\w+)(?:\s+at\s+([\d.]+\w+\/s))?(?:\s+ETA\s+(\S+))?/);
  if (progressMatch) {
    state.currentProgress = parseFloat(progressMatch[1]);
    if (progressMatch[3]) state.speed = progressMatch[3];
    if (progressMatch[4]) state.eta = progressMatch[4];
    broadcastState();
    return;
  }

  // [download] 100% of    5.36MiB
  const doneMatch = line.match(/100%\s+of/);
  if (doneMatch) {
    state.currentProgress = 100;
    broadcastState();
    return;
  }

  // [ExtractAudio] Destination: ...
  if (line.includes('[ExtractAudio]')) {
    state.status = 'converting';
    broadcastState();
    addLog(line, 'info');
    return;
  }

  // [download] Destination: filename
  const destMatch = line.match(/\[download\] Destination:\s+(.+)/);
  if (destMatch) {
    state.status = 'downloading';
    const filePath = destMatch[1];
    const baseName = path.basename(filePath).replace(/\.\w+$/, '');
    state.currentTitle = baseName;
    state.currentProgress = 0;
    broadcastState();
    addLog(line, 'info');
    return;
  }

  if (line.includes('has already been recorded in the archive') || line.includes('has already been downloaded')) {
    state.skipped++;
    addLog(line, 'dim');
    broadcastState();
    return;
  }

  // Handle ERROR messages
  if (line.includes('ERROR:')) {
    const errorMatch = line.match(/ERROR:\s*(?:\[youtube\]\s*)?([^:]+):\s*(.*)/);
    if (errorMatch) {
      const vid = errorMatch[1].trim();
      const reason = errorMatch[2].trim();
      // Avoid pushing duplicates
      if (!state.failedVideos.find(f => f.id === vid)) {
        state.failedVideos.push({ id: vid, reason });
        state.failed++;
      }
    } else {
      // Fallback if match fails
      state.failed++;
    }
    broadcastState();
  }

  // Finished downloading
  if (line.includes('[ExtractAudio]') && line.includes('Destination')) {
    state.downloaded = getArchiveCount();
    state.status = 'downloading';
    broadcastState();
  }

  // Periodic archive recount on any line mentioning download completion
  if (line.includes('Deleting original file')) {
    state.downloaded = getArchiveCount();
    state.status = 'downloading';
    broadcastState();
    addLog(line, 'dim');
    return;
  }

  // Generic log
  const type = line.includes('ERROR') ? 'error' : line.includes('WARNING') ? 'warn' : 'dim';
  addLog(line, type);
}

// ─── WebSocket ───────────────────────────────────────────────────────

wss.on('connection', (ws) => {
  // Send full state on connect
  const { logs, ...rest } = state;
  ws.send(JSON.stringify({ event: 'state', data: rest }));
  // Send last 200 logs
  state.logs.slice(-200).forEach(entry => {
    ws.send(JSON.stringify({ event: 'log', data: entry }));
  });
});

// ─── Start ───────────────────────────────────────────────────────────

server.listen(PORT, () => {
  console.log(`\n  🎵 YouTube Playlist → MP3 Dashboard`);
  console.log(`  ────────────────────────────────────`);
  console.log(`  Running at: http://localhost:${PORT}\n`);
});
