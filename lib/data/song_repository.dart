import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remizz/data/song_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

class SongRepository {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.audio.request().isGranted) return true;
      if (await Permission.storage.request().isGranted) return true;
      if (await Permission.manageExternalStorage.request().isGranted) return true;
    }
    return true;
  }

  Future<List<Song>> fetchLocalSongs() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return [];

      final querySongs = await _audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      final box = Hive.box('settings');
      final List<String> ignoredPaths = List<String>.from(
        box.get('ignored_paths', defaultValue: ['whatsapp', 'telegram', 'recorder', 'voice notes'])
      );
      final int minDuration = box.get('min_duration', defaultValue: 30);

      return querySongs.where((s) {
        final path = s.data.toLowerCase();
        final duration = s.duration ?? 0;

        if (duration < (minDuration * 1000)) return false;

        for (final ignored in ignoredPaths) {
          if (path.contains(ignored.toLowerCase())) return false;
        }

        return true;
      }).map((s) {
        // Recalculamos ou acessamos a duração aqui dentro do map também
        final songDuration = s.duration ?? 0;
        
        return Song(
          id: s.id.toString(),
          title: s.title,
          artist: s.artist == '<unknown>' ? 'Artista Desconhecido' : (s.artist ?? 'Artista Desconhecido'),
          album: s.album == '<unknown>' ? 'Álbum Desconhecido' : (s.album ?? 'Álbum Desconhecido'),
          audioUrl: s.data,
          thumbnailUrl: '',
          duration: Duration(milliseconds: songDuration),
          localPath: s.data,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}

final songRepositoryProvider = Provider((ref) {
  return SongRepository();
});

final songListProvider = FutureProvider((ref) async {
  return await ref.watch(songRepositoryProvider).fetchLocalSongs();
});
