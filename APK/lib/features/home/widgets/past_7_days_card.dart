import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/utils/weather_utils.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../models/past_day_weather.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/weather_provider.dart';

class Past7DaysCard extends StatelessWidget {
  const Past7DaysCard({super.key});

  @override
  Widget build(BuildContext context) {
    final weatherProvider = context.watch<WeatherProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final pastList = weatherProvider.past7Days;
    final isLoading = weatherProvider.isLoadingPast7Days;
    final isFahrenheit = settingsProvider.isFahrenheit;
    final lang = settingsProvider.language;

    if (pastList.isEmpty && !isLoading) {
      return const SizedBox.shrink();
    }

    final title = lang == 'gu'
        ? 'છેલ્લા ૭ દિવસ'
        : (lang == 'hi' ? 'पिछले 7 दिन' : 'PAST 7 DAYS');

    return GlassContainer(
      level: GlassLevel.dark,
      borderRadius: 24.0,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header matching DailyForecastSnapshot frame
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              if (pastList.isNotEmpty)
                GestureDetector(
                  onTap: () => _showDayDetails(
                    context,
                    pastList.first,
                    weatherProvider,
                    isFahrenheit,
                    lang,
                  ),
                  child: Row(
                    children: [
                      Text(
                        lang == 'gu' ? 'વિગતો' : (lang == 'hi' ? 'विवरण' : 'Details'),
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Colors.white.withAlpha(200),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          if (isLoading && pastList.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Color(0xFF38BDF8)),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pastList.length,
              separatorBuilder: (context, index) => Divider(
                height: 12,
                color: Colors.white.withAlpha(15),
              ),
              itemBuilder: (context, index) {
                final item = pastList[index];

                // Derive formatted MM/dd string from item.dateTime
                String datePrefix = '';
                try {
                  final dt = item.dateTime;
                  datePrefix = '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ';
                } catch (_) {
                  datePrefix = '';
                }

                final displayLabel = '$datePrefix${item.dayLabel}';

                return InkWell(
                  onTap: () => _showDayDetails(
                    context,
                    item,
                    weatherProvider,
                    isFahrenheit,
                    lang,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        // Column 1: Date & Relative Day (flex: 4)
                        Expanded(
                          flex: 4,
                          child: Text(
                            displayLabel,
                            style: TextStyle(
                              color: Colors.white.withAlpha(190),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Column 2: Condition Icon + Optional Rain/Precipitation (flex: 3)
                        Expanded(
                          flex: 3,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                AppAssets.getConditionIcon(item.condition),
                                size: 18,
                                color: Colors.white,
                              ),
                              if (item.precipitationMm > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '${item.precipitationMm.toStringAsFixed(1)}mm',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(210),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Column 3: Min and Max temperatures right-aligned (flex: 3)
                        Expanded(
                          flex: 3,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                isFahrenheit
                                    ? '${WeatherUtils.cToF(item.minTemp.toDouble()).round()}'
                                    : '${item.minTemp.round()}',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(150),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                isFahrenheit
                                    ? '${WeatherUtils.cToF(item.maxTemp.toDouble()).round()}'
                                    : '${item.maxTemp.round()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showDayDetails(
    BuildContext context,
    PastDayWeather day,
    WeatherProvider provider,
    bool isFahrenheit,
    String lang,
  ) {
    final currentTemp = provider.weatherData?.temperature;
    String tempDiffText = '';
    if (currentTemp != null) {
      final diff = (day.maxTemp - currentTemp).round();
      if (diff > 0) {
        tempDiffText = '+$diff° warmer than today';
      } else if (diff < 0) {
        tempDiffText = '$diff° cooler than today';
      } else {
        tempDiffText = 'Same as today';
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      AppAssets.getConditionIcon(day.condition),
                      size: 32,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${day.dayLabel} • ${day.formattedDate}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            day.condition,
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (tempDiffText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withAlpha(40),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF0EA5E9).withAlpha(80)),
                        ),
                        child: Text(
                          tempDiffText,
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildDetailBox(
                      title: 'High Temp',
                      val: WeatherUtils.formatTemp(day.maxTemp, isFahrenheit: isFahrenheit, showUnit: true),
                      icon: Icons.arrow_upward_rounded,
                      color: const Color(0xFFF87171),
                    ),
                    const SizedBox(width: 10),
                    _buildDetailBox(
                      title: 'Low Temp',
                      val: WeatherUtils.formatTemp(day.minTemp, isFahrenheit: isFahrenheit, showUnit: true),
                      icon: Icons.arrow_downward_rounded,
                      color: const Color(0xFF60A5FA),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildDetailBox(
                      title: 'Rainfall',
                      val: '${day.precipitationMm.toStringAsFixed(1)} mm',
                      icon: Icons.water_drop_rounded,
                      color: const Color(0xFF38BDF8),
                    ),
                    const SizedBox(width: 10),
                    _buildDetailBox(
                      title: 'Max Wind',
                      val: '${day.windSpeedKph.toStringAsFixed(0)} km/h',
                      icon: Icons.air_rounded,
                      color: const Color(0xFF34D399),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailBox({
    required String title,
    required String val,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                Text(
                  val,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
