import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/components/neu_box.dart';
import 'package:rhythm/models/playlist_provider.dart';
import 'package:rhythm/components/marquee_text.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:rhythm/components/song_options_bottom_sheet.dart';
import 'package:rhythm/pages/queue_page.dart';

class SongPage extends StatefulWidget {
  const SongPage({super.key});

  @override
  State<SongPage> createState() => _SongPageState();
}

class _SongPageState extends State<SongPage> {
  Timer? _seekTimer;

  // Durations format function (min:sec format)
  String formatTime(Duration duration) {
    String twoDigitsSeconds = duration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    String formattedTime = "${duration.inMinutes}:$twoDigitsSeconds";

    return formattedTime;
  }

  void _startSeeking(PlaylistProvider provider, bool forward) {
    _seekTimer?.cancel();
    _seekTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      final current = provider.currentDuration;
      final total = provider.totalDuration;
      final step = const Duration(seconds: 2);

      if (forward) {
        final newPos = current + step;
        provider.seek(newPos < total ? newPos : total);
      } else {
        final newPos = current - step;
        provider.seek(newPos > Duration.zero ? newPos : Duration.zero);
      }
    });
  }

  void _stopSeeking() {
    _seekTimer?.cancel();
    _seekTimer = null;
  }

  @override
  void dispose() {
    _seekTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlaylistProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 25.0,
                vertical: 10,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      20,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                        // menu button
                        Selector<PlaylistProvider, int?>(
                          selector: (_, p) => p.currentQueueIndex,
                          builder: (context, currentQueueIndex, _) {
                            if (currentQueueIndex == null ||
                                provider.queue.isEmpty) {
                              return const SizedBox(width: 48);
                            }
                            final song = provider.queue[currentQueueIndex];
                            return IconButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  useRootNavigator: true,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) =>
                                      SongOptionsBottomSheet(song: song),
                                );
                              },
                              icon: const Icon(Icons.more_vert),
                            );
                          },
                        ),
                      ],
                    ),

                    // album art & info
                    Selector<PlaylistProvider, int?>(
                      selector: (_, p) => p.currentQueueIndex,
                      builder: (context, currentQueueIndex, _) {
                        if (currentQueueIndex == null ||
                            provider.queue.isEmpty) {
                          return const Center(child: Text("No song selected"));
                        }
                        final currentSong = provider.queue[currentQueueIndex];

                        return NeuBox(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // image
                              Hero(
                                tag: 'song_artwork_${currentSong.id}',
                                child: SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.7,
                                  height:
                                      MediaQuery.of(context).size.width * 0.7,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: currentSong.isLocal
                                        ? QueryArtworkWidget(
                                            key: ValueKey(currentSong.id),
                                            id: currentSong.id!,
                                            type: ArtworkType.AUDIO,
                                            artworkWidth:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.7,
                                            artworkHeight:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.7,
                                            artworkFit: BoxFit.cover,
                                            nullArtworkWidget: Container(
                                              width:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.7,
                                              height:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.7,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                              child: Icon(
                                                Icons.music_note,
                                                size:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width *
                                                    0.4,
                                              ),
                                            ),
                                          )
                                        : Image.asset(
                                            currentSong.albumArtImagePath ??
                                                "assets/images/album_artwork_1.png",
                                            width:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.7,
                                            height:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.7,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                              ),

                              // song/artist name
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // song, artist name
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          MarqueeText(
                                            text: currentSong.songName,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          MarqueeText(
                                            text: currentSong.artistName,
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // fav icon
                                    IconButton(
                                      onPressed: () {
                                        provider.toggleFavorite(
                                          currentSong.id ?? -1,
                                        );
                                      },
                                      icon:
                                          Selector<PlaylistProvider, List<int>>(
                                            selector: (_, p) => p.favoriteIds,
                                            builder: (context, favoriteIds, _) {
                                              return Icon(
                                                favoriteIds.contains(
                                                      currentSong.id ?? -1,
                                                    )
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: Colors.red,
                                              );
                                            },
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // song duration slider
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // start time
                              Selector<PlaylistProvider, Duration>(
                                selector: (_, p) => p.currentDuration,
                                builder: (context, currentDuration, _) {
                                  return Text(formatTime(currentDuration));
                                },
                              ),

                              // shuffle icon
                              Selector<PlaylistProvider, bool>(
                                selector: (_, p) => p.isShuffle,
                                builder: (context, isShuffle, _) {
                                  return IconButton(
                                    onPressed: provider.toggleShuffle,
                                    icon: Icon(
                                      Icons.shuffle,
                                      color: isShuffle
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
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
                              Selector<PlaylistProvider, (bool, bool)>(
                                selector: (_, p) => (p.isRepeat, p.isRepeatOne),
                                builder: (context, repeatState, _) {
                                  final isRepeat = repeatState.$1;
                                  final isRepeatOne = repeatState.$2;
                                  return IconButton(
                                    onPressed: provider.toggleRepeat,
                                    icon: Icon(
                                      isRepeatOne
                                          ? Icons.repeat_one
                                          : Icons.repeat,
                                      color: isRepeat || isRepeatOne
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : null,
                                    ),
                                  );
                                },
                              ),

                              // end time
                              Selector<PlaylistProvider, Duration>(
                                selector: (_, p) => p.totalDuration,
                                builder: (context, totalDuration, _) {
                                  return Text(formatTime(totalDuration));
                                },
                              ),
                            ],
                          ),
                        ),

                        Selector<PlaylistProvider, (Duration, Duration)>(
                          selector: (_, p) =>
                              (p.currentDuration, p.totalDuration),
                          builder: (context, durationData, _) {
                            final currentDuration = durationData.$1;
                            final totalDuration = durationData.$2;
                            return SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 4,
                                ),
                              ),
                              child: Slider(
                                value: currentDuration.inSeconds
                                    .toDouble()
                                    .clamp(
                                      0,
                                      totalDuration.inSeconds.toDouble(),
                                    ),
                                min: 0,
                                max: totalDuration.inSeconds.toDouble(),
                                activeColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                onChanged: (double val) {
                                  provider.seek(Duration(seconds: val.toInt()));
                                },
                                onChangeEnd: (double val) {
                                  provider.seek(Duration(seconds: val.toInt()));
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    // media controls
                    Row(
                      children: [
                        // skip previous
                        Expanded(
                          child: NeuBox(
                            onTap: provider.playPreviousSong,
                            onLongPress: () => _startSeeking(provider, false),
                            onTapCancel: _stopSeeking,
                            onLongPressEnd: _stopSeeking,
                            child: const SizedBox(
                              height: 48,
                              child: Center(child: Icon(Icons.skip_previous)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 25),
                        // play/pause
                        Expanded(
                          flex: 2,
                          child: Selector<PlaylistProvider, bool>(
                            selector: (_, p) => p.isPlaying,
                            builder: (context, isPlaying, _) {
                              return NeuBox(
                                onTap: provider.pauseOrResume,
                                child: SizedBox(
                                  height: 48,
                                  child: Center(
                                    child: Icon(
                                      isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        // skip forward
                        Expanded(
                          child: NeuBox(
                            onTap: provider.playNextSong,
                            onLongPress: () => _startSeeking(provider, true),
                            onTapCancel: _stopSeeking,
                            onLongPressEnd: _stopSeeking,
                            child: const SizedBox(
                              height: 48,
                              child: Center(child: Icon(Icons.skip_next)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
