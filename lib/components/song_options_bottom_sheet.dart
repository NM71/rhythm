import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/models/playlist_provider.dart';
import 'package:rhythm/models/song.dart';
import 'package:rhythm/pages/edit_metadata_page.dart';

class SongOptionsBottomSheet extends StatelessWidget {
  final Song song;

  const SongOptionsBottomSheet({super.key, required this.song});

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 10),
            Text(
              "Song Details",
              style: TextStyle(
                color: Theme.of(context).colorScheme.inversePrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow(context, "Title", song.songName, Icons.title_rounded),
              _detailRow(
                context,
                "Artist",
                song.artistName,
                Icons.person_rounded,
              ),
              _detailRow(context, "Album", song.albumName, Icons.album_rounded),
              _detailRow(
                context,
                "Duration",
                song.formattedDuration,
                Icons.timer_rounded,
              ),
              _detailRow(
                context,
                "Type",
                song.isLocal ? "Local File" : "Asset",
                Icons.insert_drive_file_rounded,
              ),
              if (song.audioPath.isNotEmpty)
                _detailRow(
                  context,
                  "Path",
                  song.audioPath,
                  Icons.folder_open_rounded,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Close",
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.primary.withAlpha(180)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1.1,
                    color: colorScheme.primary.withAlpha(150),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.inversePrimary,
                  ),
                ),
              ],
            ),
          ),
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
          const Divider(color: Colors.transparent),
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
            leading: const Icon(Icons.edit_note),
            title: const Text("Edit Info"),
            onTap: () async {
              Navigator.pop(context);
              // ignore: use_build_context_synchronously
              final bool? result =
                  await Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (context) => EditMetadataPage(song: song),
                    ),
                  );

              if (result == true && context.mounted) {
                provider.fetchSongs();
              }
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
          const Divider(color: Colors.transparent),
          ListTile(
            leading: const Icon(Icons.remove_circle_outline),
            title: const Text("Remove from Library"),
            subtitle: const Text("Keep file, hide from app"),
            onTap: () => _confirmRemoveFromLibrary(context, provider),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text("Delete from Storage"),
            subtitle: const Text("Warning: Permanent removal"),
            onTap: () => _confirmDeleteFromDevice(context, provider),
          ),
        ],
      ),
    );
  }
}
