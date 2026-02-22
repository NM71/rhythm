# Rhythm Music Player

Rhythm is a sleek, offline-first music player for Android, built with Flutter. It focuses on a premium Neumorphic design language while maintaining industry-leading performance and power efficiency.

![Rhythm Header](assets/images/album_artwork_1.png) <!-- Replace with a proper banner if available -->

## ✨ Features

- **Neumorphic UI**: A modern, soft-UI aesthetic for a premium tactile feel.
- **Offline Playback**: High-performance local library scanning and playback.
- **Queue Management**: Dynamic queue editing, reordering, and shuffle/repeat modes.
- **Smart Search**: Token-based scoring engine for instant, relevant music discovery.
- **Library Control**: Include or exclude specific folders to keep your music library clean.
- **Metadata Support**: View and edit song metadata on the fly.
- **Favorites & Playlists**: Create custom collections of your favorite tracks.

## 🚀 Performance-First Architecture

Unlike standard music players, Rhythm implements deep optimizations to ensure smooth 60fps interaction even on lower-end devices:

- **Decoupled Playback State**: High-frequency position updates (timers) are isolated using `ValueNotifier`, preventing global UI rebuilds.
- **Gapless Artwork Transitions**: Background pre-fetching of artwork bytes for the next song eliminates flickering during transitions.
- **Memory Optimization**: Adaptive artwork resizing and bitmap caching to significantly reduce RAM usage.
- **Isolated Shadows**: Shadow rendering is isolated via `RepaintBoundary` to minimize GPU repaint costs.

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Audio Core**: [audio_service](https://pub.dev/packages/audio_service) & [just_audio](https://pub.dev/packages/just_audio)
- **Storage**: [Hive](https://pub.dev/packages/hive) (High-performance NoSQL)
- **Metadata**: [on_audio_query](https://pub.dev/packages/on_audio_query) & [audiotags](https://pub.dev/packages/audiotags)

## 📦 Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio / VS Code with Flutter extension

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/rhythm.git
   ```
2. Navigate to the project directory:
   ```bash
   cd rhythm
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
*Created with ❤️ for music lovers.*
