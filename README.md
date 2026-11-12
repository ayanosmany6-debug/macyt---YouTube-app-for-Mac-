# MacYT - Native YouTube Client

A native, lightweight, and professional YouTube client for macOS that outperforms web apps in RAM efficiency.

## 📦 Distribution

**Built as a Universal Binary** - Works on both Apple Silicon (M1/M2/M3/M4) AND Intel Macs.

**Includes bundled dependencies:**
- ✅ yt-dlp (video downloader)
- ✅ FFmpeg (format converter)

---

## ✨ Features

### Core Features
- ✅ **Built-in AdBlocker**: Blacks out all ads (not just hides)
- ✅ **SponsorBlock**: Auto-skips sponsored content
- ✅ **OLED Dark Mode**: Pure black theme for MacBook Pro screens
- ✅ **Zen Mode**: Hide sidebar and comments for focused viewing (⌘ + Z)
- ✅ **Auto-HD**: Forces highest quality playback automatically
- ✅ **Volume Scroll**: Adjust volume by scrolling over video
- ✅ **Picture-in-Picture**: Automatically pops into PiP when minimizing
- ✅ **System Media Keys**: Control playback with F7, F8, F9
- ✅ **Control Center Integration**: See what's playing in macOS menu bar

### Native Integration
- ✅ **Keyboard Shortcuts**: Space (play/pause), ⌘+M (minimize), ⌘+Shift+M (mute), etc.
- ✅ **Menu Bar Controls**: Play, pause, mute, download, go back/forward
- ✅ **Menu Bar Mini Player**: Mini player lives in menu bar when minimized
- ✅ **File Menu**: Home, Download Video, Minimize, Close, Go Back/Forward
- ✅ **Playback Menu**: Play/Pause, Mute, Speed, PiP
- ✅ **Tools Menu**: Download, OLED Mode, Zen Mode, Auto-HD
- ✅ **Settings**: Configure all preferences

### Download Features
- ✅ **yt-dlp Integration**: Download videos with format selection
- ✅ **FFmpeg Support**: Convert/download any format
- ✅ **No External Dependencies**: All tools bundled inside the app

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| <kbd>Space</kbd> | Play / Pause Video |
| <kbd>⌘</kbd> + <kbd>M</kbd> | Minimize (Smart PiP) |
| <kbd>⌘</kbd> + <kbd>Shift</kbd> + <kbd>M</kbd> | Mute / Unmute |
| <kbd>⌘</kbd> + <kbd>Option</kbd> + <kbd>O</kbd> | Toggle OLED Black Mode |
| <kbd>⌘</kbd> + <kbd>Z</kbd> | Toggle Zen Mode (Hide UI) |
| <kbd>⌘</kbd> + <kbd>X</kbd> | Force Auto-HD |
| <kbd>⌘</kbd> + <kbd>D</kbd> | Download Video |
| <kbd>⌘</kbd> + <kbd>,</kbd> | Open Settings |
| <kbd>[</kbd> | Go Back |
| <kbd>]</kbd> | Go Forward |

---

## 📱 Menu Bar Options

Click the YouTube icon in the menu bar for quick access:

- Restore Window
- Play / Pause
- Mute
- Download Video
- Go Back / Go Forward
- Quit

---

## 📁 File Menu

- **Home** - Return to YouTube homepage
- **Download Video** - Download current video using yt-dlp
- **Minimize** - Minimize the window
- **Close Window** - Close the window
- **Go Back** - Navigate back in history
- **Go Forward** - Navigate forward in history

---

## ▶️ Playback Menu

- **Play / Pause** - Toggle video playback
- **Mute** - Toggle audio mute
- **Playback Speed** - Adjust playback speed (0.5x - 2.0x)
- **Picture-in-Picture** - Enable PiP mode

---

## 🛠️ Tools Menu

- **Download Video** - Send video to yt-dlp for downloading
- **OLED Mode** - Enable pure black theme
- **Zen Mode (Hide UI)** - Hide sidebar and comments
- **Force High Quality (Auto-HD)** - Force highest quality playback

---

## ⚙️ Settings

Access via <kbd>⌘</kbd> + <kbd>,</kbd>:
- AdBlocker (Hide all ads)
- SponsorBlock (Auto-skip promos)
- Auto-HD (Force highest quality)
- OLED Pitch Black Mode
- Smart PiP (Pop out when switching)

---

## 🚀 Installation

1. **Open the DMG** - Double-click to open `MacYT.dmg`
2. **Drag to Applications** - Drag `MacYT.app` to your Applications folder
3. **First Launch** - If you see "App is damaged" error:
   - Double-click "Double-Click to Fix 'Damaged App' Error.command" in the DMG
   - Or run in Terminal: `xattr -cr /Applications/MacYT.app`

---

## 📦 What's Included

**No external dependencies required!** All tools are bundled inside the app:
- Native YouTube client with WKWebView
- yt-dlp video downloader
- FFmpeg format converter

---

## 🛠️ Build from Source

```bash
./build.sh
```

This generates the Universal Binary with bundled dependencies.

---

*Note: MacYT is not affiliated with Google or YouTube.*  
*Made by Ayan Osmany*  
*RAM Efficient • Native Performance • Privacy Focused • Offline Downloads Available*