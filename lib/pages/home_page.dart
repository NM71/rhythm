import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/pages/library_scanning_page.dart';
import 'package:rhythm/components/my_drawer.dart';
import 'package:rhythm/components/song_options_bottom_sheet.dart';
import 'package:rhythm/models/playlist_provider.dart';
import 'package:rhythm/models/song.dart';
import 'package:rhythm/pages/song_page.dart';
import 'package:rhythm/pages/albums_page.dart';
import 'package:rhythm/pages/artists_page.dart';
import 'package:rhythm/pages/recently_played_page.dart';
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("S O N G S"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.library_music_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LibraryScanningPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<PlaylistProvider>(
        builder: (context, value, child) {
          if (value.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!value.permissionGranted) {
            return _buildPermissionDenied(value);
          }

          final List<Song> playlist = value.filteredPlaylist;

          return Column(
            children: [
              // Category Chips
              _buildCategoryChips(context),

              // Search and Sort Bar
              _buildSearchAndSortBar(context, value),

              Expanded(child: _buildMainContent(context, value, playlist)),
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

          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: song.isLocal
                  ? QueryArtworkWidget(
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
            title: Text(
              song.songName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              song.artistName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  song.formattedDuration,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => SongOptionsBottomSheet(song: song),
                    );
                  },
                ),
              ],
            ),
            onTap: () {
              value.loadListIntoQueue(playlist, initialIndex: index);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SongPage()),
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
                    ).colorScheme.inversePrimary.withOpacity(0.5),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(
                      context,
                    ).colorScheme.inversePrimary.withOpacity(0.5),
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
      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      child: Icon(
        Icons.music_note,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
