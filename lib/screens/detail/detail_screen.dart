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
import '../auth/login_screen.dart';

// Tema Warna Neumorphism & Fintech
const Color _bgColor = Color(0xFFF0F4F8);
const Color _shadowDark = Color(0xFFD1D9E6);
const Color _shadowLight = Colors.white;
const Color _primaryText = Color(0xFF1E293B);
const Color _secondaryText = Color(0xFF64748B);
const Color _primary = Color(0xFF3B6FE8);
const Color _primaryDark = Color(0xFF1CB8C8);
const Color _dividerColor = Color(0xFFE2E8F0);

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
  bool _openHoursExpanded = false;

  double _newRating = 4.0;
  final _commentController = TextEditingController();
  bool _submitting = false;

  String get _userName {
    final user = _supabase.currentUser;
    final displayName = user?.userMetadata?['display_name'] as String?;
    if (displayName != null && displayName.isNotEmpty) return displayName;
    final email = user?.email ?? '';
    return email.isNotEmpty ? email.split('@').first : 'Pengguna';
  }

  String get _userInitial {
    return _userName.isNotEmpty ? _userName[0].toUpperCase() : '?';
  }

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
    if (_supabase.currentUser == null) {
      _showLoginRequiredDialog('favorit');
      return;
    }
    setState(() => _favoriteScale = 1.3);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _favoriteScale = 1.0);
    });
    final newStatus = await _favService.toggleFavorite(widget.place.id);
    if (mounted) {
      setState(() => _isFavorite = newStatus);
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

  void _showLoginRequiredDialog(String feature) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 24,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded, color: _primary, size: 32),
              ),
              const SizedBox(height: 20),
              const Text(
                'Login Diperlukan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _primaryText),
              ),
              const SizedBox(height: 12),
              Text(
                'Silakan login terlebih dahulu untuk menambahkan $feature.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: _secondaryText, height: 1.5),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Nanti',
                        style: TextStyle(color: _secondaryText, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [_primary, _primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withOpacity(0.4),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Login', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_supabase.currentUser == null) {
      _showLoginRequiredDialog('ulasan');
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await _supabase.addReview(
        placeId: widget.place.id,
        rating: _newRating,
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      );
      _commentController.clear();
      await _loadReviews();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Review berhasil dikirim! Terima kasih ulasannya'),
            backgroundColor: const Color(0xFF22C55E),
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
            backgroundColor: const Color(0xFFEF4444),
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
        title: const Text('Hapus Ulasan?', style: TextStyle(fontWeight: FontWeight.w800, color: _primaryText)),
        content: const Text('Ulasan Anda akan dihapus secara permanen.', style: TextStyle(color: _secondaryText, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: _secondaryText, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFEF2F2),
              foregroundColor: const Color(0xFFEF4444),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar dengan Hero Image ──
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: _primaryText, size: 18),
                ),
              ),
            ),
            actions: [
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
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Icon(
                        _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _isFavorite ? const Color(0xFFEF4444) : _primaryText,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MapScreen(places: [place], focusPlace: place)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: const Icon(Icons.map_rounded, color: _primaryText, size: 18),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: place.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: place.photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: const Color(0xFFE2E8F0)),
                      errorWidget: (_, __, ___) => _PlaceholderImage(name: place.name),
                    )
                  : _PlaceholderImage(name: place.name),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: Nama, Chip Kategori, Rating, Jarak ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama tempat
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _primaryText,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Chip kategori + status buka
                      Row(
                        children: [
                          if (place.categoryName != null) ...[
                            _CategoryChip(label: place.categoryName!),
                            const SizedBox(width: 8),
                          ],
                          _StatusChip(isOpen: true),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Rating + Jarak
                      Row(
                        children: [
                          if (place.rating != null) ...[
                            Row(
                              children: [
                                ...List.generate(
                                  5,
                                  (i) => Icon(
                                    i < place.rating!.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                                    size: 18,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  place.rating!.toStringAsFixed(1),
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _primaryText),
                                ),
                                if (_reviews.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${_reviews.length} ulasan)',
                                    style: const TextStyle(fontSize: 13, color: _secondaryText),
                                  ),
                                ],
                              ],
                            ),
                          ],
                          if (place.distanceMeters != null) ...[
                            const SizedBox(width: 16),
                            Row(
                              children: [
                                const Icon(Icons.near_me_rounded, size: 16, color: _primary),
                                const SizedBox(width: 4),
                                Text(
                                  place.distanceText,
                                  style: const TextStyle(fontSize: 13, color: _secondaryText, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(color: _dividerColor, thickness: 1, height: 1),

                // ── Informasi Tempat ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Text(
                    'INFORMASI TEMPAT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _secondaryText,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                // Alamat
                if (place.address != null && place.address!.isNotEmpty) ...[
                  _InfoTile(
                    icon: Icons.location_on_outlined,
                    iconColor: _primary,
                    child: Text(
                      place.address!,
                      style: const TextStyle(fontSize: 14, color: _primaryText, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ),
                  const Divider(indent: 60, endIndent: 20, color: _dividerColor, thickness: 1, height: 1),
                ],

                // Jam operasional dengan expand
                if (place.openHours != null && place.openHours!.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () => setState(() => _openHoursExpanded = !_openHoursExpanded),
                    behavior: HitTestBehavior.opaque,
                    child: _InfoTile(
                      icon: Icons.access_time_rounded,
                      iconColor: _primary,
                      trailing: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _bgColor,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(color: _shadowDark.withOpacity(0.4), offset: const Offset(3, 3), blurRadius: 6),
                            const BoxShadow(color: _shadowLight, offset: Offset(-3, -3), blurRadius: 6),
                          ],
                        ),
                        child: Icon(
                          _openHoursExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          size: 20,
                          color: _secondaryText,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.openHours!,
                            style: const TextStyle(fontSize: 14, color: _primaryText, fontWeight: FontWeight.w600),
                          ),
                          if (_openHoursExpanded) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Informasi jam operasional dapat berubah\npada hari libur nasional.',
                              style: TextStyle(fontSize: 12, color: _secondaryText, height: 1.5),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Divider(indent: 60, endIndent: 20, color: _dividerColor, thickness: 1, height: 1),
                ],

                // Deskripsi / about
                if (place.description != null && place.description!.isNotEmpty) ...[
                  _InfoTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: _primary,
                    child: Text(
                      place.description!,
                      style: const TextStyle(fontSize: 14, color: _primaryText, fontWeight: FontWeight.w500, height: 1.5),
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                const Divider(color: _dividerColor, thickness: 8, height: 8),

                // ── Layanan Tersedia ──
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Text(
                    'LAYANAN TERSEDIA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _secondaryText,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _buildServiceChips(place),
                  ),
                ),

                const Divider(color: _dividerColor, thickness: 8, height: 8),

                // ── Ulasan ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'ULASAN PENGGUNA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _secondaryText,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (!_loadingReviews)
                        Text(
                          _reviews.isEmpty ? 'Belum ada ulasan' : '${_reviews.length} ulasan',
                          style: const TextStyle(fontSize: 12, color: _secondaryText, fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ),

                // Form Ulasan
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _NeumorphicCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [_primary, _primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                              ),
                              child: Center(
                                child: Text(_userInitial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_userName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _primaryText)),
                                  const SizedBox(height: 2),
                                  const Text('Tulis ulasan Anda', style: TextStyle(color: _secondaryText, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RatingBar.builder(
                              initialRating: _newRating,
                              minRating: 1,
                              direction: Axis.horizontal,
                              allowHalfRating: false,
                              itemCount: 5,
                              itemPadding: const EdgeInsets.only(right: 4),
                              itemSize: 34,
                              itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
                              onRatingUpdate: (rating) => setState(() => _newRating = rating),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _ratingLabel,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _commentController,
                          maxLines: 3,
                          style: const TextStyle(fontSize: 14, color: _primaryText),
                          decoration: InputDecoration(
                            hintText: 'Bagikan pengalaman Anda di sini...',
                            hintStyle: TextStyle(color: _secondaryText.withOpacity(0.6), fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: _dividerColor, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: _primary, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [_primary, _primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: _primary.withOpacity(0.35), offset: const Offset(0, 4), blurRadius: 12)],
                          ),
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submitReview,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _submitting
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                : const Text('Publikasikan Ulasan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // List Ulasan
                if (_loadingReviews)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: _primary)))
                else if (_reviews.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _NeumorphicCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                                child: Icon(Icons.rate_review_outlined, size: 36, color: _secondaryText),
                              ),
                              const SizedBox(height: 12),
                              const Text('Belum ada ulasan', style: TextStyle(color: _primaryText, fontSize: 15, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              const Text('Jadilah yang pertama mengulas!', style: TextStyle(color: _secondaryText, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _reviews.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final r = _reviews[index];
                        return _ReviewCard(review: r, onDelete: () => _deleteReview(r));
                      },
                    ),
                  ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),

      // ── Bottom Bar: Tombol Mulai Rute ──
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4)),
          ],
        ),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_primary, _primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: _primary.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: ElevatedButton.icon(
            onPressed: _openRoute,
            icon: const Icon(Icons.navigation_rounded, size: 20, color: Colors.white),
            label: const Text('Mulai Rute', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.2, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildServiceChips(Place place) {
    // Buat chips layanan dari deskripsi atau kategori
    final services = <Map<String, dynamic>>[];

    if (place.categoryName?.toLowerCase().contains('fotocopy') == true ||
        place.categoryName?.toLowerCase().contains('percetakan') == true) {
      services.addAll([
        {'icon': Icons.content_copy_rounded, 'label': 'Fotocopy'},
        {'icon': Icons.print_rounded, 'label': 'Print Dokumen'},
        {'icon': Icons.layers_rounded, 'label': 'Laminating'},
        {'icon': Icons.menu_book_rounded, 'label': 'Jilid Buku'},
        {'icon': Icons.scanner_rounded, 'label': 'Scan'},
        {'icon': Icons.badge_rounded, 'label': 'Foto KTP/Pas Foto'},
      ]);
    } else {
      // Tampilkan chip generik berdasarkan deskripsi
      if (place.description != null) {
        services.add({'icon': Icons.storefront_rounded, 'label': place.categoryName ?? 'Layanan'});
      }
    }

    if (services.isEmpty) return [];

    return services.map((s) => _ServiceChip(icon: s['icon'] as IconData, label: s['label'] as String)).toList();
  }
}

// ─────────────────────────────────────────────────────────
// COMPONENT WIDGETS
// ─────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primary.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _primary),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isOpen;
  const _StatusChip({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isOpen ? const Color(0xFF22C55E).withOpacity(0.3) : const Color(0xFFEF4444).withOpacity(0.3)),
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ServiceChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _dividerColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _primary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryText)),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Widget child;
  final Widget? trailing;
  const _InfoTile({required this.icon, required this.iconColor, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 16),
          Expanded(child: child),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _NeumorphicCard extends StatelessWidget {
  final Widget child;
  const _NeumorphicCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _shadowDark.withOpacity(0.5), offset: const Offset(6, 6), blurRadius: 14),
          const BoxShadow(color: _shadowLight, offset: Offset(-6, -6), blurRadius: 14),
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
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_primary, _primaryDark]),
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
    final initial = reviewName.isNotEmpty ? reviewName[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: isOwn
                      ? const LinearGradient(colors: [_primary, _primaryDark])
                      : const LinearGradient(colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: isOwn ? _primary.withOpacity(0.3) : Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Center(
                  child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reviewName,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _primaryText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOwn) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFEEF4FF), borderRadius: BorderRadius.circular(8)),
                            child: const Text('Anda', style: TextStyle(fontSize: 10, color: _primary, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 14,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                        if (review.createdAt != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(review.createdAt!),
                            style: const TextStyle(fontSize: 11, color: _secondaryText),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isOwn && onDelete != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                  ),
                ),
              ],
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: TextStyle(fontSize: 13, color: _primaryText.withOpacity(0.8), height: 1.5, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}