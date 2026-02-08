import 'package:flutter/material.dart';
import 'package:rhythm/models/song.dart';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:rhythm/models/playlist.dart';
import 'package:audio_service/audio_service.dart';
import 'package:rhythm/models/audio_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum SortType { title, artist, duration, dateAdded }

class PlaylistProvider extends ChangeNotifier {
  final AudioHandler _audioHandler;

  // playlist of songs
  List<Song> _playlist = [];

  // Custom playlists
  List<Playlist> _customPlaylists = [];

  // Queue Management
  List<Song> _queue = [];
  int? _currentQueueIndex;

  // Search query
  String _searchQuery = '';

  // Sort options
  SortType _currentSortType = SortType.title;
  bool _sortAscending = true;

  // Recently Played
  List<Song> _recentlyPlayed = [];

  // Library Scanning Settings
  int _minSongDurationMs = 30000; // Default 30s

  final OnAudioQuery _audioQuery = OnAudioQuery();

  // Loading and permission states
  bool _isLoading = false;
  bool _permissionGranted = false;
  bool _isInitialized = false;

  // Durations
  Duration _currentDuration = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // Shuffle and Repeat states
  bool _isShuffle = false;
  bool _isRepeat = false;
  bool _isRepeatOne = false;

  // Hive Box Names
  static const String _favoritesBox = 'favorites_box';
  static const String _recentlyPlayedBox = 'recently_played_box';
  static const String _playlistsBox = 'playlists_box';
  static const String _settingsBox = 'settings_box';
  static const String _libraryCacheBox = 'library_cache_box';

  // Constructor
  PlaylistProvider({required AudioHandler audioHandler})
    : _audioHandler = audioHandler {
    _initPersistence().then((_) {
      if (_audioHandler is MyAudioHandler) {
        _audioHandler.onSkipToNext = playNextSong;
        _audioHandler.onSkipToPrevious = playPreviousSong;

        _audioHandler.onRepeatModeChanged = (mode) {
          if (mode == AudioServiceRepeatMode.one) {
            _isRepeatOne = true;
            _isRepeat = false;
          } else if (mode == AudioServiceRepeatMode.all) {
            _isRepeatOne = false;
            _isRepeat = true;
          } else {
            _isRepeatOne = false;
            _isRepeat = false;
          }
          notifyListeners();
        };

        _audioHandler.onShuffleModeChanged = (mode) {
          _isShuffle = mode == AudioServiceShuffleMode.all;
          notifyListeners();
        };
      }
      listenToDuration();
      // fetch songs on init is usually managed by UI, but we can call it here too
      // or rely on the UI calling it after permissions.
    });
  }

  Future<void> _initPersistence() async {
    // Open boxes
    await Hive.openBox(_favoritesBox);
    await Hive.openBox(_recentlyPlayedBox);
    await Hive.openBox(_playlistsBox);
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_libraryCacheBox);

    _loadData();
    _isInitialized = true;
    notifyListeners();
  }

  void _loadData() {
    // Load Favorites
    final favoritesBox = Hive.box(_favoritesBox);
    _favorites = List<int>.from(favoritesBox.get('ids', defaultValue: []));

    // Load Recently Played
    final recentBox = Hive.box(_recentlyPlayedBox);
    final recentItems = recentBox.get('songs', defaultValue: []);
    _recentlyPlayed = recentItems
        .map((item) => Song.fromMap(Map.from(item)))
        .toList()
        .cast<Song>();

    // Load Playlists
    final playlistBox = Hive.box(_playlistsBox);
    final playlistItems = playlistBox.get('items', defaultValue: []);
    _customPlaylists = playlistItems
        .map((item) => Playlist.fromMap(Map.from(item)))
        .toList()
        .cast<Playlist>();

    // Load Settings
    final settingsBox = Hive.box(_settingsBox);
    _minSongDurationMs = settingsBox.get('minDuration', defaultValue: 30000);

    // Load Library Cache
    final cacheBox = Hive.box(_libraryCacheBox);
    final cachedSongs = cacheBox.get('songs', defaultValue: []);
    if (cachedSongs.isNotEmpty) {
      _playlist = cachedSongs
          .map((item) => Song.fromMap(Map.from(item)))
          .toList()
          .cast<Song>();
    }

    notifyListeners();
  }

  void _saveFavorites() {
    Hive.box(_favoritesBox).put('ids', _favorites);
  }

  void _saveRecentlyPlayed() {
    Hive.box(
      _recentlyPlayedBox,
    ).put('songs', _recentlyPlayed.map((s) => s.toMap()).toList());
  }

  void _savePlaylists() {
    Hive.box(
      _playlistsBox,
    ).put('items', _customPlaylists.map((p) => p.toMap()).toList());
  }

  void _saveSettings() {
    Hive.box(_settingsBox).put('minDuration', _minSongDurationMs);
  }

  void _saveLibraryCache() {
    Hive.box(
      _libraryCacheBox,
    ).put('songs', _playlist.map((s) => s.toMap()).toList());
  }

  // Request permissions and fetch songs
  Future<void> fetchSongs() async {
    while (!_isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Request permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.audio, // For Android 13+
      ].request();

      if (statuses[Permission.storage]!.isGranted ||
          statuses[Permission.audio]!.isGranted) {
        _permissionGranted = true;

        // query songs
        List<SongModel> songs = await _audioQuery.querySongs(
          sortType: SongSortType.TITLE,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        );

        // Convert to our Song model and filter by duration
        _playlist = songs
            .where((song) => (song.duration ?? 0) >= _minSongDurationMs)
            .map((song) {
              return Song(
                songName: song.title,
                artistName: song.artist ?? "Unknown",
                albumName: song.album ?? "Unknown Album",
                audioPath: song.data,
                albumArtImagePath: null,
                id: song.id,
                isLocal: true,
                duration: song.duration ?? 0,
                dateAdded: song.dateAdded,
              );
            })
            .toList();
        _saveLibraryCache();
      } else {
        _permissionGranted = false;
      }
    } catch (e) {
      debugPrint('Error fetching songs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // initially not playing
  bool _isPlaying = false;

  // play song
  void play() async {
    if (_queue.isEmpty || _currentQueueIndex == null) return;

    // get song
    final Song song = _queue[_currentQueueIndex!];
    final String path = song.audioPath;

    // Reset durations for the new song
    _currentDuration = Duration.zero;
    _totalDuration = Duration(milliseconds: song.duration);
    notifyListeners();

    try {
      final mediaItem = MediaItem(
        id: path,
        album: song.albumName,
        title: song.songName,
        artist: song.artistName,
        duration: Duration(milliseconds: song.duration),
      );

      // Cast to MyAudioHandler if possible to use custom playSong method
      // or just use playMediaItem if implemented.
      // Since MyAudioHandler is a custom class, let's use it.
      if (_audioHandler is MyAudioHandler) {
        await _audioHandler.playSong(path, mediaItem, songId: song.id);
      } else {
        // Fallback or generic way if needed
      }

      _isPlaying = true;
      // Add to recently played
      _addToRecentlyPlayed(song);
    } catch (e) {
      debugPrint("Error playing song: $e");
      _isPlaying = false;
    }
    notifyListeners();
  }

  // pause current song
  void pause() async {
    await _audioHandler.pause();
    _isPlaying = false;
    notifyListeners();
  }

  // resume playing
  void resume() async {
    await _audioHandler.play();
    _isPlaying = true;
    notifyListeners();
  }

  // pause or resume
  void pauseOrResume() async {
    _isPlaying ? pause() : resume();
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  // toggle repeat
  void toggleRepeat() {
    if (_isRepeatOne) {
      _isRepeatOne = false;
      _isRepeat = false;
    } else if (_isRepeat) {
      _isRepeat = false;
      _isRepeatOne = true;
    } else {
      _isRepeat = true;
      _isRepeatOne = false;
    }
    notifyListeners();
  }

  // seek to a specific position in current song
  void seek(Duration position) async {
    await _audioHandler.seek(position);
  }

  // play next song
  void playNextSong() {
    if (_queue.isEmpty || _currentQueueIndex == null) return;

    if (_isShuffle) {
      if (_queue.length > 1) {
        int randomIndex;
        do {
          randomIndex = Random().nextInt(_queue.length);
        } while (randomIndex == _currentQueueIndex);
        _currentQueueIndex = randomIndex;
      }
    } else if (_isRepeatOne) {
      // stay on same index
    } else if (_currentQueueIndex! < _queue.length - 1) {
      _currentQueueIndex = _currentQueueIndex! + 1;
    } else {
      // wrap around to the first song
      _currentQueueIndex = 0;

      // If repeat is off and this was an auto-advance,
      // some might prefer to stop, but for a "Next" button
      // it should definitely play the first song.
      // We'll keep it simple and consistent with playPreviousSong for now.
    }
    play();
  }

  // play previous song
  void playPreviousSong() async {
    if (_queue.isEmpty || _currentQueueIndex == null) return;

    if (_currentDuration.inSeconds > 2) {
      seek(Duration.zero);
    } else {
      if (_currentQueueIndex! > 0) {
        _currentQueueIndex = _currentQueueIndex! - 1;
      } else {
        _currentQueueIndex = _queue.length - 1;
      }
      play();
    }
  }

  // listen to duration
  void listenToDuration() {
    // listen to playback state
    _audioHandler.playbackState.listen((state) {
      _isPlaying = state.playing;

      if (state.processingState == AudioProcessingState.completed) {
        playNextSong();
      }
      notifyListeners();
    });

    // Listen to real-time position updates
    if (_audioHandler is MyAudioHandler) {
      (_audioHandler as MyAudioHandler).positionStream.listen((position) {
        _currentDuration = position;
        notifyListeners();
      });
    }

    // listen to media item change (total duration)
    _audioHandler.mediaItem.listen((item) {
      if (item != null && item.duration != null) {
        _totalDuration = item.duration!;
        notifyListeners();
      }
    });
  }

  // Queue Management Methods
  List<Song> get queue => _queue;
  int? get currentQueueIndex => _currentQueueIndex;

  void loadListIntoQueue(List<Song> songs, {int initialIndex = 0}) {
    _queue = List.from(songs);
    _currentQueueIndex = initialIndex;
    play();
    notifyListeners();
  }

  void addToQueue(Song song) {
    _queue.add(song);
    notifyListeners();
  }

  void playNext(Song song) {
    if (_currentQueueIndex == null) {
      _queue = [song];
      _currentQueueIndex = 0;
      play();
    } else {
      _queue.insert(_currentQueueIndex! + 1, song);
    }
    notifyListeners();
  }

  void removeFromQueue(int index) async {
    if (index == _currentQueueIndex) {
      if (_queue.length > 1) {
        playNextSong();
        _queue.removeAt(index);
        // adjust index if needed
        if (_currentQueueIndex! > index) {
          _currentQueueIndex = _currentQueueIndex! - 1;
        }
      } else {
        await _audioHandler.stop();
        _queue.clear();
        _currentQueueIndex = null;
        _isPlaying = false;
      }
    } else {
      _queue.removeAt(index);
      if (_currentQueueIndex != null && _currentQueueIndex! > index) {
        _currentQueueIndex = _currentQueueIndex! - 1;
      }
    }
    notifyListeners();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final Song song = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, song);

    // update current index if it moved
    if (_currentQueueIndex == oldIndex) {
      _currentQueueIndex = newIndex;
    } else if (_currentQueueIndex! > oldIndex &&
        _currentQueueIndex! <= newIndex) {
      _currentQueueIndex = _currentQueueIndex! - 1;
    } else if (_currentQueueIndex! < oldIndex &&
        _currentQueueIndex! >= newIndex) {
      _currentQueueIndex = _currentQueueIndex! + 1;
    }

    notifyListeners();
  }

  void clearQueue() async {
    await _audioHandler.stop();
    _queue.clear();
    _currentQueueIndex = null;
    _isPlaying = false;
    notifyListeners();
  }

  // dispose
  @override
  void dispose() {
    // AudioHandler is usually singleton/global and doesn't need dispose here
    // but just_audio player inside should be disposed eventually.
    super.dispose();
  }

  // Favorites
  List<int> _favorites = [];
  List<int> get favorites => _favorites;

  void toggleFavorite(int id) {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
    _saveFavorites();
    notifyListeners();
  }

  bool isFavorite(int id) {
    return _favorites.contains(id);
  }

  void clearFavorites() {
    _favorites.clear();
    _saveFavorites();
    notifyListeners();
  }

  // ---------------------------------------------------------
  /* 
    
    G E T T E R S

    */

  List<Song> get playlist => _playlist;
  int? get currentSongIndex =>
      _currentQueueIndex; // Return queue index for compatibility
  bool get isPlaying => _isPlaying;
  Duration get currentDuration => _currentDuration;
  Duration get totalDuration => _totalDuration;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;
  bool get isRepeatOne => _isRepeatOne;
  List<int> get favoriteIds => List.from(_favorites);
  bool get isLoading => _isLoading;
  bool get permissionGranted => _permissionGranted;
  String get searchQuery => _searchQuery;
  List<Song> get recentlyPlayed => _recentlyPlayed;
  int get minSongDurationMs => _minSongDurationMs;

  Song? get currentSong =>
      (_currentQueueIndex != null &&
          _currentQueueIndex! >= 0 &&
          _currentQueueIndex! < _queue.length)
      ? _queue[_currentQueueIndex!]
      : null;

  int? get currentSongId => currentSong?.id;

  // Filtered playlist based on search
  List<Song> get filteredPlaylist {
    if (_searchQuery.isEmpty) return _playlist;
    final query = _searchQuery.toLowerCase();
    return _playlist.where((song) {
      return song.songName.toLowerCase().contains(query) ||
          song.artistName.toLowerCase().contains(query);
    }).toList();
  }

  // Get favorite songs
  List<Song> get favoriteSongs {
    return _playlist.where((song) => _favorites.contains(song.id)).toList();
  }

  // Get unique albums with song count
  List<Map<String, dynamic>> get albums {
    final albumMap = <String, List<Song>>{};
    for (final song in _playlist) {
      albumMap.putIfAbsent(song.albumName, () => []).add(song);
    }
    return albumMap.entries
        .map((e) => {'name': e.key, 'songs': e.value, 'count': e.value.length})
        .toList()
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  }

  // Get unique artists with song count
  List<Map<String, dynamic>> get artists {
    final artistMap = <String, List<Song>>{};
    for (final song in _playlist) {
      artistMap.putIfAbsent(song.artistName, () => []).add(song);
    }
    return artistMap.entries
        .map((e) => {'name': e.key, 'songs': e.value, 'count': e.value.length})
        .toList()
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Scanning refinements
  void setMinSongDuration(int durationMs) {
    _minSongDurationMs = durationMs;
    _saveSettings();
    fetchSongs(); // Re-scan with new filter
    notifyListeners();
  }

  Future<int> scanSongs() async {
    final oldSongIds = _playlist.map((s) => s.id).toSet();
    await fetchSongs();
    final newSongs = _playlist
        .where((s) => !oldSongIds.contains(s.id))
        .toList();
    return newSongs.length;
  }

  // Recently played logic
  void _addToRecentlyPlayed(Song song) {
    // remove if already exists to move to top
    _recentlyPlayed.removeWhere((s) => s.id == song.id);
    _recentlyPlayed.insert(0, song);

    // limit to 50
    if (_recentlyPlayed.length > 50) {
      _recentlyPlayed.removeLast();
    }
    _saveRecentlyPlayed();
    notifyListeners();
  }

  void clearRecentlyPlayed() {
    _recentlyPlayed.clear();
    _saveRecentlyPlayed();
    notifyListeners();
  }

  // Sort getters
  SortType get currentSortType => _currentSortType;
  bool get sortAscending => _sortAscending;

  // Sort the playlist
  void sortPlaylist(SortType sortType, {bool? ascending}) {
    _currentSortType = sortType;
    if (ascending != null) {
      _sortAscending = ascending;
    } else {
      // Toggle if same sort type
      if (_currentSortType == sortType) {
        _sortAscending = !_sortAscending;
      }
    }

    switch (sortType) {
      case SortType.title:
        _playlist.sort(
          (a, b) => _sortAscending
              ? a.songName.toLowerCase().compareTo(b.songName.toLowerCase())
              : b.songName.toLowerCase().compareTo(a.songName.toLowerCase()),
        );
        break;
      case SortType.artist:
        _playlist.sort(
          (a, b) => _sortAscending
              ? a.artistName.toLowerCase().compareTo(b.artistName.toLowerCase())
              : b.artistName.toLowerCase().compareTo(
                  a.artistName.toLowerCase(),
                ),
        );
        break;
      case SortType.duration:
        _playlist.sort(
          (a, b) => _sortAscending
              ? a.duration.compareTo(b.duration)
              : b.duration.compareTo(a.duration),
        );
        break;
      case SortType.dateAdded:
        _playlist.sort(
          (a, b) => _sortAscending
              ? (a.dateAdded ?? 0).compareTo(b.dateAdded ?? 0)
              : (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0),
        );
        break;
    }
    notifyListeners();
  }

  /* 
    
    S E T T E R S

    */

  set currentSongIndex(int? newIndex) {
    // update current song index
    _currentQueueIndex = newIndex;
    if (newIndex != null) {
      play(); // play the song which is at the new index
    }

    // update UI
    notifyListeners();
  }

  // ---------------------------------------------------------
  /* 
    S O N G   O P T I O N S
    */

  Future<void> shareSong(Song song) async {
    if (song.audioPath.isNotEmpty) {
      await Share.shareXFiles([
        XFile(song.audioPath),
      ], text: 'Listen to ${song.songName} by ${song.artistName}');
    }
  }

  Future<bool> removeFromLibrary(Song song) async {
    try {
      // 1. If currently playing, stop it
      final currentQueueIndex = _currentQueueIndex;
      if (currentQueueIndex != null &&
          _queue[currentQueueIndex].id == song.id) {
        await _audioHandler.stop();
        _isPlaying = false;
      }

      // 2. Remove from collections
      _queue.removeWhere((s) => s.id == song.id);
      _playlist.removeWhere((s) => s.id == song.id);
      _favorites.remove(song.id);
      _recentlyPlayed.removeWhere((s) => s.id == song.id);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error removing from library: $e");
      return false;
    }
  }

  Future<bool> deleteFromDevice(Song song) async {
    try {
      // 1. Remove from app first
      await removeFromLibrary(song);

      // 2. Delete from physical storage if local
      if (song.isLocal && song.audioPath.isNotEmpty) {
        final file = File(song.audioPath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error deleting from storage: $e");
      return false;
    }
  }

  // ---------------------------------------------------------
  /* 
    P L A Y L I S T   M A N A G E M E N T
    */

  List<Playlist> get customPlaylists => _customPlaylists;

  void createPlaylist(String name) {
    final newPlaylist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      songs: [],
    );
    _customPlaylists.add(newPlaylist);
    _savePlaylists();
    notifyListeners();
  }

  void deletePlaylist(Playlist playlist) {
    _customPlaylists.remove(playlist);
    _savePlaylists();
    notifyListeners();
  }

  void renamePlaylist(Playlist playlist, String newName) {
    playlist.name = newName;
    _savePlaylists();
    notifyListeners();
  }

  void addSongToPlaylist(Song song, Playlist playlist) {
    if (!playlist.songs.contains(song)) {
      playlist.songs.add(song);
      _savePlaylists();
      notifyListeners();
    }
  }

  void removeSongFromPlaylist(Song song, Playlist playlist) {
    playlist.songs.remove(song);
    _savePlaylists();
    notifyListeners();
  }
}
