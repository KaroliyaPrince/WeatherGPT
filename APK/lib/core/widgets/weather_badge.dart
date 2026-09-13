import 'package:flutter/material.dart';

class WeatherBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Color? textColor;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const WeatherBadge({
    super.key,
    required this.label,
    this.icon,
    required this.color,
    this.textColor,
    this.fontSize = 11.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withAlpha(76),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: textColor ?? color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: textColor ?? color,
            ),
          ),
        ],
      ),
    );
  }
}
