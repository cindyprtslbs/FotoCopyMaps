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

  /// Buka rute di OpenStreetMap (lewat browser)
  Future<bool> openRoute({
    required double destLat,
    required double destLng,
    double? originLat,
    double? originLng,
  }) async {
    // Bangun URL OpenStreetMap Directions
    // Format: https://www.openstreetmap.org/directions?from=lat,lng&to=lat,lng&engine=fossgis_osrm_car
    final StringBuffer urlBuffer = StringBuffer(
      'https://www.openstreetmap.org/directions?',
    );

    if (originLat != null && originLng != null) {
      urlBuffer.write(
        'from=${originLat.toStringAsFixed(6)},${originLng.toStringAsFixed(6)}&',
      );
    }

    urlBuffer.write(
      'to=${destLat.toStringAsFixed(6)},${destLng.toStringAsFixed(6)}'
      '&engine=fossgis_osrm_car',
    );

    final osmUrl = Uri.parse(urlBuffer.toString());

    if (await canLaunchUrl(osmUrl)) {
      return await launchUrl(osmUrl, mode: LaunchMode.externalApplication);
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