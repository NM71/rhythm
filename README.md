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
