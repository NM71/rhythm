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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TextEditingController _searchController;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
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

          return Column(
            children: [
              // Category Chips
              _buildCategoryChips(context),

              // Search and Sort Bar
              _buildSearchAndSortBar(context, provider),

              // Song Count Display
              Expanded(
                child: Selector<PlaylistProvider, List<Song>>(
                  selector: (_, p) => p.filteredPlaylist,
                  builder: (context, playlist, _) {
                    return _buildMainContent(context, provider, playlist);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    PlaylistProvider value,
    List<Song> playlist,
  ) {
    if (playlist.isEmpty && value.searchQuery.isNotEmpty) {
      return _buildNoResults(value.searchQuery);
    }

    if (playlist.isEmpty && value.searchQuery.isEmpty) {
      return _buildEmptyState(value);
    }

    return RefreshIndicator(
      onRefresh: () => value.fetchSongs(),
      child: ListView.builder(
        itemCount: playlist.length + 1, // +1 for padding
        itemBuilder: (context, index) {
          if (index == playlist.length) {
            return const SizedBox(height: 100);
          }

          final Song song = playlist[index];

          return Selector<PlaylistProvider, bool>(
            selector: (_, p) => p.currentSongId == song.id,
            builder: (context, isPlaying, child) {
              return ListTile(
                leading: SizedBox(
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
                            nullArtworkWidget: _buildPlaceholderArt(context),
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
                title: Text(
                  song.songName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
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
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha((0.8 * 255).toInt())
                        : null,
                  ),
                ),
                trailing: Row(
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
                  value.loadListIntoQueue(playlist, initialIndex: index);
                },
              );
            },
          );
        },
      ),
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

          // Song Count
          Text(
            "${value.filteredPlaylist.length} Songs",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
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
                width: 40,
                height: 40,
              ),
              const SizedBox(height: 8),
              Text(
                'R H Y T H M',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Theme.of(sheetContext).colorScheme.inversePrimary,
                ),
              ),
              const SizedBox(height: 16),
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
                  showAboutDialog(
                    context: context,
                    applicationName: 'Rhythm',
                    applicationVersion: '1.0.0',
                    applicationIcon: Image.asset(
                      'assets/rhythm-logo-new.png',
                      color: Theme.of(context).colorScheme.inversePrimary,
                      width: 40,
                      height: 40,
                    ),
                    children: [const Text('Built with ❤️ by Nousher Murtaza')],
                  );
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
