// // lib/screens/map/map_screen.dart

// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:geolocator/geolocator.dart';
// import '../../models/place_model.dart';
// import '../../models/category_model.dart';
// import '../../services/supabase_service.dart';
// import '../../services/location_service.dart';
// import '../../utils/constants.dart';
// import '../detail/detail_screen.dart';
// import '../auth/login_screen.dart';

// class MapScreen extends StatefulWidget {
//   final List<Place>? places;
//   final Place? focusPlace;

//   const MapScreen({
//     super.key,
//     this.places,
//     this.focusPlace,
//   });

//   @override
//   State<MapScreen> createState() => _MapScreenState();
// }

// class _MapScreenState extends State<MapScreen> {
//   final _mapController = MapController();
//   final _location = LocationService();
//   final _supabase = SupabaseService();
//   final _searchController = TextEditingController();

//   List<Place> _places = [];
//   List<Category> _categories = [];
//   int? _selectedCategoryId;
//   Place? _selectedPlace;
//   LatLng? _userLatLng;
//   bool _isLoading = true;
//   bool _showSearch = false;

//   @override
//   void initState() {
//     super.initState();
//     _init();
//   }

//   Future<void> _init() async {
//     await _setupLocation();
//     if (widget.places != null) {
//       setState(() {
//         _places = widget.places!;
//         _isLoading = false;
//       });
//     } else {
//       await _loadData();
//     }
//   }

//   Future<void> _setupLocation() async {
//     final pos = _location.lastPosition ?? await _location.getCurrentLocation();
//     if (pos != null && mounted) {
//       setState(() => _userLatLng = LatLng(pos.latitude, pos.longitude));
//       // Langsung geser peta ke lokasi user
//       Future.delayed(const Duration(milliseconds: 500), () {
//         if (mounted) {
//           _mapController.move(_userLatLng!, 15.0);
//         }
//       });
//     }

//     if (widget.focusPlace != null) {
//       Future.delayed(const Duration(milliseconds: 300), () {
//         if (mounted) {
//           _mapController.move(
//             LatLng(widget.focusPlace!.lat, widget.focusPlace!.lng),
//             17.0,
//           );
//           setState(() => _selectedPlace = widget.focusPlace);
//         }
//       });
//     }
//   }

//   Future<void> _loadData() async {
//     setState(() => _isLoading = true);
//     try {
//       final results = await Future.wait([
//         _supabase.getPlaces(categoryId: _selectedCategoryId),
//         _supabase.getCategories(),
//       ]);
//       var places = results[0] as List<Place>;
//       places = _location.sortByDistance(places);
//       if (mounted) {
//         setState(() {
//           _places = places;
//           _categories = results[1] as List<Category>;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Gagal memuat data: $e')),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _searchPlaces(String keyword) async {
//     try {
//       var places = await _supabase.getPlaces(
//         categoryId: _selectedCategoryId,
//         search: keyword,
//       );
//       places = _location.sortByDistance(places);
//       if (mounted) setState(() => _places = places);
//     } catch (_) {}
//   }

//   LatLng get _center {
//     if (widget.focusPlace != null) {
//       return LatLng(widget.focusPlace!.lat, widget.focusPlace!.lng);
//     }
//     if (_userLatLng != null) return _userLatLng!;
//     return LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;

//     return Scaffold(
//       body: Stack(
//         children: [
//           // ── Peta utama ──────────────────────────
//           FlutterMap(
//             mapController: _mapController,
//             options: MapOptions(
//               initialCenter: _center,
//               initialZoom: 15.0,
//               onTap: (_, __) => setState(() => _selectedPlace = null),
//             ),
//             children: [
//               TileLayer(
//                 urlTemplate:
//                     'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//                 userAgentPackageName: 'com.example.fotocopy_app',
//               ),

//               // Marker lokasi user
//               if (_userLatLng != null)
//                 MarkerLayer(
//                   markers: [
//                     Marker(
//                       point: _userLatLng!,
//                       width: 44,
//                       height: 44,
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: Colors.blue.shade600,
//                           shape: BoxShape.circle,
//                           border:
//                               Border.all(color: Colors.white, width: 3),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.blue.withOpacity(0.4),
//                               blurRadius: 8,
//                               spreadRadius: 2,
//                             ),
//                           ],
//                         ),
//                         child: const Icon(
//                           Icons.person,
//                           color: Colors.white,
//                           size: 22,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//               // Marker tempat fotocopy
//               if (!_isLoading)
//                 MarkerLayer(
//                   markers: _places.map((place) {
//                     final isSelected = _selectedPlace?.id == place.id;
//                     return Marker(
//                       point: LatLng(place.lat, place.lng),
//                       width: isSelected ? 56 : 44,
//                       height: isSelected ? 56 : 44,
//                       child: GestureDetector(
//                         onTap: () {
//                           setState(() => _selectedPlace = place);
//                           _mapController.move(
//                               LatLng(place.lat, place.lng), 16);
//                         },
//                         child: AnimatedContainer(
//                           duration: const Duration(milliseconds: 200),
//                           decoration: BoxDecoration(
//                             color: isSelected
//                                 ? scheme.primary
//                                 : Colors.white,
//                             shape: BoxShape.circle,
//                             border: Border.all(
//                               color: scheme.primary,
//                               width: 2.5,
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.2),
//                                 blurRadius: 6,
//                                 offset: const Offset(0, 2),
//                               ),
//                             ],
//                           ),
//                           child: Icon(
//                             Icons.content_copy_rounded,
//                             color: isSelected
//                                 ? Colors.white
//                                 : scheme.primary,
//                             size: isSelected ? 30 : 24,
//                           ),
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//             ],
//           ),

//           // ── Top bar: search + filter ─────────────
//           SafeArea(
//             child: Column(
//               children: [
//                 // Search bar
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
//                   child: Material(
//                     elevation: 4,
//                     borderRadius: BorderRadius.circular(28),
//                     child: TextField(
//                       controller: _searchController,
//                       onSubmitted: _searchPlaces,
//                       onChanged: (v) {
//                         if (v.isEmpty) _loadData();
//                       },
//                       decoration: InputDecoration(
//                         hintText: 'Cari fotocopy…',
//                         prefixIcon: const Icon(Icons.search),
//                         suffixIcon: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             if (_searchController.text.isNotEmpty)
//                               IconButton(
//                                 icon: const Icon(Icons.clear),
//                                 onPressed: () {
//                                   _searchController.clear();
//                                   _loadData();
//                                 },
//                               ),
//                             // Logout
//                             IconButton(
//                               icon: const Icon(Icons.logout),
//                               tooltip: 'Logout',
//                               onPressed: () async {
//                                 await SupabaseService().signOut();
//                                 if (context.mounted) {
//                                   Navigator.pushReplacement(
//                                     context,
//                                     MaterialPageRoute(
//                                         builder: (_) =>
//                                             const LoginScreen()),
//                                   );
//                                 }
//                               },
//                             ),
//                           ],
//                         ),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(28),
//                           borderSide: BorderSide.none,
//                         ),
//                         filled: true,
//                         fillColor: Colors.white,
//                         contentPadding:
//                             const EdgeInsets.symmetric(vertical: 0),
//                       ),
//                     ),
//                   ),
//                 ),

//                 // Filter kategori
//                 if (_categories.isNotEmpty)
//                   SizedBox(
//                     height: 44,
//                     child: ListView(
//                       scrollDirection: Axis.horizontal,
//                       padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
//                       children: [
//                         _CategoryPill(
//                           label: 'Semua',
//                           isSelected: _selectedCategoryId == null,
//                           onTap: () {
//                             setState(() => _selectedCategoryId = null);
//                             _loadData();
//                           },
//                         ),
//                         ..._categories.map((cat) => _CategoryPill(
//                               label: cat.name,
//                               isSelected:
//                                   _selectedCategoryId == cat.id,
//                               onTap: () {
//                                 setState(() =>
//                                     _selectedCategoryId = cat.id);
//                                 _loadData();
//                               },
//                             )),
//                       ],
//                     ),
//                   ),
//               ],
//             ),
//           ),

//           // ── Loading indicator ────────────────────
//           if (_isLoading)
//             const Center(child: CircularProgressIndicator()),

//           // ── Popup detail tempat ──────────────────
//           if (_selectedPlace != null)
//             Positioned(
//               bottom: 24,
//               left: 16,
//               right: 16,
//               child: _PlacePopup(
//                 place: _selectedPlace!,
//                 userLatLng: _userLatLng,
//                 onDetail: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) =>
//                           DetailScreen(place: _selectedPlace!),
//                     ),
//                   );
//                 },
//                 onRoute: () async {
//                   await LocationService().openRoute(
//                     destLat: _selectedPlace!.lat,
//                     destLng: _selectedPlace!.lng,
//                     originLat: _userLatLng?.latitude,
//                     originLng: _userLatLng?.longitude,
//                   );
//                 },
//               ),
//             ),
//         ],
//       ),

//       // ── FAB: kembali ke lokasi user ──────────────
//       floatingActionButton: _userLatLng != null
//           ? FloatingActionButton(
//               onPressed: () => _mapController.move(_userLatLng!, 15.0),
//               tooltip: 'Lokasi saya',
//               child: const Icon(Icons.my_location),
//             )
//           : null,
//     );
//   }
// }

// // ── Pill filter kategori ─────────────────────────
// class _CategoryPill extends StatelessWidget {
//   final String label;
//   final bool isSelected;
//   final VoidCallback onTap;

//   const _CategoryPill({
//     required this.label,
//     required this.isSelected,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;
//     return Padding(
//       padding: const EdgeInsets.only(right: 8),
//       child: GestureDetector(
//         onTap: onTap,
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 180),
//           padding:
//               const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
//           decoration: BoxDecoration(
//             color: isSelected ? scheme.primary : Colors.white,
//             borderRadius: BorderRadius.circular(20),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 4,
//               ),
//             ],
//           ),
//           child: Text(
//             label,
//             style: TextStyle(
//               fontSize: 13,
//               fontWeight:
//                   isSelected ? FontWeight.w600 : FontWeight.normal,
//               color: isSelected ? Colors.white : Colors.black87,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ── Popup info tempat ────────────────────────────
// class _PlacePopup extends StatelessWidget {
//   final Place place;
//   final LatLng? userLatLng;
//   final VoidCallback onDetail;
//   final VoidCallback onRoute;

//   const _PlacePopup({
//     required this.place,
//     required this.userLatLng,
//     required this.onDetail,
//     required this.onRoute,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;

//     String? distanceText;
//     if (userLatLng != null) {
//       final meters = Geolocator.distanceBetween(
//         userLatLng!.latitude,
//         userLatLng!.longitude,
//         place.lat,
//         place.lng,
//       );
//       distanceText = meters < 1000
//           ? '${meters.toStringAsFixed(0)} m'
//           : '${(meters / 1000).toStringAsFixed(1)} km';
//     }

//     return Card(
//       elevation: 8,
//       shadowColor: Colors.black26,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     place.name,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 if (distanceText != null)
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: scheme.primaryContainer,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       distanceText,
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: scheme.onPrimaryContainer,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//             if (place.address != null) ...[
//               const SizedBox(height: 4),
//               Text(
//                 place.address!,
//                 style:
//                     const TextStyle(fontSize: 12, color: Colors.grey),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ],
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: onDetail,
//                     icon: const Icon(Icons.info_outline, size: 16),
//                     label: const Text('Detail'),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: FilledButton.icon(
//                     onPressed: onRoute,
//                     icon: const Icon(Icons.directions, size: 16),
//                     label: const Text('Rute'),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }








// saran temannnnn

// lib/screens/map/map_screen.dart
//
// Tampilkan semua tempat sebagai marker di OpenStreetMap.
// Tap marker → popup info → navigasi ke DetailScreen.

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
