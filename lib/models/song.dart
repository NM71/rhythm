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

  // To Map for JSON/Hive
  Map<String, dynamic> toMap() {
    return {
      'songName': songName,
      'artistName': artistName,
      'albumName': albumName,
      'albumArtImagePath': albumArtImagePath,
      'audioPath': audioPath,
      'id': id,
      'isLocal': isLocal,
      'duration': duration,
      'dateAdded': dateAdded,
    };
  }

  // From Map
  factory Song.fromMap(Map<dynamic, dynamic> map) {
    return Song(
      songName: map['songName'] ?? '',
      artistName: map['artistName'] ?? '',
      albumName: map['albumName'] ?? 'Unknown Album',
      albumArtImagePath: map['albumArtImagePath'],
      audioPath: map['audioPath'] ?? '',
      id: map['id'],
      isLocal: map['isLocal'] ?? false,
      duration: map['duration'] ?? 0,
      dateAdded: map['dateAdded'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
