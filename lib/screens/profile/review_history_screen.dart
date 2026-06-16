import 'package:flutter/material.dart';
// import '../../models/place_model.dart';
// import '../../models/review_model.dart';
import '../../services/supabase_service.dart';
import '../detail/detail_screen.dart';

const _kPrimary = Color(0xFF3B6FE8);
const _kGradientEnd = Color(0xFF1CB8C8);
const _kBackground = Color(0xFFF5F7FF);
const _kDark = Color(0xFF1A1A2E);

class ReviewHistoryScreen extends StatefulWidget {
  const ReviewHistoryScreen({super.key});

  @override
  State<ReviewHistoryScreen> createState() => _ReviewHistoryScreenState();
}

class _ReviewHistoryScreenState extends State<ReviewHistoryScreen> {
  final _supabase = SupabaseService();

  bool _loading = true;

  List<ReviewHistoryItem> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      setState(() => _loading = true);

      final reviews = await _supabase.getMyReviews();

      if (mounted) {
        setState(() {
          _reviews = reviews;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteReview(ReviewHistoryItem review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Ulasan'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus ulasan ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.deleteReview(review.review.id);

      await _loadReviews();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ulasan berhasil dihapus'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus ulasan: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: RefreshIndicator(
        onRefresh: _loadReviews,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _kPrimary,
                      _kGradientEnd,
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 20,
                  right: 20,
                  bottom: 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Riwayat Ulasan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _loading
                          ? 'Memuat...'
                          : '${_reviews.length} ulasan telah dibuat',
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),

            if (_loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: _kPrimary,
                  ),
                ),
              )
            else if (_reviews.isEmpty)
              const SliverFillRemaining(
                child: _EmptyReviewView(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _reviews[index];

                      return _ReviewHistoryCard(
                        item: item,
                        onDelete: () => _deleteReview(item),
                      );
                    },
                    childCount: _reviews.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReviewHistoryCard extends StatelessWidget {
  final ReviewHistoryItem item;
  final VoidCallback onDelete;

  const _ReviewHistoryCard({
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final review = item.review;
    final place = item.place;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withOpacity(.04),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            place.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _kDark,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < review.rating.round()
                    ? Icons.star
                    : Icons.star_border,
                size: 18,
                color: Colors.amber,
              ),
            ),
          ),

          const SizedBox(height: 10),

          if (review.comment != null)
            Text(
              review.comment!,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),

          const SizedBox(height: 12),

          Text(
            _formatDate(review.createdAt!),
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [

              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.location_on_outlined),
                  label: const Text('Lihat Tempat'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(
                          place: place,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Hapus'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                  ),
                  onPressed: onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','Mei','Jun',
      'Jul','Agu','Sep','Okt','Nov','Des'
    ];

    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}


class _EmptyReviewView extends StatelessWidget {
  const _EmptyReviewView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Ulasan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ulasan yang kamu buat akan muncul di sini',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}