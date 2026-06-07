import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  // Key unik per user
  String get _key {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
    return 'favorite_place_ids_$userId';   // ← berbeda per akun
  }

  Future<Set<int>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.map((e) => int.tryParse(e) ?? -1).where((e) => e != -1).toSet();
  }

  Future<bool> isFavorite(int placeId) async {
    final ids = await getFavoriteIds();
    return ids.contains(placeId);
  }

  Future<bool> toggleFavorite(int placeId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await getFavoriteIds();
    if (ids.contains(placeId)) {
      ids.remove(placeId);
      await prefs.setStringList(_key, ids.map((e) => e.toString()).toList());
      return false;
    } else {
      ids.add(placeId);
      await prefs.setStringList(_key, ids.map((e) => e.toString()).toList());
      return true;
    }
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}