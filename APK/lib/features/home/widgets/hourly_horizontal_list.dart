import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/weather_utils.dart';
import '../../../models/hourly_forecast.dart';

class HourlyHorizontalList extends StatelessWidget {
  final List<HourlyForecast> hourlyList;
  final bool isFahrenheit;

  const HourlyHorizontalList({
    super.key,
    required this.hourlyList,
    required this.isFahrenheit,
  });

  @override
  Widget build(BuildContext context) {
    if (hourlyList.isEmpty) return const SizedBox.shrink();

    // Take up to 24 hours
    final items = hourlyList.take(24).toList();
    const double colWidth = 76.0;
    final double totalWidth = items.length * colWidth;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: totalWidth,
            height: 270,
            child: Stack(
              children: [
                // Active column translucent highlight (first item "Now")
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: colWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(18),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                      ),
                    ),
                  ),
                ),

                // Temperature Wave Curve Canvas (GPU raster cached)
                Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  height: 140,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: Size(totalWidth, 140),
                      painter: _HourlyCurvePainter(
                        hourly: items,
                        colWidth: colWidth,
                        isFahrenheit: isFahrenheit,
                      ),
                    ),
                  ),
                ),

                // Aligned Meteorological Rows under the curve
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Row(
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      final isNow = index == 0;

                      // Direct wind speed in km/h
                      final windSpeed = item.windSpeed.round();

                      // UV condition / label
                      final uvCategory = isNow ? 'Weak' : (index % 3 == 0 ? 'Mod' : 'Weak');

                      return SizedBox(
                        width: colWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 1. Weather Icon
                            Icon(
                              AppAssets.getConditionIcon(item.conditionEmoji),
                              size: 20,
                              color: Colors.white,
                            ),

                            const SizedBox(height: 12),

                            // 2. Wind Fan Icon + Direct Speed ("14 km/h")
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.air_rounded,
                                  size: 11,
                                  color: Colors.white.withAlpha(200),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$windSpeed km/h',
                              style: TextStyle(
                                color: Colors.white.withAlpha(220),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // 3. Sun protection / Hat Icon + Label ("Weak")
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.beach_access_rounded,
                                  size: 11,
                                  color: AppColors.uvPurple,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              uvCategory,
                              style: const TextStyle(
                                color: AppColors.uvPurple,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // 4. Time label ("Now", "11:00", "13:00", etc.)
                            Text(
                              isNow ? 'Now' : item.hourLabel,
                              style: TextStyle(
                                color: isNow ? Colors.white : Colors.white.withAlpha(180),
                                fontSize: 12,
                                fontWeight: isNow ? FontWeight.w800 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HourlyCurvePainter extends CustomPainter {
  final List<HourlyForecast> hourly;
  final double colWidth;
  final bool isFahrenheit;

  _HourlyCurvePainter({
    required this.hourly,
    required this.colWidth,
    required this.isFahrenheit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hourly.isEmpty) return;

    final temps = hourly
        .map((e) => isFahrenheit
            ? WeatherUtils.cToF(e.temperature.toDouble())
            : e.temperature.toDouble())
        .toList();

    double minT = temps.reduce(min);
    double maxT = temps.reduce(max);
    if (minT == maxT) {
      maxT += 1.0;
      minT -= 1.0;
    }

    const double topMargin = 40.0;
    const double bottomMargin = 20.0;
    final double plotHeight = size.height - topMargin - bottomMargin;

    // Calculate (x, y) coordinates for each point
    final List<Offset> points = [];
    for (int i = 0; i < hourly.length; i++) {
      final x = (i * colWidth) + (colWidth / 2);
      final normalized = (temps[i] - minT) / (maxT - minT);
      final y = size.height - bottomMargin - (normalized * plotHeight);
      points.add(Offset(x, y));
    }

    // Find peak index
    int peakIndex = 0;
    double maxVal = temps[0];
    for (int i = 1; i < temps.length; i++) {
      if (temps[i] > maxVal) {
        maxVal = temps[i];
        peakIndex = i;
      }
    }

    // 1. Draw dashed horizontal guideline across from Now point
    final dashedPaint = Paint()
      ..color = Colors.white.withAlpha(55)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final nowY = points[0].dy;
    double dashX = points[0].dx;
    while (dashX < size.width) {
      canvas.drawLine(
        Offset(dashX, nowY),
        Offset(min(dashX + 4, size.width), nowY),
        dashedPaint,
      );
      dashX += 8;
    }

    // 2. Draw continuous cubic Bézier curve
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    final curvePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [
          AppColors.curveActive,
          AppColors.curveLine,
          AppColors.curvePeak,
          AppColors.curveLine,
        ],
        stops: [0.0, 0.35, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, curvePaint);

    // 3. Draw Round Temperature Badges Following the Curve for Every Hour in the Day
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final tempVal = temps[i].round();
      final isNow = i == 0;
      final isPeak = i == peakIndex;

      final double radius = isNow ? 13.5 : 12.0;

      // Outer luminous glow for Now or Peak point (GPU RadialGradient)
      if (isNow || isPeak) {
        final glowColor = isNow ? AppColors.curveActive : AppColors.curvePeak;
        final glowRect = Rect.fromCircle(center: pt, radius: radius + 4.0);
        final glowPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              glowColor.withAlpha(90),
              glowColor.withAlpha(0),
            ],
            stops: const [0.0, 1.0],
          ).createShader(glowRect);
        canvas.drawCircle(pt, radius + 4.0, glowPaint);
      }

      // Solid white circular badge to cleanly mask the curve underneath
      final bgPaint = Paint()..color = Colors.white;
      canvas.drawCircle(pt, radius, bgPaint);

      // Colored ring border following curve theme (Green for normal, Accent for Now, Amber for Peak)
      final ringColor = isNow
          ? AppColors.curveActive
          : (isPeak ? AppColors.curvePeak : AppColors.curveLine);
      final ringPaint = Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isNow ? 2.4 : 1.8;
      canvas.drawCircle(pt, radius, ringPaint);

      // Temperature number centered inside the circle badge
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$tempVal',
          style: TextStyle(
            color: const Color(0xFF1E293B),
            fontSize: isNow ? 11.5 : 10.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(pt.dx - (textPainter.width / 2), pt.dy - (textPainter.height / 2)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HourlyCurvePainter oldDelegate) {
    return oldDelegate.hourly != hourly ||
        oldDelegate.colWidth != colWidth ||
        oldDelegate.isFahrenheit != isFahrenheit;
  }
}
