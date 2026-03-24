class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String audioUrl;
  final String thumbnailUrl;
  final Duration duration;
  final String? localPath; // Novo campo para o caminho do arquivo baixado

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.audioUrl,
    required this.thumbnailUrl,
    required this.duration,
    this.localPath,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? audioUrl,
    String? thumbnailUrl,
    Duration? duration,
    String? localPath,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      audioUrl: audioUrl ?? this.audioUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      localPath: localPath ?? this.localPath,
    );
  }

  // Útil para salvar no Hive/Banco futuramente
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'audioUrl': audioUrl,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration.inMilliseconds,
      'localPath': localPath,
    };
  }

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'],
      title: map['title'],
      artist: map['artist'],
      album: map['album'],
      audioUrl: map['audioUrl'],
      thumbnailUrl: map['thumbnailUrl'],
      duration: Duration(milliseconds: map['duration']),
      localPath: map['localPath'],
    );
  }
}
