import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remizz/data/library_repository.dart';
import 'package:remizz/data/song_model.dart';
import 'package:remizz/main.dart';
import 'package:audio_service/audio_service.dart';
import 'package:remizz/core/app_theme.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// Notifier para gerenciar a consulta de busca local
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

final filteredLocalSongsProvider = Provider<List<Song>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final allSongs = ref.watch(downloadedSongsProvider);
  
  if (query.isEmpty) return allSongs;
  
  return allSongs.where((song) {
    return song.title.toLowerCase().contains(query) || 
           song.artist.toLowerCase().contains(query);
  }).toList();
});

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(filteredLocalSongsProvider);
    final audioHandler = ref.watch(audioHandlerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10, width: 1),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.transparent,
                backgroundImage: const AssetImage('assets/logo.png'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Pesquisar em suas músicas...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white38),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).setQuery(value);
                },
              ),
            ),
          ],
        ),
      ),
      body: searchResults.isEmpty
          ? Center(
              child: Text(
                ref.watch(searchQueryProvider).isEmpty 
                    ? 'Digite algo para pesquisar' 
                    : 'Nenhuma música encontrada localmente', 
                style: const TextStyle(color: Colors.white60)
              ),
            )
          : ListView.builder(
              itemCount: searchResults.length,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              itemBuilder: (context, index) {
                final song = searchResults[index];

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
                      child: QueryArtworkWidget(
                        id: int.parse(song.id),
                        type: ArtworkType.AUDIO,
                        nullArtworkWidget: Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[900],
                          child: const Icon(Icons.music_note, color: Colors.white24),
                        ),
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
                      try {
                        final playlist = searchResults.map((s) => MediaItem(
                          id: s.id,
                          album: s.album,
                          title: s.title,
                          artist: s.artist,
                          duration: s.duration,
                          artUri: null,
                          extras: {'localPath': s.localPath},
                        )).toList();

                        // Sempre atualiza a fila com os resultados da busca
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
