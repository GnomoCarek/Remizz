import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remizz/data/playlist_model.dart';
import 'package:remizz/data/playlist_provider.dart';
import 'package:remizz/data/library_repository.dart';
import 'package:remizz/data/song_model.dart';
import 'package:remizz/main.dart';
import 'package:remizz/core/app_theme.dart';
import 'package:remizz/core/theme_provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistProvider);
    final primaryColor = ref.watch(themeColorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showCreatePlaylistDialog(context, ref),
          ),
        ],
      ),
      body: playlists.isEmpty
          ? _buildEmptyState(context, ref, primaryColor)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return _PlaylistCard(playlist: playlist);
              },
            ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Nova Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nome da playlist',
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(playlistProvider.notifier).createPlaylist(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.playlist_add_rounded, size: 80, color: primaryColor.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text('Sua biblioteca está vazia', style: TextStyle(color: Colors.white60, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreatePlaylistDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Criar Minha Primeira Playlist'),
          ),
        ],
      ),
    );
  }
}

class _PlaylistCard extends ConsumerWidget {
  final Playlist playlist;
  const _PlaylistCard({required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = ref.watch(themeColorProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor.withOpacity(0.2), primaryColor.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.playlist_play_rounded, color: primaryColor, size: 30),
        ),
        title: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        subtitle: Text('${playlist.songIds.length} músicas', style: const TextStyle(color: Colors.white38, fontSize: 13)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistDetailsScreen(playlistId: playlist.id),
            ),
          );
        },
      ),
    );
  }
}

class PlaylistDetailsScreen extends ConsumerWidget {
  final String playlistId;
  const PlaylistDetailsScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = ref.watch(themeColorProvider);
    final playlist = ref.watch(playlistProvider).firstWhere(
      (p) => p.id == playlistId,
      orElse: () => Playlist(id: '', name: 'Removida', songIds: []),
    );

    if (playlist.id == '') {
      WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(context));
      return const Scaffold();
    }

    final allSongs = ref.watch(downloadedSongsProvider);
    final audioHandler = ref.watch(audioHandlerProvider);

    final playlistSongs = playlist.songIds.map((id) {
      return allSongs.firstWhere((s) => s.id == id, orElse: () => Song(
        id: id, title: 'Música removida', artist: '', album: '', audioUrl: '', thumbnailUrl: '', duration: Duration.zero
      ));
    }).where((s) => s.title != 'Música removida').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle_rounded),
            tooltip: 'Ordem Aleatória',
            onPressed: playlistSongs.isEmpty ? null : () async {
              final mediaItems = playlistSongs.map((s) => MediaItem(
                id: s.id,
                album: s.album,
                title: s.title,
                artist: s.artist,
                duration: s.duration,
                artUri: null,
                extras: {'localPath': s.localPath},
              )).toList();
              
              await audioHandler.addQueueItems(mediaItems);
              await audioHandler.setShuffleMode(AudioServiceShuffleMode.all);
              await audioHandler.play();
            },
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add_rounded),
            tooltip: 'Adicionar Músicas',
            onPressed: () => _showAddSongsDialog(context, ref, allSongs, playlist, primaryColor),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            tooltip: 'Excluir Playlist',
            onPressed: () => _confirmDeletePlaylist(context, ref, playlist),
          ),
        ],
      ),
      floatingActionButton: playlistSongs.isEmpty ? null : FloatingActionButton.extended(
        onPressed: () async {
          final mediaItems = playlistSongs.map((s) => MediaItem(
            id: s.id,
            album: s.album,
            title: s.title,
            artist: s.artist,
            duration: s.duration,
            artUri: null,
            extras: {'localPath': s.localPath},
          )).toList();

          await audioHandler.addQueueItems(mediaItems);
          await audioHandler.setShuffleMode(AudioServiceShuffleMode.none);
          await audioHandler.play();
        },
        backgroundColor: primaryColor,
        icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 28),
        label: const Text('OUVIR TUDO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
      body: playlistSongs.isEmpty
          ? _buildEmptyDetailsState(context, ref, allSongs, playlist, primaryColor)
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              itemCount: playlistSongs.length,
              onReorder: (oldIndex, newIndex) {
                ref.read(playlistProvider.notifier).reorderSongs(playlistId, oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final song = playlistSongs[index];
                return Container(
                  key: ValueKey('song_${song.id}_$index'),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: QueryArtworkWidget(
                        id: int.parse(song.id),
                        type: ArtworkType.AUDIO,
                        nullArtworkWidget: Container(
                          width: 44, height: 44, color: Colors.white10,
                          child: const Icon(Icons.music_note, size: 20, color: Colors.white24),
                        ),
                      ),
                    ),
                    title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(song.artist, style: const TextStyle(fontSize: 12, color: Colors.white38), maxLines: 1),
                    // Usamos um DragStartListener explícito no ícone para facilitar o arraste
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.drag_handle_rounded, color: Colors.white24),
                      ),
                    ),
                    onTap: () async {
                      try {
                        final mediaItems = playlistSongs.map((s) => MediaItem(
                          id: s.id,
                          album: s.album,
                          title: s.title,
                          artist: s.artist,
                          duration: s.duration,
                          artUri: null,
                          extras: {'localPath': s.localPath},
                        )).toList();

                        await audioHandler.addQueueItems(mediaItems);
                        await audioHandler.playMediaItem(mediaItems[index]);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao tocar: $e')),
                        );
                      }
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyDetailsState(BuildContext context, WidgetRef ref, List<Song> allSongs, Playlist playlist, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_off_outlined, size: 60, color: Colors.white10),
          const SizedBox(height: 16),
          const Text('Nenhuma música nesta playlist', style: TextStyle(color: Colors.white38)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showAddSongsDialog(context, ref, allSongs, playlist, primaryColor),
            child: const Text('Adicionar Músicas'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePlaylist(BuildContext context, WidgetRef ref, Playlist playlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Excluir Playlist?'),
        content: Text('Deseja realmente apagar "${playlist.name}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              ref.read(playlistProvider.notifier).removePlaylist(playlist.id);
              Navigator.pop(context); // Fecha o diálogo
              Navigator.pop(context); // Volta para a lista de playlists
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddSongsDialog(BuildContext context, WidgetRef ref, List<Song> allSongs, Playlist playlist, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('Adicionar Música', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: allSongs.length,
                itemBuilder: (context, index) {
                  final song = allSongs[index];
                  final alreadyIn = playlist.songIds.contains(song.id);
                  
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: QueryArtworkWidget(
                        id: int.parse(song.id),
                        type: ArtworkType.AUDIO,
                        nullArtworkWidget: Container(width: 40, height: 40, color: Colors.white10, child: const Icon(Icons.music_note, size: 20)),
                      ),
                    ),
                    title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(song.artist, maxLines: 1),
                    trailing: Icon(alreadyIn ? Icons.check_circle : Icons.add_circle_outline, 
                      color: alreadyIn ? primaryColor : Colors.white24),
                    onTap: alreadyIn ? null : () {
                      ref.read(playlistProvider.notifier).addSongToPlaylist(playlist.id, song.id);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
