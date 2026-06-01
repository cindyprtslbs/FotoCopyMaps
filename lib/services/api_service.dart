import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/place_model.dart';
import '../models/category_model.dart';
import '../models/review_model.dart';

/// Hasil dari setiap API call — sukses atau gagal dengan pesan jelas.
sealed class ApiResult<T> {}

class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  ApiSuccess(this.data);
}

class ApiError<T> extends ApiResult<T> {
  final String message;
  ApiError(this.message);
}

/// Bundle hasil fetch awal (places + categories sekaligus)
class InitData {
  final List<Place> places;
  final List<Category> categories;
  InitData({required this.places, required this.categories});
}

class ApiService {
  // ── GAS Endpoint ──────────────────────────────────
  static const String _baseUrl =
      'https://script.google.com/macros/s/AKfycbzVmc9-wxeUd-julH5QF0JSZMkqUb-mVjIov8k4mYdrE0CLpyrmDCQhvN4JCIM2xD9GqA/exec';

  static const Duration _timeout = Duration(seconds: 20);

  // ── In-memory cache ───────────────────────────────
  static InitData? _cache;
  static DateTime? _cacheTime;
  static const Duration _cacheTtl = Duration(minutes: 5);

  static bool get _cacheValid =>
      _cache != null &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheTtl;

  static final List<Category> _demoCategories = [
    Category(id: 1, name: 'Fotokopi', icon: '🖨️'),
    Category(id: 2, name: 'Kantin', icon: '🍽️'),
    Category(id: 3, name: 'Cafe', icon: '☕'),
  ];

  static final List<Place> _demoPlaces = [
    Place(
      id: 1,
      categoryId: 1,
      name: 'Fotokopi Kampus',
      lat: -7.275614,
      lng: 112.797110,
      address: 'Jalan Kampus No. 12, Surabaya',
      description: 'Layanan fotokopi cepat dan lengkap untuk mahasiswa.',
    ),
    Place(
      id: 2,
      categoryId: 1,
      name: 'Copy Center 24 Jam',
      lat: -7.276980,
      lng: 112.798530,
      address: 'Depan Gedung Rektorat',
      description: 'Tempat fotokopi dan print dengan harga terjangkau.',
    ),
    Place(
      id: 3,
      categoryId: 2,
      name: 'Kantin Hijau',
      lat: -7.274320,
      lng: 112.796200,
      address: 'Area Parkir Utama',
      description: 'Kantin kampus dengan variasi nasi kotak dan minuman segar.',
    ),
    Place(
      id: 4,
      categoryId: 3,
      name: 'Cafe Kampus',
      lat: -7.277700,
      lng: 112.795400,
      address: 'Gedung Pertemuan',
      description: 'Cafe santai dengan kopi dan snack ringan.',
    ),
  ];

  static final List<Review> _demoReviews = [
    Review(
      id: 1,
      placeId: 1,
      userId: 1,
      rating: 4.5,
      comment: 'Pelayanan cepat dan harga ramah mahasiswa.',
    ),
    Review(
      id: 2,
      placeId: 1,
      userId: 2,
      rating: 4.0,
      comment: 'Tempatnya bersih dan mudah ditemukan.',
    ),
    Review(
      id: 3,
      placeId: 2,
      userId: 3,
      rating: 4.2,
      comment: 'Buka 24 jam, cocok buat ngerjain tugas malam.',
    ),
  ];

  static List<Place> _demoPlacesForCategory(String? category) {
    if (category == null) return _demoPlaces;
    final normalized = category.toLowerCase();
    final matched = _demoCategories.firstWhere(
      (c) => c.name.toLowerCase() == normalized,
      orElse: () => _demoCategories.first,
    );
    return _demoPlaces.where((p) => p.categoryId == matched.id).toList();
  }

  static void clearCache() {
    _cache = null;
    _cacheTime = null;
  }

  // ── Generic GET helper ────────────────────────────
  static Future<ApiResult<dynamic>> _get(
    String action, {
    Map<String, String>? params,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'action': action,
          ...?params,
        },
      );

      // Debug: log outgoing request
      print('ApiService._get: GET $uri');

      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print('ApiService._get: action=$action OK, body-length=${response.body.length}');
        return ApiSuccess(decoded);
      } else {
        print('ApiService._get: action=$action server error ${response.statusCode}');
        return ApiError('Server error: ${response.statusCode}');
      }
    } on SocketException {
      print('ApiService._get: SocketException (no internet)');
      return ApiError('Tidak ada koneksi internet. Periksa jaringan kamu.');
    } on HttpException {
      print('ApiService._get: HttpException');
      return ApiError('Gagal menghubungi server. Coba lagi nanti.');
    } on FormatException {
      print('ApiService._get: FormatException - invalid JSON');
      return ApiError('Data dari server tidak valid.');
    } catch (e) {
      print('ApiService._get: unexpected error: ${e.toString()}');
      if (e.toString().contains('TimeoutException')) {
        return ApiError('Koneksi timeout. Server terlalu lambat merespons.');
      }
      return ApiError('Terjadi kesalahan: ${e.toString()}');
    }
  }

  // ── Get All Places ────────────────────────────────
  static Future<ApiResult<List<Place>>> getPlaces({
    String? category,
  }) async {
    final params = category != null ? {'category': category} : null;
    final result = await _get('places', params: params);

    if (result is ApiSuccess) {
      final data = result.data;
      return ApiSuccess((data['data'] as List).map((e) => Place.fromJson(e)).toList());
    }

    // ApiError -> fallback to demo data so UI doesn't hang
    if (result is ApiError) {
      print('ApiService.getPlaces: API error, returning demo data');
      return ApiSuccess(_demoPlacesForCategory(category));
    }

    return ApiError('Unknown error');
  }

  // ── Get Place Detail ──────────────────────────────
  static Future<ApiResult<Place>> getPlaceById(int id) async {
    final result = await _get('place_detail', params: {'id': id.toString()});

    if (result is ApiSuccess) {
      final data = result.data;
      return ApiSuccess(Place.fromJson(data['data']));
    }

    if (result is ApiError) {
      print('ApiService.getPlaceById: API error for id=$id, returning demo');
      return ApiSuccess(_demoPlaces.firstWhere((place) => place.id == id, orElse: () => _demoPlaces.first));
    }

    return ApiError('Unknown error');
  }

  // ── Get Categories ────────────────────────────────
  static Future<ApiResult<List<Category>>> getCategories() async {
    final result = await _get('categories');

    if (result is ApiSuccess) {
      final data = result.data;
      return ApiSuccess((data['data'] as List).map((e) => Category.fromJson(e)).toList());
    }

    if (result is ApiError) {
      print('ApiService.getCategories: API error, returning demo categories');
      return ApiSuccess(_demoCategories);
    }

    return ApiError('Unknown error');
  }

  // ── Get Init (places + categories dalam 1 call) ───
  /// Menggunakan cache jika masih valid (< 5 menit).
  /// Jika GAS belum support action=init, fallback ke 2 request paralel.
  static Future<ApiResult<InitData>> getInit({bool forceRefresh = false}) async {
    if (!forceRefresh && _cacheValid) {
      return ApiSuccess(_cache!);
    }

    // Coba 1 request dulu (jika GAS sudah support action=init)
    final initResult = await _get('init');
    if (initResult is ApiSuccess) {
      try {
        final data = initResult.data;
        final result = InitData(
          places: (data['places'] as List).map((e) => Place.fromJson(e)).toList(),
          categories: (data['categories'] as List).map((e) => Category.fromJson(e)).toList(),
        );
        _cache = result;
        _cacheTime = DateTime.now();
        return ApiSuccess(result);
      } catch (_) {
        // GAS belum support action=init, fallback ke 2 request paralel
        print('ApiService.getInit: response shape not matching expected init payload, falling back');
      }
    }

    // Fallback: 2 request paralel
    final results = await Future.wait([
      getPlaces(),
      getCategories(),
    ]);

    final placesResult = results[0] as ApiResult<List<Place>>;
    final catsResult = results[1] as ApiResult<List<Category>>;

    if (placesResult case ApiError(:final message)) {
      print('ApiService.getInit: places request failed: $message');
      return ApiError(message);
    }
    if (catsResult case ApiError(:final message)) {
      print('ApiService.getInit: categories request failed: $message');
      return ApiError(message);
    }

    final initData = InitData(
      places: (placesResult as ApiSuccess<List<Place>>).data,
      categories: (catsResult as ApiSuccess<List<Category>>).data,
    );
    _cache = initData;
    _cacheTime = DateTime.now();
    return ApiSuccess(initData);
  }

  // ── Get Reviews by Place ──────────────────────────
  static Future<ApiResult<List<Review>>> getReviews(int placeId) async {
    final result = await _get('reviews', params: {'place_id': placeId.toString()});

    if (result is ApiSuccess) {
      final data = result.data;
      return ApiSuccess((data['data'] as List).map((e) => Review.fromJson(e)).toList());
    }

    if (result is ApiError) {
      print('ApiService.getReviews: API error for placeId=$placeId, returning demo reviews');
      return ApiSuccess(_demoReviews.where((review) => review.placeId == placeId).toList());
    }

    return ApiError('Unknown error');
  }
}