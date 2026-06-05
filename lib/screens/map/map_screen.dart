import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/place_model.dart';
import '../../services/location_service.dart';
import '../../utils/constants.dart';
import '../detail/detail_screen.dart';

// ── Warna konsisten dengan app ─────────────────────────
const _kPrimary = Color(0xFF3B6FE8);
const _kGradientEnd = Color(0xFF1CB8C8);
const _kDark = Color(0xFF1A1A2E);

class MapScreen extends StatefulWidget {
  final List<Place> places;
  final Place? focusPlace;

  const MapScreen({
    super.key,
    required this.places,
    this.focusPlace,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  final _location = LocationService();
  Place? _selectedPlace;
  LatLng? _userLatLng;

  @override
  void initState() {
    super.initState();
    _setupLocation();
  }

  Future<void> _setupLocation() async {
    final pos =
        _location.lastPosition ?? await _location.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() => _userLatLng = LatLng(pos.latitude, pos.longitude));
    }

    if (widget.focusPlace != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _mapController.move(
          LatLng(widget.focusPlace!.lat, widget.focusPlace!.lng),
          17.0,
        );
        if (mounted) setState(() => _selectedPlace = widget.focusPlace);
      });
    }
  }

  LatLng get _center {
    if (widget.focusPlace != null) {
      return LatLng(widget.focusPlace!.lat, widget.focusPlace!.lng);
    }
    if (_userLatLng != null) return _userLatLng!;
    return LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: Stack(
        children: [
          // ── Peta utama ──────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: AppConstants.defaultZoom,
              onTap: (_, __) => setState(() => _selectedPlace = null),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.campus_directory',
              ),

              // Marker lokasi pengguna
              if (_userLatLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLatLng!,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _kPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: _kPrimary.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

              // Marker tempat
              MarkerLayer(
                markers: widget.places.map((place) {
                  final isSelected = _selectedPlace?.id == place.id;
                  return Marker(
                    point: LatLng(place.lat, place.lng),
                    width: isSelected ? 54 : 46,
                    height: isSelected ? 54 : 46,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedPlace = place);
                        _mapController.move(
                            LatLng(place.lat, place.lng), 16);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [_kPrimary, _kGradientEnd],
                                )
                              : null,
                          color: isSelected ? null : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _kPrimary,
                            width: isSelected ? 0 : 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _kPrimary.withOpacity(
                                  isSelected ? 0.4 : 0.15),
                              blurRadius: isSelected ? 12 : 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.place_rounded,
                          color:
                              isSelected ? Colors.white : _kPrimary,
                          size: isSelected ? 28 : 24,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // ── Top Bar (custom app bar) ─────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_kPrimary, _kGradientEnd],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: Row(
                children: [
                  // Tombol kembali
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Judul
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.focusPlace != null
                              ? widget.focusPlace!.name
                              : 'Peta Direktori',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${widget.places.length} tempat',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tombol lokasi saya
                  if (_userLatLng != null)
                    GestureDetector(
                      onTap: () => _mapController.move(_userLatLng!, 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Loading GPS indicator ─────────────────
          if (_userLatLng == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _kPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Mendapatkan lokasi…',
                        style: TextStyle(
                          fontSize: 12,
                          color: _kDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Popup info tempat yang dipilih ─────────
          if (_selectedPlace != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: _PlacePopup(
                place: _selectedPlace!,
                userLatLng: _userLatLng,
                onDetail: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DetailScreen(place: _selectedPlace!),
                    ),
                  );
                },
                onRoute: () async {
                  await LocationService().openRoute(
                    destLat: _selectedPlace!.lat,
                    destLng: _selectedPlace!.lng,
                    originLat: _userLatLng?.latitude,
                    originLng: _userLatLng?.longitude,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// PLACE POPUP
// ─────────────────────────────────────────────────────────
class _PlacePopup extends StatelessWidget {
  final Place place;
  final LatLng? userLatLng;
  final VoidCallback onDetail;
  final VoidCallback onRoute;

  const _PlacePopup({
    required this.place,
    required this.userLatLng,
    required this.onDetail,
    required this.onRoute,
  });

  @override
  Widget build(BuildContext context) {
    String? distanceText;
    if (userLatLng != null) {
      final meters = Geolocator.distanceBetween(
        userLatLng!.latitude,
        userLatLng!.longitude,
        place.lat,
        place.lng,
      );
      distanceText = meters < 1000
          ? '${meters.toStringAsFixed(0)} m'
          : '${(meters / 1000).toStringAsFixed(1)} km';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon kategori
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_kPrimary, _kGradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.place_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _kDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (place.categoryName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          place.categoryName!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (place.address != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          place.address!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (distanceText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F3FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      distanceText,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            if (place.rating != null || place.openHours != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (place.rating != null) ...[
                    const Icon(Icons.star_rounded,
                        size: 14, color: Colors.amber),
                    const SizedBox(width: 3),
                    Text(
                      place.rating!.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (place.openHours != null) ...[
                    Icon(Icons.access_time_rounded,
                        size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Text(
                      place.openHours!,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: onDetail,
                      icon: const Icon(Icons.info_outline_rounded, size: 16),
                      label: const Text(
                        'Detail',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: const BorderSide(color: _kPrimary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: onRoute,
                      icon: const Icon(Icons.directions_rounded, size: 16),
                      label: const Text(
                        'Rute',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}