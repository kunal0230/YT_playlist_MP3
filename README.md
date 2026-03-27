#  YTSync  YouTube Playlist to MP3 Converter

> Download entire YouTube playlists as high-quality MP3 files, with a live dashboard, smart resume, and zero duplicate downloads.

---

##  Table of Contents

1. [What is YTSync?](#what-is-ytsync)
2. [Before You Begin  System Requirements](#before-you-begin--system-requirements)
3. [Step 1  Install the Requirements](#step-1--install-the-requirements)
   - [A. Install Node.js](#a-install-nodejs)
   - [B. Install yt-dlp](#b-install-yt-dlp-the-downloader)
   - [C. Install FFmpeg](#c-install-ffmpeg-the-audio-converter)
   - [D. Verify Your Installation](#d-verify-your-installation-recommended)
4. [Step 2  Start YTSync for the First Time](#step-2--start-ytsync-for-the-first-time)
5. [Step 3  Download Your Music](#step-3--download-your-music)
6. [Understanding the Dashboard](#understanding-the-dashboard)
7. [Settings & Customization](#settings--customization)
8. [Troubleshooting Common Problems](#troubleshooting-common-problems)
9. [Frequently Asked Questions](#frequently-asked-questions)

---

## What is YTSync?

YTSync is a tool that runs on your own computer and lets you download entire YouTube playlists and save them as MP3 audio files. Instead of downloading one song at a time, you just paste a playlist link and YTSync handles everything automatically.

### What makes YTSync different?

| Feature | What it means for you |
|---|---|
| **Live Dashboard** | Watch each download happen in real-time, with a progress ring and speed meter |
| **Smart Resume** | If your internet cuts out or you close the app, it picks up exactly where it left off  no re-downloading |
| **No Duplicates** | Already downloaded a song? YTSync remembers and skips it automatically |
| **Safe from Blocks** | Automatically pauses between downloads so YouTube doesn't flag or block your activity |
| **Choose Your Folder** | Save your music wherever you want on your computer |
| **Handles Failures Gracefully** | Songs blocked by copyright or age restrictions are logged separately so you can retry them later |

---

## Before You Begin  System Requirements

YTSync works on both **Windows** and **macOS**. You'll need:

- A computer running **Windows 10/11** or **macOS 11 (Big Sur)** or newer
- A stable internet connection
- About **200 MB of free disk space** for the app itself (plus space for your music)
- A modern web browser (Chrome, Firefox, Safari, Edge  any of these will work)

>  **You do NOT need any programming experience.** Just follow each step carefully. The setup is a one-time process  after that, starting the app takes about 10 seconds.

---

## Step 1  Install the Requirements

YTSync depends on three tools to work. Think of them as the engine parts that make everything run. You only install these **once**.

| Tool | What it does |
|---|---|
| **Node.js** | Runs the YTSync dashboard (the website you'll interact with) |
| **yt-dlp** | The actual downloader  fetches videos from YouTube |
| **FFmpeg** | Converts the downloaded video into a clean MP3 audio file |

---

### A. Install Node.js

Node.js is a free, open-source tool used by millions of apps worldwide.

#### On Windows:
1. Open your browser and go to **[https://nodejs.org](https://nodejs.org)**
2. You will see two download buttons. Click the one labeled **"LTS"** (it says "Recommended For Most Users" underneath).
3. Once the file downloads, open it to start the installer.
4. Click **Next** on every screen  the default options are all correct.
5. When the final screen says "Finish", you're done.

#### On macOS:
1. Open your browser and go to **[https://nodejs.org](https://nodejs.org)**
2. Click the **"LTS"** download button. It will download a `.pkg` file.
3. Open the downloaded file and follow the installer. Click **Continue** and **Install** when prompted.
4. You may be asked to enter your Mac password  this is normal and required.

>  **How to confirm it worked:** Open Terminal (macOS) or Command Prompt (Windows), type `node --version`, and press Enter. You should see a version number like `v20.11.0`. If you do, Node.js is installed correctly.

---

### B. Install yt-dlp (The Downloader)

yt-dlp is the tool that actually talks to YouTube and fetches the audio.

#### On Windows:
1. Press the **Windows key**, type **"Command Prompt"**, and press Enter to open it.
2. Type the following command and press **Enter**:
   ```
   winget install yt-dlp
   ```
3. Wait for the installation to complete. You will see a success message.

>  **If `winget` gives an error:** Your version of Windows may not have it. Download yt-dlp manually from **[https://github.com/yt-dlp/yt-dlp/releases](https://github.com/yt-dlp/yt-dlp/releases)**  download the file named `yt-dlp.exe` and place it in your `C:\Windows\System32` folder.

#### On macOS:
1. Open the **Terminal** app. (Press `Cmd + Space`, type "Terminal", and hit Enter.)
2. Type the following command and press **Enter**:
   ```
   brew install yt-dlp
   ```
3. Wait for it to finish.

>  **If you see "command not found: brew":** You need to install Homebrew first. Go to **[https://brew.sh](https://brew.sh)**, copy the install command shown on that page, paste it into Terminal, and press Enter. Once Homebrew installs, run `brew install yt-dlp` again.

>  **How to confirm it worked:** Type `yt-dlp --version` and press Enter. You should see a version number.

---

### C. Install FFmpeg (The Audio Converter)

FFmpeg converts the downloaded file into a proper MP3. Without it, you'd end up with a video file instead of audio.

#### On Windows:
1. In **Command Prompt**, type the following and press **Enter**:
   ```
   winget install ffmpeg
   ```
2. Wait for the installation to finish.

#### On macOS:
1. In **Terminal**, type the following and press **Enter**:
   ```
   brew install ffmpeg
   ```
2. This may take a few minutes as FFmpeg is a larger package.

>  **How to confirm it worked:** Type `ffmpeg -version` and press Enter. You should see several lines of version information.

---

### D. Verify Your Installation (Recommended)

Before moving on, it's a good idea to confirm all three tools are installed correctly. Open your Terminal or Command Prompt and run these three commands one by one:

```
node --version
yt-dlp --version
ffmpeg -version
```

Each command should print a version number (not an error). If all three work, you're ready to move on. 

---

## Step 2  Start YTSync for the First Time

Follow these steps carefully. After the first time, starting the app is much faster (just steps 1, 2, and 4).

### Step-by-step:

**1. Open your terminal:**
- **macOS:** Press `Cmd + Space`, type "Terminal", and press Enter.
- **Windows:** Press the Windows key, type "Command Prompt", and press Enter.

**2. Navigate to the YTSync folder:**

You need to tell the terminal where the YTSync folder is. The easiest way:
- Type `cd ` (that's `cd` followed by a single space  don't press Enter yet)
- Now **drag and drop** the `YTSync` folder from your file manager directly into the terminal window
- The folder path will be filled in automatically
- Press **Enter**

>  Alternatively, if you know the path, you can type it directly. For example: `cd /Users/YourName/Downloads/YTSync` on Mac, or `cd C:\Users\YourName\Downloads\YTSync` on Windows.

**3. Install dependencies (First time only):**

Type this and press **Enter**:
```
npm install
```

This downloads the extra libraries that YTSync needs to run. You will see a lot of text scroll by  this is normal. Wait until it stops and you see your cursor again. This usually takes 30–60 seconds.

>  **You only need to do this once.** Next time you start YTSync, you can skip straight to step 4.

**4. Start the app:**

Type this and press **Enter**:
```
npm start
```

You should see a message like:
```
 YTSync is running at http://localhost:3000
```

>  **Important:** Do NOT close this terminal window while you are downloading music. The app runs inside it. Minimizing it is fine  just don't close it.

**5. Open the dashboard in your browser:**

Open Chrome, Safari, Firefox, or any browser, click the address bar at the top, type:
```
http://localhost:3000
```
...and press **Enter**. The YTSync dashboard will load.

---

## Step 3  Download Your Music

Once the dashboard is open, downloading a playlist is simple.

**1. Get your playlist link from YouTube:**
- Go to [youtube.com](https://youtube.com) and find the playlist you want.
- Click on the playlist title to open it.
- Copy the URL from your browser's address bar. It should look something like:
  `https://www.youtube.com/playlist?list=PLxxxxxxxxxxxxxxxx`

>  **Tip:** Make sure the URL contains `playlist?list=`  if it just says `watch?v=`, that's a single video, not a playlist.

**2. Paste the link into YTSync:**
- On the dashboard, find the box labeled **"Sync New Playlist"**.
- Click inside the box and paste your copied link (`Ctrl+V` on Windows, `Cmd+V` on Mac).

**3. Read the playlist:**
- Click the **"Sync Playlist"** button.
- YTSync will read the playlist from YouTube and display the total number of songs it found. This usually takes 5–15 seconds.

**4. Start downloading:**
- Click the **"Start"** button.
- The dashboard will begin downloading and converting your songs one by one.
- You can see a **progress ring** filling up for the current song, the download speed, and a count of how many songs are done.

**5. Wait for it to finish:**
- YTSync automatically pauses briefly between songs to stay safe from blocks.
- When all songs are complete, you will see a "Done" status on the dashboard.
- Your MP3 files are now saved in the output folder (see the tip below to choose where).

>  **Where did my music go?** By default, a folder called `downloads` is created inside the YTSync app folder. To change this to any folder on your computer, go to the **Settings** tab (see next section).

---

## Understanding the Dashboard

Here's a quick guide to what you'll see on the dashboard:

| Element | What it shows |
|---|---|
| **Progress Ring** | The circular animation shows how much of the current song has downloaded |
| **Speed Meter** | Shows your current download speed (e.g., `1.2 MB/s`) |
| **Song Counter** | Shows `X of Y done`  how many songs have been successfully downloaded so far |
| **Queue** | Lists the songs waiting to be downloaded |
| **Failed Tab** | Songs that couldn't be downloaded (copyright blocks, deleted videos, etc.) |
| **Sun/Moon Icon** | Toggles between light mode and dark mode |

---

## Settings & Customization

Click the **"Settings"** tab on the left sidebar to access these options:

### Storage & Location
- **Change Output Folder:** Click **"Change"** under "Storage & Location" to open a folder picker. Navigate to wherever you want your MP3s saved and select it. From now on, all downloads will go there.

### Handling Failed Downloads
Sometimes a video can't be downloaded. Common reasons include:
- The video is blocked in your country
- The video has age restrictions
- The video was deleted after the playlist was created
- YouTube rate-limited the download

**To retry failed downloads:**
1. Click the **"Failed"** tab in the left sidebar
2. You'll see a list of every song that didn't download, with a reason for each failure
3. Click **"Retry All Failed"** at the top to attempt those songs again
4. If a specific song keeps failing, it's likely permanently blocked and can't be downloaded

### Resume After Interruption
If the app closes unexpectedly or you lose internet:
1. Simply start the app again (`npm start`) and open `http://localhost:3000`
2. YTSync will detect the unfinished job and offer to resume it
3. Songs already downloaded will be skipped automatically  it picks up from where it left off

---

## Troubleshooting Common Problems

** "npm: command not found" when running `npm start`**
Node.js is not installed correctly, or your terminal hasn't refreshed. Try closing and reopening your terminal, then run `node --version` to confirm. If that also fails, reinstall Node.js from [nodejs.org](https://nodejs.org).

---

** The dashboard doesn't load at `http://localhost:3000`**
- Make sure you can still see your terminal window running `npm start`  it should not show any errors.
- Make sure you typed the address correctly: `http://localhost:3000` (not `https://`).
- Try a different browser.
- Check that no other app is using port 3000. If so, close it and restart YTSync.

---

** "yt-dlp: command not found" error in the dashboard**
yt-dlp is either not installed or not added to your system's PATH. Reinstall it following the instructions in Step 1B. On Windows, make sure `yt-dlp.exe` is in `C:\Windows\System32` if the winget method didn't work.

---

** Songs download but there's no audio / the file won't play**
FFmpeg is likely not installed or not found. Without FFmpeg, the file can't be converted to MP3. Reinstall it following Step 1C, then verify it works by running `ffmpeg -version` in your terminal.

---

** "This video is unavailable" for most songs**
YouTube may have temporarily flagged your IP for too many requests. Wait 30–60 minutes before trying again. YTSync's built-in delay reduces this risk, but very large playlists (200+ songs) can still occasionally trigger it.

---

**The app says it's downloading but no files appear in the folder**
Double-check your output folder in **Settings → Storage & Location**. Make sure you have write permission to that folder (it's not on a read-only drive or a protected system folder).

---

## Frequently Asked Questions

**Q: Is YTSync free?**
Yes, completely free and open-source.

**Q: Can I download a single video instead of a playlist?**
YTSync is optimized for playlists. For single videos, yt-dlp can be used directly from the terminal.

**Q: Will this work for private or unlisted playlists?**
Only if you are logged into YouTube in the same browser session and the playlist belongs to your account. Fully private playlists owned by other people cannot be downloaded.

**Q: What audio quality are the MP3s?**
By default, YTSync downloads the highest available audio quality YouTube offers and converts it to MP3. This is typically 128–192 kbps for most videos.

**Q: Can I close my browser while it's downloading?**
Yes! The downloads continue running in the background as long as the terminal window is still open. You can close and reopen your browser without affecting the downloads.

**Q: Can I run multiple playlists at the same time?**
It's recommended to run one playlist at a time. Starting a second playlist while one is in progress may cause conflicts.

**Q: Do I need to run `npm install` every time?**
No  only the very first time. After that, just `npm start` is enough.

---

*YTSync is intended for personal, non-commercial use. Please respect copyright laws and the terms of service of the platforms you use.*
