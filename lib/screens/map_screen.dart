import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/place_model.dart';
import '../services/location_service.dart';
import '../widgets/loading_indicator.dart';

class MapScreen extends StatefulWidget {
  final Place place;
  final Position? userPosition;
  /// Opsional: daftar tempat sekitar untuk ditampilkan sebagai marker tambahan
  final List<Place>? nearbyPlaces;

  const MapScreen({
    super.key,
    required this.place,
    this.userPosition,
    this.nearbyPlaces,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with TickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  Position? _currentPosition;
  bool _isLoadingGps = false;

  /// Tempat yang sedang dipilih di peta (nil = tempat utama)
  Place? _selectedPlace;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedPlace = widget.place;

    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _currentPosition = widget.userPosition;
    _refreshPosition();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshPosition() async {
    setState(() => _isLoadingGps = true);
    final result = await LocationService.getCurrentLocation();
    if (result is LocationSuccess && mounted) {
      setState(() {
        _currentPosition = result.position;
        _isLoadingGps = false;
      });
      // Pindahkan peta ke lokasi pengguna setelah GPS berhasil diperoleh
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 15);
      });
    } else {
      setState(() => _isLoadingGps = false);
    }
  }

  Future<void> _openRoute() async {
    if (_isLoadingGps) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Menunggu GPS... Coba lagi sebentar.'),
        backgroundColor: Color(0xFFFF9800),
      ));
      return;
    }

    final target = _selectedPlace ?? widget.place;
    final dest = '${target.lat},${target.lng}';
    String url;

    if (_currentPosition != null) {
      final origin =
          '${_currentPosition!.latitude},${_currentPosition!.longitude}';
      url = 'https://www.google.com/maps/dir/?api=1'
          '&origin=$origin'
          '&destination=$dest'
          '&travelmode=walking';
    } else {
      url = 'https://maps.google.com/maps?daddr=$dest&dirflg=w';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tidak dapat membuka Google Maps.'),
          backgroundColor: Color(0xFFFF6B6B),
        ));
      }
    }
  }

  String? _distanceFor(Place place) {
    if (_currentPosition == null) return null;
    final m = LocationService.distanceBetween(
      userLat: _currentPosition!.latitude,
      userLng: _currentPosition!.longitude,
      placeLat: place.lat,
      placeLng: place.lng,
    );
    return LocationService.formatDistance(m);
  }

  String? get _distanceText => _distanceFor(_selectedPlace ?? widget.place);

  void _selectPlace(Place place) {
    setState(() => _selectedPlace = place);
    _mapController.move(LatLng(place.lat, place.lng), 16);
  }

  @override
  Widget build(BuildContext context) {
    final mainTarget = LatLng(widget.place.lat, widget.place.lng);
    final active = _selectedPlace ?? widget.place;

    // Gabungkan tempat utama + tempat sekitar
    final allPlaces = <Place>{widget.place, ...?widget.nearbyPlaces}.toList();

    final markers = <Marker>[
      // Marker tempat sekitar
      ...allPlaces.where((p) => p.id != active.id).map(
            (p) => Marker(
              point: LatLng(p.lat, p.lng),
              width: 44,
              height: 44,
              child: GestureDetector(
                onTap: () => _selectPlace(p),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF4A90D9), width: 2),
                    boxShadow: const [
                      BoxShadow(color: Color(0x334A90D9), blurRadius: 6),
                    ],
                  ),
                  child: const Icon(Icons.place_rounded,
                      color: Color(0xFF4A90D9), size: 20),
                ),
              ),
            ),
          ),

      // Marker tempat yang sedang aktif (pulse)
      Marker(
        point: LatLng(active.lat, active.lng),
        width: 80,
        height: 80,
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Stack(alignment: Alignment.center, children: [
            Container(
              width: 56 * _pulseAnim.value,
              height: 56 * _pulseAnim.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4A90D9)
                    .withValues(alpha: 0.2 * _pulseAnim.value),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF4A90D9),
                boxShadow: [
                  BoxShadow(
                      color: Color(0x664A90D9),
                      blurRadius: 8,
                      spreadRadius: 2),
                ],
              ),
              child: const Icon(Icons.place_rounded,
                  color: Colors.white, size: 16),
            ),
          ]),
        ),
      ),

      // Marker posisi pengguna
      if (_currentPosition != null)
        Marker(
          point: LatLng(
              _currentPosition!.latitude, _currentPosition!.longitude),
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1DB954),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0x661DB954), blurRadius: 8),
              ],
            ),
            child:
                const Icon(Icons.person_rounded, color: Colors.white, size: 18),
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1A2340),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2340),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
            child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Peta Lokasi',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          Text(active.name,
              style: const TextStyle(
                  color: Color(0xFF7ABCF0), fontSize: 12)),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () => _mapController.move(mainTarget, 16),
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.my_location_rounded,
                    color: Color(0xFF4A90D9), size: 20),
              ),
            ),
          ),
        ],
      ),
      body: Column(children: [
        // ── Peta ────────────────────────────────────────────────
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: mainTarget,
                initialZoom: 16,
                interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.fotocopyfinder_app',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
        ),

        // ── Bottom Sheet Kartu Tempat ────────────────────────────
        Container(
          color: const Color(0xFF1A2340),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Scroll horizontal tempat terdekat (jika ada nearbyPlaces)
            if (widget.nearbyPlaces != null &&
                widget.nearbyPlaces!.isNotEmpty)
              SizedBox(
                height: 86,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: allPlaces.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final p = allPlaces[i];
                    final isActive = p.id == active.id;
                    final dist = _distanceFor(p);
                    return GestureDetector(
                      onTap: () => _selectPlace(p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 200,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF4A90D9)
                              : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFF4A90D9)
                                : Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : const Color(0xFFE0E8F5),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  )),
                              const SizedBox(height: 3),
                              Row(children: [
                                Icon(Icons.near_me_rounded,
                                    size: 11,
                                    color: isActive
                                        ? Colors.white70
                                        : const Color(0xFF7ABCF0)),
                                const SizedBox(width: 3),
                                Text(
                                  dist ?? 'GPS mati',
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white70
                                        : const Color(0xFF7ABCF0),
                                    fontSize: 11,
                                  ),
                                ),
                              ]),
                            ]),
                      ),
                    );
                  },
                ),
              ),

            // Detail kartu tempat aktif
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90D9).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.place_rounded,
                      color: Color(0xFF4A90D9), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(active.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(active.address,
                          style: const TextStyle(
                              color: Color(0xFF7ABCF0), fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ])),
                if (_distanceText != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90D9).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_distanceText!,
                        style: const TextStyle(
                            color: Color(0xFF7ABCF0),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ]),
            ),

            const SizedBox(height: 12),

            // GPS loading
            if (_isLoadingGps)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90D9).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  AppLoadingIndicator(size: 16, strokeWidth: 2, color: Color(0xFF4A90D9)),
                  const SizedBox(width: 8),
                  const Text('Mengambil lokasi GPS...',
                      style: TextStyle(
                          color: Color(0xFF7ABCF0), fontSize: 12)),
                ]),
              ),

            // GPS off warning
            if (!_isLoadingGps && _currentPosition == null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFFF9800).withOpacity(0.3)),
                ),
                child: const Row(children: [
                  Icon(Icons.gps_off_rounded,
                      color: Color(0xFFFF9800), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text(
                    'GPS tidak aktif — rute akan dibuka tanpa origin',
                    style: TextStyle(
                        color: Color(0xFFFF9800), fontSize: 12),
                  )),
                ]),
              ),

            // Tombol Mulai Navigasi
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openRoute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90D9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: _isLoadingGps
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: SizedBox())
                      : const Icon(Icons.directions_rounded, size: 20),
                  // show a small white spinner inside the label when loading
                  // (we keep the icon area stable)
                  
                  label: Text(
                    _isLoadingGps ? 'Mengambil GPS...' : 'Mulai Navigasi',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}