import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final youtubeClientProvider = Provider<YoutubeExplode>((ref) {
  final client = YoutubeExplode();
  
  ref.onDispose(() {
    client.close();
  });
  
  return client;
});
