import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/models/playlist_provider.dart';
import 'package:on_audio_query/on_audio_query.dart';

class QueuePage extends StatelessWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("P L A Y I N G   Q U E U E"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              Provider.of<PlaylistProvider>(
                context,
                listen: false,
              ).clearQueue();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Consumer<PlaylistProvider>(
        builder: (context, value, child) {
          final queue = value.queue;

          if (queue.isEmpty) {
            return const Center(child: Text("Queue is empty"));
          }

          return ReorderableListView.builder(
            itemCount: queue.length,
            onReorder: (oldIndex, newIndex) {
              value.reorderQueue(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final song = queue[index];
              final bool isPlaying = value.currentQueueIndex == index;

              return ListTile(
                key: ValueKey(song.id.toString() + index.toString()),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: song.isLocal
                      ? QueryArtworkWidget(
                          id: song.id!,
                          type: ArtworkType.AUDIO,
                          artworkWidth: 50,
                          artworkHeight: 50,
                          artworkFit: BoxFit.cover,
                          nullArtworkWidget: Container(
                            width: 50,
                            height: 50,
                            color: Theme.of(context).colorScheme.secondary,
                            child: const Icon(Icons.music_note),
                          ),
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
                  style: TextStyle(
                    fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                    color: isPlaying
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
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
                    if (isPlaying)
                      Icon(
                        Icons.volume_up,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => value.removeFromQueue(index),
                    ),
                    const Icon(Icons.drag_handle),
                  ],
                ),
                onTap: () {
                  value.currentSongIndex = index;
                },
              );
            },
          );
        },
      ),
    );
  }
}
