import 'package:flutter/material.dart';

class AppAssets {
  static const String appName = 'WeatherGPT';
  static const String appTagline = 'Your Intelligent Meteorological Companion';
  static const String appVersion = '2.0.0';

  // Weather Condition Emojis & Icons
  static IconData getConditionIcon(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('thunder') || lower.contains('lightning')) {
      return Icons.thunderstorm_rounded;
    } else if (lower.contains('rain') || lower.contains('drizzle') || lower.contains('shower')) {
      return Icons.water_drop_rounded;
    } else if (lower.contains('snow') || lower.contains('blizzard') || lower.contains('sleet')) {
      return Icons.ac_unit_rounded;
    } else if (lower.contains('cloud') || lower.contains('overcast')) {
      return Icons.cloud_rounded;
    } else if (lower.contains('fog') || lower.contains('mist') || lower.contains('haze')) {
      return Icons.foggy;
    } else if (lower.contains('wind') || lower.contains('gale')) {
      return Icons.air_rounded;
    } else {
      return Icons.wb_sunny_rounded;
    }
  }

  static String getConditionEmoji(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('thunder') || lower.contains('lightning')) return '⛈️';
    if (lower.contains('rain') || lower.contains('drizzle')) return '🌧️';
    if (lower.contains('snow')) return '❄️';
    if (lower.contains('cloud') || lower.contains('overcast')) return '☁️';
    if (lower.contains('fog') || lower.contains('mist')) return '🌫️';
    if (lower.contains('wind')) return '💨';
    return '☀️';
  }
}
