import 'dart:io';
import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  Timer? _sleepTimer;
  
  final _sleepTimerController = StreamController<int?>.broadcast();
  Stream<int?> get sleepTimerStream => _sleepTimerController.stream;

  AudioPlayer get player => _player;

  MyAudioHandler() {
    _initSession();
    
    // CORREÇÃO: Usar listen em vez de pipe para evitar o erro "Bad state: You cannot add items..."
    _player.playbackEventStream.listen((event) {
      playbackState.add(_transformEvent(event));
    });
    
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  Future<void> _initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    
    session.becomingNoisyEventStream.listen((_) {
      pause();
    });

    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(0.5);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            pause();
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(1.0);
            break;
          case AudioInterruptionType.pause:
            play();
            break;
          case AudioInterruptionType.unknown:
            break;
        }
      }
    });
  }

  void setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    if (minutes <= 0) {
      _sleepTimerController.add(null);
      return;
    }

    int remainingSeconds = minutes * 60;
    _sleepTimerController.add(minutes);

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remainingSeconds--;
      
      if (remainingSeconds % 60 == 0) {
        _sleepTimerController.add(remainingSeconds ~/ 60);
      }

      if (remainingSeconds <= 0) {
        pause();
        _sleepTimer?.cancel();
        _sleepTimerController.add(null);
      }
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimerController.add(null);
  }

  void _broadcastState() {
    playbackState.add(_transformEvent(_player.playbackEvent));
  }

  @override
  Future<void> addQueueItems(List<MediaItem> items) async {
    try {
      final audioSources = items.map((item) {
        final path = item.extras?['localPath'] as String?;
        return AudioSource.uri(
          Uri.parse(Uri.file(path ?? '').toString()),
          tag: item,
        );
      }).toList();

      queue.add(items);
      // await _player.stop(); // Removido stop para evitar interrupção brusca se já estiver tocando algo similar
      await _player.setAudioSource(
        ConcatenatingAudioSource(children: audioSources),
        preload: true,
      );
    } catch (e) {
      debugPrint('Erro ao carregar playlist: $e');
    }
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    final index = queue.value.indexWhere((item) => item.id == mediaItem.id);
    if (index != -1) {
      await _player.seek(Duration.zero, index: index);
      return play();
    } else {
      await addQueueItems([mediaItem]);
      return play();
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
    _broadcastState();
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (shuffleMode == AudioServiceShuffleMode.all) {
      await _player.setShuffleModeEnabled(true);
    } else {
      await _player.setShuffleModeEnabled(false);
    }
    _broadcastState();
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.setRepeatMode,
        MediaAction.setShuffleMode,
      },
      androidCompactActionIndices: const [0, 1, 3],
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _player.currentIndex,
      repeatMode: const {
        LoopMode.off: AudioServiceRepeatMode.none,
        LoopMode.one: AudioServiceRepeatMode.one,
        LoopMode.all: AudioServiceRepeatMode.all,
      }[_player.loopMode] ?? AudioServiceRepeatMode.none,
      shuffleMode: _player.shuffleModeEnabled 
          ? AudioServiceShuffleMode.all 
          : AudioServiceShuffleMode.none,
    );
  }
}
