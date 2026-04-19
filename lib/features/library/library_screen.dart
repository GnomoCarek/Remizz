import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:remizz/data/library_repository.dart';
import 'package:remizz/main.dart';
import 'package:remizz/core/app_theme.dart';
import 'package:on_audio_query/on_audio_query.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadedSongs = ref.watch(downloadedSongsProvider);
    final audioHandler = ref.watch(audioHandlerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Músicas Locais', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(downloadedSongsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: downloadedSongs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.library_music_outlined, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhuma música encontrada no dispositivo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => ref.read(downloadedSongsProvider.notifier).refresh(),
                    child: const Text('Escanear Agora'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: downloadedSongs.length,
              itemBuilder: (context, index) {
                final song = downloadedSongs[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: QueryArtworkWidget(
                        id: int.parse(song.id),
                        type: ArtworkType.AUDIO,
                        nullArtworkWidget: Container(
                          width: 52,
                          height: 52,
                          color: Colors.grey[900],
                          child: const Icon(Icons.music_note, color: Colors.white24),
                        ),
                      ),
                    ),
                    title: Text(
                      song.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(song.artist, style: const TextStyle(color: Colors.white38)),
                    onTap: () async {
                      try {
                        final playlist = downloadedSongs.map((s) => MediaItem(
                          id: s.id,
                          album: s.album,
                          title: s.title,
                          artist: s.artist,
                          duration: s.duration,
                          artUri: null,
                          extras: {'localPath': s.localPath},
                        )).toList();

                        // Sempre atualiza a fila para refletir a lista da biblioteca
                        await audioHandler.addQueueItems(playlist);
                        
                        final mediaItem = playlist.firstWhere((item) => item.id == song.id);
                        await audioHandler.playMediaItem(mediaItem);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao tocar música: $e')),
                        );
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
