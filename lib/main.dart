import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remizz/core/app_theme.dart';
import 'package:remizz/features/player/audio_player_handler.dart';
import 'package:remizz/features/home/home_screen.dart';
import 'package:remizz/features/library/library_screen.dart';
import 'package:remizz/features/home/search_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';

late MyAudioHandler _audioHandler;

final audioHandlerProvider = Provider<MyAudioHandler>((ref) => _audioHandler);

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Inicializa o Hive para persistência local
    await Hive.initFlutter();
    await Hive.openBox('favorites');
    await Hive.openBox('library_songs'); // Novo box para biblioteca local

    _audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.remizz.audio',
        androidNotificationChannelName: 'Remizz Playback',
        androidNotificationOngoing: true,
      ),
    );

    runApp(
      const ProviderScope(
        child: RemizzApp(),
      ),
    );
  } catch (e) {
    debugPrint('Erro na inicialização: $e');
    // Se falhar, tenta rodar o app mesmo assim (pode quebrar funções, mas evita tela branca)
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Erro ao iniciar o Remizz: $e')),
        ),
      ),
    );
  }
}

class RemizzApp extends StatelessWidget {
  const RemizzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remizz',
      theme: AppTheme.darkTheme,
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
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 0,
            child: _MiniPlayer(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Library'),
        ],
      ),
    );
  }
}

class _MiniPlayer extends ConsumerWidget {
  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    String minutes = duration.inMinutes.toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);

    return StreamBuilder<MediaItem?>(
      stream: handler.mediaItem,
      builder: (context, mediaSnapshot) {
        final mediaItem = mediaSnapshot.data;
        if (mediaItem == null) return const SizedBox.shrink();

        return StreamBuilder<PlaybackState>(
          stream: handler.playbackState,
          builder: (context, playbackSnapshot) {
            final playbackState = playbackSnapshot.data;
            final playing = playbackState?.playing ?? false;
            final position = playbackState?.position ?? Duration.zero;
            final duration = mediaItem.duration ?? Duration.zero;
            final progress = duration.inMilliseconds > 0 
                ? position.inMilliseconds / duration.inMilliseconds 
                : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(76),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: mediaItem.artUri != null
                          ? Image.network(mediaItem.artUri.toString(), width: 48, height: 48, fit: BoxFit.cover)
                          : Container(
                              width: 48,
                              height: 48,
                              color: Colors.grey[800],
                              child: const Icon(Icons.music_note),
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
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_formatDuration(position)} / ${_formatDuration(duration)}',
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 36),
                          color: AppTheme.primaryColor,
                          onPressed: () {
                            if (playing) {
                              handler.pause();
                            } else {
                              handler.play();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        minHeight: 3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
