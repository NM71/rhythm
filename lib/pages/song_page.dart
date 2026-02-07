import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/components/neu_box.dart';
import 'package:rhythm/models/playlist_provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:rhythm/components/song_options_bottom_sheet.dart';
import 'package:rhythm/pages/queue_page.dart';

class SongPage extends StatelessWidget {
  const SongPage({super.key});

  // Durations format function (min:sec format)
  String formatTime(Duration duration) {
    String twoDigitsSeconds = duration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    String formattedTime = "${duration.inMinutes}:$twoDigitsSeconds";

    return formattedTime;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, value, child) {
        // get queue
        final queue = value.queue;

        // Handle empty queue or null index
        if (queue.isEmpty || value.currentQueueIndex == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const Center(child: Text("No song selected")),
          );
        }

        // get current song
        final currentSong = queue[value.currentQueueIndex!];

        // return Scaffold UI
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 25.0, right: 25, bottom: 25),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // app bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // back button
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      // title
                      const Text("P L A Y I N G   N O W"),
                      // // queue button
                      // IconButton(
                      //   onPressed: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => const QueuePage(),
                      //       ),
                      //     );
                      //   },
                      //   icon: const Icon(Icons.queue_music),
                      // ),
                      // menu button
                      IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) =>
                                SongOptionsBottomSheet(song: currentSong),
                          );
                        },
                        icon: const Icon(Icons.more_vert),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),
                  // album art
                  NeuBox(
                    child: Column(
                      children: [
                        // image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: currentSong.isLocal
                              ? QueryArtworkWidget(
                                  id: currentSong.id!,
                                  type: ArtworkType.AUDIO,
                                  artworkWidth: 300,
                                  artworkHeight: 300,
                                  artworkFit: BoxFit.cover,
                                  nullArtworkWidget: const Icon(
                                    Icons.music_note,
                                    size: 200,
                                  ),
                                )
                              : Image.asset(
                                  currentSong.albumArtImagePath ??
                                      "assets/images/album_artwork_1.png",
                                ),
                        ),

                        // song/artist name
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Row(
                            mainAxisAlignment: .spaceBetween,
                            children: [
                              // song, artist name
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentSong.songName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    currentSong.artistName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              // fav icon
                              IconButton(
                                onPressed: () {
                                  value.toggleFavorite(currentSong.id ?? -1);
                                },
                                icon: Icon(
                                  value.isFavorite(currentSong.id ?? -1)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  // song duration slider
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // start/end time
                            Text(formatTime(value.currentDuration)),
                            // shuffle icon
                            Consumer<PlaylistProvider>(
                              builder: (context, value, child) {
                                return IconButton(
                                  onPressed: value.toggleShuffle,
                                  icon: Icon(
                                    Icons.shuffle,
                                    color: value.isShuffle
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                );
                              },
                            ),

                            // queue button
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const QueuePage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.queue_music),
                            ),

                            // repeat icon
                            Consumer<PlaylistProvider>(
                              builder: (context, value, child) {
                                return IconButton(
                                  onPressed: value.toggleRepeat,
                                  icon: Icon(
                                    value.isRepeatOne
                                        ? Icons.repeat_one
                                        : Icons.repeat,
                                    color: value.isRepeat || value.isRepeatOne
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                );
                              },
                            ),

                            // end time
                            Text(formatTime(value.totalDuration)),
                          ],
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: 4,
                          ),
                        ),
                        child: Slider(
                          value: value.currentDuration.inSeconds.toDouble(),
                          min: 0,
                          max: value.totalDuration.inSeconds.toDouble(),
                          activeColor: Theme.of(context).colorScheme.primary,
                          onChanged: (double double) {
                            // update current duration while dragging
                            value.seek(Duration(seconds: double.toInt()));
                          },
                          onChangeEnd: (double double) {
                            // sliding has finished, goto that position in song
                            value.seek(Duration(seconds: double.toInt()));
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // media controls
                  Row(
                    children: [
                      // skip previous
                      Expanded(
                        child: NeuBox(
                          child: IconButton(
                            onPressed: value.playPreviousSong,
                            icon: const Icon(Icons.skip_previous),
                          ),
                        ),
                      ),
                      const SizedBox(width: 25),
                      // play/pause
                      Expanded(
                        flex: 2,
                        child: NeuBox(
                          child: IconButton(
                            onPressed: value.pauseOrResume,
                            icon: Icon(
                              value.isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // skip forward
                      Expanded(
                        child: NeuBox(
                          child: IconButton(
                            onPressed: value.playNextSong,
                            icon: const Icon(Icons.skip_next),
                          ),
                        ),
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
