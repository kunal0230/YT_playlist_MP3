# YTSync

Download entire YouTube playlists as MP3s. Runs locally, resumes on crash, skips already-downloaded tracks, and ships with a real-time web dashboard.

---

## Requirements

- **Node.js** ≥ 18 — [nodejs.org](https://nodejs.org) (download the LTS version)
- **yt-dlp** — the actual downloader
- **ffmpeg** — handles audio conversion

### Install yt-dlp + ffmpeg

**macOS**
```bash
brew install yt-dlp ffmpeg
```
No Homebrew? Install it first: [brew.sh](https://brew.sh)

**Windows**
```bash
winget install yt-dlp
winget install ffmpeg
```
If `winget` isn't available, grab `yt-dlp.exe` from the [releases page](https://github.com/yt-dlp/yt-dlp/releases) and drop it in `C:\Windows\System32`.

**Verify everything is in place:**
```bash
node --version
yt-dlp --version
ffmpeg -version
```
All three should print version numbers, not errors.

---

## Installation

```bash
git clone https://github.com/kunal0230/YT_playlist_MP3.git
cd YT_playlist_MP3
npm install
```

`npm install` only needs to run once. After that, skip straight to `npm start`.

---

## Running the App

```bash
npm start
```

Open `http://localhost:3000` in your browser. The terminal window must stay open while downloads are running — minimizing it is fine, closing it stops everything.

---

## Downloading a Playlist

1. Go to YouTube, open the playlist, and copy the URL from the address bar.
   It should contain `playlist?list=` — if it just says `watch?v=`, that's a single video.

2. Paste the URL into the **Sync New Playlist** field and click **Sync Playlist**.
   YTSync fetches the playlist metadata and shows you the total track count and how many are already downloaded.

3. Click **Start**. Downloads begin immediately.

Progress, speed, and per-track status update live in the dashboard.

### Advanced Options

Click **Advanced options** under the URL field to expand:

| Option | Default | Description |
|--------|---------|-------------|
| Quality | 320 kbps | Audio bitrate for the output MP3 |
| Speed Limit | 2 MB/s | Per-file download cap. Set to "No limit" to remove it |
| Start From | — | Skip to a specific track number in the playlist |
| End At | — | Stop after this track number |
| Browser Cookies | Disabled | Pass your browser session to bypass age restrictions or "Video unavailable" blocks |

---

## Resuming After Interruption

YTSync writes a per-playlist archive file that tracks every downloaded video. If the process stops for any reason — network drop, app crash, manual stop — just run `npm start` again and click **Start** on the same playlist. Already-downloaded tracks are skipped automatically.

---

## Failed Downloads

Some videos can't be downloaded: deleted videos, region blocks, copyright claims, or age restrictions without cookies enabled. These show up under the **Failed** tab with a reason for each failure.

Click **Retry All Failed** to attempt them again. If a track keeps failing after retries, it's either permanently blocked or no longer available.

---

## Changing the Output Folder

By default, MP3s are saved to `~/Downloads/YTSync`. To change it:

- Go to **Settings → Storage & Location → Change**
- Pick any folder on your computer

All subsequent downloads will go there. The change persists across restarts.

---

## Bash Script (Headless / Server Use)

If you don't need the dashboard, `yt-playlist-mp3.sh` handles everything from the terminal:

```bash
# Download a full playlist
./yt-playlist-mp3.sh "https://youtube.com/playlist?list=PLxxxxx"

# Download a specific range of tracks
./yt-playlist-mp3.sh --range 50 150 "https://..."

# Check how many tracks have been downloaded
./yt-playlist-mp3.sh --status "https://..."

# Retry previously failed videos
./yt-playlist-mp3.sh --retry-failed "https://..."

# List playlist contents without downloading anything
./yt-playlist-mp3.sh --dry-run "https://..."

# Run in background with tmux
tmux new -s downloads './yt-playlist-mp3.sh "https://..."'
```

All the same resume and deduplication logic applies.

---

## Common Issues

**`npm: command not found`**
Node.js isn't installed or the terminal hasn't picked it up yet. Close and reopen the terminal, then run `node --version`. If that still fails, reinstall Node from [nodejs.org](https://nodejs.org).

**Dashboard doesn't load at `localhost:3000`**
Make sure the terminal running `npm start` is still open and shows no errors. Also check you're using `http://` not `https://`.

**`yt-dlp: command not found` error in the dashboard**
yt-dlp isn't on your PATH. Reinstall it and verify with `yt-dlp --version` in a fresh terminal.

**Files download but won't play / no audio**
ffmpeg is missing or not found. Run `ffmpeg -version` to check. Without it, the file stays as a video container instead of converting to MP3.

**Most tracks fail with "Video unavailable"**
YouTube rate-limited your IP. Wait 30–60 minutes. For persistent failures on age-restricted content, enable **Browser Cookies** in Settings and make sure the relevant browser is closed before starting.

**App says it's running but no files appear**
Check Settings → Storage & Location to confirm the output path. Make sure the destination folder exists and you have write permission to it.

---

## File Layout

```
YT_playlist_MP3/
├── server.js
├── public/
│   └── index.html
├── yt-playlist-mp3.sh
└── .yt-mp3-data/
    ├── settings.json
    ├── {playlist_id}_archive.txt
    └── {playlist_id}_download.log
```

The `.yt-mp3-data/` directory is created automatically on first run. Don't delete the archive files unless you want YTSync to re-download everything from scratch. The **Settings → Clear App Data** button does this safely.

---

## Notes

- One playlist at a time. Running two simultaneous downloads against the same archive file will cause conflicts.
- Private playlists work only if the owning account's browser cookies are passed via the cookies option.
- The native folder picker (Settings → Change) is macOS and Windows only. On Linux, edit `.yt-mp3-data/settings.json` directly.
- For personal, non-commercial use.
