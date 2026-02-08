import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/models/playlist_provider.dart';
import 'package:rhythm/models/song.dart';
import 'package:rhythm/components/playing_indicator.dart';
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
      body: Selector<PlaylistProvider, List<Song>>(
        selector: (_, p) => p.queue,
        builder: (context, queue, child) {
          final provider = Provider.of<PlaylistProvider>(
            context,
            listen: false,
          );

          if (queue.isEmpty) {
            return const Center(child: Text("Queue is empty"));
          }

          return ReorderableListView.builder(
            itemCount: queue.length,
            onReorder: (oldIndex, newIndex) {
              provider.reorderQueue(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final song = queue[index];

              return Selector<PlaylistProvider, int?>(
                key: ValueKey(song.id.toString() + index.toString()),
                selector: (_, p) => p.currentQueueIndex,
                builder: (context, currentQueueIndex, child) {
                  final bool isPlaying = currentQueueIndex == index;

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
                        fontWeight: isPlaying
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isPlaying
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPlaying)
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: PlayingIndicator(),
                          ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => provider.removeFromQueue(index),
                        ),
                        const Icon(Icons.drag_handle),
                      ],
                    ),
                    onTap: () {
                      provider.currentSongIndex = index;
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
