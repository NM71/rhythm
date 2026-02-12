import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/models/playlist_provider.dart';
import 'package:rhythm/models/song.dart';

class SongOptionsBottomSheet extends StatelessWidget {
  final Song song;

  const SongOptionsBottomSheet({super.key, required this.song});

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("Song Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow("Title", song.songName),
            _detailRow("Artist", song.artistName),
            _detailRow("Album", song.albumName),
            _detailRow("Duration", song.formattedDuration),
            _detailRow("Type", song.isLocal ? "Local File" : "Asset"),
            if (song.audioPath.isNotEmpty) _detailRow("Path", song.audioPath),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _showPlaylistSelector(BuildContext context, PlaylistProvider provider) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Add to Playlist",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            if (provider.customPlaylists.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("No playlists created yet."),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.customPlaylists.length,
                  itemBuilder: (context, index) {
                    final playlist = provider.customPlaylists[index];
                    return ListTile(
                      leading: const Icon(Icons.playlist_play),
                      title: Text(playlist.name),
                      trailing: const Icon(Icons.add),
                      onTap: () {
                        provider.addSongToPlaylist(song, playlist);
                        Navigator.pop(context); // close selector
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Added to ${playlist.name}")),
                        );
                      },
                    );
                  },
                ),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text("Create New Playlist"),
              onTap: () {
                Navigator.pop(context); // close selector
                _showCreatePlaylistDialog(context, provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(
    BuildContext context,
    PlaylistProvider provider,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Playlist"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter playlist name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final newPlaylist = provider.createPlaylist(controller.text);
                // AUTO-ADD SONG
                provider.addSongToPlaylist(song, newPlaylist);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Created ${controller.text} and added ${song.songName}",
                    ),
                  ),
                );
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveFromLibrary(
    BuildContext context,
    PlaylistProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("Remove from Library?"),
        content: Text(
          "This will hide '${song.songName}' from the app, but the file will remain on your device storage.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close bottom sheet
              final success = await provider.removeFromLibrary(song);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? "Removed ${song.songName} from library"
                          : "Failed to remove song",
                    ),
                  ),
                );
              }
            },
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFromDevice(
    BuildContext context,
    PlaylistProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("Delete permanently?"),
        content: Text(
          "Are you sure you want to PERMANENTLY delete '${song.songName}' from your device storage? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close bottom sheet
              final success = await provider.deleteFromDevice(song);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? "Deleted ${song.songName} from device"
                          : "Failed to delete song",
                    ),
                  ),
                );
              }
            },
            child: const Text(
              "Delete Permanently",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlaylistProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.inversePrimary.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 15),
          // Song Info Header
          ListTile(
            leading: Icon(
              Icons.music_note,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              song.songName,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              song.artistName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(),
          // Options
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("Details"),
            onTap: () {
              Navigator.pop(context);
              _showDetails(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text("Add to Playlist"),
            onTap: () {
              Navigator.pop(context);
              _showPlaylistSelector(context, provider);
            },
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text("Share"),
            onTap: () {
              Navigator.pop(context);
              provider.shareSong(song);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.remove_circle_outline,
              color: Colors.orange,
            ),
            title: const Text("Remove from Library"),
            subtitle: const Text("Keep file, hide from app"),
            onTap: () => _confirmRemoveFromLibrary(context, provider),
          ),
          ListTile(
            leading: const Icon(
              Icons.delete_forever_outlined,
              color: Colors.red,
            ),
            title: const Text(
              "Delete from Storage",
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text("Warning: Permanent removal"),
            onTap: () => _confirmDeleteFromDevice(context, provider),
          ),
        ],
      ),
    );
  }
}
