import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path; 
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/place_model.dart';
import '../../services/location_service.dart';
import '../../services/favorites_service.dart';
import '../../utils/constants.dart';
import '../detail/detail_screen.dart';

// Tema Neumorphism Fintech
const Color _bgColor = Color(0xFFF0F4F8);
const Color _shadowDark = Color(0xFFD1D9E6);
const Color _shadowLight = Colors.white;
const Color _primaryText = Color(0xFF1E293B);
const Color _secondaryText = Color(0xFF64748B);
const Color _primary = Color(0xFF3B82F6);
const Color _primaryDark = Color(0xFF1D4ED8);

// ── Helper Markers ──────────────
_MarkerStyle _markerStyleFor(String? categoryName) {
  final cat = (categoryName ?? '').toLowerCase();

  if (cat.contains('fotokopi') || cat.contains('fotocopy') || cat.contains('copy')) {
    return _MarkerStyle(
      colors: [const Color(0xFF10B981), const Color(0xFF059669)],
      icon: Icons.print_rounded,
      emoji: '🖨️',
    );
  } else if (cat.contains('kantin') || cat.contains('makan') || cat.contains('food')) {
    return _MarkerStyle(
      colors: [const Color(0xFFFF6B35), const Color(0xFFE55A2B)],
      icon: Icons.restaurant_rounded,
      emoji: '🍽️',
    );
  } else if (cat.contains('cafe') || cat.contains('kopi') || cat.contains('coffee')) {
    return _MarkerStyle(
      colors: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
      icon: Icons.local_cafe_rounded,
      emoji: '☕',
    );
  } else if (cat.contains('atm') || cat.contains('bank')) {
    return _MarkerStyle(
      colors: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
      icon: Icons.account_balance_rounded,
      emoji: '🏧',
    );
  } else if (cat.contains('parkir') || cat.contains('parking')) {
    return _MarkerStyle(
      colors: [const Color(0xFF6B7280), const Color(0xFF4B5563)],
      icon: Icons.local_parking_rounded,
      emoji: '🅿️',
    );
  } else if (cat.contains('kos') || cat.contains('indekos') || cat.contains('kontrakan')) {
    return _MarkerStyle(
      colors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      icon: Icons.home_rounded,
      emoji: '🏠',
    );
  } else if (cat.contains('toko') || cat.contains('minimarket') || cat.contains('mart')) {
    return _MarkerStyle(
      colors: [const Color(0xFFEC4899), const Color(0xFFDB2777)],
      icon: Icons.store_rounded,
      emoji: '🛒',
    );
  } else {
    return _MarkerStyle(
      colors: [_primary, _primaryDark],
      icon: Icons.place_rounded,
      emoji: '📍',
    );
  }
}

class _MarkerStyle {
  final List<Color> colors;
  final IconData icon;
  final String emoji;
  const _MarkerStyle({
    required this.colors,
    required this.icon,
    required this.emoji,
  });
}

// ─────────────────────────────────────────────────────────
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

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  final _mapController = MapController();
  final _location = LocationService();
  final _favService = FavoritesService();

  Place? _selectedPlace;
  LatLng? _userLatLng;
  Set<int> _favoriteIds = {};
  late AnimationController _popupAnim;
  late Animation<double> _popupScale;

  @override
  void initState() {
    super.initState();
    _popupAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _popupScale = CurvedAnimation(parent: _popupAnim, curve: Curves.easeOutBack);
    _setupLocation();
    _loadFavorites();
  }

  @override
  void dispose() {
    _popupAnim.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final ids = await _favService.getFavoriteIds();
    if (mounted) setState(() => _favoriteIds = ids);
  }

  Future<void> _setupLocation() async {
    final pos = _location.lastPosition ?? await _location.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() => _userLatLng = LatLng(pos.latitude, pos.longitude));
    }

    if (widget.focusPlace != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _mapController.move(
          LatLng(widget.focusPlace!.lat, widget.focusPlace!.lng),
          17.0,
        );
        if (mounted) {
          setState(() => _selectedPlace = widget.focusPlace);
          _popupAnim.forward();
        }
      });
    }
  }

  void _selectPlace(Place place) {
    setState(() => _selectedPlace = place);
    _popupAnim.forward(from: 0);
    _mapController.move(LatLng(place.lat, place.lng), 16);
  }

  void _deselectPlace() {
    _popupAnim.reverse().then((_) {
      if (mounted) setState(() => _selectedPlace = null);
    });
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
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: AppConstants.defaultZoom,
              onTap: (_, __) => _deselectPlace(),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.campus_directory',
              ),

              if (_userLatLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLatLng!,
                      width: 56,
                      height: 56,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 40,
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
                                  color: _primary.withOpacity(0.45),
                                  blurRadius: 14,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.navigation_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              MarkerLayer(
                markers: widget.places.map((place) {
                  final isSelected = _selectedPlace?.id == place.id;
                  final isFav = _favoriteIds.contains(place.id);
                  final style = _markerStyleFor(place.categoryName);

                  return Marker(
                    point: LatLng(place.lat, place.lng),
                    width: isSelected ? 64 : 52,
                    height: isSelected ? 72 : 60,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => _selectPlace(place),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        child: Stack(
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.none,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: isSelected ? 50 : 42,
                                  height: isSelected ? 50 : 42,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: isSelected
                                          ? style.colors
                                          : [Colors.white, Colors.white],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? Colors.white : style.colors[0],
                                      width: isSelected ? 2.5 : 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: style.colors[0].withOpacity(isSelected ? 0.55 : 0.25),
                                        blurRadius: isSelected ? 18 : 8,
                                        offset: const Offset(0, 4),
                                        spreadRadius: isSelected ? 2 : 0,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      style.icon,
                                      color: isSelected ? Colors.white : style.colors[0],
                                      size: isSelected ? 24 : 20,
                                    ),
                                  ),
                                ),
                                CustomPaint(
                                  size: const Size(12, 8),
                                  painter: _PinTipPainter(
                                    color: isSelected ? style.colors[1] : style.colors[0],
                                  ),
                                ),
                              ],
                            ),
                            if (isFav)
                              Positioned(
                                top: -2,
                                right: isSelected ? 0 : 2,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.35),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.favorite_rounded,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 24,
            right: 24,
            child: _NeumorphicCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: _primary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.focusPlace != null
                              ? widget.focusPlace!.name
                              : 'Peta Lokasi Terdekat',
                          style: const TextStyle(
                            color: _primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.places.length} tempat ditemukan',
                          style: const TextStyle(color: _secondaryText, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (_userLatLng != null)
                    GestureDetector(
                      onTap: () => _mapController.move(_userLatLng!, 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.my_location_rounded, color: _primary, size: 20),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (_userLatLng == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 100,
              left: 0,
              right: 0,
              child: Center(
                child: _NeumorphicCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: _primary),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Mencari sinyal GPS...',
                        style: TextStyle(fontSize: 13, color: _primaryText, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_selectedPlace == null)
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: _CategoryLegend(places: widget.places),
            ),

          if (_selectedPlace != null)
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: ScaleTransition(
                scale: _popupScale,
                child: _PlacePopup(
                  place: _selectedPlace!,
                  userLatLng: _userLatLng,
                  isFavorite: _favoriteIds.contains(_selectedPlace!.id),
                  onDetail: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(place: _selectedPlace!),
                      ),
                    ).then((_) => _loadFavorites());
                  },
                  onRoute: () async {
                    await LocationService().openRoute(
                      destLat: _selectedPlace!.lat,
                      destLng: _selectedPlace!.lng,
                      originLat: _userLatLng?.latitude,
                      originLng: _userLatLng?.longitude,
                    );
                  },
                  onClose: _deselectPlace,
                ),
              ),
            ),
        ],
      ),
    );
  }
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
          BoxShadow(
            color: _shadowDark.withOpacity(0.6),
            offset: const Offset(8, 8),
            blurRadius: 16,
          ),
          const BoxShadow(
            color: _shadowLight,
            offset: Offset(-8, -8),
            blurRadius: 16,
          ),
        ],
      ),
      child: child,
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
  bool shouldRepaint(covariant _PinTipPainter oldDelegate) => oldDelegate.color != color;
}

class _CategoryLegend extends StatelessWidget {
  final List<Place> places;
  const _CategoryLegend({required this.places});

  @override
  Widget build(BuildContext context) {
    final cats = <String>{};
    for (final p in places) {
      if (p.categoryName != null) cats.add(p.categoryName!);
    }
    if (cats.isEmpty) return const SizedBox.shrink();

    return _NeumorphicCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: cats.map((cat) {
          final style = _markerStyleFor(cat);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: style.colors),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: style.colors[0].withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))
                  ]
                ),
                child: Icon(style.icon, color: Colors.white, size: 12),
              ),
              const SizedBox(width: 8),
              Text(
                cat,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _primaryText),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _PlacePopup extends StatelessWidget {
  final Place place;
  final LatLng? userLatLng;
  final bool isFavorite;
  final VoidCallback onDetail;
  final VoidCallback onRoute;
  final VoidCallback onClose;

  const _PlacePopup({
    required this.place,
    required this.userLatLng,
    required this.isFavorite,
    required this.onDetail,
    required this.onRoute,
    required this.onClose,
  });

  Widget _buildPlaceholder(_MarkerStyle style) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [style.colors[0], style.colors[1]],
        ),
      ),
      child: Center(
        child: Text(style.emoji, style: const TextStyle(fontSize: 32)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _markerStyleFor(place.categoryName);

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

    return _NeumorphicCard(
      padding: const EdgeInsets.all(0), // Custom internal padding
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: style.colors),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(style.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (place.categoryName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            place.categoryName!.toUpperCase(),
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ]
                      ],
                    ),
                  ),
                  if (isFavorite)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite_rounded, color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                          ),
                          child: place.photoUrl != null && place.photoUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: place.photoUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Center(
                                    child: SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: _primary),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => _buildPlaceholder(style),
                                )
                              : _buildPlaceholder(style),
                        ),
                      ),
                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (place.rating != null)
                                  _InfoChip(
                                    icon: Icons.star_rounded,
                                    label: place.rating!.toStringAsFixed(1),
                                    iconColor: const Color(0xFFD97706),
                                    bgColor: const Color(0xFFFEF3C7),
                                  ),
                                if (distanceText != null)
                                  _InfoChip(
                                    icon: Icons.near_me_rounded,
                                    label: distanceText,
                                    iconColor: _primary,
                                    bgColor: const Color(0xFFDBEAFE),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (place.openHours != null && place.openHours!.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 14, color: _secondaryText),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      place.openHours!,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _primaryText),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 6),

                            if (place.address != null && place.address!.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: _secondaryText),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      place.address!,
                                      style: const TextStyle(fontSize: 12, color: _secondaryText),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: onDetail,
                            icon: const Icon(Icons.info_outline_rounded, size: 18),
                            label: const Text('Detail', style: TextStyle(fontWeight: FontWeight.w700)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: style.colors[0],
                              side: BorderSide(color: style.colors[0], width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: style.colors),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: style.colors[0].withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: onRoute,
                            icon: const Icon(Icons.directions_rounded, size: 18),
                            label: const Text('Rute', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor, bgColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: iconColor),
          ),
        ],
      ),
    );
  }
}