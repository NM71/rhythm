import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/models/playlist_provider.dart';
import 'package:rhythm/models/song.dart';
import 'package:rhythm/pages/song_page.dart';

class ArtistsPage extends StatelessWidget {
  const ArtistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("A R T I S T S"),
        centerTitle: true,
      ),
      body: Consumer<PlaylistProvider>(
        builder: (context, value, child) {
          final artists = value.artists;

          if (artists.isEmpty) {
            return const Center(child: Text("No artists found"));
          }

          return ListView.builder(
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              final String artistName = artist['name'] as String;
              final List<Song> songs = artist['songs'] as List<Song>;
              final int count = artist['count'] as int;

              return ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.2),
                  child: Text(
                    artistName.isNotEmpty ? artistName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  artistName,
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
                    subtitle: Text(song.albumName),
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
