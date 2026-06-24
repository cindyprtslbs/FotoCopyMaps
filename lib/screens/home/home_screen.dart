import 'package:flutter/material.dart';
import '../../models/place_model.dart';
import '../../models/category_model.dart';
import '../../services/supabase_service.dart';
import '../../services/location_service.dart';
import '../../widgets/place_card.dart';
import '../../widgets/category_chip.dart';
import '../map/map_screen.dart';
import '../detail/detail_screen.dart';
import '../../services/favorites_service.dart';
import '../auth/login_screen.dart';
import '../profile/edit_profile.dart';
import '../profile/help_screen.dart';
import '../profile/review_history_screen.dart';

const Color _bgColor = Color(0xFFF0F4F8);
const Color _shadowDark = Color(0xFFD1D9E6);
const Color _shadowLight = Colors.white;
const Color _primaryText = Color(0xFF1E293B);
const Color _secondaryText = Color(0xFF64748B);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _HomeTab(),
    _MapsTab(),
    _FavoriteTab(),
    _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Required for the floating bottom nav effect
      backgroundColor: _bgColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// BOTTOM NAV (Neumorphic Floating Pill)
// ─────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      {
        'iconUnselected': Icons.home_outlined,
        'iconSelected': Icons.home_rounded,
        'label': 'Home'
      },
      {
        'iconUnselected': Icons.map_outlined,
        'iconSelected': Icons.map_rounded,
        'label': 'Maps'
      },
      {
        'iconUnselected': Icons.favorite_border_rounded,
        'iconSelected': Icons.favorite_rounded,
        'label': 'Favorite'
      },
      {
        'iconUnselected': Icons.person_outline_rounded,
        'iconSelected': Icons.person_rounded,
        'label': 'Profile'
      },
    ];

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        height: 85, // Tinggi total untuk memberi ruang pada item yang menonjol ke atas
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Background Pill Putih
            Container(
              height: 64, // Tinggi asli kapsul putih
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            
            // Deretan Ikon Menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(items.length, (i) {
                final isSelected = i == currentIndex;
                final iconUnselected = items[i]['iconUnselected'] as IconData;
                final iconSelected = items[i]['iconSelected'] as IconData;
                final label = items[i]['label'] as String;

                return GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 70,
                    height: 85,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Teks (Muncul saat tidak dipilih, turun & hilang saat dipilih)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          bottom: isSelected ? -10 : 10,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isSelected ? 0.0 : 1.0,
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                        // Lingkaran Ikon Utama (Berpindah ke atas dan ganti warna saat dipilih)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutBack,
                          top: isSelected ? 2 : 24,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: isSelected ? 56 : 40,
                            height: isSelected ? 56 : 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF1C1F2E) // Warna biru dongker super gelap meniru referensi
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                // Border putih tebal ini menutupi tepi kapsul di bawahnya 
                                // sehingga menciptakan ilusi lengkungan yang menyatu sempurna.
                                width: isSelected ? 6 : 0, 
                              ),
                            ),
                            child: Icon(
                              isSelected ? iconSelected : iconUnselected,
                              color: isSelected
                                  ? const Color(0xFFFFC107) // Kuning emas
                                  : const Color(0xFF94A3B8), // Abu-abu pudar
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// HOME TAB
// ─────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _supabase = SupabaseService();
  final _location = LocationService();
  final _searchController = TextEditingController();

  List<Place> _places = [];
  List<Category> _categories = [];
  int? _selectedCategoryId;
  bool _isLoading = true;
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
    } catch (_) {}
  }

  Future<void> _loadLocation() async {
    await _location.getCurrentLocation();
  }

  Future<void> _loadPlaces({String? search}) async {
    if (mounted) setState(() { _isLoading = true; _error = null; });
    try {
      var places = await _supabase.getPlaces(
        categoryId: _selectedCategoryId,
        search: search,
      );
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService().currentUser;
    final displayName = user?.userMetadata?['display_name'] as String?;
    final email = user?.email ?? '';
    final name = displayName ?? (email.isNotEmpty ? email.split('@').first : 'Pengguna');

    return Scaffold(
      backgroundColor: _bgColor,
      body: RefreshIndicator(
        onRefresh: _init,
        color: const Color(0xFF3B82F6),
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header Gradient Card ──────────────────────
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      offset: const Offset(0, 10),
                      blurRadius: 24,
                    ),
                  ],
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: 24,
                  right: 24,
                  bottom: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, $name',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Temukan tempat di sekitar kampus',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            await SupabaseService().signOut();
                            if (mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                                (route) => false,
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Logout',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (value) => _loadPlaces(search: value),
                        onChanged: (v) {
                          if (v.isEmpty) _loadPlaces();
                          setState(() {});
                        },
                        style: TextStyle(
                          fontSize: 15,
                          color: _primaryText,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cari tempat fotocopy...',
                          hintStyle: TextStyle(
                            color: _secondaryText.withOpacity(0.6),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: const Color(0xFF3B82F6),
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear_rounded,
                                      color: _secondaryText),
                                  onPressed: () {
                                    _searchController.clear();
                                    _loadPlaces();
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.transparent,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_categories.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
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

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tempat Terdekat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _primaryText,
                      ),
                    ),
                    if (!_isLoading)
                      Text(
                        '${_places.length} tempat',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF3B82F6),
                  ),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: _ErrorView(message: _error!, onRetry: _init),
              )
            else if (_places.isEmpty)
              const SliverFillRemaining(child: _EmptyView())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 140), // Jarak bawah ditambah agar item terakhir tidak tertutup
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final place = _places[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: PlaceCard(
                          place: place,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(place: place),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _places.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapsTab extends StatefulWidget {
  const _MapsTab();

  @override
  State<_MapsTab> createState() => _MapsTabState();
}

class _MapsTabState extends State<_MapsTab> {
  final _supabase = SupabaseService();
  final _location = LocationService();

  List<Place> _places = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    if (mounted) setState(() { _isLoading = true; _error = null; });
    try {
      final places = await _supabase.getPlaces();
      final sorted = _location.sortByDistance(places);
      if (mounted) setState(() => _places = sorted);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _bgColor,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: _ErrorView(message: _error!, onRetry: _loadPlaces),
      );
    }

    if (_places.isEmpty) {
      return const Scaffold(
        backgroundColor: _bgColor,
        body: _EmptyView(),
      );
    }

    return MapScreen(places: _places);
  }
}

// ─────────────────────────────────────────────────────────
// HELPER: Cek login & redirect
// ─────────────────────────────────────────

/// Tampilkan halaman "perlu login" lalu arahkan ke LoginScreen.
void _goToLogin(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
}

/// Widget tampilan ketika fitur memerlukan login.
class _LoginRequiredView extends StatelessWidget {
  final String feature;
  const _LoginRequiredView({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD1D9E6).withOpacity(0.2),
                    offset: const Offset(6, 6),
                    blurRadius: 12,
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    offset: Offset(-6, -6),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(Icons.lock_outline_rounded, size: 48, color: Color(0xFF3B82F6)),
            ),
            const SizedBox(height: 28),
            const Text(
              'Login Diperlukan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Untuk menggunakan fitur $feature, silakan login terlebih dahulu.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.4),
                    offset: const Offset(0, 6),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _goToLogin(context),
                icon: const Icon(Icons.login_rounded, color: Colors.white, size: 20),
                label: const Text(
                  'Login Sekarang',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// FAVORITE TAB
// ─────────────────────────────────────────────────────────
class _FavoriteTab extends StatefulWidget {
  const _FavoriteTab();

  @override
  State<_FavoriteTab> createState() => _FavoriteTabState();
}

class _FavoriteTabState extends State<_FavoriteTab> {
  final _supabase = SupabaseService();
  final _favService = FavoritesService();
  final _location = LocationService();

  List<Place> _favPlaces = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final ids = await _favService.getFavoriteIds();
      if (ids.isEmpty) {
        if (mounted) setState(() { _favPlaces = []; _isLoading = false; });
        return;
      }
      final allPlaces = await _supabase.getPlaces();
      final favs = allPlaces.where((p) => ids.contains(p.id)).toList();
      for (var p in favs) {
        p.distanceMeters = _location.distanceTo(p);
      }
      if (mounted) setState(() => _favPlaces = favs);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Jika belum login, tampilkan halaman login
    final isLoggedIn = SupabaseService().currentUser != null;
    if (!isLoggedIn) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 24,
                right: 24,
                bottom: 32,
              ),
              child: const Text(
                'Tersimpan',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Expanded(child: _LoginRequiredView(feature: 'Favorit')),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      body: RefreshIndicator(
        onRefresh: _loadFavorites,
        color: const Color(0xFF3B82F6),
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                      offset: const Offset(0, 10),
                      blurRadius: 24,
                    ),
                  ],
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: 24,
                  right: 24,
                  bottom: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tersimpan',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isLoading
                          ? 'Memuat data...'
                          : _favPlaces.isEmpty
                              ? 'Belum ada tempat yang disimpan'
                              : '${_favPlaces.length} tempat favorit kamu',
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                ),
              )
            else if (_favPlaces.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bookmark_border_rounded,
                        size: 80,
                        color: Color(0xFFCBD5E1),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Belum ada favorit',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tempat yang kamu simpan akan muncul di sini',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 140), // Jarak bawah ditambah
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final place = _favPlaces[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: PlaceCard(
                          place: place,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(place: place),
                              ),
                            );
                            _loadFavorites();
                          },
                        ),
                      );
                    },
                    childCount: _favPlaces.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// PROFILE TAB (Full Neumorphic Styling)
// ─────────────────────────────────────────────────────────

class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  late String _userName;
  late String _userEmail;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = SupabaseService().currentUser;
    _userEmail = user?.email ?? '-';
    _userName = user?.userMetadata?['display_name'] ?? _userEmail.split('@').first;
  }

  void _showEditProfile() {
    showDialog(
      context: context,
      builder: (context) => _EditProfileDialog(
        currentName: _userName,
        currentEmail: _userEmail,
        onSave: (newName) async {
          try {
            setState(() => _isLoading = true);
            await SupabaseService().updateUserProfile(
              displayName: newName,
              username: newName.toLowerCase().replaceAll(' ', '_'),
            );
            _loadUserData();
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Profil berhasil diperbarui'),
                  backgroundColor: const Color(0xFF22C55E), // Fintech Green
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(24),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal memperbarui profil: $e'),
                  backgroundColor: const Color(0xFFEF4444), // Fintech Red
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(24),
                ),
              );
            }
          } finally {
            setState(() => _isLoading = false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Jika belum login, tampilkan halaman login
    final isLoggedIn = SupabaseService().currentUser != null;
    if (!isLoggedIn) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 24),
            const Expanded(child: _LoginRequiredView(feature: 'Profil')),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 40,
                left: 24,
                right: 24,
                bottom: 24,
              ),
              child: Column(
                children: [
                  // Neumorphic Avatar
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: _bgColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _shadowDark.withOpacity(0.5),
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
                    child: Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    _userName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _userEmail,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengaturan Akun',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _secondaryText,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _ProfileMenuItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Edit Profil',
                    onTap: _showEditProfile,
                  ),
                  const SizedBox(height: 16),
                  _ProfileMenuItem(
                    icon: Icons.history_rounded,
                    label: 'Riwayat Ulasan',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReviewHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _ProfileMenuItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Pusat Bantuan',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HelpScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Neumorphic Logout Button
                  GestureDetector(
                    onTap: () async {
                      await SupabaseService().signOut();
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: _bgColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _shadowDark.withOpacity(0.5),
                            offset: const Offset(6, 6),
                            blurRadius: 12,
                          ),
                          const BoxShadow(
                            color: _shadowLight,
                            offset: Offset(-6, -6),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 22),
                          SizedBox(width: 10),
                          Text(
                            'Keluar Akun',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEF4444), // Red for logout
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 140), // padding bawah untuk menghindari bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// PROFILE MENU ITEM (Neumorphic Card)
// ─────────────────────────────────────────────────────────
class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _shadowDark.withOpacity(0.4),
              offset: const Offset(6, 6),
              blurRadius: 12,
            ),
            const BoxShadow(
              color: _shadowLight,
              offset: Offset(-6, -6),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF3B82F6), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _primaryText,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: _secondaryText, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// EDIT PROFILE DIALOG (Soft UI)
// ─────────────────────────────────────────────────────────
class _EditProfileDialog extends StatefulWidget {
  final String currentName;
  final String currentEmail;
  final Function(String) onSave;

  const _EditProfileDialog({
    required this.currentName,
    required this.currentEmail,
    required this.onSave,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  InputDecoration _dialogInputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _secondaryText.withOpacity(0.6), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      elevation: 24,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_rounded, color: Color(0xFF3B82F6), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Edit Profil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _primaryText,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.close_rounded, color: _secondaryText, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            Text(
              'Email (Tetap)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryText),
            ),
            const SizedBox(height: 8),
            TextField(
              enabled: false,
              style: TextStyle(fontSize: 14, color: _secondaryText),
              decoration: _dialogInputDecoration(hint: widget.currentEmail),
            ),
            const SizedBox(height: 20),

            Text(
              'Nama Lengkap',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryText),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: TextStyle(fontSize: 15, color: _primaryText),
              decoration: _dialogInputDecoration(hint: 'Masukkan nama Anda'),
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        color: _secondaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.4),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              if (_nameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Nama tidak boleh kosong'),
                                    backgroundColor: const Color(0xFFEF4444),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                                return;
                              }
                              setState(() => _isSaving = true);
                              await widget.onSave(_nameController.text.trim());
                              if (mounted) Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'Simpan',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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

// ─────────────────────────────────────────────────────────
// HELPERS (Error & Empty States)
// ─────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 40, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 24),
            Text(
              'Gagal memuat data',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _primaryText),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: _secondaryText, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _shadowDark.withOpacity(0.5),
                  offset: const Offset(6, 6),
                  blurRadius: 12,
                ),
                const BoxShadow(
                  color: _shadowLight,
                  offset: Offset(-6, -6),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.location_off_rounded, size: 48, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada tempat',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _primaryText),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah kata kunci pencarianmu',
            style: TextStyle(fontSize: 14, color: _secondaryText),
          ),
        ],
      ),
    );
  }
}