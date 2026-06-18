import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = AppTheme.getSurfaceLight(context);
    final shimmerColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.03);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(
          duration: 1500.ms,
          color: shimmerColor,
        );
  }
}
