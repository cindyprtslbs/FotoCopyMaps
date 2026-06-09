import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/place_model.dart';
import '../../models/review_model.dart';
import '../../services/supabase_service.dart';
import '../../services/location_service.dart';
import '../../services/favorites_service.dart';
import '../map/map_screen.dart';
import '../map/route_screen.dart';

// Tema Warna Neumorphism & Fintech
const Color _bgColor = Color(0xFFF0F4F8);
const Color _shadowDark = Color(0xFFD1D9E6);
const Color _shadowLight = Colors.white;
const Color _primaryText = Color(0xFF1E293B);
const Color _secondaryText = Color(0xFF64748B);
const Color _primary = Color(0xFF3B82F6);
const Color _primaryDark = Color(0xFF1D4ED8);

class DetailScreen extends StatefulWidget {
  final Place place;
  const DetailScreen({super.key, required this.place});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> with SingleTickerProviderStateMixin {
  final _supabase = SupabaseService();
  final _location = LocationService();
  final _favService = FavoritesService();

  List<Review> _reviews = [];
  bool _loadingReviews = true;
  bool _isFavorite = false;
  double _favoriteScale = 1.0;

  double _newRating = 4.0;
  final _commentController = TextEditingController();
  bool _submitting = false;

  // Nama user dari email (bagian sebelum @)
  String get _userName {
    final user = _supabase.currentUser;
    final displayName = user?.userMetadata?['display_name'] as String?;
    if (displayName != null && displayName.isNotEmpty) return displayName;
    final email = user?.email ?? '';
    return email.isNotEmpty ? email.split('@').first : 'Pengguna';
  }

  // Inisial untuk avatar
  String get _userInitial {
    return _userName.isNotEmpty ? _userName[0].toUpperCase() : '?';
  }

  // Dapatkan label dinamis interaktif untuk rating bintang yang dipilih
  String get _ratingLabel {
    if (_newRating >= 5.0) return 'Luar Biasa!';
    if (_newRating >= 4.0) return 'Sangat Bagus!';
    if (_newRating >= 3.0) return 'Cukup Baik';
    if (_newRating >= 2.0) return 'Kurang Memuaskan';
    return 'Buruk Sekali';
  }

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    final fav = await _favService.isFavorite(widget.place.id);
    if (mounted) setState(() => _isFavorite = fav);
  }

  Future<void> _toggleFavorite() async {
    // Animasi klik memantul
    setState(() => _favoriteScale = 1.3);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _favoriteScale = 1.0);
    });

    final newStatus = await _favService.toggleFavorite(widget.place.id);
    if (mounted) {
      setState(() => _isFavorite = newStatus);
      
      // Feedback haptic visual dengan SnackBar elegan
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  newStatus ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  newStatus
                      ? '${widget.place.name} ditambahkan ke favorit'
                      : '${widget.place.name} dihapus dari favorit',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: newStatus ? _primary : const Color(0xFF475569),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(24),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await _supabase.getReviewsByPlace(widget.place.id);
      if (mounted) setState(() => _reviews = reviews);
    } catch (_) {}
    if (mounted) setState(() => _loadingReviews = false);
  }

  void _openRoute() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteScreen(destination: widget.place),
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await _supabase.addReview(
        placeId: widget.place.id,
        rating: _newRating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );
      _commentController.clear();
      await _loadReviews();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Review berhasil dikirim! Terima kasih ulasannya'),
            backgroundColor: const Color(0xFF22C55E), // Fintech Success Green
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(24),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim review: $e'),
            backgroundColor: const Color(0xFFEF4444), // Fintech Error Red
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(24),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteReview(Review review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Hapus Ulasan?',
          style: TextStyle(fontWeight: FontWeight.w800, color: _primaryText),
        ),
        content: Text(
          'Ulasan Anda akan dihapus secara permanen.',
          style: TextStyle(color: _secondaryText, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: _secondaryText, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFEF2F2),
              foregroundColor: const Color(0xFFEF4444),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Ya, Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.deleteReview(review.id);
      await _loadReviews();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ulasan berhasil dihapus.'),
            backgroundColor: const Color(0xFF475569),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(24),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus ulasan: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(24),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;

    return Scaffold(
      backgroundColor: _bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Premium App Bar dengan Image Header ──
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: _bgColor,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
            actions: [
              // ── Tombol Favorit Interaktif ──
              AnimatedScale(
                scale: _favoriteScale,
                duration: const Duration(milliseconds: 150),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: GestureDetector(
                    onTap: _toggleFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Icon(
                        _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _isFavorite ? const Color(0xFFEF4444) : Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // ── Tombol Akses Peta Langsung ──
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapScreen(places: [place], focusPlace: place),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.map_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  place.photoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: place.photoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: _shadowDark),
                          errorWidget: (_, __, ___) => _PlaceholderImage(name: place.name),
                        )
                      : _PlaceholderImage(name: place.name),
                  // Dark Multi-layer Gradient Overlay
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black45,
                          Colors.transparent,
                          Color(0xDD000000), 
                        ],
                        stops: [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (place.categoryName != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _primary.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Text(
                              place.categoryName!.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          place.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(blurRadius: 10, color: Colors.black54, offset: Offset(0, 4))
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Dynamic Premium Chips Section ──
                    Row(
                      children: [
                        if (place.rating != null) ...[
                          _StatChip(
                            icon: Icons.star_rounded,
                            label: place.rating!.toStringAsFixed(1),
                            iconColor: const Color(0xFFF59E0B),
                            bgColor: const Color(0xFFFEF3C7),
                            textColor: const Color(0xFFB45309),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (place.distanceMeters != null) ...[
                          _StatChip(
                            icon: Icons.near_me_rounded,
                            label: place.distanceText,
                            iconColor: _primary,
                            bgColor: const Color(0xFFDBEAFE),
                            textColor: _primaryDark,
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ── Deskripsi / Tentang Tempat Card (Neumorphic) ──
                    if (place.description != null && place.description!.isNotEmpty) ...[
                      const _SectionHeader(title: 'Tentang Tempat'),
                      const SizedBox(height: 16),
                      _NeumorphicCard(
                        child: Text(
                          place.description!,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: _primaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // ── Detail Informasi Operasional Card (Neumorphic) ──
                    const _SectionHeader(title: 'Detail Informasi'),
                    const SizedBox(height: 16),
                    _NeumorphicCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (place.address != null && place.address!.isNotEmpty) ...[
                            _InfoRow(
                              icon: Icons.location_on_outlined,
                              title: 'Alamat Lokasi',
                              label: place.address!,
                            ),
                          ],
                          if (place.openHours != null && place.openHours!.isNotEmpty) ...[
                            if (place.address != null && place.address!.isNotEmpty)
                              const _HDivider(),
                            _InfoRow(
                              icon: Icons.access_time_rounded,
                              title: 'Jam Operasional',
                              label: place.openHours!,
                            ),
                          ],
                          if ((place.address == null || place.address!.isEmpty) &&
                              (place.openHours == null || place.openHours!.isEmpty))
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Text(
                                  'Informasi operasional terperinci belum tersedia.',
                                  style: TextStyle(color: _secondaryText, fontSize: 13),
                                ),
                              ),
                            )
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Premium Route Button dengan Ripple Gradient Effect ──
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primary, _primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _openRoute,
                        icon: const Icon(Icons.directions_rounded, size: 22, color: Colors.white),
                        label: const Text(
                          'Buka Rute',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.2, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── Formulir Penulisan Ulasan Interaktif (Neumorphic) ──
                    const _SectionHeader(
                      title: 'Beri Ulasan Anda',
                      subtitle: 'Bagikan pengalaman terbaikmu',
                    ),
                    const SizedBox(height: 16),

                    _NeumorphicCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_primary, _primaryDark],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _userInitial,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _userName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: _primaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Penulis Ulasan Resmi',
                                      style: TextStyle(
                                        color: _secondaryText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Sesi Interaktif Penentuan Skor Bintang
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Sentuh untuk Menilai:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryText,
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _ratingLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          RatingBar.builder(
                            initialRating: _newRating,
                            minRating: 1,
                            direction: Axis.horizontal,
                            allowHalfRating: false,
                            itemCount: 5,
                            itemPadding: const EdgeInsets.only(right: 8),
                            itemSize: 40,
                            itemBuilder: (_, __) => const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFF59E0B),
                            ),
                            onRatingUpdate: (rating) {
                              setState(() => _newRating = rating);
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          TextField(
                            controller: _commentController,
                            maxLines: 3,
                            style: TextStyle(fontSize: 15, color: _primaryText),
                            decoration: InputDecoration(
                              hintText: 'Ketik ulasan atau pengalaman Anda tentang tempat ini di sini...',
                              hintStyle: TextStyle(color: _secondaryText.withOpacity(0.6), fontSize: 14),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
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
                                borderSide: const BorderSide(color: _primary, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_primary, _primaryDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _primary.withOpacity(0.4),
                                  offset: const Offset(0, 4),
                                  blurRadius: 12,
                                )
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submitReview,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Publikasikan Ulasan',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── Bagian Daftar Ulasan Komunitas Kampus ──
                    _SectionHeader(
                      title: 'Ulasan Pengguna',
                      subtitle: _reviews.isEmpty ? 'Belum ada ulasan' : '${_reviews.length} ulasan kontributor',
                    ),
                    const SizedBox(height: 16),

                    if (_loadingReviews)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(color: _primary),
                        ),
                      )
                    else if (_reviews.isEmpty)
                      _NeumorphicCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.rate_review_outlined, size: 40, color: _secondaryText),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum ada ulasan',
                                  style: TextStyle(color: _primaryText, fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Jadilah orang pertama yang mengulas tempat ini!',
                                  style: TextStyle(color: _secondaryText, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _reviews.length,
                        itemBuilder: (context, index) {
                          final r = _reviews[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _ReviewCard(
                              review: r,
                              onDelete: () => _deleteReview(r),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 48),
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

// ─────────────────────────────────────────────────────────
// REUSABLE NEUMORPHIC DECORATIVE COMPONENT WIDGETS
// ─────────────────────────────────────────────────────────

class _NeumorphicCard extends StatelessWidget {
  final Widget child;
  const _NeumorphicCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(24),
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
      child: child,
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  final String name;
  const _PlaceholderImage({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, _primaryDark],
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 84, fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor, bgColor, textColor;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.4),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String label;
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE0E7FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 22, color: _primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _secondaryText,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: _primaryText,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HDivider extends StatelessWidget {
  const _HDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Divider(color: _shadowDark.withOpacity(0.5), height: 1, thickness: 1),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _primaryText, letterSpacing: -0.2),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: TextStyle(fontSize: 12, color: _secondaryText, fontWeight: FontWeight.w600),
          ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  final VoidCallback? onDelete;
  const _ReviewCard({required this.review, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final reviewName = (review.userName != null && review.userName!.isNotEmpty)
        ? review.userName!
        : (review.userEmail != null && review.userEmail!.isNotEmpty
            ? review.userEmail!.split('@').first
            : 'Pengguna');

    final currentUserId = SupabaseService().currentUser?.id;
    final isOwn = review.userId != null && review.userId == currentUserId;
    final displayName = reviewName;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Premium Profile Avatar Wrapper
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: isOwn
                      ? const LinearGradient(colors: [_primary, _primaryDark])
                      : const LinearGradient(colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: isOwn ? _primary.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _primaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOwn) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E7FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Anda',
                              style: TextStyle(
                                fontSize: 10,
                                color: _primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (review.createdAt != null)
                      Text(
                        _formatDate(review.createdAt!),
                        style: TextStyle(fontSize: 12, color: _secondaryText, fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Compact Rating Indicator Stars
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 16,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ),
              if (isOwn && onDelete != null) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                review.comment!,
                style: TextStyle(
                  fontSize: 14,
                  color: _primaryText.withOpacity(0.8),
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}