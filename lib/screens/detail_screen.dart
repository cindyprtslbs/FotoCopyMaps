import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/place_model.dart';
import '../models/review_model.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../widgets/loading_indicator.dart';
import 'map_screen.dart';

class DetailScreen extends StatefulWidget {
  final Place place;
  final Position? userPosition;
  /// Tempat-tempat sekitar untuk ditampilkan sebagai marker tambahan di peta
  final List<Place>? nearbyPlaces;

  const DetailScreen({
    super.key,
    required this.place,
    this.userPosition,
    this.nearbyPlaces,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  List<Review> _reviews = [];
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    final result = await ApiService.getReviews(widget.place.id);
    if (mounted) {
      setState(() {
        _isLoadingReviews = false;
        if (result is ApiSuccess<List<Review>>) _reviews = result.data;
      });
    }
  }

  double get _avgRating {
    if (_reviews.isEmpty) return 0;
    return _reviews.map((r) => r.rating).reduce((a, b) => a + b) /
        _reviews.length;
  }

  String? get _distanceText {
    if (widget.userPosition == null) return null;
    final m = LocationService.distanceBetween(
      userLat: widget.userPosition!.latitude,
      userLng: widget.userPosition!.longitude,
      placeLat: widget.place.lat,
      placeLng: widget.place.lng,
    );
    return LocationService.formatDistance(m);
  }

  void _goToMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapScreen(
          place: widget.place,
          userPosition: widget.userPosition,
          nearbyPlaces: widget.nearbyPlaces,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2340),
      // ── App Bar transparan di atas hero ─────────────────────
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.9),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: Color(0xFF1A2340)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8),
            child: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              child: IconButton(
                icon: const Icon(Icons.map_rounded,
                    size: 18, color: Color(0xFF4A90D9)),
                onPressed: _goToMap,
                tooltip: 'Lihat di Peta',
              ),
            ),
          ),
        ],
      ),

      body: Column(children: [
        // ── Hero Banner ─────────────────────────────────────────
        Container(
          height: 230,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A5FA8), Color(0xFF4A90D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _BgPainter())),
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: const Icon(Icons.place_rounded,
                      color: Colors.white, size: 36),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.place.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                // Badge jarak + rating
                Row(mainAxisSize: MainAxisSize.min, children: [
                  if (_distanceText != null) ...[
                    _HeroBadge(
                      icon: Icons.near_me_rounded,
                      label: _distanceText!,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (!_isLoadingReviews && _reviews.isNotEmpty)
                    _HeroBadge(
                      icon: Icons.star_rounded,
                      label: _avgRating.toStringAsFixed(1),
                      iconColor: const Color(0xFFFFC107),
                    ),
                ]),
              ]),
            ),
          ]),
        ),

        // ── Content Card (bottom-sheet style) ─────────────────
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF4F7FC),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFCDD2DE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // ── Info Card ─────────────────────────────
                    _InfoCard(children: [
                      _InfoRow(
                          icon: Icons.location_on_rounded,
                          label: 'Alamat',
                          value: widget.place.address),
                      const Divider(height: 24, color: Color(0xFFF0F4FF)),
                      _InfoRow(
                          icon: Icons.info_outline_rounded,
                          label: 'Deskripsi',
                          value: widget.place.description),
                      const Divider(height: 24, color: Color(0xFFF0F4FF)),
                      _InfoRow(
                        icon: Icons.my_location_rounded,
                        label: 'Koordinat',
                        value:
                            '${widget.place.lat.toStringAsFixed(6)}, ${widget.place.lng.toStringAsFixed(6)}',
                      ),
                      if (widget.userPosition == null) ...[
                        const Divider(height: 24, color: Color(0xFFF0F4FF)),
                        Row(children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.gps_off_rounded,
                                size: 18, color: Color(0xFFFF9800)),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                              child: Text(
                            'GPS tidak aktif — jarak tidak dapat dihitung',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFFFF9800)),
                          )),
                        ]),
                      ],
                    ]),

                    const SizedBox(height: 16),

                    // ── Rating & Ulasan ───────────────────────
                    _InfoCard(children: [
                      Row(children: [
                        const Text('Rating & Ulasan',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A2340))),
                        const Spacer(),
                        if (!_isLoadingReviews && _reviews.isNotEmpty) ...[
                          Text(_avgRating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A2340))),
                          const SizedBox(width: 6),
                          _StarRow(rating: _avgRating),
                          const SizedBox(width: 6),
                          Text('(${_reviews.length})',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFADB5C8))),
                        ],
                      ]),
                      const Divider(height: 20, color: Color(0xFFF0F4FF)),
                      if (_isLoadingReviews)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: AppLoadingIndicator(size: 28, strokeWidth: 2, color: Color(0xFF4A90D9)),
                          ),
                        )
                      else if (_reviews.isEmpty)
                        const Text('Belum ada review.',
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFFADB5C8)))
                      else
                        Column(
                          children: _reviews
                              .map((r) => _ReviewTile(review: r))
                              .toList(),
                        ),
                    ]),

                    // Padding bawah agar tidak tertutup tombol
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ]),

      // ── Tombol "Buka Rute" mengambang di bawah ──────────────
      bottomNavigationBar: Container(
        color: const Color(0xFFF4F7FC),
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _goToMap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90D9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: const Color(0xFF4A90D9).withValues(alpha: 0.4),
            ),
            icon: const Icon(Icons.directions_rounded, size: 22),
            label: Text(
              _distanceText != null
                  ? 'Buka Rute  •  $_distanceText'
                  : 'Buka Rute',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _HeroBadge({
    required this.icon,
    required this.label,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: const Color(0xFF4A90D9)),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFADB5C8),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF1A2340), height: 1.4)),
        ])),
      ]);
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.2), 80, p);
    canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.85), 60, p);
    canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 1.1), 100, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _StarRow extends StatelessWidget {
  final double rating;
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return const Icon(Icons.star_rounded,
              size: 16, color: Color(0xFFFFC107));
        } else if (i < rating) {
          return const Icon(Icons.star_half_rounded,
              size: 16, color: Color(0xFFFFC107));
        }
        return const Icon(Icons.star_outline_rounded,
            size: 16, color: Color(0xFFDDE3EE));
      }),
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
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFF0F4FF),
          child: Text('U${review.userId}',
              style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF4A90D9),
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Text('User ${review.userId}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2340))),
                const Spacer(),
                _StarRow(rating: review.rating),
              ]),
              const SizedBox(height: 4),
              if (review.comment.isNotEmpty)
                Text(review.comment,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5A6478),
                        height: 1.4)),
            ])),
      ]),
    );
  }
}