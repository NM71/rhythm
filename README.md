<p align="center">
  <img src="android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" width="120" alt="Rhythm Logo">
</p>

# Rhythm

**Rhythm** is a premium offline music player for Android. Built with Flutter, it combines a beautiful Neumorphic design with high-performance audio engine optimizations.

## 🌟 Why Rhythm?

- **Premium UI**: Soft-UI Neumorphic design that feels tactile and modern.
- **Ultra-Smooth**: ZERO lag during playback thanks to decoupled UI/Audio timers.
- **Flicker-Free**: Gapless artwork transitions for a seamless visual experience.
- **Smart Search**: Token-based scoring helps you find your music instantly.
- **Full Control**: Folder-based library scanning & metadata editing.

## ⚡ Performance Highlights

- **Decoupled State**: High-frequency position updates don't trigger global UI rebuilds.
- **Background Pre-fetching**: Artwork bytes are loaded before the song starts to avoid flickering.
- **GPU Optimization**: Expensive shadows are isolated using `RepaintBoundary` for 60fps scrolling.

## 📸 Screenshots

<table>
  <tr>
    <td><strong>Splash Screen</strong></td>
    <td><strong>HomePage</strong></td>
    <td><strong>SongPage (dark)></td>
  </tr>
  <tr>
    <td><img src="android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" width="200"/></td>
    <td><img src="screenshots/2.webp" width="200"/></td>
    <td><img src="screenshots/3 (dark).webp" width="200"/></td>
  </tr>
  <tr>
    <td><strong>SongPage (light)</strong></td>
    <td><strong>Scan Library</strong></td>
    <td><strong>Edit Metadata</strong></td>
  </tr>
  <tr>
    <td><img src="screenshots/3 (light).webp" width="200"/></td>
    <td><img src="screenshots/4.webp" width="200"/></td>
    <td><img src="screenshots/5.webp" width="200"/></td>
  </tr>
    <tr>
    <td><strong>Playlists</strong></td>
    <td><strong>Settings</strong></td>
    <td><strong>About</strong></td>
  </tr>
  <tr>
    <td><img src="screenshots/6.webp" width="200"/></td>
    <td><img src="screenshots/7.webp" width="200"/></td>
    <td><img src="screenshots/8.webp" width="200"/></td>
  </tr>
</table>


## 🛠️ Setup

1. **Clone & Get Stats**:
   ```bash
   git clone https://github.com/your-username/rhythm.git
   cd rhythm
   flutter pub get
   ```
2. **Run**:
   ```bash
   flutter run
   ```

---
*Simple. Soft. Fast.*
