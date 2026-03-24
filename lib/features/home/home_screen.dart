import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:remizz/data/library_repository.dart';
import 'package:remizz/main.dart';
import 'package:remizz/data/favorites_provider.dart';
import 'package:remizz/core/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Agora observamos as músicas baixadas em vez da busca online
    final downloadedSongs = ref.watch(downloadedSongsProvider);
    final audioHandler = ref.watch(audioHandlerProvider);
    final favoriteIds = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 32),
            const SizedBox(width: 12),
            const Text('Remizz', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Suas Músicas',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Acesse rapidamente seus downloads',
              style: TextStyle(fontSize: 14, color: Colors.white38),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: downloadedSongs.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: downloadedSongs.length,
                      padding: const EdgeInsets.only(bottom: 100), // Espaço para o miniplayer
                      itemBuilder: (context, index) {
                        // Mostramos as últimas baixadas primeiro
                        final song = downloadedSongs.reversed.toList()[index];
                        final isFavorite = favoriteIds.contains(song.id);

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
                              child: Image.network(
                                song.thumbnailUrl,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 52,
                                  height: 52,
                                  color: Colors.grey[900],
                                  child: const Icon(Icons.music_note),
                                ),
                              ),
                            ),
                            title: Text(
                              song.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text('${song.artist} • Baixado', style: const TextStyle(color: Colors.white38)),
                            trailing: IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? AppTheme.primaryColor : Colors.white38,
                              ),
                              onPressed: () {
                                ref.read(favoritesProvider.notifier).toggleFavorite(song.id);
                              },
                            ),
                            onTap: () async {
                              final mediaItem = MediaItem(
                                id: song.id,
                                album: song.album,
                                title: song.title,
                                artist: song.artist,
                                duration: song.duration,
                                artUri: Uri.parse(song.thumbnailUrl),
                                extras: {'localPath': song.localPath}, // Crucial para tocar localmente
                              );
                              
                              audioHandler.playMediaItem(mediaItem);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.library_music_outlined, size: 72, color: Colors.white10),
          const SizedBox(height: 20),
          const Text(
            'Sua biblioteca está vazia',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white60),
          ),
          const SizedBox(height: 10),
          const Text(
            'Pesquise e baixe músicas para ouvi-las aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
