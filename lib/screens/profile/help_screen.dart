import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('Bantuan'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3B6FE8),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _FaqCategory(
            title: 'Lokasi dan GPS',
            items: [
              FaqItem(
                question: 'Mengapa lokasi saya tidak muncul?',
                answer:
                    'Pastikan GPS perangkat aktif dan aplikasi memiliki izin lokasi.',
              ),
              FaqItem(
                question: 'Mengapa jarak tempat tidak muncul?',
                answer:
                    'Jarak hanya dapat dihitung jika lokasi pengguna berhasil diperoleh.',
              ),
            ],
          ),

          SizedBox(height: 12),

          _FaqCategory(
            title: 'Data Tempat',
            items: [
              FaqItem(
                question: 'Bagaimana cara mencari tempat fotokopi?',
                answer:
                    'Gunakan fitur pencarian atau pilih kategori Fotocopy pada halaman utama.',
              ),
              FaqItem(
                question:
                    'Apakah informasi tempat fotokopi dapat dilihat di peta?',
                answer:
                    'Tempat dapat dilihat di peta dengan menekan tombol "Buka Rute" atau "Lihat Rute" pada halaman detail.',
              ),
            ],
          ),

          SizedBox(height: 12),

          _FaqCategory(
            title: 'Akun',
            items: [
              FaqItem(
                question: 'Bagaimana cara mengubah profil?',
                answer:
                    'Buka menu Profil kemudian pilih Edit Profil.',
              ),
              FaqItem(
                question: 'Bagaimana cara menyimpan tempat favorit?',
                answer:
                    'Tekan ikon hati pada halaman detail tempat untuk menyimpannya ke favorit.',
              ),
            ],
          ),

          SizedBox(height: 12),

          _FaqCategory(
            title: 'Review',
            items: [
              FaqItem(
                question: 'Bagaimana cara memberikan review?',
                answer:
                    'Buka detail tempat kemudian tambahkan review dan rating.',
              ),
              FaqItem(
                question: 'Apakah saya bisa mengubah review?',
                answer:
                    'Tidak, review tidak dapat diedit tetapi dapat dihapus.',
              ),
            ],
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
  final List<FaqItem> items;

  const _FaqCategory({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        children: items
            .map(
              (faq) => ExpansionTile(
                title: Text(
                  faq.question,
                  style: const TextStyle(fontSize: 14),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        faq.answer,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}