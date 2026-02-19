import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/models/playlist_provider.dart';
import 'package:rhythm/models/playlist.dart';
import 'package:rhythm/models/song.dart';
import 'package:rhythm/components/playing_indicator.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PlaylistDetailsPage extends StatelessWidget {
  final Playlist playlist;

  const PlaylistDetailsPage({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(playlist.name),
        centerTitle: true,
      ),
      body: Selector<PlaylistProvider, (List<Song>, int)>(
        selector: (_, p) => (playlist.songs, playlist.songs.length),
        builder: (context, data, child) {
          final songs = data.$1;
          final provider = Provider.of<PlaylistProvider>(
            context,
            listen: false,
          );

          if (songs.isEmpty) {
            return const Center(child: Text("This playlist is empty."));
          }

          final totalMs = songs.fold<int>(0, (sum, s) => sum + s.duration);
          final hours = totalMs ~/ 3600000;
          final minutes = (totalMs % 3600000) ~/ 60000;
          final durationStr = hours > 0
              ? '${hours}h ${minutes}m'
              : '${minutes}m';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Duration header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Text(
                  '${songs.length} songs • $durationStr',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).colorScheme.inversePrimary.withAlpha(140),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];

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
                                  ? Theme.of(context).colorScheme.primary
                                        .withAlpha((0.8 * 255).toInt())
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withAlpha((0.2 * 255).toInt()),
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
                                onPressed: () {
                                  provider.removeSongFromPlaylist(
                                    song,
                                    playlist,
                                  );
                                  Fluttertoast.cancel();
                                  Fluttertoast.showToast(
                                    msg: "Removed from ${playlist.name}",
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.BOTTOM,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.inversePrimary,
                                    textColor: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            provider.loadListIntoQueue(
                              songs,
                              initialIndex: index,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
