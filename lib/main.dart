import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar transparan
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const FotoCopyFinder());
}

class FotoCopyFinder extends StatelessWidget {
  const FotoCopyFinder({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FotoCopyFinder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90D9),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF4F7FC),
      ),
      // Entry point: SplashScreen yang handle GPS permission
      home: const SplashScreen(),
    );
  }
}