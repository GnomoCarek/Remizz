import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remizz/data/download_service.dart';
import 'package:remizz/data/library_repository.dart';
import 'package:remizz/data/song_model.dart';
import 'package:remizz/data/youtube_client.dart';

final downloadServiceProvider = Provider((ref) {
  final yt = ref.watch(youtubeClientProvider);
  return DownloadService(yt);
});

class DownloadState {
  final Map<String, double> progress; // videoId: progresso (0.0 a 1.0)
  DownloadState({this.progress = const {}});

  DownloadState copyWith({Map<String, double>? progress}) {
    return DownloadState(progress: progress ?? this.progress);
  }
}

final downloadProvider = NotifierProvider<DownloadNotifier, DownloadState>(
  DownloadNotifier.new,
);

// Notifier moderno para mensagens de erro
class DownloadErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setError(String? message) => state = message;
  void clear() => state = null;
}

final downloadErrorMessageProvider = NotifierProvider<DownloadErrorNotifier, String?>(
  DownloadErrorNotifier.new,
);

class DownloadNotifier extends Notifier<DownloadState> {
  @override
  DownloadState build() => DownloadState();

  Future<void> startDownload(Song song) async {
    final service = ref.read(downloadServiceProvider);
    final repo = ref.read(libraryRepositoryProvider);
    final errorNotifier = ref.read(downloadErrorMessageProvider.notifier);

    if (state.progress.containsKey(song.id)) return;

    state = state.copyWith(
      progress: {...state.progress, song.id: 0.01},
    );

    try {
      final localPath = await service.downloadSong(
        song,
        onProgress: (p) {
          final currentP = state.progress[song.id] ?? 0.0;
          if (p > currentP) {
            state = state.copyWith(
              progress: {...state.progress, song.id: p},
            );
          }
        },
      );

      if (localPath != null) {
        final downloadedSong = song.copyWith(localPath: localPath);
        await repo.saveDownloadedSong(downloadedSong);
        ref.read(downloadedSongsProvider.notifier).refresh();
      } else {
        errorNotifier.setError('Não foi possível baixar "${song.title}".');
      }
    } catch (e) {
      errorNotifier.setError('Erro no download: Limite atingido ou sem conexão.');
    } finally {
      final newProgress = Map<String, double>.from(state.progress);
      newProgress.remove(song.id);
      state = state.copyWith(progress: newProgress);
    }
  }
}
