import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:remizz/data/song_model.dart';
import 'package:remizz/data/song_repository.dart'; // Importação que faltava

class LibraryRepository {
  static const String boxName = 'library_songs';

  Box get _box => Hive.box(boxName);

  /// Salva uma música na biblioteca local
  Future<void> saveDownloadedSong(Song song) async {
    await _box.put(song.id, song.toMap());
  }

  /// Remove uma música da biblioteca
  Future<void> removeSong(String id) async {
    await _box.delete(id);
  }

  /// Retorna todas as músicas
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

/// Notifier para gerenciar a lista de músicas locais de forma reativa
class DownloadedSongsNotifier extends Notifier<List<Song>> {
  @override
  List<Song> build() {
    // Escuta o songListProvider e atualiza o estado quando as músicas forem carregadas
    ref.listen(songListProvider, (previous, next) {
      next.whenData((songs) {
        state = songs;
      });
    });

    // Se já tivermos dados, inicializamos com eles, caso contrário lista vazia
    return ref.watch(songListProvider).maybeWhen(
      data: (songs) => songs,
      orElse: () => <Song>[],
    );
  }

  /// Recarrega a lista escaneando o dispositivo novamente
  Future<void> refresh() async {
    ref.invalidate(songListProvider);
    final songs = await ref.read(songListProvider.future);
    state = songs;
  }
}

final downloadedSongsProvider = NotifierProvider<DownloadedSongsNotifier, List<Song>>(
  DownloadedSongsNotifier.new,
);
