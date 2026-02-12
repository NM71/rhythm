import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/pages/library_scanning_page.dart';
import 'package:rhythm/components/my_drawer.dart';
import 'package:rhythm/components/song_options_bottom_sheet.dart';
import 'package:rhythm/models/playlist_provider.dart';
import 'package:rhythm/models/song.dart';
import 'package:rhythm/pages/albums_page.dart';
import 'package:rhythm/pages/artists_page.dart';
import 'package:rhythm/pages/recently_played_page.dart';
import 'package:rhythm/components/playing_indicator.dart';
import 'package:on_audio_query/on_audio_query.dart';

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
      drawer: const MyDrawer(),
      appBar: AppBar(
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    Selector<PlaylistProvider, int>(
                      selector: (_, p) => p.filteredPlaylist.length,
                      builder: (context, count, _) {
                        return Text(
                          "$count Songs",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.inversePrimary
                                .withAlpha((0.7 * 255).toInt()),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

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
        avatar: Icon(icon, size: 16),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.inversePrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        onPressed: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  PopupMenuItem<SortType> _sortItem(
    SortType type,
    String label,
    PlaylistProvider value,
  ) {
    return PopupMenuItem(
      value: type,
      child: Row(
        children: [
          Icon(
            type == SortType.title
                ? Icons.title
                : type == SortType.artist
                ? Icons.person
                : type == SortType.duration
                ? Icons.timer
                : Icons.calendar_today,
          ),
          const SizedBox(width: 8),
          Text(label),
          if (value.currentSortType == type)
            Icon(
              value.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndSortBar(BuildContext context, PlaylistProvider value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (query) => value.setSearchQuery(query),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                decoration: InputDecoration(
                  hintText: "Search songs, artists...",
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.inversePrimary.withAlpha((0.5 * 255).toInt()),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(
                      context,
                    ).colorScheme.inversePrimary.withAlpha((0.5 * 255).toInt()),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  suffixIcon: value.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
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
          const SizedBox(width: 12),
          // Sort Button
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(15),
            ),
            child: PopupMenuButton<SortType>(
              icon: Icon(
                Icons.sort_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: "Sort by",
              offset: const Offset(0, 50),
              onSelected: (sortType) => value.sortPlaylist(sortType),
              itemBuilder: (context) => [
                _sortItem(SortType.title, "Title", value),
                _sortItem(SortType.artist, "Artist", value),
                _sortItem(SortType.duration, "Duration", value),
                _sortItem(SortType.dateAdded, "Date Added", value),
              ],
            ),
          ),
        ],
      ),
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
