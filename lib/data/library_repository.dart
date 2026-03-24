import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:remizz/data/song_model.dart';

class LibraryRepository {
  static const String boxName = 'library_songs';

  Box get _box => Hive.box(boxName);

  /// Salva uma música na biblioteca local (após o download)
  Future<void> saveDownloadedSong(Song song) async {
    await _box.put(song.id, song.toMap());
  }

  /// Remove uma música da biblioteca
  Future<void> removeSong(String id) async {
    await _box.delete(id);
  }

  /// Retorna todas as músicas baixadas
  List<Song> getDownloadedSongs() {
    return _box.values.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return Song.fromMap(map);
    }).toList();
  }

  /// Verifica se uma música já está na biblioteca
  bool isDownloaded(String id) {
    return _box.containsKey(id);
  }
}

final libraryRepositoryProvider = Provider((ref) {
  return LibraryRepository();
});

/// Notifier para gerenciar a lista de músicas baixadas de forma reativa
class DownloadedSongsNotifier extends Notifier<List<Song>> {
  @override
  List<Song> build() {
    // Inicialmente carrega as músicas do repositório
    return ref.watch(libraryRepositoryProvider).getDownloadedSongs();
  }

  /// Recarrega a lista (chamado após um novo download)
  void refresh() {
    state = ref.read(libraryRepositoryProvider).getDownloadedSongs();
  }

  /// Remove uma música e atualiza o estado
  Future<void> removeSong(String id) async {
    await ref.read(libraryRepositoryProvider).removeSong(id);
    refresh();
  }
}

final downloadedSongsProvider = NotifierProvider<DownloadedSongsNotifier, List<Song>>(
  DownloadedSongsNotifier.new,
);
