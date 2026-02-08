import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/models/playlist_provider.dart';
import 'package:rhythm/models/song.dart';
import 'package:rhythm/components/playing_indicator.dart';
import 'package:on_audio_query/on_audio_query.dart';

class RecentlyPlayedPage extends StatelessWidget {
  const RecentlyPlayedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("R E C E N T L Y   P L A Y E D"),
        centerTitle: true,
      ),
      body: Selector<PlaylistProvider, List<Song>>(
        selector: (_, p) => p.recentlyPlayed,
        builder: (context, recentlyPlayed, child) {
          final provider = Provider.of<PlaylistProvider>(
            context,
            listen: false,
          );

          if (recentlyPlayed.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withAlpha((0.5 * 255).toInt()),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No History Yet",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text("Songs you play will appear here."),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: recentlyPlayed.length,
            itemBuilder: (context, index) {
              final song = recentlyPlayed[index];

              return Selector<PlaylistProvider, int?>(
                selector: (_, p) => p.currentSongId,
                builder: (context, currentSongId, child) {
                  final bool isPlaying = currentSongId == song.id;

                  return ListTile(
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
                                color: Theme.of(context).colorScheme.primary
                                    .withAlpha((0.2 * 255).toInt()),
                                child: Icon(
                                  Icons.music_note,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
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
                    trailing: isPlaying ? const PlayingIndicator() : null,
                    onTap: () {
                      // Load recently played list into queue
                      provider.loadListIntoQueue(
                        recentlyPlayed,
                        initialIndex: index,
                      );
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
