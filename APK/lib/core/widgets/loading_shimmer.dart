import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const LoadingShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 14.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9));
  }
}

class WeatherSkeletonView extends StatelessWidget {
  const WeatherSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              LoadingShimmer(width: 160, height: 28),
              LoadingShimmer(width: 40, height: 40, borderRadius: 20),
            ],
          ),
          const SizedBox(height: 20),
          // Hero Card Skeleton
          const LoadingShimmer(width: double.infinity, height: 220, borderRadius: 28),
          const SizedBox(height: 24),
          // Hourly Section
          const LoadingShimmer(width: 140, height: 22),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, i) => const Padding(
                padding: EdgeInsets.only(right: 12),
                child: LoadingShimmer(width: 80, height: 130, borderRadius: 20),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Compact Metrics Skeleton
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: List.generate(4, (i) => const LoadingShimmer(width: double.infinity, height: 100)),
          ),
        ],
      ),
    );
  }
}
