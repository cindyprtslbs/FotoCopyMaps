// lib/services/location_service.dart
//
// Semua urusan GPS dan kalkulasi jarak ada di sini.

import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/place_model.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _lastPosition;
  Position? get lastPosition => _lastPosition;

  /// Minta izin GPS dan ambil lokasi pengguna.
  /// Mengembalikan null jika ditolak atau GPS mati.
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null; // GPS mati di device
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null; // User menolak izin
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null; // User menolak permanen → arahkan ke settings
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _lastPosition = position;
      return position;
    } catch (e) {
      return null;
    }
  }

  /// Hitung jarak antara posisi pengguna dan sebuah tempat (dalam meter)
  double? distanceTo(Place place) {
    if (_lastPosition == null) return null;
    return Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      place.lat,
      place.lng,
    );
  }

  /// Hitung jarak antara dua koordinat
  double distanceBetween(
    double startLat, double startLng,
    double endLat, double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Buka rute di Google Maps (intent URL)
  Future<bool> openRoute({
    required double destLat,
    required double destLng,
    double? originLat,
    double? originLng,
  }) async {
    final origin = (originLat != null && originLng != null)
        ? '${originLat.toStringAsFixed(6)},${originLng.toStringAsFixed(6)}'
        : '';

    // Coba Google Maps dulu
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/$origin/'
      '${destLat.toStringAsFixed(6)},${destLng.toStringAsFixed(6)}',
    );

    // Fallback: geo: URI (buka di app peta apapun yang tersedia)
    final geoUrl = Uri.parse(
      'geo:${destLat.toStringAsFixed(6)},${destLng.toStringAsFixed(6)}'
      '?q=${destLat.toStringAsFixed(6)},${destLng.toStringAsFixed(6)}',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      return await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(geoUrl)) {
      return await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Urutkan list tempat berdasarkan jarak dari posisi pengguna
  List<Place> sortByDistance(List<Place> places) {
    if (_lastPosition == null) return places;

    for (var place in places) {
      place.distanceMeters = distanceTo(place);
    }

    final sorted = List<Place>.from(places);
    sorted.sort((a, b) {
      if (a.distanceMeters == null) return 1;
      if (b.distanceMeters == null) return -1;
      return a.distanceMeters!.compareTo(b.distanceMeters!);
    });
    return sorted;
  }
}
