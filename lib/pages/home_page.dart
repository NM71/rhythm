import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/components/my_drawer.dart';
import 'package:rhythm/models/playlist_provider.dart';
import 'package:rhythm/models/song.dart';
import 'package:rhythm/pages/song_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  void goToSong(BuildContext context) {
    _showSongPageBottomSheet(context);
  }

  void _showSongPageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: const SongPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: const Text('P L A Y L I S T'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () async {
                  await playlistProvider.scanAudioFiles();
                },
              ),
            ],
          ),
          drawer: const MyDrawer(),
          body: Stack(
            children: [
              ListView.builder(
                itemCount: playlistProvider.playlist.length,
                itemBuilder: (context, index) {
                  final Song song = playlistProvider.playlist[index];
                  final bool isPlaying = playlistProvider.isPlaying && playlistProvider.currentSongIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ListTile(
                      title: Text(song.songName),
                      subtitle: Text(song.artistName),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: song.isAsset
                            ? Image.asset(song.albumArtImagePath)
                            : const Icon(Icons.music_note),
                      ),
                      trailing: IconButton(
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () => playlistProvider.togglePlayPause(index),
                      ),
                      onTap: () {
                        playlistProvider.currentSongIndex = index;
                        goToSong(context);
                      },
                    ),
                  );
                },
              ),
              if (playlistProvider.isScanning)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: playlistProvider.scanProgress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                  ),
                ),
              if (playlistProvider.currentSongIndex != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: playlistProvider.playlist[playlistProvider.currentSongIndex!].isAsset
                              ? Image.asset(
                            playlistProvider.playlist[playlistProvider.currentSongIndex!].albumArtImagePath,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                              : Icon(Icons.music_note, size: 50),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => goToSong(context),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  playlistProvider.playlist[playlistProvider.currentSongIndex!].songName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  playlistProvider.playlist[playlistProvider.currentSongIndex!].artistName,
                                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(playlistProvider.isPlaying ? Icons.pause : Icons.play_arrow),
                          onPressed: playlistProvider.pauseOrResume,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}