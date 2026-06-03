// lib/utils/constants.dart

class AppConstants {
  // ──────────────────────────────────────────────
  // Ganti dengan URL dan ANON KEY dari Supabase kamu
  // Cek di: Supabase Dashboard → Project Settings → API
  // ──────────────────────────────────────────────
  static const String supabaseUrl = 'https://vhazsmmlxzlqwdzsivwt.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZoYXpzbW1seHpscXdkenNpdnd0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAzMTkyMTQsImV4cCI6MjA5NTg5NTIxNH0.W6fx9n_eOamnaP6pLjy_nNNelwpAFTO0ttY4zMP066E';

  // App info
  static const String appName = 'FotoCopy Finder';
  static const String appVersion = '1.0.0';

  // Default center map (ganti dengan koordinat kampus kamu)
  static const double defaultLat = -7.2726067;   
  static const double defaultLng = 112.7583743;
  static const double defaultZoom = 15.0;

  // Radius pencarian dalam meter
  static const double searchRadiusMeters = 1000;

  // Kategori warna (opsional, untuk marker)
  static const Map<String, int> categoryColors = {
    'kantin': 0xFFFF6B35,
    'cafe': 0xFF8B5CF6,
    'fotokopi': 0xFF10B981,
    'atm': 0xFF3B82F6,
    'parkir': 0xFF6B7280,
    'kos': 0xFFF59E0B,
    'default': 0xFF1D4ED8,
  };
}
