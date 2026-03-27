# YTSync - YouTube Playlist to MP3 Converter

## Overview
YTSync is a professional, robust web-based dashboard and backend engine designed for downloading YouTube playlists and converting them reliably to high-quality MP3 audio. It was built to handle large-scale playlists (500+ videos) with automatic resume, retry mechanisms, rate-limit handling, and connection drop safety.

## Features
- **Robust Downloader Engine:** Powered by `yt-dlp` and `ffmpeg`.
- **Cross-Platform Compatibility:** Runs seamlessly on macOS, Windows, and Linux.
- **Fail-Safe Processing:** Automatic tracking of completed files. If the process is halted, it will resume exactly where it left off without re-downloading files.
- **Web Dashboard:** Real-time monitoring of download progress, speeds, ETAs, and terminal-level log output via WebSockets.
- **Native Folder Picker:** Allows users to select output directories using the operating system's native folder selection dialog (macOS and Windows supported).
- **Data Management:** Built-in settings cache clearing capability to reset UI views while preserving downloaded MP3s.

## Prerequisites
Before running YTSync, ensure that the following dependencies are installed on your system and accessible via your system's PATH.

### 1. Node.js (Runtime)
Required to run the web server and dashboard.
- Download from: https://nodejs.org
- Verify installation:
  ```bash
  node -v
  npm -v
  ```

### 2. yt-dlp (Downloader Engine)
Required to fetch media streams from YouTube.
- **macOS:** `brew install yt-dlp`
- **Windows:** Download the `.exe` from the official repository and add it to your PATH, or use `winget install yt-dlp`.
- Verify installation:
  ```bash
  yt-dlp --version
  ```

### 3. FFmpeg (Audio Converter)
Required to extract and convert the media streams to MP3.
- **macOS:** `brew install ffmpeg`
- **Windows:** Download the pre-compiled binary from the official site and add it to your PATH, or use `winget install ffmpeg`.
- Verify installation:
  ```bash
  ffmpeg -version
  ```

## Installation

1. Clone or download this repository to your local machine.
2. Open a terminal (macOS/Linux) or Command Prompt/PowerShell (Windows).
3. Navigate to the project directory:
   ```bash
   cd "path/to/YTSync"
   ```
4. Install the required Node.js dependencies (Express and WebSockets):
   ```bash
   npm install express ws
   ```

## Usage

1. Start the YTSync server by running:
   ```bash
   npm start
   ```
   Or alternatively:
   ```bash
   node server.js
   ```
2. The terminal will display that the dashboard is running. Open your web browser and navigate to:
   `http://localhost:3000`

### Accessing the Dashboard
- **Dashboard Tab:** Paste your target YouTube Playlist URL (ensure it includes `list=...`), and click "Sync Playlist". Review the playlist metadata and begin the download.
- **Downloads Tab:** View all successfully downloaded and converted MP3s. The files will be grouped by their respective playlist folders.
- **Settings Tab:** Configure global application parameters:
  - **Download Directory:** Define where your MP3s should be saved. Selecting "Change" will prompt your operating system's native folder dialog.
  - **Download Defaults:** Set maximum speeds (e.g., 2 MB/s to prevent rate limits) and target audio bitrates.
  - **Data Management:** Utilize "Clear App Data" to remove temporary `.log` files and reset download state histories. This will never delete your MP3 files.

## Technical Notes
- **State Storage:** YTSync uses a `.yt-mp3-data` hidden folder inside the application directory to store state files (`settings.json`, temporary logs, and `_archive.txt` files). Discarding this folder will wipe the application's memory of what has been downloaded, causing it to re-parse playlists from scratch.
- **Output Structure:** By default, files are segmented into hierarchical folders based on the Playlist's title. Track numbers and track names are automatically prefixed to the MP3 files.
- **Concurrency & Rate Limits:** To prevent HTTP 429 Too Many Requests errors from YouTube, the default sleep interval between requests is set to 3 to 8 seconds. This is a crucial safety measure when processing playlists containing hundreds of videos.
