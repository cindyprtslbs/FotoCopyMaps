// lib/screens/home/home_screen.dart
//
// Layar utama: daftar tempat + filter kategori + search.
// Navigasi ke MapScreen dan DetailScreen dari sini.

import 'package:flutter/material.dart';
import '../../models/place_model.dart';
import '../../models/category_model.dart';
import '../../services/supabase_service.dart';
import '../../services/location_service.dart';
import '../../widgets/place_card.dart';
import '../../widgets/category_chip.dart';
import '../map/map_screen.dart';
import '../detail/detail_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = SupabaseService();
  final _location = LocationService();
  final _searchController = TextEditingController();

  List<Place> _places = [];
  List<Category> _categories = [];
  int? _selectedCategoryId;
  bool _isLoading = true;
  bool _locationLoaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadCategories();
    await _loadLocation();
    await _loadPlaces();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _supabase.getCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (e) {
      // kategori gagal tidak fatal
    }
  }

  Future<void> _loadLocation() async {
    await _location.getCurrentLocation();
    if (mounted) setState(() => _locationLoaded = true);
  }

  Future<void> _loadPlaces({String? search}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      var places = await _supabase.getPlaces(
        categoryId: _selectedCategoryId,
        search: search,
      );

      // Hitung & isi jarak, lalu urutkan
      places = _location.sortByDistance(places);

      if (mounted) setState(() => _places = places);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onCategorySelected(int? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    _loadPlaces(search: _searchController.text);
  }

  void _onSearch(String value) {
    _loadPlaces(search: value);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        title: const Text(
          '🏛️ Campus Directory',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Lihat Peta',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MapScreen(places: _places),
                ),
              );
            },
          ),
          // Tambah tombol logout
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await SupabaseService().signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _init,
        child: CustomScrollView(
          slivers: [
            // ── Search bar ──────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _onSearch,
                  onChanged: (v) {
                    if (v.isEmpty) _loadPlaces();
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari tempat…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadPlaces();
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),

            // ── Filter kategori ──────────────────────
            if (_categories.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Chip "Semua"
                      CategoryChip(
                        label: 'Semua',
                        icon: '🗺️',
                        isSelected: _selectedCategoryId == null,
                        onTap: () => _onCategorySelected(null),
                      ),
                      ..._categories.map((cat) => CategoryChip(
                            label: cat.name,
                            icon: cat.icon ?? '📍',
                            isSelected: _selectedCategoryId == cat.id,
                            onTap: () => _onCategorySelected(cat.id),
                          )),
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // ── Konten utama ─────────────────────────
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: _ErrorView(
                  message: _error!,
                  onRetry: _init,
                ),
              )
            else if (_places.isEmpty)
              const SliverFillRemaining(
                child: _EmptyView(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final place = _places[index];
                      return PlaceCard(
                        place: place,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(place: place),
                            ),
                          );
                        },
                      );
                    },
                    childCount: _places.length,
                  ),
                ),
              ),
          ],
        ),
      ),

      // ── FAB: buka peta ──────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MapScreen(places: _places),
            ),
          );
        },
        icon: const Icon(Icons.map),
        label: const Text('Peta'),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_outlined, size: 56, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Belum ada tempat ditemukan',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
