import 'dart:math';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rhythm/models/song.dart';

class PlaylistProvider extends ChangeNotifier {
  final List<Song> _playlist = [];
  int? _currentSongIndex;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _currentDuration = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  final OnAudioQuery _audioQuery = OnAudioQuery();
  double _scanProgress = 0.0;
  bool _isScanning = false;

  bool _isShuffling = false;
  bool _isRepeating = false;


  bool get isShuffling => _isShuffling;
  bool get isRepeating => _isRepeating;



  void toggleShuffle() {
    _isShuffling = !_isShuffling;
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeating = !_isRepeating;
    notifyListeners();
  }

  PlaylistProvider() {
    listenToDuration();
    _loadInitialPlaylist();
  }

  void _loadInitialPlaylist() {
    _playlist.addAll([
      Song(
        songName: 'Tu Juliet',
        artistName: 'Diljit Dosanjh',
        albumArtImagePath: 'assets/images/tu_juliet_albumArt.jpg',
        audioPath: 'audio/Tu Juliet.mp3',
        isAsset: true,
      ),
      Song(
        songName: 'Haye Juliet',
        artistName: 'Diljit Dosanjh',
        albumArtImagePath: 'assets/images/haye_juliet_albumArt.jpg',
        audioPath: 'audio/Haye Juliet.mp3',
        isAsset: true,
      ),
    ]);
    notifyListeners();
  }

  Future<void> scanAudioFiles() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      try {
        _isScanning = true;
        _scanProgress = 0.0;
        notifyListeners();

        List<SongModel> songs = await _audioQuery.querySongs(
          sortType: null,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        );

        songs = songs.where((song) => song.size != null && song.size! > 1000000).toList();

        for (int i = 0; i < songs.length; i++) {
          if (!_isScanning) break; // Check if scanning was cancelled

          var song = songs[i];
          _playlist.add(Song(
            songName: song.title,
            artistName: song.artist ?? 'Unknown Artist',
            albumArtImagePath: '',
            audioPath: song.data,
            isAsset: false,
          ));

          _scanProgress = (i + 1) / songs.length;
          notifyListeners();

          // Add a small delay to allow the UI to update
          await Future.delayed(Duration(milliseconds: 10));
        }

        _isScanning = false;
        _scanProgress = 0.0;
        notifyListeners();
      } catch (e) {
        print("Error scanning audio files: $e");
        _isScanning = false;
        _scanProgress = 0.0;
        notifyListeners();
      }
    } else {
      print("Storage permission denied");
    }
  }

  void cancelScan() {
    _isScanning = false;
    _scanProgress = 0.0;
    notifyListeners();
  }


  void togglePlayPause(int index) {
    if (_currentSongIndex == index && _isPlaying) {
      pause();
    } else if (_currentSongIndex == index && !_isPlaying) {
      resume();
    } else {
      currentSongIndex = index;
    }
  }

  void play() async {
    if (_currentSongIndex != null && _currentSongIndex! < _playlist.length) {
      final song = _playlist[_currentSongIndex!];
      try {
        await _audioPlayer.stop();
        if (song.isAsset) {
          await _audioPlayer.play(AssetSource(song.audioPath));
        } else {
          await _audioPlayer.play(DeviceFileSource(song.audioPath));
        }
        _isPlaying = true;
        notifyListeners();
      } catch (e) {
        print("Error playing audio: $e");
      }
    }
  }

  void pause() async {
    await _audioPlayer.pause();
    _isPlaying = false;
    notifyListeners();
  }

  void resume() async {
    await _audioPlayer.resume();
    _isPlaying = true;
    notifyListeners();
  }

  void pauseOrResume() async {
    if (_isPlaying) {
      pause();
    } else {
      resume();
    }
    notifyListeners();
  }

  void seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void playNextSong() {
    if (_isRepeating) {
      seek(Duration.zero); // Restart the current song
      play();
    } else if (_isShuffling) {
      final randomIndex = (new Random()).nextInt(_playlist.length);
      currentSongIndex = randomIndex;
    } else {
      if (_currentSongIndex != null && _playlist.isNotEmpty) {
        if (_currentSongIndex! < _playlist.length - 1) {
          currentSongIndex = _currentSongIndex! + 1;
        } else {
          currentSongIndex = 0;
        }
      }
    }
  }


  void playPreviousSong() async {
    if (_currentDuration.inSeconds > 2) {
      seek(Duration.zero);
    } else {
      if (_currentSongIndex! > 0) {
        currentSongIndex = _currentSongIndex! - 1;
      } else {
        currentSongIndex = _playlist.length - 1;
      }
    }
  }

  void listenToDuration() {
    _audioPlayer.onDurationChanged.listen((newDuration) {
      _totalDuration = newDuration;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      _currentDuration = newPosition;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      playNextSong();
    });
  }

  List<Song> get playlist => _playlist;
  int? get currentSongIndex => _currentSongIndex;
  bool get isPlaying => _isPlaying;
  bool get isScanning => _isScanning;
  double get scanProgress => _scanProgress;
  Duration get currentDuration => _currentDuration;
  Duration get totalDuration => _totalDuration;

  set currentSongIndex(int? newIndex) {
    _currentSongIndex = newIndex;
    if (newIndex != null) {
      play();
    }
    notifyListeners();
  }
}