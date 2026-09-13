import 'package:flutter/material.dart';

class AppColors {
  // Realistic Sky Blue Atmospheric Identity (MIUI/ColorOS Style)
  static const Color skyBlueLight = Color(0xFF6CA8F4);
  static const Color skyBlueBase = Color(0xFF3E82DC);
  static const Color skyBlueDeep = Color(0xFF1E4C8F);
  static const Color skyBlueDark = Color(0xFF143769);
  static const Color skyMidnight = Color(0xFF0C1D3B);

  // Surface & Typography
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textWhite70 = Color(0xB3FFFFFF);
  static const Color textWhite50 = Color(0x80FFFFFF);
  static const Color offWhite = Color(0xFFF7F8F3);

  // Weather Trend Curve & Markers
  static const Color curvePeak = Color(0xFFFF6B6B);
  static const Color curveActive = Color(0xFF4ADE80);
  static const Color curveLine = Color(0xFFF6AD55);
  static const Color curveDashed = Color(0x4DFFFFFF);

  // Accents & Badges
  static const Color rainAccent = Color(0xFF70B4FF);
  static const Color sunnyAccent = Color(0xFFFFC107);
  static const Color warningAccent = Color(0xFFF97316);
  static const Color uvPurple = Color(0xFFC084FC);
  static const Color windCyan = Color(0xFF38BDF8);
  static const Color forestMint = Color(0xFF4ADE80);

  // Compatibility aliases
  static const Color primary = skyBlueBase;
  static const Color primaryDark = skyBlueDeep;
  static const Color accent = skyBlueLight;
  static const Color mainGreen = skyBlueBase;
  static const Color deepGreen = skyBlueDark;
  static const Color cardGreen = skyBlueDeep;
  static const Color softGreen = Color(0xFFD7E6FA);
  static const Color sageBg = Color(0xFFE8F1FC);
  static const Color primaryNavy = Color(0xFF0F1E38);
  static const Color slateSecondary = Color(0xFF748AA6);
  static const Color success = Color(0xFF10B981);
  static const Color warning = warningAccent;
  static const Color error = Color(0xFFEF4444);

  // Surfaces
  static const Color lightBg = Color(0xFF3E82DC);
  static const Color lightCard = Color(0x28FFFFFF);
  static const Color lightSurface = Color(0x20FFFFFF);
  static const Color lightTextPrimary = pureWhite;
  static const Color lightTextSecondary = textWhite70;

  static const Color darkBg = skyMidnight;
  static const Color darkCard = Color(0x35142E56);
  static const Color darkSurface = Color(0x280E2140);
  static const Color darkTextPrimary = pureWhite;
  static const Color darkTextSecondary = textWhite70;

  // 3-Level Glass System for Sky Theme
  static const Color glassLight = Color(0x24FFFFFF); // 14% white
  static const Color glassLightBorder = Color(0x38FFFFFF); // 22% white
  static const Color glassMedium = Color(0x30153866); // Sky-tinted glass
  static const Color glassMediumBorder = Color(0x40FFFFFF);
  static const Color glassDark = Color(0x550F2B52); // Deep sky dark glass
  static const Color glassDarkBorder = Color(0x403E82DC);

  // Dark mode glass
  static const Color glassDarkBg = Color(0x600B1D38);
  static const Color glassDarkBorderMode = Color(0x336CA8F4);

  // Atmospheric Full-Screen Weather Gradients (Sky & Clouds)
  static List<Color> getWeatherGradient(String condition, {bool isDark = false}) {
    final lower = condition.toLowerCase();
    if (isDark) {
      return const [
        Color(0xFF0C1E3C),
        Color(0xFF132B54),
        Color(0xFF19376D),
      ];
    }

    if (lower.contains('thunder') || lower.contains('storm')) {
      return const [
        Color(0xFF2C3E5E),
        Color(0xFF3D557C),
        Color(0xFF1E2E48),
      ];
    } else if (lower.contains('rain') || lower.contains('drizzle')) {
      return const [
        Color(0xFF3B679B),
        Color(0xFF2D5584),
        Color(0xFF1E3F66),
      ];
    } else if (lower.contains('snow')) {
      return const [
        Color(0xFF7097C2),
        Color(0xFF537EA8),
        Color(0xFF395D82),
      ];
    } else if (lower.contains('cloud') || lower.contains('overcast')) {
      // Natural Cloudy Sky (as in user screenshot)
      return const [
        Color(0xFF6BAAF7),
        Color(0xFF4A8EE4),
        Color(0xFF2E6BBE),
        Color(0xFF21559C),
      ];
    } else {
      // Sunny / Clear vibrant sky
      return const [
        Color(0xFF5BA2F4),
        Color(0xFF3D85DF),
        Color(0xFF2465BE),
        Color(0xFF194C94),
      ];
    }
  }

  // AQI Category Color
  static Color getAqiColor(int aqi) {
    if (aqi <= 50) return const Color(0xFF34D399); // Crisp mint green
    if (aqi <= 100) return const Color(0xFFFBBF24); // Moderate
    if (aqi <= 150) return const Color(0xFFF97316); // Sensitive
    if (aqi <= 200) return const Color(0xFFEF4444); // Unhealthy
    if (aqi <= 300) return const Color(0xFFA855F7); // Very Unhealthy
    return const Color(0xFFE11D48); // Hazardous
  }
}
