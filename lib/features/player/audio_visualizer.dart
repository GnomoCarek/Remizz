import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remizz/core/theme_provider.dart';
import 'dart:math' as math;

class AudioVisualizer extends ConsumerStatefulWidget {
  final bool isPlaying;
  const AudioVisualizer({super.key, required this.isPlaying});

  @override
  ConsumerState<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends ConsumerState<AudioVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();
  
  late List<double> _heights;
  final int _barCount = 25;

  @override
  void initState() {
    super.initState();
    _heights = List.generate(_barCount, (index) => 0.1);
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_updateVisualizer);
    
    if (widget.isPlaying) _controller.repeat();
  }

  void _updateVisualizer() {
    if (!widget.isPlaying) return;

    setState(() {
      for (int i = 0; i < _barCount; i++) {
        if (_random.nextDouble() > 0.85) {
          double centerFactor = 1.0 - ((i - _barCount / 2).abs() / (_barCount / 2));
          _heights[i] = (_random.nextDouble() * 0.7 + 0.3) * centerFactor;
        } else {
          _heights[i] = (_heights[i] * 0.85).clamp(0.05, 1.0);
        }
      }
    });
  }

  @override
  void didUpdateWidget(AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      _controller.repeat();
    } else {
      _controller.stop();
      setState(() {
        _heights = _heights.map((h) => 0.05).toList();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = ref.watch(themeColorProvider);

    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_barCount, (index) {
          return _buildBar(_heights[index], index, primaryColor);
        }),
      ),
    );
  }

  Widget _buildBar(double heightFactor, int index, Color primaryColor) {
    final Color barColor = Color.lerp(
      primaryColor.withOpacity(0.4),
      primaryColor,
      heightFactor,
    )!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: 6,
      height: 150 * heightFactor + 10,
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          if (heightFactor > 0.6)
            BoxShadow(
              color: primaryColor.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 2,
            )
        ],
      ),
    );
  }
}
