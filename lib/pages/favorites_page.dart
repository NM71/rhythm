import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/models/playlist_provider.dart';
import 'package:rhythm/models/song.dart';
import 'package:rhythm/components/playing_indicator.dart';
import 'package:on_audio_query/on_audio_query.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("F A V O R I T E S"),
        centerTitle: true,
      ),
      body: Selector<PlaylistProvider, List<Song>>(
        selector: (_, p) => p.favoriteSongs,
        builder: (context, favorites, child) {
          final provider = Provider.of<PlaylistProvider>(
            context,
            listen: false,
          );

          // Empty state
          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_outline,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No Favorites Yet",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Tap the heart icon on any song to add it here.",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final Song song = favorites[index];

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
                            ? Theme.of(context).colorScheme.primary.withAlpha(
                                (0.8 * 255).toInt(),
                              )
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
                                color: Theme.of(context).colorScheme.primary
                                    .withAlpha((0.2 * 255).toInt()),
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPlaying)
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: PlayingIndicator(),
                          ),
                        IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () =>
                              provider.toggleFavorite(song.id ?? -1),
                        ),
                      ],
                    ),
                    onTap: () {
                      provider.loadListIntoQueue(
                        favorites,
                        initialIndex: index,
                      );
                    },
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
