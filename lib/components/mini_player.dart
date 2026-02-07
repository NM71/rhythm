import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/models/playlist_provider.dart';
import 'package:rhythm/models/song.dart';
import 'package:rhythm/pages/song_page.dart';
import 'package:on_audio_query/on_audio_query.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, value, child) {
        if (value.currentSongIndex == null ||
            value.playlist.isEmpty ||
            value.currentSongIndex! >= value.playlist.length) {
          return const SizedBox.shrink();
        }

        final Song currentSong = value.playlist[value.currentSongIndex!];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SongPage()),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.black.withOpacity(0.1)
                      : Colors.black.withOpacity(0.4),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: currentSong.isLocal
                        ? QueryArtworkWidget(
                            id: currentSong.id!,
                            type: ArtworkType.AUDIO,
                            artworkWidth: 50,
                            artworkHeight: 50,
                            artworkFit: BoxFit.cover,
                            nullArtworkWidget: const Icon(Icons.music_note),
                          )
                        : Image.asset(
                            currentSong.albumArtImagePath ??
                                "assets/images/album_artwork_1.png",
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(width: 15),
                  // song info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSong.songName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentSong.artistName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.inversePrimary.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // controls
                  Row(
                    children: [
                      // previous
                      IconButton(
                        onPressed: value.playPreviousSong,
                        icon: const Icon(Icons.skip_previous),
                      ),
                      const SizedBox(width: 15),
                      // play/pause
                      IconButton(
                        onPressed: value.pauseOrResume,
                        icon: Icon(
                          value.isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 15),
                      // next
                      IconButton(
                        onPressed: value.playNextSong,
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
