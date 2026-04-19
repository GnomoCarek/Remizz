import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:remizz/data/playlist_model.dart';
import 'package:uuid/uuid.dart';

class PlaylistNotifier extends Notifier<List<Playlist>> {
  static const String boxName = 'playlists_box';
  final _uuid = const Uuid();

  @override
  List<Playlist> build() {
    final box = Hive.box(boxName);
    return box.values.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return Playlist.fromMap(map);
    }).toList();
  }

  Future<void> createPlaylist(String name) async {
    final newPlaylist = Playlist(
      id: _uuid.v4(),
      name: name,
      songIds: [],
    );
    state = [...state, newPlaylist];
    await _saveToHive(newPlaylist);
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    state = [
      for (final playlist in state)
        if (playlist.id == playlistId)
          playlist.copyWith(
            songIds: [...playlist.songIds, songId],
          )
        else
          playlist,
    ];
    final updated = state.firstWhere((p) => p.id == playlistId);
    await _saveToHive(updated);
  }

  Future<void> reorderSongs(String playlistId, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    
    state = [
      for (final playlist in state)
        if (playlist.id == playlistId)
          (() {
            final ids = List<String>.from(playlist.songIds);
            final movedId = ids.removeAt(oldIndex);
            ids.insert(newIndex, movedId);
            return playlist.copyWith(songIds: ids);
          })()
        else
          playlist,
    ];
    
    final updated = state.firstWhere((p) => p.id == playlistId);
    await _saveToHive(updated);
  }

  Future<void> removePlaylist(String id) async {
    state = state.where((p) => p.id != id).toList();
    final box = Hive.box(boxName);
    await box.delete(id);
  }

  Future<void> _saveToHive(Playlist playlist) async {
    final box = Hive.box(boxName);
    await box.put(playlist.id, playlist.toMap());
  }
}

final playlistProvider = NotifierProvider<PlaylistNotifier, List<Playlist>>(
  PlaylistNotifier.new,
);
