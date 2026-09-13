import 'package:flutter/material.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/weather_utils.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../models/weather_data.dart';

class CurrentWeatherCard extends StatelessWidget {
  final WeatherData data;
  final bool isFahrenheit;
  final bool isOffline;

  const CurrentWeatherCard({
    super.key,
    required this.data,
    required this.isFahrenheit,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    final tempVal = data.temperature.round();
    final minVal = data.tempMin.round();
    final maxVal = data.tempMax.round();
    final feelsVal = data.apparentTemperature.round();

    final pm25Value = data.airQuality != null ? data.airQuality!.pm25.round() : 13;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top Row: PM2.5 Pill Badge & Online/Offline status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // PM2.5 Pill Badge (as seen in screenshot)
              GlassContainer(
                level: GlassLevel.light,
                borderRadius: 16.0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PM',
                          style: TextStyle(
                            color: AppColors.curveActive,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          '2.5',
                          style: TextStyle(
                            color: AppColors.curveActive,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$pm25Value',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Weather Icon / Condition badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AppAssets.getConditionIcon(data.condition),
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      data.condition,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Condition Header (e.g. "Cloudy")
          Text(
            data.condition,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 4),

          // Temperature Range & Feels like: "28 ~ 39°C  Feels like 33°C"
          Text(
            isFahrenheit
                ? '${WeatherUtils.cToF(minVal.toDouble()).round()} ~ ${WeatherUtils.cToF(maxVal.toDouble()).round()}°F   Feels like ${WeatherUtils.cToF(feelsVal.toDouble()).round()}°F'
                : '$minVal ~ $maxVal°C   Feels like $feelsVal°C',
            style: TextStyle(
              color: Colors.white.withAlpha(210),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 10),

          // Giant Hero Temperature ("28°C") - Clean, modern typography
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isFahrenheit
                    ? '${WeatherUtils.cToF(tempVal.toDouble()).round()}'
                    : '$tempVal',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 88,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                  letterSpacing: -2.0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 2),
                child: Text(
                  isFahrenheit ? '°F' : '°C',
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Floating Frosted Glass Pill Bar (High, Low, Humidity, Wind)
          GlassContainer(
            level: GlassLevel.light,
            borderRadius: 22.0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Flexible(
                  child: _buildQuickMetric(
                    icon: Icons.thermostat_rounded,
                    label: 'High/Low',
                    value: isFahrenheit
                        ? '${WeatherUtils.cToF(maxVal.toDouble()).round()}°/${WeatherUtils.cToF(minVal.toDouble()).round()}°'
                        : '$maxVal°/$minVal°',
                  ),
                ),
                Container(
                  height: 20,
                  width: 1,
                  color: Colors.white.withAlpha(35),
                ),
                Flexible(
                  child: _buildQuickMetric(
                    icon: Icons.water_drop_rounded,
                    label: 'Humidity',
                    value: '${data.humidity}%',
                  ),
                ),
                Container(
                  height: 20,
                  width: 1,
                  color: Colors.white.withAlpha(35),
                ),
                Flexible(
                  child: _buildQuickMetric(
                    icon: Icons.air_rounded,
                    label: 'Wind',
                    value: '${data.windSpeed} km/h',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white.withAlpha(220)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withAlpha(160),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }
}
