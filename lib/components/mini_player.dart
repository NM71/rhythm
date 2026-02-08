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
        if (currentSongIndex == null ||
            provider.playlist.isEmpty ||
            currentSongIndex >= provider.playlist.length) {
          return const SizedBox.shrink();
        }

        final Song currentSong = provider.playlist[currentSongIndex];

        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const SongPage(),
            );
          },
          child: Container(
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
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  // album art
                  SizedBox(
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
                                color: Theme.of(context).colorScheme.secondary,
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
                            color: Theme.of(context).colorScheme.inversePrimary
                                .withAlpha((0.6 * 255).toInt()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // controls
                  Row(
                    children: [
                      // previous
                      IconButton(
                        onPressed: provider.playPreviousSong,
                        icon: const Icon(Icons.skip_previous),
                      ),
                      const SizedBox(width: 15),
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
                      const SizedBox(width: 15),
                      // next
                      IconButton(
                        onPressed: provider.playNextSong,
                        icon: const Icon(Icons.skip_next),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
