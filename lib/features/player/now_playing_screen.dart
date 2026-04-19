import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:remizz/core/app_theme.dart';
import 'package:remizz/core/theme_provider.dart';
import 'package:remizz/main.dart';
import 'dart:ui';
import 'package:remizz/features/player/audio_visualizer.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  bool _showVisualizer = false;

  String _formatDuration(Duration? duration) {
    if (duration == null) return '00:00';
    String minutes = duration.inMinutes.toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final handler = ref.watch(audioHandlerProvider);
    final primaryColor = ref.watch(themeColorProvider);

    return StreamBuilder<MediaItem?>(
      stream: handler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;
        if (mediaItem == null) return const Scaffold(body: Center(child: Text('Nada tocando')));

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Background Blur Effect
              Positioned.fill(
                child: QueryArtworkWidget(
                  id: int.parse(mediaItem.id),
                  type: ArtworkType.AUDIO,
                  nullArtworkWidget: Container(color: Colors.grey[900]),
                  keepOldArtwork: true,
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0.8),
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Main Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Column(
                            children: [
                              Text(
                                'TOCANDO AGORA',
                                style: TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold, color: Colors.white54),
                              ),
                            ],
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded),
                            color: AppTheme.surfaceColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            onSelected: (value) {
                              if (value == 'visualizer') {
                                setState(() => _showVisualizer = !_showVisualizer);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'visualizer',
                                child: Row(
                                  children: [
                                    Icon(_showVisualizer ? Icons.image : Icons.analytics_outlined, size: 20),
                                    const SizedBox(width: 12),
                                    Text(_showVisualizer ? 'Mostrar Capa' : 'Mostrar Visualizador'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const Spacer(),
                      
                      // Artwork or Visualizer
                      Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: _showVisualizer 
                            ? StreamBuilder<PlaybackState>(
                                stream: handler.playbackState,
                                builder: (context, snapshot) {
                                  return SizedBox(
                                    height: 200,
                                    child: AudioVisualizer(isPlaying: snapshot.data?.playing ?? false),
                                  );
                                },
                              )
                            : Container(
                                key: const ValueKey('artwork'),
                                width: MediaQuery.of(context).size.width * 0.8,
                                height: MediaQuery.of(context).size.width * 0.8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.2),
                                      blurRadius: 40,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: QueryArtworkWidget(
                                    id: int.parse(mediaItem.id),
                                    type: ArtworkType.AUDIO,
                                    artworkWidth: double.infinity,
                                    artworkHeight: double.infinity,
                                    nullArtworkWidget: Container(
                                      color: Colors.grey[900],
                                      child: const Icon(Icons.music_note, size: 100, color: Colors.white10),
                                    ),
                                  ),
                                ),
                              ),
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Info
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mediaItem.title,
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  mediaItem.artist ?? 'Artista Desconhecido',
                                  style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.6)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite_border_rounded, size: 28),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Progress Bar
                      StreamBuilder<Duration>(
                        stream: handler.player.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          final duration = mediaItem.duration ?? Duration.zero;
                          
                          return Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                  activeTrackColor: primaryColor,
                                  inactiveTrackColor: Colors.white10,
                                  thumbColor: Colors.white,
                                  overlayColor: primaryColor.withOpacity(0.2),
                                ),
                                child: Slider(
                                  value: position.inMilliseconds.toDouble(),
                                  max: duration.inMilliseconds.toDouble() > 0 
                                      ? duration.inMilliseconds.toDouble() 
                                      : 1.0,
                                  onChanged: (value) {
                                    handler.seek(Duration(milliseconds: value.toInt()));
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatDuration(position), style: const TextStyle(fontSize: 12, color: Colors.white38)),
                                    Text(_formatDuration(duration), style: const TextStyle(fontSize: 12, color: Colors.white38)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          StreamBuilder<PlaybackState>(
                            stream: handler.playbackState,
                            builder: (context, snapshot) {
                              final shuffle = snapshot.data?.shuffleMode == AudioServiceShuffleMode.all;
                              return IconButton(
                                icon: Icon(Icons.shuffle_rounded, color: shuffle ? primaryColor : Colors.white38),
                                onPressed: () => handler.setShuffleMode(shuffle ? AudioServiceShuffleMode.none : AudioServiceShuffleMode.all),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_previous_rounded, size: 45),
                            onPressed: () => handler.skipToPrevious(),
                          ),
                          StreamBuilder<PlaybackState>(
                            stream: handler.playbackState,
                            builder: (context, snapshot) {
                              final playing = snapshot.data?.playing ?? false;
                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: IconButton(
                                  icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                                  iconSize: 45,
                                  color: Colors.black,
                                  onPressed: () => playing ? handler.pause() : handler.play(),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded, size: 45),
                            onPressed: () => handler.skipToNext(),
                          ),
                          StreamBuilder<PlaybackState>(
                            stream: handler.playbackState,
                            builder: (context, snapshot) {
                              final repeatMode = snapshot.data?.repeatMode ?? AudioServiceRepeatMode.none;
                              return IconButton(
                                icon: Icon(
                                  repeatMode == AudioServiceRepeatMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                                  color: repeatMode != AudioServiceRepeatMode.none ? primaryColor : Colors.white38,
                                ),
                                onPressed: () {
                                  if (repeatMode == AudioServiceRepeatMode.none) handler.setRepeatMode(AudioServiceRepeatMode.all);
                                  else if (repeatMode == AudioServiceRepeatMode.all) handler.setRepeatMode(AudioServiceRepeatMode.one);
                                  else handler.setRepeatMode(AudioServiceRepeatMode.none);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
