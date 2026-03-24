import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:remizz/data/song_model.dart';

import 'package:remizz/data/youtube_client.dart';

class SongRepository {
  final YoutubeExplode _yt;

  SongRepository(this._yt);

  Future<List<Song>> fetchSongs({String query = 'latest music 2026 hits'}) async {
    try {
      final searchList = await _yt.search.search(query);
      
      final songs = <Song>[];
      
      // Limitando a 10 resultados para carregar rápido
      for (var video in searchList.take(10)) {
        songs.add(
          Song(
            id: video.id.value,
            title: video.title,
            artist: video.author,
            album: 'YouTube Music',
            audioUrl: '', // Deixamos vazio e pegamos quando for tocar
            thumbnailUrl: video.thumbnails.standardResUrl.isNotEmpty 
                ? video.thumbnails.standardResUrl 
                : video.thumbnails.mediumResUrl,
            duration: video.duration ?? Duration.zero,
          ),
        );
      }
      return songs;
    } catch (e) {
      return [];
    }
  }

  Future<String> getAudioUrl(String videoId) async {
    final manifest = await _yt.videos.streamsClient.getManifest(videoId);
    final audioStream = manifest.audioOnly.withHighestBitrate();
    return audioStream.url.toString();
  }

  void dispose() {
    _yt.close();
  }
}

final songRepositoryProvider = Provider((ref) {
  final yt = ref.watch(youtubeClientProvider);
  return SongRepository(yt);
});

final songListProvider = FutureProvider((ref) async {
  return await ref.watch(songRepositoryProvider).fetchSongs();
});
