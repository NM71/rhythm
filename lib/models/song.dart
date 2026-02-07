class Song {
  final String songName;
  final String artistName;
  final String albumName;
  final String? albumArtImagePath;
  final String audioPath;
  final int? id; // for local files
  final bool isLocal;
  final int duration; // in milliseconds

  final int? dateAdded;

  Song({
    required this.songName,
    required this.artistName,
    this.albumName = 'Unknown Album',
    this.albumArtImagePath,
    required this.audioPath,
    this.id,
    this.isLocal = false,
    this.duration = 0,
    this.dateAdded,
  });

  // Format duration as mm:ss
  String get formattedDuration {
    final minutes = (duration ~/ 60000);
    final seconds = ((duration % 60000) ~/ 1000).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
