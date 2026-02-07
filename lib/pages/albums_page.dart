import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/models/playlist_provider.dart';
import 'package:rhythm/models/song.dart';
import 'package:rhythm/pages/song_page.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AlbumsPage extends StatelessWidget {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("A L B U M S"),
        centerTitle: true,
      ),
      body: Consumer<PlaylistProvider>(
        builder: (context, value, child) {
          final albums = value.albums;

          if (albums.isEmpty) {
            return const Center(child: Text("No albums found"));
          }

          return ListView.builder(
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              final String albumName = album['name'] as String;
              final List<Song> songs = album['songs'] as List<Song>;
              final int count = album['count'] as int;

              // Get first song for artwork
              final firstSong = songs.first;

              return ExpansionTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: firstSong.isLocal
                      ? QueryArtworkWidget(
                          id: firstSong.id!,
                          type: ArtworkType.ALBUM,
                          artworkWidth: 50,
                          artworkHeight: 50,
                          artworkFit: BoxFit.cover,
                          nullArtworkWidget: Container(
                            width: 50,
                            height: 50,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.2),
                            child: const Icon(Icons.album),
                          ),
                        )
                      : const Icon(Icons.album),
                ),
                title: Text(
                  albumName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text("$count songs"),
                children: songs.asMap().entries.map((entry) {
                  final sIndex = entry.key;
                  final song = entry.value;
                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 72, right: 16),
                    title: Text(
                      song.songName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(song.artistName),
                    trailing: Text(song.formattedDuration),
                    onTap: () {
                      value.loadListIntoQueue(songs, initialIndex: sIndex);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SongPage(),
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
