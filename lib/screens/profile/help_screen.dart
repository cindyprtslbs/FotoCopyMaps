import 'package:flutter/material.dart';

// Tema Warna Neumorphism & Fintech
const Color _bgColor = Color(0xFFF0F4F8);
const Color _shadowDark = Color(0xFFD1D9E6);
const Color _shadowLight = Colors.white;
const Color _primaryText = Color(0xFF1E293B);
const Color _secondaryText = Color(0xFF64748B);
const Color _primary = Color(0xFF3B82F6);
const Color _primaryDark = Color(0xFF1D4ED8);

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Premium App Bar ──
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
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
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_primary, _primaryDark],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -40,
                      top: -40,
                      child: Icon(Icons.help_outline_rounded, size: 200, color: Colors.white.withOpacity(0.1)),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 24, bottom: 32, right: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pusat Bantuan',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Temukan jawaban atas kendala yang Anda alami.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── FAQ Content ──
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _FaqCategory(
                  title: 'Lokasi dan GPS',
                  icon: Icons.location_on_rounded,
                  items: [
                    FaqItem(
                      question: 'Mengapa lokasi saya tidak muncul?',
                      answer: 'Pastikan fitur GPS pada perangkat Anda telah aktif dan Anda telah memberikan izin akses lokasi pada aplikasi ini di pengaturan.',
                    ),
                    FaqItem(
                      question: 'Mengapa jarak tempat tidak muncul?',
                      answer: 'Jarak hanya dapat dihitung jika lokasi presisi perangkat Anda berhasil diperoleh oleh sistem kami.',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const _FaqCategory(
                  title: 'Data Tempat',
                  icon: Icons.store_rounded,
                  items: [
                    FaqItem(
                      question: 'Bagaimana cara mencari tempat fotokopi?',
                      answer: 'Anda dapat menggunakan fitur pencarian di beranda atau dengan mengetuk kategori "Fotocopy" pada filter di atas daftar.',
                    ),
                    FaqItem(
                      question: 'Apakah informasi tempat dapat dilihat di peta?',
                      answer: 'Tentu. Setiap tempat dapat dilihat secara langsung di peta dengan menekan tombol "Buka Rute" atau ikon peta di halaman detail.',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const _FaqCategory(
                  title: 'Akun & Profil',
                  icon: Icons.person_rounded,
                  items: [
                    FaqItem(
                      question: 'Bagaimana cara mengubah profil?',
                      answer: 'Akses menu "Profile" di navigasi bawah, kemudian pilih "Edit Profil" untuk memperbarui nama dan username Anda.',
                    ),
                    FaqItem(
                      question: 'Bagaimana cara menyimpan tempat favorit?',
                      answer: 'Ketuk ikon berbentuk hati (❤️) pada halaman detail atau di peta untuk menyimpannya ke dalam koleksi Favorit Anda.',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const _FaqCategory(
                  title: 'Sistem Review',
                  icon: Icons.star_rounded,
                  items: [
                    FaqItem(
                      question: 'Bagaimana cara memberikan ulasan?',
                      answer: 'Buka halaman detail dari tempat yang ingin Anda ulas, gulir ke bawah, pilih rating bintang, isi komentar, lalu publikasikan.',
                    ),
                    FaqItem(
                      question: 'Apakah saya bisa mengubah ulasan?',
                      answer: 'Saat ini ulasan tidak dapat diubah (edit) secara langsung. Namun, Anda dapat menghapusnya dan membuat ulasan baru.',
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class FaqItem {
  final String question;
  final String answer;

  const FaqItem({
    required this.question,
    required this.answer,
  });
}

class _FaqCategory extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<FaqItem> items;

  const _FaqCategory({
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent, // Menghilangkan garis divider bawaan ExpansionTile
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            iconColor: _primary,
            collapsedIconColor: _secondaryText,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _primary, size: 20),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: _primaryText,
              ),
            ),
            children: items.map((faq) => _NeumorphicNestedFaq(faq: faq)).toList(),
          ),
        ),
      ),
    );
  }
}

class _NeumorphicNestedFaq extends StatelessWidget {
  final FaqItem faq;

  const _NeumorphicNestedFaq({required this.faq});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        iconColor: _primary,
        collapsedIconColor: _secondaryText,
        title: Text(
          faq.question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _primaryText,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                faq.answer,
                style: const TextStyle(
                  color: _secondaryText,
                  height: 1.6,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}