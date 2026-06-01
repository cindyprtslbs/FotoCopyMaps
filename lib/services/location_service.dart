import 'package:geolocator/geolocator.dart';

/// Hasil dari request lokasi — bisa berhasil, ditolak, atau GPS mati.
sealed class LocationResult {}

class LocationSuccess extends LocationResult {
  final Position position;
  LocationSuccess(this.position);
}

class LocationDenied extends LocationResult {
  final String message;
  LocationDenied(this.message);
}

class LocationServiceDisabled extends LocationResult {}

/// Service untuk mengambil lokasi pengguna dengan penanganan error lengkap.
class LocationService {
  /// Minta permission lalu ambil posisi saat ini.
  static Future<LocationResult> getCurrentLocation() async {
    print('LocationService.getCurrentLocation: start');

    // 1. Cek apakah GPS aktif
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print('LocationService: serviceEnabled=$serviceEnabled');
    if (!serviceEnabled) {
      return LocationServiceDisabled();
    }

    // 2. Cek permission
    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      print('LocationService: permission currently denied, requesting');
      permission = await Geolocator.requestPermission();
      print('LocationService: permission after request=$permission');
      if (permission == LocationPermission.denied) {
        return LocationDenied(
          'Izin lokasi ditolak. Aktifkan di pengaturan aplikasi.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('LocationService: permission deniedForever');
      return LocationDenied(
        'Izin lokasi diblokir permanen. Buka Pengaturan → Izin Aplikasi → Lokasi.',
      );
    }

    // 3. Ambil posisi
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      print('LocationService: got position ${position.latitude}, ${position.longitude}');
      return LocationSuccess(position);
    } catch (e) {
      print('LocationService: error getting position: ${e.toString()}');
      return LocationDenied(
        'Gagal mendapatkan lokasi: ${e.toString()}',
      );
    }
  }

  /// Hitung jarak antara user dan tempat (dalam meter).
  static double distanceBetween({
    required double userLat,
    required double userLng,
    required double placeLat,
    required double placeLng,
  }) {
    return Geolocator.distanceBetween(
      userLat,
      userLng,
      placeLat,
      placeLng,
    );
  }

  /// Format jarak jadi string yang ramah dibaca.
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}