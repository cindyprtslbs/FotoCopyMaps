import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';
import '../widgets/loading_indicator.dart';
import 'home_screen.dart';

/// Layar pertama yang dibuka saat aplikasi launch.
/// Tugasnya: request GPS permission → navigasi ke HomeScreen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  String _statusText = 'Memuat aplikasi…';
  bool _showRetry = false;
  bool _showSkip = false;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.elasticOut,
    ));

    _animCtrl.forward();

    // Mulai cek GPS segera (paralel dengan animasi)
    _checkGps();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── GPS Permission Flow ───────────────────────────
  Future<void> _checkGps() async {
    if (!mounted) return;
    setState(() {
      _statusText = 'Meminta izin lokasi…';
      _showRetry = false;
      _showSkip = false;
    });

    final result =
        await LocationService.getCurrentLocation();

    switch (result) {
      case LocationSuccess():
        // GPS berhasil → lanjut ke Home
        setState(() => _statusText = 'Lokasi ditemukan ✓');
        await Future.delayed(const Duration(milliseconds: 300));
        _goHome(result.position);

      case LocationServiceDisabled():
        setState(() {
          _statusText =
              'GPS tidak aktif.\nAktifkan lokasi di pengaturan HP kamu.';
          _showRetry = true;
          _showSkip = true;
        });

      case LocationDenied(:final message):
        setState(() {
          _statusText = message;
          _showRetry = true;
          _showSkip = true;
        });
    }
  }

  void _goHome(Position? position) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(userPosition: position)),
    );
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();
    _checkGps();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1829),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Background Decorations ─────────────
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                  decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4A90D9)
                      .withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 280,
                height: 280,
                  decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4A90D9)
                      .withValues(alpha: 0.06),
                ),
              ),
            ),

            // ── Main Content ───────────────────────
            Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                        horizontal: 40),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      ScaleTransition(
                        scale: _scaleAnim,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient:
                                const LinearGradient(
                              colors: [
                                Color(0xFF4A90D9),
                                Color(0xFF1A5FA8),
                              ],
                              begin:
                                  Alignment.topLeft,
                              end: Alignment
                                  .bottomRight,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                                    28),
                            boxShadow: [
                                BoxShadow(
                                color: const Color(
                                    0xFF4A90D9)
                                  .withValues(alpha: 0.4),
                                blurRadius: 30,
                                offset:
                                  const Offset(0, 10),
                                ),
                            ],
                          ),
                          child: const Icon(
                            Icons.explore_rounded,
                            color: Colors.white,
                            size: 52,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // App name
                      const Text(
                        'FotoCopyFinder',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Direktori Tempat Sekitar Kampus',
                        style: TextStyle(
                          color: Color(0xFF7ABCF0),
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 56),

                      // Status / loading
                      if (!_showRetry)
                        Column(
                          children: [
                            AppLoadingIndicator(size: 28, strokeWidth: 2.5, color: Color(0xFF4A90D9)),
                            const SizedBox(height: 16),
                            Text(
                              _statusText,
                              style: const TextStyle(
                                color:
                                    Color(0xFFADB5C8),
                                fontSize: 14,
                                height: 1.5,
                              ),
                              textAlign:
                                  TextAlign.center,
                            ),
                          ],
                        ),

                      if (_showRetry) ...[
                        const Icon(
                          Icons.location_off_rounded,
                          color: Color(0xFFFF6B6B),
                          size: 40,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _statusText,
                          style: const TextStyle(
                            color: Color(0xFFADB5C8),
                            fontSize: 14,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),

                        // Retry button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _openLocationSettings,
                            style: ElevatedButton
                                .styleFrom(
                              backgroundColor:
                                  const Color(
                                      0xFF4A90D9),
                              foregroundColor:
                                  Colors.white,
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                      vertical: 14),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(14),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(
                              Icons
                                  .settings_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'Buka Pengaturan Lokasi',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Skip (lanjut tanpa GPS)
                        if (_showSkip)
                          TextButton(
                            onPressed: () =>
                                _goHome(null),
                            child: const Text(
                              'Lanjutkan tanpa GPS',
                              style: TextStyle(
                                color:
                                    Color(0xFF7ABCF0),
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}