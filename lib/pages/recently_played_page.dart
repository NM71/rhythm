import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/models/playlist_provider.dart';
import 'package:rhythm/pages/song_page.dart';
import 'package:on_audio_query/on_audio_query.dart';

class RecentlyPlayedPage extends StatelessWidget {
  const RecentlyPlayedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("R E C E N T L Y   P L A Y E D"),
        centerTitle: true,
      ),
      body: Consumer<PlaylistProvider>(
        builder: (context, value, child) {
          final recentlyPlayed = value.recentlyPlayed;

          if (recentlyPlayed.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No History Yet",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text("Songs you play will appear here."),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: recentlyPlayed.length,
            itemBuilder: (context, index) {
              final song = recentlyPlayed[index];
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
                            child: Icon(
                              Icons.music_note,
                              color: Theme.of(context).colorScheme.primary,
                            ),
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
                onTap: () {
                  // Load recently played list into queue
                  value.loadListIntoQueue(recentlyPlayed, initialIndex: index);
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
