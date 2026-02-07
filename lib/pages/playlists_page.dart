import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/models/playlist_provider.dart';
import 'package:rhythm/pages/favorites_page.dart';
import 'package:rhythm/pages/playlist_details_page.dart';

class PlaylistsPage extends StatelessWidget {
  const PlaylistsPage({super.key});

  void _showCreatePlaylistDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("New Playlist"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter playlist name"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Provider.of<PlaylistProvider>(
                  context,
                  listen: false,
                ).createPlaylist(name);
                Navigator.pop(context);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("P L A Y L I S T S"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showCreatePlaylistDialog(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Consumer<PlaylistProvider>(
        builder: (context, value, child) {
          final playlists = value.customPlaylists;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Favorites Playlist (Fixed at top)
              _buildPlaylistTile(
                context,
                title: "Favorites",
                count: value.favoriteIds.length,
                icon: Icons.favorite,
                iconColor: Colors.red,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FavoritesPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),

              // Custom Playlists
              if (playlists.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Text("No custom playlists yet"),
                  ),
                )
              else
                ...playlists.map(
                  (playlist) => _buildPlaylistTile(
                    context,
                    title: playlist.name,
                    count: playlist.songs.length,
                    icon: Icons.playlist_play,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PlaylistDetailsPage(playlist: playlist),
                        ),
                      );
                    },
                    onDelete: () {
                      value.deletePlaylist(playlist);
                    },
                  ),
                ),

              // Bottom padding for mini player
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlaylistTile(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    Color? iconColor,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: (iconColor ?? Theme.of(context).colorScheme.primary)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$count songs"),
        trailing: onDelete != null
            ? IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Theme.of(
                    context,
                  ).colorScheme.inversePrimary.withOpacity(0.5),
                ),
                onPressed: onDelete,
              )
            : Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(
                  context,
                ).colorScheme.inversePrimary.withOpacity(0.4),
              ),
      ),
    );
  }
}
