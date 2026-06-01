import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/place_model.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../widgets/place_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_indicator.dart';
import 'detail_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  /// Posisi dari SplashScreen. Null jika user skip GPS.
  final Position? userPosition;

  const HomeScreen({
    super.key,
    this.userPosition,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Place> _allPlaces = [];
  List<Place> _filteredPlaces = [];
  List<Category> _categories = [];
  Position? _userPosition;

  bool _isLoading = true;
  String? _placesError;

  int _selectedCategoryId = -1;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _userPosition = widget.userPosition;
    _searchCtrl.addListener(_applyFilter);
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _fetchAll();

    if (_userPosition == null) {
      await _refreshGps();
    }
  }

  Future<void> _fetchAll({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _placesError = null;
    });

    final result = await ApiService.getInit(forceRefresh: forceRefresh);
    if (!mounted) return;

    if (result is ApiSuccess<InitData>) {
      setState(() {
        _isLoading = false;
        _allPlaces = result.data.places;
        _categories = result.data.categories;
        _applyFilter();
      });
    } else if (result is ApiError<InitData>) {
      setState(() {
        _isLoading = false;
        _placesError = result.message;
      });
    }
  }




  void _applyFilter() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filteredPlaces = _allPlaces.where((p) {
        final matchCat = _selectedCategoryId == -1 || p.categoryId == _selectedCategoryId;
        final matchQuery = query.isEmpty ||
            p.name.toLowerCase().contains(query) ||
            p.address.toLowerCase().contains(query);
        return matchCat && matchQuery;
      }).toList();

      if (_userPosition != null) {
        _filteredPlaces.sort((a, b) {
          final dA = LocationService.distanceBetween(
            userLat: _userPosition!.latitude, userLng: _userPosition!.longitude,
            placeLat: a.lat, placeLng: a.lng,
          );
          final dB = LocationService.distanceBetween(
            userLat: _userPosition!.latitude, userLng: _userPosition!.longitude,
            placeLat: b.lat, placeLng: b.lng,
          );
          return dA.compareTo(dB);
        });
      }
    });
  }

  void _selectCategory(int id) {
    setState(() => _selectedCategoryId = id);
    _applyFilter();
  }

  Future<void> _refreshGps() async {
    final result = await LocationService.getCurrentLocation();
    if (result is LocationSuccess) {
      setState(() => _userPosition = result.position);
      _applyFilter();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lokasi diperbarui ✓'),
          backgroundColor: Color(0xFF1DB954),
          duration: Duration(seconds: 2),
        ));
      }
    } else if (result is LocationDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.message),
          backgroundColor: const Color(0xFFFF6B6B),
        ));
      }
    }
  }

  String? _distanceLabel(Place place) {
    if (_userPosition == null) return null;
    final m = LocationService.distanceBetween(
      userLat: _userPosition!.latitude, userLng: _userPosition!.longitude,
      placeLat: place.lat, placeLng: place.lng,
    );
    return LocationService.formatDistance(m);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A90D9), Color(0xFF1A5FA8)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.explore_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('FotoCopyFinder', style: TextStyle(
            color: Color(0xFF1A2340), fontWeight: FontWeight.w800,
            fontSize: 20, letterSpacing: -0.5,
          )),
        ]),
        actions: [
          GestureDetector(
            onTap: _refreshGps,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _userPosition != null
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  _userPosition != null ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
                  size: 14,
                  color: _userPosition != null ? const Color(0xFF1DB954) : const Color(0xFFFF9800),
                ),
                const SizedBox(width: 4),
                Text(
                  _userPosition != null ? 'GPS Aktif' : 'GPS Mati',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: _userPosition != null ? const Color(0xFF1DB954) : const Color(0xFFFF9800),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF4A90D9),
        onRefresh: () => _fetchAll(forceRefresh: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Mini Map Header ───────────────────────────────────
            SliverToBoxAdapter(
              child: _MiniMapHeader(
                userPosition: _userPosition,
                places: _filteredPlaces,
                isLoading: _isLoading,
                onMarkerTap: (place) => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MapScreen(
                      place: place,
                      userPosition: _userPosition,
                    ),
                  ),
                ),
              ),
            ),
            // Search
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE4E8F0)),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Cari nama tempat atau alamat…',
                      hintStyle: TextStyle(color: Color(0xFFADB5C8), fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF4A90D9), size: 22),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ),
            // Categories
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.only(left: 20, bottom: 20),
                child: _isLoading
                    ? SizedBox(height: 40,
                        child: Center(child: AppLoadingIndicator(size: 20, strokeWidth: 2, color: Color(0xFF4A90D9))))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          CategoryChip(
                            category: Category(id: -1, name: 'Semua', icon: '🗺️'),
                            isSelected: _selectedCategoryId == -1,
                            onTap: () => _selectCategory(-1),
                          ),
                          ..._categories.map((cat) => CategoryChip(
                            category: cat,
                            isSelected: _selectedCategoryId == cat.id,
                            onTap: () => _selectCategory(cat.id),
                          )),
                        ]),
                      ),
              ),
            ),
            // Count label
            if (!_isLoading && _placesError == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Text(
                    '${_filteredPlaces.length} tempat ditemukan'
                    '${_userPosition != null ? ' • terdekat duluan' : ''}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF7A8499), fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            // Body
            if (_placesError != null)
              SliverFillRemaining(
                child: AppErrorWidget(message: _placesError!, onRetry: () => _fetchAll(forceRefresh: true)),
              )
            else if (_isLoading)
              SliverFillRemaining(
                child: _PlacesShimmer(),
              )
            else if (_filteredPlaces.isEmpty)
              SliverFillRemaining(
                child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.search_off_rounded, size: 64,
                    color: const Color(0xFF4A90D9).withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  const Text('Tempat tidak ditemukan',
                    style: TextStyle(color: Color(0xFFADB5C8), fontSize: 15)),
                ])),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final place = _filteredPlaces[index];
                    return PlaceCard(
                      place: place,
                      distance: _distanceLabel(place),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => DetailScreen(
                          place: place,
                          userPosition: _userPosition,
                          nearbyPlaces: _filteredPlaces,
                        ),
                      )),
                    );
                  },
                  childCount: _filteredPlaces.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer skeleton saat data loading ────────────────────────────────────────
class _PlacesShimmer extends StatefulWidget {
  @override
  State<_PlacesShimmer> createState() => _PlacesShimmerState();
}

class _PlacesShimmerState extends State<_PlacesShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final opacity = 0.4 + (_anim.value * 0.4);
        return Column(
          children: List.generate(4, (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12, offset: const Offset(0, 4),
              )],
            ),
            child: Row(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90D9).withValues(alpha: opacity * 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14, width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4E8F0).withValues(alpha: opacity),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 11, width: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4E8F0).withValues(alpha: opacity * 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 20, width: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1FC).withValues(alpha: opacity),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              )),
            ]),
          )),
        );
      },
    );
  }
}

// ── Mini Map Preview Widget ────────────────────────────────────────────────────
class _MiniMapHeader extends StatefulWidget {
  final Position? userPosition;
  final List<Place> places;
  final void Function(Place) onMarkerTap;
  final bool isLoading;

  const _MiniMapHeader({
    required this.userPosition,
    required this.places,
    required this.onMarkerTap,
    this.isLoading = false,
  });

  @override
  State<_MiniMapHeader> createState() => _MiniMapHeaderState();
}

class _MiniMapHeaderState extends State<_MiniMapHeader> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(_MiniMapHeader old) {
    super.didUpdateWidget(old);
    // Pindahkan peta ke posisi user saat GPS baru diterima
    if (widget.userPosition != null &&
        (old.userPosition == null ||
            old.userPosition!.latitude != widget.userPosition!.latitude ||
            old.userPosition!.longitude != widget.userPosition!.longitude)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(
          LatLng(widget.userPosition!.latitude, widget.userPosition!.longitude),
          15,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userPos = widget.userPosition;
    final places = widget.places;

    final center = userPos != null
        ? LatLng(userPos.latitude, userPos.longitude)
        : places.isNotEmpty
            ? LatLng(places.first.lat, places.first.lng)
            : const LatLng(-7.2575, 112.7521);

    final markers = <Marker>[
      if (userPos != null)
        Marker(
          point: LatLng(userPos.latitude, userPos.longitude),
          width: 28,
          height: 28,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1DB954),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Color(0x661DB954), blurRadius: 8, spreadRadius: 2),
              ],
            ),
          ),
        ),
      ...places.take(20).map(
            (p) => Marker(
              point: LatLng(p.lat, p.lng),
              width: 36,
              height: 36,
              child: GestureDetector(
                onTap: () => widget.onMarkerTap(p),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4A90D9),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Color(0x664A90D9), blurRadius: 6),
                    ],
                  ),
                  child: const Icon(Icons.place_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
          ),
    ];

    return Stack(
      children: [
        SizedBox(
          height: 200,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.fotocopyfinder_app',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 48,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xFFF4F7FC)],
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.explore_rounded, size: 14, color: Color(0xFF4A90D9)),
              const SizedBox(width: 6),
              Text(
                userPos != null
                    ? 'Diurutkan dari lokasi kamu'
                    : 'Temukan Tempat di Sekitar Kampus',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2340),
                ),
              ),
            ]),
          ),
        ),
        // Loading overlay di atas peta saat data belum ada
        if (widget.isLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppLoadingIndicator(size: 22, strokeWidth: 2.5, color: Color(0xFF4A90D9)),
                    const SizedBox(height: 8),
                    const Text(
                      'Memuat tempat…',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2340),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (!widget.isLoading && places.isNotEmpty)
          Positioned(
            top: 12,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90D9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${places.length} tempat',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}