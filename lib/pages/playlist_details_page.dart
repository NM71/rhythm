import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/models/playlist_provider.dart';
import 'package:rhythm/models/playlist.dart';
import 'package:rhythm/pages/song_page.dart';
import 'package:on_audio_query/on_audio_query.dart';

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
      body: Consumer<PlaylistProvider>(
        builder: (context, value, child) {
          final songs = playlist.songs;

          if (songs.isEmpty) {
            return const Center(child: Text("This playlist is empty."));
          }

          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                title: Text(
                  song.songName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  song.artistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.2),
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
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    value.removeSongFromPlaylist(song, playlist);
                  },
                ),
                onTap: () {
                  value.loadListIntoQueue(songs, initialIndex: index);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SongPage()),
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
