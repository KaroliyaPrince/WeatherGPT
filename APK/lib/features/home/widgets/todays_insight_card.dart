import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../models/weather_data.dart';

class TodaysInsightCard extends StatelessWidget {
  final WeatherData data;

  const TodaysInsightCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final rainProb = data.hourly.isNotEmpty ? data.hourly.first.rainProbability : 0;
    final isRainy = rainProb > 40 || data.condition.toLowerCase().contains('rain');
    final uvLevel = data.uvIndex;
    final humidity = data.humidity;

    String recommendation;
    String badgeTitle;
    IconData badgeIcon;
    Color accentColor;

    if (isRainy) {
      badgeTitle = 'Rain Alert';
      badgeIcon = Icons.umbrella_rounded;
      accentColor = AppColors.rainAccent;
      recommendation = 'High chance of precipitation ($rainProb%). Carry rain protection and drive cautiously.';
    } else if (uvLevel >= 8) {
      badgeTitle = 'Very High UV';
      badgeIcon = Icons.wb_sunny_rounded;
      accentColor = AppColors.sunnyAccent;
      recommendation = 'UV index is strong ($uvLevel). Apply sunscreen and wear sun protective gear.';
    } else if (humidity > 80) {
      badgeTitle = 'High Moisture';
      badgeIcon = Icons.water_drop_rounded;
      accentColor = AppColors.windCyan;
      recommendation = 'Air humidity is saturated at $humidity%. Outdoor heat feeling is elevated.';
    } else {
      badgeTitle = 'Pleasant Weather';
      badgeIcon = Icons.sentiment_very_satisfied_rounded;
      accentColor = AppColors.curveActive;
      recommendation = 'Comfortable atmospheric conditions today. Great window for outdoor activities.';
    }

    return GlassContainer(
      level: GlassLevel.dark,
      borderRadius: 22.0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withAlpha(90)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 13, color: accentColor),
                    const SizedBox(width: 5),
                    Text(
                      badgeTitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "TODAY'S HIGHLIGHT",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Colors.white.withAlpha(160),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            recommendation,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildMetricChip(
                icon: Icons.water_drop_outlined,
                label: 'Rain: $rainProb%',
              ),
              _buildMetricChip(
                icon: Icons.wb_sunny_outlined,
                label: 'UV: $uvLevel',
              ),
              _buildMetricChip(
                icon: Icons.air_rounded,
                label: '${data.windSpeed} km/h',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withAlpha(220)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
