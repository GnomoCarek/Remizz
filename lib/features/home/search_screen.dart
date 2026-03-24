import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remizz/data/song_repository.dart';
import 'package:remizz/data/download_notifier.dart';
import 'package:remizz/data/library_repository.dart';
import 'package:remizz/data/song_model.dart';
import 'package:remizz/main.dart';
import 'package:audio_service/audio_service.dart';
import 'package:remizz/core/app_theme.dart';

/// Notifier para gerenciar a consulta de busca
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

final searchResultsProvider = FutureProvider<List<Song>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  return await ref.read(songRepositoryProvider).fetchSongs(query: query);
});

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(searchResultsProvider);
    final downloadState = ref.watch(downloadProvider);
    final libraryRepo = ref.watch(libraryRepositoryProvider);

    // Escuta por erros de download para mostrar SnackBar
    ref.listen(downloadErrorMessageProvider, (previous, next) {
      if (next != null) {
        final message = next.toString(); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Limpa o erro após mostrar
        ref.read(downloadErrorMessageProvider.notifier).clear();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 32),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Pesquisar músicas...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white38),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                onSubmitted: (value) {
                  ref.read(searchQueryProvider.notifier).setQuery(value);
                },
              ),
            ),
          ],
        ),
      ),
      body: searchResults.when(
        data: (songs) {
          if (songs.isEmpty) {
            return const Center(
              child: Text('Pesquise por artistas ou músicas', 
                style: TextStyle(color: Colors.white60)),
            );
          }
          return ListView.builder(
            itemCount: songs.length,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            itemBuilder: (context, index) {
              final song = songs[index];
              final isDownloaded = libraryRepo.isDownloaded(song.id);
              final progress = downloadState.progress[song.id];
              final isDownloading = progress != null;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      song.thumbnailUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.music_note),
                    ),
                  ),
                  title: Text(song.title, 
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis),
                  subtitle: Text(song.artist, 
                    style: const TextStyle(color: Colors.white38),
                    maxLines: 1),
                  onTap: () async {
                    if (isDownloaded) {
                      final handler = ref.read(audioHandlerProvider);
                      final localSongs = libraryRepo.getDownloadedSongs();
                      String? path;
                      try {
                        path = localSongs.firstWhere((s) => s.id == song.id).localPath;
                      } catch (_) {
                        path = null;
                      }

                      if (path != null) {
                        handler.playMediaItem(MediaItem(
                          id: song.id,
                          title: song.title,
                          artist: song.artist,
                          duration: song.duration,
                          artUri: Uri.parse(song.thumbnailUrl),
                          extras: {'localPath': path},
                        ));
                      }
                    } else if (!isDownloading) {
                      // Se não estiver baixada nem baixando agora, inicia o download
                      ref.read(downloadProvider.notifier).startDownload(song);
                    }
                  },
                  trailing: _buildTrailing(ref, song, isDownloaded, isDownloading, progress),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  Widget _buildTrailing(WidgetRef ref, Song song, bool isDownloaded, bool isDownloading, double? progress) {
    if (isDownloading) {
      final percentage = ((progress ?? 0) * 100).toInt();
      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          Text('$percentage', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      );
    }

    if (isDownloaded) {
      return const Icon(Icons.check_circle, color: AppTheme.secondaryColor);
    }

    return IconButton(
      icon: const Icon(Icons.download_for_offline_rounded, color: Colors.white70),
      onPressed: () {
        ref.read(downloadProvider.notifier).startDownload(song);
      },
    );
  }
}
