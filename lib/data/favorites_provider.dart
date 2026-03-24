import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FavoritesNotifier extends Notifier<Set<String>> {
  late Box _box;

  @override
  Set<String> build() {
    _box = Hive.box('favorites');
    final favorites = _box.get('favorite_ids', defaultValue: <dynamic>[]);
    return Set<String>.from(favorites.cast<String>());
  }

  void toggleFavorite(String songId) {
    final newState = Set<String>.from(state);
    if (newState.contains(songId)) {
      newState.remove(songId);
    } else {
      newState.add(songId);
    }
    state = newState;
    _box.put('favorite_ids', state.toList());
  }

  bool isFavorite(String songId) => state.contains(songId);
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);
