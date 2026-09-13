import 'dart:math';
import 'package:flutter/material.dart';

enum ChartMetricType { temperature, rainProbability, windSpeed, humidity }

class WeatherChartPoint {
  final String label;
  final double value;
  final String displayValue;

  const WeatherChartPoint({
    required this.label,
    required this.value,
    required this.displayValue,
  });
}

class WeatherChart extends StatefulWidget {
  final List<WeatherChartPoint> points;
  final ChartMetricType metricType;
  final Color primaryColor;

  const WeatherChart({
    super.key,
    required this.points,
    required this.metricType,
    this.primaryColor = const Color(0xFF0EA5E9),
  });

  @override
  State<WeatherChart> createState() => _WeatherChartState();
}

class _WeatherChartState extends State<WeatherChart> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void didUpdateWidget(WeatherChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metricType != widget.metricType || oldWidget.points != widget.points) {
      _animController.reset();
      _animController.forward();
      _selectedIndex = null;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No forecast points available')),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        // For 7-day outlook (<= 7 points), fit nicely in available width.
        // For 24h hourly (> 7 points), enable horizontal scrolling with comfortable spacing (54px per point)
        final bool isScrollable = widget.points.length > 7;
        const double pointSpacing = 54.0;
        const double horizontalPadding = 24.0;
        final double chartWidth = isScrollable
            ? max(availableWidth, (widget.points.length - 1) * pointSpacing + (horizontalPadding * 2))
            : availableWidth;

        Widget chartCanvas = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _handleTouch(details.localPosition, chartWidth, horizontalPadding),
          onPanUpdate: isScrollable
              ? null
              : (details) => _handleTouch(details.localPosition, chartWidth, horizontalPadding),
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return RepaintBoundary(
                child: CustomPaint(
                  size: Size(chartWidth, 160),
                  painter: _WeatherChartPainter(
                    points: widget.points,
                    progress: _animController.value,
                    selectedIndex: _selectedIndex,
                    primaryColor: widget.primaryColor,
                    isBarChart: widget.metricType == ChartMetricType.rainProbability,
                    textColor: Theme.of(context).colorScheme.onSurface,
                    horizontalPadding: horizontalPadding,
                  ),
                ),
              );
            },
          ),
        );

        return Column(
          children: [
            // Selected Point Info
            if (_selectedIndex != null && _selectedIndex! < widget.points.length)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.primaryColor.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.points[_selectedIndex!].label}: ',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.points[_selectedIndex!].displayValue,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: widget.primaryColor),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 25),

            // Canvas (Scrollable if > 7 points, or fitted if <= 7 points)
            isScrollable
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: chartCanvas,
                  )
                : chartCanvas,
          ],
        );
      },
    );
  }

  void _handleTouch(Offset localPosition, double chartWidth, double horizontalPadding) {
    if (widget.points.isEmpty) return;
    final double availableW = chartWidth - (horizontalPadding * 2);
    final double step = availableW / (widget.points.length - 1).clamp(1, 999);
    final double relativeX = localPosition.dx - horizontalPadding;
    final index = (relativeX / step).round().clamp(0, widget.points.length - 1);
    setState(() => _selectedIndex = index);
  }
}

class _WeatherChartPainter extends CustomPainter {
  final List<WeatherChartPoint> points;
  final double progress;
  final int? selectedIndex;
  final Color primaryColor;
  final bool isBarChart;
  final Color textColor;
  final double horizontalPadding;

  _WeatherChartPainter({
    required this.points,
    required this.progress,
    required this.selectedIndex,
    required this.primaryColor,
    required this.isBarChart,
    required this.textColor,
    this.horizontalPadding = 24.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final double paddingBottom = 26.0;
    final double chartHeight = size.height - paddingBottom;
    final double availableWidth = size.width - (horizontalPadding * 2);

    // Find min and max
    double minVal = points.map((p) => p.value).reduce(min);
    double maxVal = points.map((p) => p.value).reduce(max);
    if (maxVal == minVal) {
      maxVal += 1;
      minVal -= 1;
    }
    final range = maxVal - minVal;

    final double stepX = availableWidth / (points.length - 1).clamp(1, 999);
    // Dynamic interval to guarantee labels never collide
    final int stepInterval = stepX < 38.0 ? (38.0 / stepX).ceil() : 1;

    if (isBarChart) {
      // Draw Bar Chart for rain probability
      final barWidth = (stepX * 0.55).clamp(8.0, 26.0);

      for (int i = 0; i < points.length; i++) {
        final norm = (points[i].value - minVal) / range;
        final h = (norm * chartHeight * progress).clamp(4.0, chartHeight);
        final x = horizontalPadding + (i * stepX);
        final y = chartHeight - h;

        final isSelected = selectedIndex == i;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x - barWidth / 2, y, barWidth, h),
          const Radius.circular(6),
        );

        canvas.drawRRect(
          rect,
          Paint()..color = isSelected ? primaryColor : primaryColor.withAlpha(140),
        );

        // Draw X-axis label
        final bool drawLabel = (i % stepInterval == 0) || (i == points.length - 1);
        if (drawLabel) {
          _drawLabel(canvas, points[i].label, x, size.height - 14);
        }
      }
    } else {
      // Draw Smooth Spline / Line Chart
      final linePath = Path();
      final fillPath = Path();

      final List<Offset> offsets = [];
      for (int i = 0; i < points.length; i++) {
        final norm = (points[i].value - minVal) / range;
        final x = horizontalPadding + (i * stepX);
        final y = chartHeight - (norm * (chartHeight - 20) * progress) - 10;
        offsets.add(Offset(x, y));
      }

      linePath.moveTo(offsets[0].dx, offsets[0].dy);
      fillPath.moveTo(offsets[0].dx, chartHeight);
      fillPath.lineTo(offsets[0].dx, offsets[0].dy);

      for (int i = 0; i < offsets.length - 1; i++) {
        final p0 = offsets[i];
        final p1 = offsets[i + 1];
        final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
        final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
        linePath.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          p1.dx,
          p1.dy,
        );
        fillPath.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          p1.dx,
          p1.dy,
        );
      }

      fillPath.lineTo(offsets.last.dx, chartHeight);
      fillPath.close();

      // Draw Gradient Fill
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor.withAlpha(70),
            primaryColor.withAlpha(0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));
      canvas.drawPath(fillPath, fillPaint);

      // Draw Stroke Line
      final linePaint = Paint()
        ..color = primaryColor
        ..strokeWidth = 3.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(linePath, linePaint);

      // Draw points & labels
      for (int i = 0; i < offsets.length; i++) {
        final off = offsets[i];
        final isSelected = selectedIndex == i;

        // Point circle
        canvas.drawCircle(
          off,
          isSelected ? 6.0 : 3.5,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          off,
          isSelected ? 4.5 : 2.5,
          Paint()..color = primaryColor,
        );

        // Draw X-axis label with smart interval
        final bool drawLabel = (i % stepInterval == 0) || (i == points.length - 1);
        if (drawLabel) {
          _drawLabel(canvas, points[i].label, off.dx, size.height - 14);
        }
      }
    }
  }

  void _drawLabel(Canvas canvas, String text, double x, double y) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: textColor.withAlpha(140),
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(x - (textPainter.width / 2), y),
    );
  }

  @override
  bool shouldRepaint(covariant _WeatherChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.horizontalPadding != horizontalPadding;
  }
}
