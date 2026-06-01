import 'package:flutter/material.dart';

class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const AppLoadingIndicator({
    this.size = 28,
    this.color,
    this.strokeWidth = 2.5,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final col = color ?? const Color(0xFF4A90D9);
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: CircularProgressIndicator(
          color: col,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}
