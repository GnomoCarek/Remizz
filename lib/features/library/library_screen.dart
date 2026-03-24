import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:remizz/data/library_repository.dart';
import 'package:remizz/main.dart';
import 'package:remizz/core/app_theme.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadedSongs = ref.watch(downloadedSongsProvider);
    final audioHandler = ref.watch(audioHandlerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sua Biblioteca', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: downloadedSongs.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_music_outlined, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma música baixada ainda.\nUse a busca para baixar suas favoritas!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38),
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
                    subtitle: Text(song.artist, style: const TextStyle(color: Colors.white38)),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white60),
                      onSelected: (value) async {
                        if (value == 'delete') {
                          await ref.read(downloadedSongsProvider.notifier).removeSong(song.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              SizedBox(width: 8),
                              Text('Remover do dispositivo'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      audioHandler.playMediaItem(MediaItem(
                        id: song.id,
                        album: song.album,
                        title: song.title,
                        artist: song.artist,
                        duration: song.duration,
                        artUri: Uri.parse(song.thumbnailUrl),
                        extras: {'localPath': song.localPath},
                      ));
                    },
                  ),
                );
              },
            ),
    );
  }
}
