import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remizz/core/app_theme.dart';
import 'package:remizz/core/theme_provider.dart';
import 'package:remizz/features/player/audio_player_handler.dart';
import 'package:remizz/features/home/home_screen.dart';
import 'package:remizz/features/library/library_screen.dart';
import 'package:remizz/features/home/search_screen.dart';
import 'package:remizz/features/library/playlists_screen.dart';
import 'package:remizz/features/player/now_playing_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:ui';

late MyAudioHandler _audioHandler;

final audioHandlerProvider = Provider<MyAudioHandler>((ref) => _audioHandler);

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter();
    await Hive.openBox('favorites');
    await Hive.openBox('library_songs');
    await Hive.openBox('playlists_box');
    await Hive.openBox('settings');

    _audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.remizz.audio',
        androidNotificationChannelName: 'Remizz Playback',
        androidNotificationOngoing: true,
      ),
    );

    runApp(const ProviderScope(child: RemizzApp()));
  } catch (e) {
    debugPrint('Erro na inicialização: $e');
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text('Erro: $e')))));
  }
}

class RemizzApp extends ConsumerWidget {
  const RemizzApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = ref.watch(themeColorProvider);

    return MaterialApp(
      title: 'Remizz',
      theme: AppTheme.getTheme(primaryColor),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const LibraryScreen(),
    const PlaylistsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          Positioned(left: 8, right: 8, bottom: 0, child: _MiniPlayer()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.playlist_play), label: 'Playlists'),
        ],
      ),
    );
  }
}

class _MiniPlayer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);

    return StreamBuilder<MediaItem?>(
      stream: handler.mediaItem,
      builder: (context, mediaSnapshot) {
        final mediaItem = mediaSnapshot.data;
        if (mediaItem == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const NowPlayingScreen(),
            );
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StreamBuilder<Duration>(
                      stream: handler.player.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final duration = mediaItem.duration ?? Duration.zero;
                        final progress = duration.inMilliseconds > 0 
                            ? position.inMilliseconds / duration.inMilliseconds 
                            : 0.0;
                        
                        return LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(ref.watch(themeColorProvider)),
                          minHeight: 2,
                        );
                      },
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: Hero(
                        tag: 'artwork',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: QueryArtworkWidget(
                            id: int.parse(mediaItem.id),
                            type: ArtworkType.AUDIO,
                            nullArtworkWidget: Container(
                              width: 44, height: 44, color: Colors.grey[900],
                              child: const Icon(Icons.music_note, color: Colors.white24),
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        mediaItem.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        mediaItem.artist ?? 'Unknown Artist',
                        style: const TextStyle(fontSize: 12, color: Colors.white60),
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StreamBuilder<PlaybackState>(
                            stream: handler.playbackState,
                            builder: (context, snapshot) {
                              final playing = snapshot.data?.playing ?? false;
                              return IconButton(
                                icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 30),
                                color: Colors.white,
                                onPressed: () => playing ? handler.pause() : handler.play(),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded, size: 30),
                            color: Colors.white,
                            onPressed: () => handler.skipToNext(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
