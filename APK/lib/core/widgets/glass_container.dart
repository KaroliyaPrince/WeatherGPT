import 'dart:ui';
import 'package:flutter/material.dart';

enum GlassLevel { light, medium, dark }

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final List<BoxShadow>? boxShadow;
  final GlassLevel level;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 0.0,
    this.borderRadius = 24.0,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.boxShadow,
    this.level = GlassLevel.medium,
  });

  /// Level 1: Light Glass for hourly & pill items
  const GlassContainer.light({
    super.key,
    required this.child,
    this.blur = 0.0,
    this.borderRadius = 20.0,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.boxShadow,
  }) : level = GlassLevel.light;

  /// Level 2: Medium Glass for metrics cards and floating info panels
  const GlassContainer.medium({
    super.key,
    required this.child,
    this.blur = 0.0,
    this.borderRadius = 24.0,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.boxShadow,
  }) : level = GlassLevel.medium;

  /// Level 3: Deep Sky Dark Glass for WeatherGPT AI card, daily outlook & bottom nav
  const GlassContainer.dark({
    super.key,
    required this.child,
    this.blur = 0.0,
    this.borderRadius = 28.0,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.boxShadow,
  }) : level = GlassLevel.dark;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color border;
    List<BoxShadow> shadows = boxShadow ?? [];

    switch (level) {
      case GlassLevel.light:
        bg = color ??
            (isDark
                ? const Color(0x35142E56)
                : const Color(0x28FFFFFF));
        border = borderColor ??
            (isDark
                ? const Color(0x306CA8F4)
                : const Color(0x40FFFFFF));
        if (shadows.isEmpty) {
          shadows = const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ];
        }
        break;

      case GlassLevel.medium:
        bg = color ??
            (isDark
                ? const Color(0x4810264A)
                : const Color(0x35193B66));
        border = borderColor ??
            (isDark
                ? const Color(0x3D6CA8F4)
                : const Color(0x3DFFFFFF));
        if (shadows.isEmpty) {
          shadows = const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ];
        }
        break;

      case GlassLevel.dark:
        bg = color ??
            (isDark
                ? const Color(0x750B1B36)
                : const Color(0x55112B4E));
        border = borderColor ?? const Color(0x38FFFFFF);
        if (shadows.isEmpty) {
          shadows = const [
            BoxShadow(
              color: Color(0x20000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ];
        }
        break;
    }

    final innerContent = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border, width: borderWidth),
      ),
      child: child,
    );

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows,
      ),
      child: blur > 0
          ? ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: innerContent,
              ),
            )
          : innerContent,
    );
  }
}
