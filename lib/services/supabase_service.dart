// lib/services/supabase_service.dart
//
// Semua komunikasi ke Supabase ada di sini.
// Screen tidak boleh akses Supabase secara langsung.

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/place_model.dart';
import '../models/category_model.dart';
import '../models/review_model.dart';

class SupabaseService {
  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // ─────────────────────────────────────────
  // CATEGORIES
  // ─────────────────────────────────────────

  /// Ambil semua kategori
  Future<List<Category>> getCategories() async {
    final response = await _client
        .from('categories')
        .select()
        .order('name');

    return (response as List)
        .map((json) => Category.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ─────────────────────────────────────────
  // PLACES
  // ─────────────────────────────────────────

  /// Ambil semua tempat (dengan join ke categories)
  Future<List<Place>> getPlaces({int? categoryId, String? search}) async {
    var query = _client
        .from('places')
        .select('*, categories(name)');

    if (categoryId != null) {
      query = query.eq('category_id', categoryId) as dynamic;
    }

    if (search != null && search.isNotEmpty) {
      query = query.ilike('name', '%$search%') as dynamic;
    }

    final response = await (query as dynamic).order('name');

    return (response as List)
        .map((json) => Place.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Ambil detail satu tempat berdasarkan ID
  Future<Place?> getPlaceById(int id) async {
    final response = await _client
        .from('places')
        .select('*, categories(name)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Place.fromJson(response);
  }

  // ─────────────────────────────────────────
  // REVIEWS
  // ─────────────────────────────────────────

  /// Ambil semua review untuk satu tempat
  Future<List<Review>> getReviewsByPlace(int placeId) async {
    final response = await _client
        .from('reviews')
        .select()
        .eq('place_id', placeId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Review.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Tambah review baru
  Future<void> addReview({
    required int placeId,
    required double rating,
    String? comment,
  }) async {
    final user = _client.auth.currentUser;
    await _client.from('reviews').insert({
      'place_id': placeId,
      'user_id': user?.id,
      'rating': rating.toInt(),
      'comment': comment,
    });
  }

  // ─────────────────────────────────────────
  // AUTH (opsional - jika pakai login)
  // ─────────────────────────────────────────

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;
}
