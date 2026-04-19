class Playlist {
  final String id;
  final String name;
  final List<String> songIds;

  Playlist({
    required this.id,
    required this.name,
    required this.songIds,
  });

  Playlist copyWith({
    String? id,
    String? name,
    List<String>? songIds,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'songIds': songIds,
    };
  }

  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      songIds: List<String>.from(map['songIds'] ?? []),
    );
  }
}
