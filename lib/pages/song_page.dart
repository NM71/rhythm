
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/components/neu_box.dart';
import 'package:rhythm/models/playlist_provider.dart';

class SongPage extends StatelessWidget {
  const SongPage({Key? key}) : super(key: key);

  String formatTime(Duration duration) {
    String twoDigitSeconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    String formattedTime = "${duration.inMinutes}:$twoDigitSeconds";
    return formattedTime;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(builder: (context, value, child) {
      final playlist = value.playlist;
      final currentSong = playlist.isNotEmpty ? playlist[value.currentSongIndex ?? 0] : null;

      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 25, right: 25, bottom: 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 25),
                if (currentSong != null) ...[
                  NeuBox(
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(currentSong.albumArtImagePath),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentSong.songName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                  ),
                                  Text(currentSong.artistName),
                                ],
                              ),
                              const Icon(Icons.favorite, color: Colors.red),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(formatTime(value.currentDuration)),
                            GestureDetector(
                              onTap: value.toggleShuffle,
                              child: Icon(
                                Icons.shuffle_outlined,
                                color: value.isShuffling ? Colors.green : Theme.of(context).colorScheme.primary,
                                size: 25,
                              ),
                            ),
                            GestureDetector(
                              onTap: value.toggleRepeat,
                              child: Icon(
                                Icons.repeat_outlined,
                                color: value.isRepeating ? Colors.green : Theme.of(context).colorScheme.primary,
                                size: 25,
                              ),
                            ),
                            Text(formatTime(value.totalDuration)),
                          ],
                        ),

                      ),
                      const SizedBox(height: 25),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                        ),
                        child: Slider(
                          min: 0,
                          max: value.totalDuration.inSeconds.toDouble(),
                          value: value.currentDuration.inSeconds.toDouble(),
                          activeColor: Colors.green,
                          onChanged: (double double) {},
                          onChangeEnd: (double double) {
                            value.seek(Duration(seconds: double.toInt()));
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: value.playPreviousSong,
                          child: const NeuBox(child: Icon(Icons.skip_previous)),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: value.pauseOrResume,
                          child: NeuBox(
                            child: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: GestureDetector(
                          onTap: value.playNextSong,
                          child: const NeuBox(child: Icon(Icons.skip_next)),
                        ),
                      ),
                    ],
                  ),
                ],

              ],
            ),
          ),
        ),
      );
    });
  }
}