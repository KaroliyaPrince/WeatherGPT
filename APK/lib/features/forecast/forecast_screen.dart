import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_assets.dart';
import '../../core/utils/weather_utils.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../models/daily_forecast.dart';
import '../../models/hourly_forecast.dart';
import '../../providers/location_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/weather_provider.dart';
import 'widgets/weather_chart.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  int _viewMode = 0; // 0: Hourly, 1: 7-Day
  ChartMetricType _metricType = ChartMetricType.temperature;

  @override
  Widget build(BuildContext context) {
    final weatherProvider = context.watch<WeatherProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final locationProvider = context.watch<LocationProvider>();

    final data = weatherProvider.weatherData;
    final isFahrenheit = settingsProvider.isFahrenheit;

    if (weatherProvider.isLoading && data == null) {
      return const Scaffold(body: WeatherSkeletonView());
    }

    if (weatherProvider.errorMessage != null && data == null) {
      return Scaffold(
        body: ErrorView(
          message: weatherProvider.errorMessage!,
          onRetry: () => weatherProvider.fetchWeather(
            location: locationProvider.currentLocation,
            language: settingsProvider.language,
          ),
        ),
      );
    }

    if (data == null) {
      return const Scaffold(
        body: Center(child: Text('No forecast data loaded.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detailed Forecast & Charts'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // View Mode Segmented Control (Hourly vs 7-Day)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildSegmentButton(
                    title: 'Hourly Forecast (24h)',
                    isSelected: _viewMode == 0,
                    onTap: () => setState(() => _viewMode = 0),
                  ),
                  _buildSegmentButton(
                    title: '7-Day Outlook',
                    isSelected: _viewMode == 1,
                    onTap: () => setState(() => _viewMode = 1),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Metric Selector Pills (Temp, Rain, Wind, Humidity)
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildMetricChip(
                    label: 'Temperature',
                    icon: Icons.thermostat_rounded,
                    type: ChartMetricType.temperature,
                    color: const Color(0xFF0EA5E9),
                  ),
                  const SizedBox(width: 8),
                  _buildMetricChip(
                    label: 'Precipitation %',
                    icon: Icons.water_drop_rounded,
                    type: ChartMetricType.rainProbability,
                    color: const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  _buildMetricChip(
                    label: 'Wind Speed',
                    icon: Icons.air_rounded,
                    type: ChartMetricType.windSpeed,
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  _buildMetricChip(
                    label: 'Humidity',
                    icon: Icons.opacity_rounded,
                    type: ChartMetricType.humidity,
                    color: const Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Interactive Chart Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).dividerColor.withAlpha(20)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getChartTitle(),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(120),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _viewMode == 0 ? Icons.swipe_rounded : Icons.touch_app_rounded,
                              size: 12,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _viewMode == 0 ? 'Swipe 24h' : 'Tap point',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  WeatherChart(
                    points: _buildChartPoints(data, isFahrenheit),
                    metricType: _metricType,
                    primaryColor: _getMetricColor(),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1)),

            const SizedBox(height: 24),

            // Breakdown List
            Text(
              _viewMode == 0 ? 'Hourly Timeline Breakdown' : '7-Day Daily Breakdown',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),

            if (_viewMode == 0)
              ...data.hourly.map((h) => _buildHourlyRow(context, h, isFahrenheit))
            else
              ...data.forecast.map((d) => _buildDailyRow(context, d, isFahrenheit)),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? const [
                    BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 2)),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF0EA5E9)
                  : Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required IconData icon,
    required ChartMetricType type,
    required Color color,
  }) {
    final isSelected = _metricType == type;

    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : color),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _metricType = type);
      },
      selectedColor: color,
      backgroundColor: Theme.of(context).cardColor,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.transparent : Theme.of(context).dividerColor.withAlpha(30),
        ),
      ),
    );
  }

  String _getChartTitle() {
    switch (_metricType) {
      case ChartMetricType.temperature:
        return 'Temperature Trend';
      case ChartMetricType.rainProbability:
        return 'Precipitation Probability (%)';
      case ChartMetricType.windSpeed:
        return 'Wind Speed (km/h)';
      case ChartMetricType.humidity:
        return 'Relative Humidity (%)';
    }
  }

  Color _getMetricColor() {
    switch (_metricType) {
      case ChartMetricType.temperature:
        return const Color(0xFF0EA5E9);
      case ChartMetricType.rainProbability:
        return const Color(0xFF2563EB);
      case ChartMetricType.windSpeed:
        return const Color(0xFF10B981);
      case ChartMetricType.humidity:
        return const Color(0xFF8B5CF6);
    }
  }

  List<WeatherChartPoint> _buildChartPoints(dynamic data, bool isFahrenheit) {
    if (_viewMode == 0) {
      // Hourly
      final List<HourlyForecast> list = data.hourly;
      return list.map((h) {
        double val = 0;
        String disp = '';
        switch (_metricType) {
          case ChartMetricType.temperature:
            val = isFahrenheit
                ? WeatherUtils.cToF(h.temperature.toDouble())
                : h.temperature.toDouble();
            disp = '${val.round()}°';
            break;
          case ChartMetricType.rainProbability:
            val = h.rainProbability.toDouble();
            disp = '${h.rainProbability}%';
            break;
          case ChartMetricType.windSpeed:
            val = h.windSpeed.toDouble();
            disp = '${h.windSpeed} km/h';
            break;
          case ChartMetricType.humidity:
            val = h.humidity.toDouble();
            disp = '${h.humidity}%';
            break;
        }
        return WeatherChartPoint(
          label: h.hourLabel,
          value: val,
          displayValue: disp,
        );
      }).toList();
    } else {
      // Daily
      final List<DailyForecast> list = data.forecast;
      return list.map((d) {
        double val = 0;
        String disp = '';
        switch (_metricType) {
          case ChartMetricType.temperature:
            val = isFahrenheit
                ? WeatherUtils.cToF(d.maxTemp.toDouble())
                : d.maxTemp.toDouble();
            disp = '${val.round()}°';
            break;
          case ChartMetricType.rainProbability:
            val = d.rainProbability.toDouble();
            disp = '${d.rainProbability}%';
            break;
          case ChartMetricType.windSpeed:
            val = (d.windSpeed ?? 14).toDouble();
            disp = '${val.round()} km/h';
            break;
          case ChartMetricType.humidity:
            val = (d.humidity ?? 60).toDouble();
            disp = '${val.round()}%';
            break;
        }
        return WeatherChartPoint(
          label: d.day,
          value: val,
          displayValue: disp,
        );
      }).toList();
    }
  }

  Widget _buildHourlyRow(BuildContext context, HourlyForecast h, bool isFahrenheit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 58,
            child: Text(h.hourLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          Text(h.conditionEmoji, style: const TextStyle(fontSize: 18)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.water_drop_rounded, size: 12, color: Color(0xFF0EA5E9)),
              const SizedBox(width: 2),
              Text('${h.rainProbability}%', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9))),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.air_rounded, size: 12, color: Color(0xFF10B981)),
              const SizedBox(width: 2),
              Text('${h.windSpeed} km/h', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
            ],
          ),
          Text(
            WeatherUtils.formatTemp(h.temperature, isFahrenheit: isFahrenheit, showUnit: true),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRow(BuildContext context, DailyForecast d, bool isFahrenheit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(20)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 55,
            child: Text(d.day, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ),
          Icon(AppAssets.getConditionIcon(d.condition), size: 20, color: const Color(0xFF0EA5E9)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              d.condition,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.water_drop_rounded, size: 12, color: Color(0xFF0EA5E9)),
              const SizedBox(width: 3),
              Text('${d.rainProbability}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9))),
            ],
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              Text(WeatherUtils.formatTemp(d.maxTemp, isFahrenheit: isFahrenheit), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(width: 6),
              Text(WeatherUtils.formatTemp(d.minTemp, isFahrenheit: isFahrenheit), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withAlpha(120))),
            ],
          ),
        ],
      ),
    );
  }
}
