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
  List<String> _excludedFolders = [];
  List<String> _selectedFolders =
      []; // New: Explicitly selected folders to scan

  final OnAudioQuery _audioQuery = OnAudioQuery();

  // Loading and permission states
  bool _isLoading = true;
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

  // Cached lists for UI stability
  List<Map<String, dynamic>>? _cachedAlbums;
  List<Map<String, dynamic>>? _cachedArtists;
  List<Song>? _cachedFilteredPlaylist;
  String _lastFilteredQuery = '';

  // Constructor
  PlaylistProvider({required AudioHandler audioHandler})
    : _audioHandler = audioHandler {
    _initPersistence().then((_) {
      if (_audioHandler is MyAudioHandler) {
        _audioHandler.onSkipToNext = () => playNextSong(manual: true);
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
    _currentSortType =
        SortType.values[settingsBox.get('sortType', defaultValue: 0)];
    _sortAscending = settingsBox.get('sortAscending', defaultValue: true);
    _excludedFolders = List<String>.from(
      settingsBox.get('excludedFolders', defaultValue: []),
    );
    _selectedFolders = List<String>.from(
      settingsBox.get('selectedFolders', defaultValue: []),
    );

    // Load Library Cache
    final cacheBox = Hive.box(_libraryCacheBox);
    final cachedSongs = cacheBox.get('songs', defaultValue: []);
    if (cachedSongs.isNotEmpty) {
      _playlist = cachedSongs
          .map((item) => Song.fromMap(Map.from(item)))
          .toList()
          .cast<Song>();

      // Load last playback state info from cache if available
      final lastQueue = cacheBox.get('lastQueue', defaultValue: []);
      if (lastQueue.isNotEmpty) {
        _queue = lastQueue
            .map((item) => Song.fromMap(Map.from(item)))
            .toList()
            .cast<Song>();
        _currentQueueIndex = cacheBox.get('lastQueueIndex');

        final lastPosSeconds = cacheBox.get(
          'lastPositionSeconds',
          defaultValue: 0,
        );
        _currentDuration = Duration(seconds: lastPosSeconds);

        // Prepare the audio source so the user can play immediately
        _prepareRestoredSong();
      }
    }

    notifyListeners();
  }

  /// Prepare the audio player with the restored song (no auto-play)
  Future<void> _prepareRestoredSong() async {
    if (_queue.isEmpty || _currentQueueIndex == null) return;
    final song = _queue[_currentQueueIndex!];
    _totalDuration = Duration(milliseconds: song.duration);

    try {
      if (_audioHandler is MyAudioHandler) {
        final handler = _audioHandler;
        final mediaItem = MediaItem(
          id: song.audioPath,
          album: song.albumName,
          title: song.songName,
          artist: song.artistName,
          duration: Duration(milliseconds: song.duration),
        );
        await handler.prepareSong(
          song.audioPath,
          mediaItem,
          songId: song.id,
          initialPosition: _currentDuration,
        );
      }
    } catch (e) {
      debugPrint("Error preparing restored song: $e");
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
    final settingsBox = Hive.box(_settingsBox);
    settingsBox.put('minDuration', _minSongDurationMs);
    settingsBox.put('sortType', _currentSortType.index);
    settingsBox.put('sortAscending', _sortAscending);
    settingsBox.put('excludedFolders', _excludedFolders);
    settingsBox.put('selectedFolders', _selectedFolders);
  }

  void _saveLibraryCache() {
    Hive.box(
      _libraryCacheBox,
    ).put('songs', _playlist.map((s) => s.toMap()).toList());
  }

  void _savePlaybackState() {
    final cacheBox = Hive.box(_libraryCacheBox);
    cacheBox.put('lastQueue', _queue.map((s) => s.toMap()).toList());
    cacheBox.put('lastQueueIndex', _currentQueueIndex);
    cacheBox.put('lastPositionSeconds', _currentDuration.inSeconds);
  }

  void _refreshCaches() {
    _cachedAlbums = null;
    _cachedArtists = null;
    _cachedFilteredPlaylist = null;
    _lastFilteredQuery = '';
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

        // Convert to our Song model and filter by duration and folders
        _playlist = songs
            .where((song) {
              final bool durationMatch =
                  (song.duration ?? 0) >= _minSongDurationMs;
              if (!durationMatch) return false;

              final String path = song.data;
              final String folder = File(path).parent.path;

              // Inclusion filter: if selectedFolders is NOT empty, only scan those
              if (_selectedFolders.isNotEmpty) {
                bool found = false;
                for (final f in _selectedFolders) {
                  if (folder.startsWith(f)) {
                    found = true;
                    break;
                  }
                }
                if (!found) return false;
              }

              // Exclusion filter
              for (final f in _excludedFolders) {
                if (folder.startsWith(f)) return false;
              }

              return true;
            })
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

        // Re-apply current sorting
        sortPlaylist(_currentSortType, ascending: _sortAscending);

        _refreshCaches();
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
  void play({bool resume = false}) async {
    if (_queue.isEmpty || _currentQueueIndex == null) return;

    // get song
    final Song song = _queue[_currentQueueIndex!];
    final String path = song.audioPath;

    if (!resume) {
      // Reset durations for the new song if not resuming
      _currentDuration = Duration.zero;
    }
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

      if (_audioHandler is MyAudioHandler) {
        final handler = _audioHandler;
        if (resume) {
          // If resuming, just prepare the source and seek, don't necessarily play immediately if it was paused on start
          // But usually 'play' means play. For app restart, we might want 'prepare'.
          // Let's assume play is called when we want to start playing.
          await handler.playSong(
            path,
            mediaItem,
            songId: song.id,
            initialPosition: _currentDuration,
          );
        } else {
          await handler.playSong(path, mediaItem, songId: song.id);
        }
      }

      _isPlaying = true;
      // Add to recently played
      _addToRecentlyPlayed(song);
      _savePlaybackState();
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
    _savePlaybackState();
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
    _audioHandler.setShuffleMode(
      _isShuffle ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    );
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
  void seek(Duration position) {
    _audioHandler.seek(position);
  }

  // play next song
  // manual: true when the user explicitly taps skip (so repeat-one is ignored)
  void playNextSong({bool manual = false}) {
    if (_queue.isEmpty || _currentQueueIndex == null) return;

    if (_isShuffle) {
      if (_queue.length > 1) {
        int randomIndex;
        do {
          randomIndex = Random().nextInt(_queue.length);
        } while (randomIndex == _currentQueueIndex);
        _currentQueueIndex = randomIndex;
      }
    } else if (_isRepeatOne && !manual) {
      // stay on same index only for auto-completion
    } else if (_currentQueueIndex! < _queue.length - 1) {
      _currentQueueIndex = _currentQueueIndex! + 1;
    } else {
      // wrap around to the first song
      _currentQueueIndex = 0;
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

      // Note: We do NOT sync shuffle state from the audio handler here.
      // Our shuffle is managed at the queue level, not the player level.

      if (state.processingState == AudioProcessingState.completed) {
        playNextSong(manual: false);
      }
      notifyListeners();
    });

    // Listen to real-time position updates
    if (_audioHandler is MyAudioHandler) {
      final handler = _audioHandler;
      handler.positionStream.listen((position) {
        _currentDuration = position;

        // Save position every 5 seconds to avoid excessive writes
        if (position.inSeconds % 5 == 0) {
          _savePlaybackState();
        }
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
    _savePlaybackState();
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

  // Filtered playlist based on a professional scoring engine
  List<Song> get filteredPlaylist {
    if (_searchQuery.isEmpty) return _playlist;

    // Return cached result if query hasn't changed
    if (_searchQuery == _lastFilteredQuery && _cachedFilteredPlaylist != null) {
      return _cachedFilteredPlaylist!;
    }

    final query = _searchQuery.toLowerCase().trim();
    final queryTokens = query
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    if (queryTokens.isEmpty) return _playlist;

    // List to store songs with their calculated scores
    final List<MapEntry<Song, double>> scoredSongs = [];

    for (final song in _playlist) {
      double score = 0;
      final title = song.songName.toLowerCase();
      final artist = song.artistName.toLowerCase();
      final album = song.albumName.toLowerCase();

      // 1. Exact Full Phrase Match (Highest Boost)
      if (title == query) {
        score += 100;
      } else if (title.contains(query)) {
        score += 50;
      }

      if (artist == query) {
        score += 60;
      } else if (artist.contains(query)) {
        score += 30;
      }

      // 2. Token-based matching (Multi-word support)
      int matchedTokens = 0;
      for (final token in queryTokens) {
        bool tokenMatched = false;

        // Title Token (Weight 1.0)
        if (title.startsWith(token)) {
          score += 20;
          tokenMatched = true;
        } else if (title.contains(token)) {
          score += 10;
          tokenMatched = true;
        }

        // Artist Token (Weight 0.8)
        if (artist.startsWith(token)) {
          score += 16;
          tokenMatched = true;
        } else if (artist.contains(token)) {
          score += 8;
          tokenMatched = true;
        }

        // Album Token (Weight 0.6)
        if (album.startsWith(token)) {
          score += 12;
          tokenMatched = true;
        } else if (album.contains(token)) {
          score += 6;
          tokenMatched = true;
        }

        if (tokenMatched) matchedTokens++;
      }

      // 3. Score weighting based on coverage
      if (matchedTokens == 0) continue;

      if (matchedTokens < queryTokens.length) {
        // Penalty for partial matches (missing some words)
        score *= (matchedTokens / queryTokens.length) * 0.5;
      } else {
        // Bonus for matching all words in the search
        score += 50;
      }

      // Only include results with meaningful match scores
      if (score < 5) continue;

      scoredSongs.add(MapEntry(song, score));
    }

    // Sort by score (descending), then by current user sort preference
    scoredSongs.sort((a, b) {
      if (b.value != a.value) {
        return b.value.compareTo(a.value);
      }
      // If scores are tied, use the existing playlist order (which is already sorted)
      return _playlist.indexOf(a.key).compareTo(_playlist.indexOf(b.key));
    });

    _cachedFilteredPlaylist = scoredSongs.map((e) => e.key).toList();
    _lastFilteredQuery = _searchQuery;
    return _cachedFilteredPlaylist!;
  }

  // Get favorite songs
  List<Song> get favoriteSongs {
    return _playlist.where((song) => _favorites.contains(song.id)).toList();
  }

  // Get unique albums with song count
  List<Map<String, dynamic>> get albums {
    if (_cachedAlbums != null) return _cachedAlbums!;

    final albumMap = <String, List<Song>>{};
    for (final song in _playlist) {
      albumMap.putIfAbsent(song.albumName, () => []).add(song);
    }
    _cachedAlbums =
        albumMap.entries
            .map(
              (e) => {'name': e.key, 'songs': e.value, 'count': e.value.length},
            )
            .toList()
          ..sort(
            (a, b) => (a['name'] as String).compareTo(b['name'] as String),
          );
    return _cachedAlbums!;
  }

  // Get unique artists with song count
  List<Map<String, dynamic>> get artists {
    if (_cachedArtists != null) return _cachedArtists!;

    final artistMap = <String, List<Song>>{};
    for (final song in _playlist) {
      artistMap.putIfAbsent(song.artistName, () => []).add(song);
    }
    _cachedArtists =
        artistMap.entries
            .map(
              (e) => {'name': e.key, 'songs': e.value, 'count': e.value.length},
            )
            .toList()
          ..sort(
            (a, b) => (a['name'] as String).compareTo(b['name'] as String),
          );
    return _cachedArtists!;
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

  // Folder Management
  List<String> get excludedFolders => _excludedFolders;
  List<String> get selectedFolders => _selectedFolders;

  void toggleFolderExclusion(String path) {
    if (_excludedFolders.contains(path)) {
      _excludedFolders.remove(path);
    } else {
      _excludedFolders.add(path);
    }
    _saveSettings();
    fetchSongs();
    notifyListeners();
  }

  void toggleFolderSelection(String path) {
    if (_selectedFolders.contains(path)) {
      _selectedFolders.remove(path);
    } else {
      _selectedFolders.add(path);
    }
    _saveSettings();
    fetchSongs();
    notifyListeners();
  }

  void setSelectedFolders(List<String> folders) {
    _selectedFolders = List.from(folders);
    _saveSettings();
    fetchSongs();
    notifyListeners();
  }

  // Helper to discover all folders containing music
  Future<List<String>> discoverMusicFolders() async {
    final List<SongModel> songs = await _audioQuery.querySongs();
    final Set<String> folders = {};
    for (final s in songs) {
      folders.add(File(s.data).parent.path);
    }
    final List<String> sortedFolders = folders.toList()..sort();
    return sortedFolders;
  }

  Future<Map<String, String>> getStorageVolumes() async {
    Map<String, String> volumes = {};
    if (Platform.isAndroid) {
      // Internal Storage
      volumes['Internal Storage'] = '/storage/emulated/0';

      // Try to find SD Cards/External Storage
      try {
        final dir = Directory('/storage');
        if (await dir.exists()) {
          final list = dir.listSync();
          for (var entity in list) {
            if (entity is Directory) {
              final path = entity.path;
              if (path != '/storage/emulated' && path != '/storage/self') {
                final name = path.split('/').last;
                // Simple check to avoid pseudo-filesystems
                if (name.contains('-') ||
                    (name.length > 4 && !name.contains('emulated'))) {
                  volumes['SD Card ($name)'] = path;
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error finding storage volumes: $e');
      }
    } else {
      // For other platforms (unlikely here but good for safety)
      volumes['User Home'] = Platform.environment['HOME'] ?? '/';
    }
    return volumes;
  }

  Future<List<FileSystemEntity>> listDirectory(String path) async {
    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        return dir.listSync().where((entity) {
          // Hide hidden files/folders
          return !entity.path
              .split(Platform.pathSeparator)
              .last
              .startsWith('.');
        }).toList();
      }
    } catch (e) {
      debugPrint('Error listing directory $path: $e');
    }
    return [];
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

    List<Song> sortedList = List.from(_playlist); // Renew list reference

    switch (sortType) {
      case SortType.title:
        sortedList.sort(
          (a, b) => _sortAscending
              ? a.songName.toLowerCase().compareTo(b.songName.toLowerCase())
              : b.songName.toLowerCase().compareTo(a.songName.toLowerCase()),
        );
        break;
      case SortType.artist:
        sortedList.sort(
          (a, b) => _sortAscending
              ? a.artistName.toLowerCase().compareTo(b.artistName.toLowerCase())
              : b.artistName.toLowerCase().compareTo(
                  a.artistName.toLowerCase(),
                ),
        );
        break;
      case SortType.duration:
        sortedList.sort(
          (a, b) => _sortAscending
              ? a.duration.compareTo(b.duration)
              : b.duration.compareTo(a.duration),
        );
        break;
      case SortType.dateAdded:
        sortedList.sort(
          (a, b) => _sortAscending
              ? (a.dateAdded ?? 0).compareTo(b.dateAdded ?? 0)
              : (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0),
        );
        break;
    }
    _playlist = sortedList; // Assign the sorted list back
    _refreshCaches();
    _saveSettings();
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
          _queue.isNotEmpty &&
          _queue[currentQueueIndex].id == song.id) {
        await _audioHandler.stop();
        _isPlaying = false;
        // Move to next song if possible
        _queue.removeAt(currentQueueIndex);
        if (_queue.isNotEmpty) {
          _currentQueueIndex = currentQueueIndex < _queue.length
              ? currentQueueIndex
              : 0;
        } else {
          _currentQueueIndex = null;
        }
      } else {
        // Remove from queue and adjust index
        final removedIndex = _queue.indexWhere((s) => s.id == song.id);
        if (removedIndex >= 0) {
          _queue.removeAt(removedIndex);
          if (_currentQueueIndex != null &&
              removedIndex < _currentQueueIndex!) {
            _currentQueueIndex = _currentQueueIndex! - 1;
          }
        }
      }

      // 2. Remove from all collections
      _playlist.removeWhere((s) => s.id == song.id);
      _favorites.remove(song.id);
      _recentlyPlayed.removeWhere((s) => s.id == song.id);

      _refreshCaches();
      _saveLibraryCache();
      _saveFavorites();
      _saveRecentlyPlayed();
      _savePlaybackState();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error removing from library: $e");
      return false;
    }
  }

  Future<bool> deleteFromDevice(Song song) async {
    try {
      if (!song.isLocal || song.audioPath.isEmpty) return false;

      // 0. If this is the currently playing song, stop playback first
      // This ensures the file is not locked by the media player
      if (currentSong?.id == song.id) {
        debugPrint(
          "Stopping playback for song being deleted: ${song.songName}",
        );
        await _audioHandler.stop();
        _isPlaying = false;
        notifyListeners();
      }

      // 1. Handle MANAGE_EXTERNAL_STORAGE on Android 11+ (API 30+)
      if (Platform.isAndroid) {
        final status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          debugPrint("Requesting MANAGE_EXTERNAL_STORAGE");
          // On Android 11+, this opens the "All files access" settings page
          final result = await Permission.manageExternalStorage.request();
          if (!result.isGranted) {
            debugPrint("MANAGE_EXTERNAL_STORAGE permission denied");
            return false;
          }
        }
      }

      final file = File(song.audioPath);
      if (await file.exists()) {
        try {
          await file.delete();
          debugPrint("Successfully deleted file: ${song.audioPath}");
        } on FileSystemException catch (e) {
          debugPrint("FileSystemException during delete: $e");
          // If delete still fails, it might be due to scoped storage or other locks
          return false;
        }
      } else {
        debugPrint(
          "File does not exist on disk, removing from library only: ${song.audioPath}",
        );
      }

      // 2. Remove from app library after successful (or unnecessary) file deletion
      await removeFromLibrary(song);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error in deleteFromDevice: $e");
      return false;
    }
  }

  // ---------------------------------------------------------
  /* 
    P L A Y L I S T   M A N A G E M E N T
    */

  List<Playlist> get customPlaylists => _customPlaylists; // Playlists Logic
  Playlist createPlaylist(String name) {
    final playlist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      songs: [],
    );
    _customPlaylists.add(playlist);
    _savePlaylists();
    notifyListeners();
    return playlist;
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
