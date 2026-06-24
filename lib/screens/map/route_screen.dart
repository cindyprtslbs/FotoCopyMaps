import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../../models/place_model.dart';
import '../../../services/location_service.dart';
// import '../../../utils/constants.dart';

// Tema warna konsisten dengan app
const Color _bgColor      = Color(0xFFF0F4F8);
const Color _shadowDark   = Color(0xFFD1D9E6);
const Color _shadowLight  = Colors.white;
const Color _primaryText  = Color(0xFF1E293B);
const Color _secondaryText = Color(0xFF64748B);
const Color _primary      = Color(0xFF3B82F6);
const Color _primaryDark  = Color(0xFF1D4ED8);

class RouteScreen extends StatefulWidget {
  final Place destination;

  const RouteScreen({super.key, required this.destination});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final _mapController = MapController();
  final _location = LocationService();

  LatLng? _userLatLng;
  List<LatLng> _routePoints = [];
  _RouteInfo? _routeInfo;

  // Status
  _RouteStatus _status = _RouteStatus.locating;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 1. Ambil posisi user
    final pos = _location.lastPosition ?? await _location.getCurrentLocation();

    if (!mounted) return;

    if (pos == null) {
      setState(() {
        _status = _RouteStatus.noGps;
        _errorMessage = 'Lokasi GPS tidak tersedia.\nPastikan izin lokasi sudah diberikan.';
      });
      return;
    }

    setState(() {
      _userLatLng = LatLng(pos.latitude, pos.longitude);
      _status = _RouteStatus.fetching;
    });

    // 2. Fetch rute dari OSRM
    await _fetchRoute(pos);
  }

  Future<void> _fetchRoute(Position origin) async {
    final dest = widget.destination;
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${origin.longitude},${origin.latitude};'
      '${dest.lng},${dest.lat}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() {
          _status = _RouteStatus.error;
          _errorMessage = 'Server rute tidak merespons (${response.statusCode}).';
        });
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;

      if (routes == null || routes.isEmpty) {
        setState(() {
          _status = _RouteStatus.error;
          _errorMessage = 'Rute tidak ditemukan untuk tujuan ini.';
        });
        return;
      }

      final route = routes[0] as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coords = geometry['coordinates'] as List;

      final points = coords
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();

      final distanceM = (route['distance'] as num).toDouble();
      final durationS = (route['duration'] as num).toDouble();

      setState(() {
        _routePoints = points;
        _routeInfo = _RouteInfo(
          distanceM: distanceM,
          durationS: durationS,
        );
        _status = _RouteStatus.ready;
      });

      // Fit peta agar semua rute terlihat
      _fitBounds(points);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _RouteStatus.error;
        _errorMessage = 'Gagal memuat rute.\nPeriksa koneksi internet Anda.';
      });
    }
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.fromLTRB(48, 120, 48, 220),
          ),
        );
      }
    });
  }

  Future<void> _retry() async {
    setState(() {
      _status = _RouteStatus.locating;
      _errorMessage = null;
      _routePoints = [];
      _routeInfo = null;
    });
    await _init();
  }

  @override
  Widget build(BuildContext context) {
    final dest = widget.destination;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // ── Peta ──────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLatLng ??
                  LatLng(dest.lat, dest.lng),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.campus_directory',
              ),

              // Polyline rute
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: _primary,
                      borderStrokeWidth: 2.0,
                      borderColor: Colors.white.withOpacity(0.1), // was 0.8
                    ),
                  ],
                ),

              // Marker user
              if (_userLatLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLatLng!,
                      width: 56,
                      height: 56,
                      child: _UserMarker(),
                    ),
                  ],
                ),

              // Marker tujuan
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(dest.lat, dest.lng),
                    width: 56,
                    height: 66,
                    alignment: Alignment.topCenter,
                    child: _DestinationMarker(),
                  ),
                ],
              ),
            ],
          ),

          // ── App Bar ─────────────────────────────────────
          Positioned(
            top: topPad + 12,
            left: 20,
            right: 20,
            child: _NeumorphicCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E7FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: _primary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dest.name,
                          style: const TextStyle(
                            color: _primaryText,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _statusLabel,
                          style: const TextStyle(
                              color: _secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  // Tombol my location
                  if (_userLatLng != null)
                    GestureDetector(
                      onTap: () => _mapController.move(_userLatLng!, 16),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.my_location_rounded,
                            color: _primary, size: 20),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Loading overlay ──────────────────────────────
          if (_status == _RouteStatus.locating ||
              _status == _RouteStatus.fetching)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: _NeumorphicCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: _primary),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _status == _RouteStatus.locating
                          ? 'Mendapatkan lokasi Anda...'
                          : 'Memuat rute terbaik...',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Error state ──────────────────────────────────
          if (_status == _RouteStatus.error ||
              _status == _RouteStatus.noGps)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: _NeumorphicCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_off_rounded,
                          color: Color(0xFFEF4444), size: 28),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage ?? 'Terjadi kesalahan.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _primaryText,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [_primary, _primaryDark]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withOpacity(0.05), // was 0.35
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _retry,
                          icon: const Icon(Icons.refresh_rounded,
                              size: 18, color: Colors.white),
                          label: const Text('Coba Lagi',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Info rute (ready) ────────────────────────────
          if (_status == _RouteStatus.ready && _routeInfo != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: _RouteInfoCard(
                info: _routeInfo!,
                destination: dest,
                onCenterRoute: () => _fitBounds(_routePoints),
              ),
            ),
        ],
      ),
    );
  }

  String get _statusLabel {
    switch (_status) {
      case _RouteStatus.locating:
        return 'Mencari lokasi Anda...';
      case _RouteStatus.fetching:
        return 'Memuat rute...';
      case _RouteStatus.ready:
        return 'Rute siap';
      case _RouteStatus.error:
      case _RouteStatus.noGps:
        return 'Gagal memuat rute';
    }
  }
}

// ─────────────────────────────────────────────────────────
// SUB-WIDGETS
// ─────────────────────────────────────────────────────────

class _RouteInfoCard extends StatelessWidget {
  final _RouteInfo info;
  final Place destination;
  final VoidCallback onCenterRoute;

  const _RouteInfoCard({
    required this.info,
    required this.destination,
    required this.onCenterRoute,
  });

  @override
  Widget build(BuildContext context) {
    return _NeumorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stat row
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.straighten_rounded,
                  iconBg: const Color(0xFFDBEAFE),
                  iconColor: _primary,
                  value: info.distanceText,
                  label: 'Jarak',
                ),
              ),
              Container(
                  width: 1,
                  height: 40,
                  color: _shadowDark.withOpacity(0.1)), 
              Expanded(
                child: _StatItem(
                  icon: Icons.access_time_rounded,
                  iconBg: const Color(0xFFF0FDF4),
                  iconColor: const Color(0xFF16A34A),
                  value: info.durationText,
                  label: 'Estimasi',
                ),
              ),
              Container(
                  width: 1,
                  height: 40,
                  color: _shadowDark.withOpacity(0.1)), // was 0.4
              Expanded(
                child: _StatItem(
                  icon: Icons.directions_car_rounded,
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  value: 'Jalan',
                  label: 'Mode',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: _shadowDark.withOpacity(0.1), height: 1), // was 0.4
          const SizedBox(height: 16),

          // Tujuan
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: _primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (destination.address != null &&
                        destination.address!.isNotEmpty)
                      Text(
                        destination.address!,
                        style: const TextStyle(
                            fontSize: 11,
                            color: _secondaryText,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Tombol center rute
              GestureDetector(
                onTap: onCenterRoute,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.fit_screen_rounded,
                      color: _primary, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String value, label;

  const _StatItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: _primaryText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: _secondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _UserMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.08), // was 0.15
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primary, _primaryDark],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.1), // was 0.45
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.navigation_rounded,
              color: Colors.white, size: 16),
        ),
      ],
    );
  }
}

class _DestinationMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withOpacity(0.1), // was 0.5
                blurRadius: 14,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.flag_rounded, color: Colors.white, size: 22),
        ),
        CustomPaint(
          size: const Size(12, 8),
          painter: _PinTipPainter(color: const Color(0xFFDC2626)),
        ),
      ],
    );
  }
}

class _PinTipPainter extends CustomPainter {
  final Color color;
  const _PinTipPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTipPainter old) => old.color != color;
}

class _NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _NeumorphicCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          // Bayangan kanan-bawah (sudah rendah di 0.1)
          BoxShadow(
            color: _shadowDark.withOpacity(0.1), 
            offset: const Offset(8, 8),
            blurRadius: 16,
          ),
          // Bayangan kiri-atas (DITURUNKAN OPACITY-NYA DI SINI)
          BoxShadow(
            color: Colors.white.withOpacity(0.5), // Ubah angka 0.5 sesuai kebutuhan
            offset: const Offset(-8, -8),
            blurRadius: 16,
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────

enum _RouteStatus { locating, fetching, ready, error, noGps }

class _RouteInfo {
  final double distanceM;
  final double durationS;

  const _RouteInfo({required this.distanceM, required this.durationS});

  String get distanceText {
    if (distanceM < 1000) {
      return '${distanceM.toStringAsFixed(0)} m';
    }
    return '${(distanceM / 1000).toStringAsFixed(1)} km';
  }

  String get durationText {
    final minutes = (durationS / 60).ceil();
    if (minutes < 60) return '$minutes mnt';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}j' : '${h}j ${m}m';
  }
}