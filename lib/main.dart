// lib/main.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/constants.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'services/supabase_service.dart';
// import 'screens/map/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase — wajib sebelum runApp
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(const FotoCopyFinder());
}

class FotoCopyFinder extends StatelessWidget {
  const FotoCopyFinder({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // ── Theme ──────────────────────────────────────
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D4ED8), // biru kampus
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),

      // ── Routing ────────────────────────────────────
      home: const AppRouter(),
    );
  }
}

/// Cek apakah user sudah login, lalu arahkan ke screen yang sesuai.
/// Jika aplikasimu tidak pakai auth, ganti langsung ke HomeScreen().
class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final service = SupabaseService();

    // Jika TIDAK pakai auth, hapus StreamBuilder ini dan kembalikan langsung:
    // return const HomeScreen();
    return StreamBuilder<AuthState>(
      stream: service.authStateChanges,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
