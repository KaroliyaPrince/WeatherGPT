import 'package:flutter/material.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/utils/weather_utils.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../models/daily_forecast.dart';

class DailyForecastSnapshot extends StatelessWidget {
  final List<DailyForecast> forecastList;
  final bool isFahrenheit;
  final VoidCallback? onViewDetails;

  const DailyForecastSnapshot({
    super.key,
    required this.forecastList,
    required this.isFahrenheit,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (forecastList.isEmpty) return const SizedBox.shrink();

    return GlassContainer(
      level: GlassLevel.dark,
      borderRadius: 24.0,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'DAILY FORECAST',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              if (onViewDetails != null)
                GestureDetector(
                  onTap: onViewDetails,
                  child: Row(
                    children: [
                      Text(
                        'Details',
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

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: forecastList.length,
            separatorBuilder: (context, index) => Divider(
              height: 12,
              color: Colors.white.withAlpha(15),
            ),
            itemBuilder: (context, index) {
              final item = forecastList[index];
              final isToday = index == 0;

              // Derive formatted MM/dd string from item.date or current date
              String datePrefix = '';
              try {
                if (item.date.isNotEmpty) {
                  final dt = DateTime.parse(item.date);
                  datePrefix = '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ';
                }
              } catch (_) {
                datePrefix = '';
              }

              final displayLabel = isToday
                  ? '${datePrefix}Today'
                  : (index == 1 ? '${datePrefix}Tomorrow' : '$datePrefix${item.day}');

              final rainPercent = item.rainProbability.round();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    // Date & Relative Day (e.g. "09/12 Today")
                    Expanded(
                      flex: 4,
                      child: Text(
                        displayLabel,
                        style: TextStyle(
                          color: isToday ? Colors.white : Colors.white.withAlpha(190),
                          fontSize: 13,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Condition Icon + Optional Rain % (as seen in screenshot: e.g. rain icon + 58%)
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
                          if (rainPercent > 20) ...[
                            const SizedBox(width: 4),
                            Text(
                              '$rainPercent%',
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

                    // Min and Max temperatures right aligned: "28  39"
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
              );
            },
          ),
        ],
      ),
    );
  }
}
