import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// O NotifierProvider é a forma moderna de gerenciar estado no Riverpod 3.x
final themeColorProvider = NotifierProvider<ThemeColorNotifier, Color>(() {
  return ThemeColorNotifier();
});

class ThemeColorNotifier extends Notifier<Color> {
  static const String _boxName = 'settings';
  static const String _colorKey = 'primary_color';
  static const Color _defaultColor = Color(0xFFBB86FC);

  @override
  Color build() {
    // O método build inicializa o estado de forma síncrona
    final box = Hive.box(_boxName);
    final int? colorValue = box.get(_colorKey);
    return colorValue != null ? Color(colorValue) : _defaultColor;
  }

  void setThemeColor(Color color) {
    state = color;
    final box = Hive.box(_boxName);
    box.put(_colorKey, color.value);
  }
}
