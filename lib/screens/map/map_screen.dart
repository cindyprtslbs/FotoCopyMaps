import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/place_model.dart';
import '../../services/location_service.dart';
import '../../utils/constants.dart';
import '../detail/detail_screen.dart';

class MapScreen extends StatefulWidget {
  final List<Place> places;
  final Place? focusPlace; // jika dibuka dari detail, langsung fokus ke sini

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
    final pos = _location.lastPosition ?? await _location.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() => _userLatLng = LatLng(pos.latitude, pos.longitude));
    }

    // Jika ada place yang difokus, geser peta ke sana
    if (widget.focusPlace != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _mapController.move(
          LatLng(widget.focusPlace!.lat, widget.focusPlace!.lng),
          17.0,
        );
        setState(() => _selectedPlace = widget.focusPlace);
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
      appBar: AppBar(
        title: Text(
          widget.focusPlace != null
              ? widget.focusPlace!.name
              : 'Peta Direktori',
        ),
        actions: [
          // Tombol ke lokasi pengguna
          if (_userLatLng != null)
            IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: 'Lokasi saya',
              onPressed: () {
                _mapController.move(_userLatLng!, 16.0);
              },
            ),
        ],
      ),

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
              // Tile layer OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.campus_directory',
              ),

              // Marker lokasi pengguna
              if (_userLatLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLatLng!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
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
                    width: isSelected ? 52 : 44,
                    height: isSelected ? 52 : 44,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedPlace = place);
                        _mapController.move(LatLng(place.lat, place.lng), 16);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.place,
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.primary,
                          size: isSelected ? 28 : 24,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // ── Popup info tempat yang dipilih ─────
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
                      builder: (_) => DetailScreen(place: _selectedPlace!),
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

          // ── Indikator GPS loading ──────────────
          if (_userLatLng == null)
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Mendapatkan lokasi…',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Popup kecil yang muncul saat marker diklik
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
    final scheme = Theme.of(context).colorScheme;

    String? distanceText;
    if (userLatLng != null) {
      final meters = Geolocator.distanceBetween(
        userLatLng!.latitude, userLatLng!.longitude,
        place.lat, place.lng,
      );
      distanceText = meters < 1000
          ? '${meters.toStringAsFixed(0)} m'
          : '${(meters / 1000).toStringAsFixed(1)} km';
    }

    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    place.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (distanceText != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      distanceText,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (place.categoryName != null) ...[
              const SizedBox(height: 4),
              Text(
                place.categoryName!,
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.primary,
                ),
              ),
            ],
            if (place.address != null) ...[
              const SizedBox(height: 4),
              Text(
                place.address!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDetail,
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Detail'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onRoute,
                    icon: const Icon(Icons.directions, size: 16),
                    label: const Text('Rute'),
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
