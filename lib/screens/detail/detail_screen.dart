import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/place_model.dart';
import '../../models/review_model.dart';
import '../../services/supabase_service.dart';
import '../../services/location_service.dart';
import '../map/map_screen.dart';

class DetailScreen extends StatefulWidget {
  final Place place;

  const DetailScreen({super.key, required this.place});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _supabase = SupabaseService();
  final _location = LocationService();

  List<Review> _reviews = [];
  bool _loadingReviews = true;

  // Form review baru
  double _newRating = 4.0;
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await _supabase.getReviewsByPlace(widget.place.id);
      if (mounted) setState(() => _reviews = reviews);
    } catch (_) {}
    if (mounted) setState(() => _loadingReviews = false);
  }

  Future<void> _openRoute() async {
    final pos = _location.lastPosition;
    final success = await _location.openRoute(
      destLat: widget.place.lat,
      destLng: widget.place.lng,
      originLat: pos?.latitude,
      originLng: pos?.longitude,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa membuka aplikasi peta.'),
        ),
      );
    }
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
          const SnackBar(content: Text('Review berhasil dikirim!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal kirim review: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar dengan foto ────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                place.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                ),
              ),
              background: place.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: place.photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey.shade200),
                      errorWidget: (_, __, ___) => _PlaceholderImage(name: place.name),
                    )
                  : _PlaceholderImage(name: place.name),
            ),
            actions: [
              // Buka di peta
              IconButton(
                icon: const Icon(Icons.map_outlined, color: Colors.white),
                tooltip: 'Lihat di peta',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapScreen(
                        places: [place],
                        focusPlace: place,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Badges ──────────────────────
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (place.categoryName != null)
                        _Badge(
                          label: place.categoryName!,
                          icon: Icons.category_outlined,
                          color: scheme.primaryContainer,
                          textColor: scheme.onPrimaryContainer,
                        ),
                      if (place.distanceMeters != null)
                        _Badge(
                          label: place.distanceText,
                          icon: Icons.near_me_outlined,
                          color: scheme.secondaryContainer,
                          textColor: scheme.onSecondaryContainer,
                        ),
                      if (place.rating != null)
                        _Badge(
                          label: place.rating!.toStringAsFixed(1),
                          icon: Icons.star_rounded,
                          color: Colors.amber.shade100,
                          textColor: Colors.amber.shade800,
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Info ─────────────────────────
                  if (place.address != null) ...[
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: place.address!,
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (place.openHours != null) ...[
                    _InfoRow(
                      icon: Icons.access_time_rounded,
                      label: place.openHours!,
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (place.priceRange != null) ...[
                    _InfoRow(
                      icon: Icons.payments_outlined,
                      label: place.priceRange!,
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (place.description != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      place.description!,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Tombol Rute ──────────────────
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _openRoute,
                      icon: const Icon(Icons.directions_rounded),
                      label: const Text(
                        'Buka Rute',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // ── Form review ──────────────────
                  const Text(
                    'Beri Ulasan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RatingBar.builder(
                    initialRating: _newRating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    itemCount: 5,
                    itemSize: 32,
                    itemBuilder: (_, __) =>
                        const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (r) => setState(() => _newRating = r),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Tulis komentar (opsional)…',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submitReview,
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Kirim Ulasan'),
                    ),
                  ),

                  const SizedBox(height: 28),
                  const Text(
                    'Ulasan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Daftar review ─────────────────
                  if (_loadingReviews)
                    const Center(child: CircularProgressIndicator())
                  else if (_reviews.isEmpty)
                    const Text(
                      'Belum ada ulasan. Jadilah yang pertama!',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ..._reviews.map((r) => _ReviewTile(review: r)),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  final String name;
  const _PlaceholderImage({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  const _Badge({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Spacer(),
                  ...List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating.round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 16,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
              if (review.comment != null && review.comment!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  review.comment!,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
              if (review.createdAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  _formatDate(review.createdAt!),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
