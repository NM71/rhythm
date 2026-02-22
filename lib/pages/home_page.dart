import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/pages/library_scanning_page.dart';
import 'package:rhythm/components/song_options_bottom_sheet.dart';
import 'package:rhythm/models/playlist_provider.dart';
import 'package:rhythm/models/song.dart';
import 'package:rhythm/pages/albums_page.dart';
import 'package:rhythm/pages/artists_page.dart';
import 'package:rhythm/pages/recently_played_page.dart';
import 'package:rhythm/components/playing_indicator.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:rhythm/pages/settings_page.dart';
import 'package:rhythm/pages/about_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TextEditingController _searchController;

  // Selection Mode State
  bool _isSelectionMode = false;
  final Set<Song> _selectedSongs = {};

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<PlaylistProvider>(context, listen: false);
    provider.fetchSongs();
    _searchController = TextEditingController(text: provider.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(Song song) {
    setState(() {
      if (_selectedSongs.contains(song)) {
        _selectedSongs.remove(song);
        if (_selectedSongs.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedSongs.add(song);
      }
    });
  }

  void _enterSelectionMode(Song song) {
    setState(() {
      _isSelectionMode = true;
      _selectedSongs.clear();
      _selectedSongs.add(song);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedSongs.clear();
    });
  }

  void _selectAll(List<Song> allSongs) {
    setState(() {
      _selectedSongs.addAll(allSongs);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              ),
              title: Text("${_selectedSongs.length} Selected"),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: () {
                    final provider = Provider.of<PlaylistProvider>(
                      context,
                      listen: false,
                    );
                    _selectAll(provider.filteredPlaylist);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.playlist_add),
                  onPressed: () {
                    _showBatchAddToPlaylistDialog(context);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _showBatchDeleteDialog(context);
                  },
                ),
              ],
            )
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  _showMenuSheet(context);
                },
              ),
              title: const Text("S O N G S"),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.library_music_rounded),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (context) => const LibraryScanningPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
      body: Selector<PlaylistProvider, (bool, bool, int)>(
        selector: (_, p) =>
            (p.isLoading, p.permissionGranted, p.playlist.length),
        builder: (context, data, child) {
          final isLoading = data.$1;
          final permissionGranted = data.$2;
          final provider = Provider.of<PlaylistProvider>(
            context,
            listen: false,
          );

          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!permissionGranted) {
            return _buildPermissionDenied(provider);
          }

          return Selector<PlaylistProvider, List<Song>>(
            selector: (_, p) => p.filteredPlaylist,
            builder: (context, playlist, _) {
              return _buildScrollableContent(context, provider, playlist);
            },
          );
        },
      ),
    );
  }

  String _formatTotalDuration(List<Song> songs) {
    final totalMs = songs.fold<int>(0, (sum, s) => sum + s.duration);
    final hours = totalMs ~/ 3600000;
    final minutes = (totalMs % 3600000) ~/ 60000;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Widget _buildScrollableContent(
    BuildContext context,
    PlaylistProvider value,
    List<Song> playlist,
  ) {
    return CustomScrollView(
      cacheExtent: 1000, // Pre-render items for smoother scrolling
      slivers: [
        // Floating SliverAppBar with chips + search bar
        SliverAppBar(
          floating: true,
          snap: true,
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).colorScheme.surface,
          toolbarHeight: 0, // We only need the bottom section
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(130),
            child: Column(
              children: [
                _buildCategoryChips(context),
                _buildSearchAndSortBar(context, value),
              ],
            ),
          ),
        ),

        // Song count + total duration header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Text(
              '${playlist.length} songs • ${_formatTotalDuration(playlist)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.inversePrimary.withAlpha(140),
              ),
            ),
          ),
        ),

        // Main content
        if (playlist.isEmpty && value.searchQuery.isNotEmpty)
          SliverFillRemaining(child: _buildNoResults(value.searchQuery))
        else if (playlist.isEmpty && value.searchQuery.isEmpty)
          SliverFillRemaining(child: _buildEmptyState(value))
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == playlist.length) {
                  return const SizedBox(height: 100); // Padding for mini player
                }

                final Song song = playlist[index];

                return Selector<PlaylistProvider, bool>(
                  selector: (_, p) => p.currentSongId == song.id,
                  builder: (context, isPlaying, child) {
                    final isSelected = _selectedSongs.contains(song);

                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                      leading: _isSelectionMode
                          ? Checkbox(
                              value: isSelected,
                              activeColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              onChanged: (bool? value) {
                                _toggleSelection(song);
                              },
                            )
                          : RepaintBoundary(
                              child: SizedBox(
                                width: 50,
                                height: 50,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: song.isLocal
                                      ? QueryArtworkWidget(
                                          key: ValueKey(song.id),
                                          id: song.id!,
                                          type: ArtworkType.AUDIO,
                                          artworkWidth: 50,
                                          artworkHeight: 50,
                                          artworkFit: BoxFit.cover,
                                          format: ArtworkFormat
                                              .JPEG, // More efficient than PNG
                                          size:
                                              100, // Reduced quality for list items
                                          nullArtworkWidget:
                                              _buildPlaceholderArt(context),
                                        )
                                      : Image.asset(
                                          song.albumArtImagePath ??
                                              "assets/images/album_artwork_1.png",
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            ),
                      title: Text(
                        song.songName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isPlaying
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isPlaying
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        "${song.artistName} • ${song.formattedDuration}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isPlaying
                              ? Theme.of(context).colorScheme.primary.withAlpha(
                                  (0.8 * 255).toInt(),
                                )
                              : null,
                        ),
                      ),
                      trailing: _isSelectionMode
                          ? null
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isPlaying)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8.0),
                                    child: PlayingIndicator(),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      useRootNavigator: true,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) =>
                                          SongOptionsBottomSheet(song: song),
                                    );
                                  },
                                ),
                              ],
                            ),
                      onTap: () {
                        if (_isSelectionMode) {
                          _toggleSelection(song);
                        } else {
                          value.loadListIntoQueue(
                            playlist,
                            initialIndex: index,
                          );
                        }
                      },
                      onLongPress: () {
                        if (!_isSelectionMode) {
                          _enterSelectionMode(song);
                        }
                      },
                    );
                  },
                );
              },
              childCount: playlist.length + 1, // +1 for padding
            ),
          ),
      ],
    );
  }

  void _showBatchAddToPlaylistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Selected to Playlist"),
          content: SizedBox(
            width: double.maxFinite,
            child: Consumer<PlaylistProvider>(
              builder: (context, provider, child) {
                final playlists = provider.customPlaylists;
                if (playlists.isEmpty) {
                  return const Text("No playlists found. Create one first.");
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return ListTile(
                      title: Text(playlist.name),
                      onTap: () {
                        for (final song in _selectedSongs) {
                          provider.addSongToPlaylist(song, playlist);
                        }
                        Navigator.pop(context);
                        _exitSelectionMode();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Added ${_selectedSongs.length} songs to ${playlist.name}",
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  void _showBatchDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete ${_selectedSongs.length} songs?"),
          content: const Text(
            "This will permanently delete the selected files from your device. This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                final provider = Provider.of<PlaylistProvider>(
                  context,
                  listen: false,
                );
                int successCount = 0;
                // Clone the list because we might modify it or the provider's list
                final songsToDelete = List<Song>.from(_selectedSongs);

                for (final song in songsToDelete) {
                  if (await provider.deleteFromDevice(song)) {
                    successCount++;
                  }
                }

                _exitSelectionMode();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Deleted $successCount songs")),
                  );
                }
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChip(context, "Albums", Icons.album, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AlbumsPage()),
            );
          }),
          _buildChip(context, "Artists", Icons.person, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ArtistsPage()),
            );
          }),
          _buildChip(context, "Recent", Icons.history, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RecentlyPlayedPage(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(label),
        avatar: Icon(icon, size: 15),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.inversePrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        onPressed: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildSearchAndSortBar(BuildContext context, PlaylistProvider value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Search Bar
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withAlpha(50),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (query) => value.setSearchQuery(query),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: "Search...",
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.inversePrimary.withAlpha((0.5 * 255).toInt()),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: Theme.of(
                      context,
                    ).colorScheme.inversePrimary.withAlpha((0.5 * 255).toInt()),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  suffixIcon: value.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            value.setSearchQuery('');
                            _searchController.clear();
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Sort Icon Button
          Selector<PlaylistProvider, (SortType, bool)>(
            selector: (_, p) => (p.currentSortType, p.sortAscending),
            builder: (context, sortData, _) {
              return IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _showSortOptions(context, value),
                icon: Icon(
                  Icons.sort,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                tooltip: 'Sort',
              );
            },
          ),

          // Shuffle Button
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.shuffle_rounded),
            color: Theme.of(context).colorScheme.primary,
            onPressed: () {
              // Randomly pick and play a song
              if (value.playlist.isNotEmpty) {
                final randomIndex =
                    (DateTime.now().millisecondsSinceEpoch %
                    value.playlist.length);
                // Ensure shuffle mode is on if user explicitly asks for shuffle
                if (!value.isShuffle) {
                  value.toggleShuffle();
                }
                value.loadListIntoQueue(
                  value.playlist,
                  initialIndex: randomIndex,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSortOptions(BuildContext context, PlaylistProvider value) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true, // Display above bottom nav and miniplayer
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Sort By",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              _buildSortOption(
                context,
                value,
                SortType.dateAdded,
                "Date Added",
              ),
              _buildSortOption(context, value, SortType.title, "Title"),
              _buildSortOption(context, value, SortType.artist, "Artist"),
              _buildSortOption(context, value, SortType.duration, "Duration"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    PlaylistProvider value,
    SortType type,
    String label,
  ) {
    final isSelected = value.currentSortType == type;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.inversePrimary,
        ),
      ),
      trailing: isSelected
          ? Icon(
              value.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () {
        value.sortPlaylist(type);
        Navigator.pop(context);
      },
    );
  }

  void _showMenuSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    sheetContext,
                  ).colorScheme.inversePrimary.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // App Logo
              Image.asset(
                'assets/rhythm-logo-new.png',
                color: Theme.of(sheetContext).colorScheme.inversePrimary,
                width: 60,
                height: 60,
              ),
              const SizedBox(height: 8),
              Text(
                'R H Y T H M',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Theme.of(sheetContext).colorScheme.inversePrimary,
                ),
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.transparent),
              // Settings
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('S E T T I N G S'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
              ),
              // About
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('A B O U T'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).push(MaterialPageRoute(builder: (_) => const AboutPage()));
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoResults(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(PlaylistProvider value) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_off,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            "No songs found",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => value.fetchSongs(),
            child: const Text("Scan for Music"),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied(PlaylistProvider value) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            "Permission Required",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => value.fetchSongs(),
            child: const Text("Grant Permission"),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderArt(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      color: Theme.of(
        context,
      ).colorScheme.primary.withAlpha((0.2 * 255).toInt()),
      child: Icon(
        Icons.music_note,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
