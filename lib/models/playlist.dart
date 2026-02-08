import 'package:rhythm/models/song.dart';

class Playlist {
  final String id;
  String name;
  final List<Song> songs;

  Playlist({required this.id, required this.name, required this.songs});

  // To Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'songs': songs.map((s) => s.toMap()).toList(),
    };
  }

  // From Map
  factory Playlist.fromMap(Map<dynamic, dynamic> map) {
    return Playlist(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      songs: (map['songs'] as List? ?? [])
          .map((s) => Song.fromMap(s as Map))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
