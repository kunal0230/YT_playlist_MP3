#  YTSync - YouTube Playlist to MP3 Converter

Welcome to **YTSync**! This tool helps you easily download entire YouTube playlists and convert them into high-quality MP3 audio files. It is designed to be simple, fast, and safe—even for playlists with hundreds of videos!

---

##  What makes YTSync great?
- **Easy Dashboard:** A beautiful, real-time website interface that shows you exactly what's downloading.
- **Smart Resume:** If you lose your internet connection or accidentally close the app, YTSync remembers where it stopped. It will never download the same song twice!
- **Download anywhere:** Click a button to choose exactly which folder on your computer you want the music saved to.
- **Safe from blocks:** It pauses automatically between downloads so YouTube doesn't block you.

---

##  Step 1: Install the Requirements
Before using YTSync, we need to quickly set up three helper tools on your computer. You only need to do this once!

### A. Install Node.js
This helps run the YTSync dashboard.
1. Go to **[Node.js Official Website](https://nodejs.org)**.
2. Download and install the version labeled **"LTS"** (Recommended for most users).
3. Follow the installation wizard and click "Next" until it finishes.

### B. Install yt-dlp (The Downloader)
This acts as the engine that actually downloads the videos.
- **If you use macOS:**  
  Open the "Terminal" app and type this, then press Enter:  
  `brew install yt-dlp`  
  *(Note: If it says "command not found: brew", you need to install Homebrew first. Search "Install Homebrew Mac" online for simple instructions.)*
- **If you use Windows:**  
  Open "Command Prompt" and type this, then press Enter:  
  `winget install yt-dlp`

### C. Install FFmpeg (The Audio Converter)
This takes the video and turns it into an MP3 file.
- **If you use macOS:**  
  Open "Terminal" and type:  
  `brew install ffmpeg`
- **If you use Windows:**  
  Open "Command Prompt" and type:  
  `winget install ffmpeg`

---

##  Step 2: How to start YTSync

Whenever you want to download music, follow these steps:

1. **Open your Terminal (macOS) or Command Prompt (Windows).**
2. **Navigate to the YTSync folder.**  
   Type `cd ` (don't forget the space!), then drag and drop the `YTSync` folder from your computer into the terminal window, and press Enter.
3. **Install the connection tools (Only needed the first time):**  
   Type `npm install` and press Enter.
4. **Start the app!**  
   Type `npm start` and press Enter. 
   *(Do not close this black window while you are downloading music!)*
5. **Open the Dashboard:**  
   Open your regular web browser (Chrome, Safari, etc.) and type this into the address bar:  
   **`http://localhost:3000`**

---

##  Step 3: Downloading your Music

Once you are on the YTSync website (`http://localhost:3000`), downloading is easy!

1. Go to YouTube and copy the link (URL) of the playlist you want.
2. Paste the link into the **"Sync New Playlist"** box.
3. Click the **"Sync Playlist"** button. The app will read the playlist and tell you how many songs are in it.
4. Click **"Start"**. 
5. Watch the dashboard as it downloads your music! You can see the progress ring fill up and monitor the speed.

### Useful Tips
- **Where did my music go?**  
  Click on the **"Settings"** tab on the left side. Under "Storage & Location", click "**Change**" to choose the exact folder on your computer where you want the MP3s to appear.
- **Failed Tracks:**  
  Sometimes YouTube blocks a video because of copyright or age restrictions. Don't worry! Click the **"Failed"** tab on the left side to see which songs were missed, and click the **"Retry All Failed"** button at the top to try downloading them again.
- **Dark Mode:**  
  Click the little sun/moon icon at the top right of the dashboard to change the color scheme!

---

*Enjoy your music!*
