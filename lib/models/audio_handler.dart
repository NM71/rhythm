import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:typed_data';
import 'dart:io';

class MyAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final _audioQuery = OnAudioQuery();
  VoidCallback? onSkipToNext;
  VoidCallback? onSkipToPrevious;
  ValueChanged<AudioServiceRepeatMode>? onRepeatModeChanged;
  ValueChanged<AudioServiceShuffleMode>? onShuffleModeChanged;

  Stream<Duration> get positionStream => _player.positionStream;

  MyAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Broadcast state changes
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Listen to errors
    _player.playbackEventStream.listen(
      (event) {},
      onError: (Object e, StackTrace st) {
        debugPrint('Audio Player Error: $e');
      },
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (onSkipToNext != null) onSkipToNext!();
  }

  @override
  Future<void> skipToPrevious() async {
    if (onSkipToPrevious != null) onSkipToPrevious!();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    if (onRepeatModeChanged != null) onRepeatModeChanged!(repeatMode);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (onShuffleModeChanged != null) onShuffleModeChanged!(shuffleMode);
  }

  @override
  Future<void> fastForward() =>
      _player.seek(_player.position + const Duration(seconds: 10));

  @override
  Future<void> rewind() =>
      _player.seek(_player.position - const Duration(seconds: 10));

  // Custom method to play specific song
  Future<void> playSong(String path, MediaItem item, {int? songId}) async {
    // try to get artwork if it's a local song
    MediaItem itemWithArtwork = item;
    if (songId != null) {
      try {
        final Uint8List? artBytes = await _audioQuery.queryArtwork(
          songId,
          ArtworkType.AUDIO,
          format: ArtworkFormat.JPEG,
        );

        if (artBytes != null) {
          // Create a temp file or use artHeaders?
          // audio_service supports artUri, but for bytes it's better to save to temp file
          // Just_audio/AudioService handles 'file://' or 'content://' or 'HTTPS'
          // We'll save it to a temporary location.
          final tempDir = Directory.systemTemp;
          final artFile = File('${tempDir.path}/art_$songId.jpg');
          await artFile.writeAsBytes(artBytes);

          itemWithArtwork = item.copyWith(artUri: Uri.file(artFile.path));
        }
      } catch (e) {
        debugPrint("Error fetching artwork for notification: $e");
      }
    }

    mediaItem.add(itemWithArtwork);
    if (path.startsWith('assets/')) {
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse('asset:///$path')),
      );
    } else {
      await _player.setAudioSource(AudioSource.uri(Uri.parse('file://$path')));
    }
    await _player.play();
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
        MediaControl.fastForward,
        MediaControl.rewind,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
        MediaAction.stop,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
