import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/models/playlist_provider.dart';
import 'package:rhythm/models/song.dart';
import 'package:rhythm/pages/song_page.dart';
import 'package:rhythm/components/marquee_text.dart';
import 'package:on_audio_query/on_audio_query.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlaylistProvider>(context, listen: false);

    return Selector<PlaylistProvider, int?>(
      selector: (_, p) => p.currentSongIndex,
      builder: (context, currentSongIndex, child) {
        final Song? currentSong = provider.currentSong;

        if (currentSong == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SongPage()),
            );
          },
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.black.withAlpha((0.1 * 255).toInt())
                      : Colors.black.withAlpha((0.4 * 255).toInt()),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      // album art
                      Hero(
                        tag: 'song_artwork_${currentSong.id}',
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: currentSong.isLocal
                                ? QueryArtworkWidget(
                                    key: ValueKey(currentSong.id),
                                    id: currentSong.id!,
                                    type: ArtworkType.AUDIO,
                                    artworkWidth: 50,
                                    artworkHeight: 50,
                                    artworkFit: BoxFit.cover,
                                    nullArtworkWidget: Container(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                      child: const Icon(Icons.music_note),
                                    ),
                                  )
                                : Image.asset(
                                    currentSong.albumArtImagePath ??
                                        "assets/images/album_artwork_1.png",
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // song info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MarqueeText(
                              text: currentSong.songName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            MarqueeText(
                              text: currentSong.artistName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary
                                    .withAlpha((0.6 * 255).toInt()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // controls
                      Row(
                        children: [
                          // play/pause
                          Selector<PlaylistProvider, bool>(
                            selector: (_, p) => p.isPlaying,
                            builder: (context, isPlaying, child) {
                              return IconButton(
                                onPressed: provider.pauseOrResume,
                                icon: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  size: 30,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Progress Bar at the bottom
                Selector<PlaylistProvider, double>(
                  selector: (_, p) {
                    final total = p.totalDuration.inMilliseconds.toDouble();
                    final current = p.currentDuration.inMilliseconds.toDouble();
                    if (total == 0) return 0;
                    return (current / total).clamp(0.0, 1.0);
                  },
                  builder: (context, progress, child) {
                    return SizedBox(
                      height: 3,
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary.withAlpha(50),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
