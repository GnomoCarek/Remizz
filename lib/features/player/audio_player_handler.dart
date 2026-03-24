import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();

  MyAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    
    mediaItem.listen((mediaItem) async {
      if (mediaItem != null) {
        try {
          final localPath = mediaItem.extras?['localPath'] as String?;
          
          if (localPath != null && localPath.isNotEmpty && await File(localPath).exists()) {
            debugPrint('Tocando arquivo local: $localPath');
            await _player.setAudioSource(
              AudioSource.file(localPath, tag: mediaItem),
            );
          } else {
            debugPrint('Erro: Tentativa de tocar arquivo inexistente ou sem path local.');
            // Opcional: Notificar erro na UI aqui
          }
        } catch (e) {
          debugPrint('Erro ao carregar áudio local: $e');
        }
      }
    });
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    this.mediaItem.add(mediaItem);
    return play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
