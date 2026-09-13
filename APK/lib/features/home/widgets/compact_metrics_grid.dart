import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/weather_utils.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../models/weather_data.dart';

class CompactMetricsGrid extends StatelessWidget {
  final WeatherData data;

  const CompactMetricsGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      childAspectRatio: 1.15,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // 1. Humidity
        _buildMetricTile(
          icon: Icons.water_drop_rounded,
          iconColor: AppColors.windCyan,
          label: 'HUMIDITY',
          value: '${data.humidity}%',
          status: WeatherUtils.getHumidityStatus(data.humidity),
          progress: (data.humidity / 100.0).clamp(0.0, 1.0),
        ),

        // 2. Wind
        _buildMetricTile(
          icon: Icons.toys_outlined,
          iconColor: AppColors.curveActive,
          label: 'WIND SPEED',
          value: '${data.windSpeed} km/h',
          status: '${data.windDirection} • Gust ${data.windGust > 0 ? "${data.windGust} km/h" : "${(data.windSpeed * 1.3).round()} km/h"}',
          progress: (data.windSpeed / 60.0).clamp(0.0, 1.0),
        ),

        // 3. UV Index
        _buildMetricTile(
          icon: Icons.wb_sunny_rounded,
          iconColor: AppColors.sunnyAccent,
          label: 'UV INDEX',
          value: '${data.uvIndex}',
          status: WeatherUtils.getUvCategory(data.uvIndex),
          progress: (data.uvIndex / 12.0).clamp(0.0, 1.0),
        ),

        // 4. Atmospheric Pressure
        _buildMetricTile(
          icon: Icons.speed_rounded,
          iconColor: const Color(0xFF60A5FA),
          label: 'PRESSURE',
          value: '${data.pressure} mb',
          status: WeatherUtils.getPressureStatus(data.pressure),
          progress: ((data.pressure - 980) / 50.0).clamp(0.0, 1.0),
        ),

        // 5. Visibility
        _buildMetricTile(
          icon: Icons.visibility_rounded,
          iconColor: AppColors.uvPurple,
          label: 'VISIBILITY',
          value: '${data.visibility} km',
          status: WeatherUtils.getVisibilityStatus(data.visibility),
          progress: (data.visibility / 10.0).clamp(0.0, 1.0),
        ),

        // 6. Sunrise & Sunset
        _buildSunTile(
          sunrise: data.sunrise,
          sunset: data.sunset,
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String status,
    required double progress,
  }) {
    return GlassContainer(
      level: GlassLevel.dark,
      borderRadius: 20.0,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Colors.white.withAlpha(160),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withAlpha(190),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          // Micro progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withAlpha(20),
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunTile({
    required String sunrise,
    required String sunset,
  }) {
    return GlassContainer(
      level: GlassLevel.dark,
      borderRadius: 20.0,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.sunnyAccent.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.wb_twilight_rounded, color: AppColors.sunnyAccent, size: 16),
              ),
              Text(
                'SUN CYCLE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Colors.white.withAlpha(160),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rise',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withAlpha(160),
                    ),
                  ),
                  Text(
                    sunrise,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                height: 24,
                width: 1,
                color: Colors.white.withAlpha(25),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withAlpha(160),
                    ),
                  ),
                  Text(
                    sunset,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Gradient track
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                colors: [AppColors.sunnyAccent, AppColors.curvePeak, Color(0xFF818CF8)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
