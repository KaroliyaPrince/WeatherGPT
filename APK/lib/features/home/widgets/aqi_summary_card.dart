import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../models/air_quality.dart';

class AqiSummaryCard extends StatelessWidget {
  final AirQuality? airQuality;

  const AqiSummaryCard({super.key, this.airQuality});

  @override
  Widget build(BuildContext context) {
    if (airQuality == null) return const SizedBox.shrink();

    final aqi = airQuality!;
    final aqiColor = AppColors.getAqiColor(aqi.aqi);

    return GlassContainer(
      level: GlassLevel.dark,
      borderRadius: 24.0,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: aqiColor.withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.air_rounded, size: 16, color: aqiColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AIR QUALITY INDEX',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withAlpha(160),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: aqiColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: aqiColor.withAlpha(90),
                  ),
                ),
                child: Text(
                  aqi.category,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: aqiColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${aqi.aqi}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: aqiColor,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'AQI',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withAlpha(150),
                ),
              ),
              const Spacer(),
              Text(
                'Dominant: ${aqi.dominantPollutant.toUpperCase()}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withAlpha(160),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (aqi.aqi / 300).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white.withAlpha(20),
              valueColor: AlwaysStoppedAnimation<Color>(aqiColor),
            ),
          ),

          const SizedBox(height: 14),

          // Pollutant breakdown chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPollutantChip('PM2.5', aqi.pm25.toStringAsFixed(1)),
              _buildPollutantChip('PM10', aqi.pm10.toStringAsFixed(1)),
              _buildPollutantChip('O3', aqi.o3.toStringAsFixed(1)),
              _buildPollutantChip('NO2', aqi.no2.toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPollutantChip(String name, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withAlpha(150),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
