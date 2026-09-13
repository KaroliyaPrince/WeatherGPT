import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../models/location_model.dart';
import '../../providers/location_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/weather_provider.dart';
import '../locations/location_search_screen.dart';
import 'widgets/aqi_summary_card.dart';
import 'widgets/compact_metrics_grid.dart';
import 'widgets/current_weather_card.dart';
import 'widgets/daily_forecast_snapshot.dart';
import 'widgets/hourly_horizontal_list.dart';
import 'widgets/past_7_days_card.dart';
import 'widgets/todays_insight_card.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenChatbot;
  final VoidCallback? onOpenForecast;

  const HomeScreen({
    super.key,
    this.onOpenChatbot,
    this.onOpenForecast,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  int _selectedFilterIndex = 0;

  final List<String> _quickFilters = [
    'Overview',
    'Hourly Curve',
    'Daily 7D',
    'Past 7 Days',
    'Sensors',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onFilterTap(int index) {
    setState(() => _selectedFilterIndex = index);
    if (index == 0) {
      _scrollController.animateTo(0, duration: 400.ms, curve: Curves.easeInOut);
    } else if (index == 1) {
      _scrollController.animateTo(300, duration: 400.ms, curve: Curves.easeInOut);
    } else if (index == 2) {
      _scrollController.animateTo(620, duration: 400.ms, curve: Curves.easeInOut);
    } else if (index == 3) {
      _scrollController.animateTo(920, duration: 400.ms, curve: Curves.easeInOut);
    } else if (index == 4) {
      _scrollController.animateTo(1240, duration: 400.ms, curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = context.watch<WeatherProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    final data = weatherProvider.weatherData;
    final isFahrenheit = settingsProvider.isFahrenheit;
    final isLoading = weatherProvider.isLoading;
    final isOffline = weatherProvider.isOffline;
    final error = weatherProvider.errorMessage;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final skyGradient = AppColors.getWeatherGradient(
      data?.condition ?? 'Cloudy',
      isDark: isDark,
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: skyGradient,
          ),
        ),
        child: Stack(
          children: [
            // Soft Realistic Cloud Atmosphere at the top (GPU-accelerated)
            Positioned(
              top: -40,
              left: -40,
              right: -40,
              height: 260,
              child: RepaintBoundary(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SkyCloudAtmospherePainter(isDark: isDark),
                  ),
                ),
              ),
            ),

            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Top Status Bar with City Name and Quick Icons
                  _buildTopBar(context, locationProvider, weatherProvider),

                  // Quick Filter Pills (Overview, Hourly Curve, AI, Daily, Sensors)
                  _buildQuickFilterBar(),

                  // Main Weather Content
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (isLoading && data == null) {
                          return const WeatherSkeletonView();
                        }

                        if (error != null && data == null) {
                          return ErrorView(
                            message: error,
                            onRetry: () => weatherProvider.fetchWeather(
                              location: locationProvider.currentLocation,
                              language: settingsProvider.language,
                              forceRefresh: true,
                            ),
                            onUseDefault: () {
                              locationProvider.selectLocation(
                                const WeatherLocation(
                                  name: 'Morvi',
                                  country: 'India',
                                  latitude: 22.8228,
                                  longitude: 70.8384,
                                ),
                              );
                              weatherProvider.fetchWeather(
                                location: locationProvider.currentLocation,
                                language: settingsProvider.language,
                                forceRefresh: true,
                              );
                            },
                          );
                        }

                        if (data != null) {
                          return RefreshIndicator(
                            color: AppColors.skyBlueLight,
                            backgroundColor: AppColors.skyMidnight,
                            onRefresh: () => weatherProvider.refresh(
                              location: locationProvider.currentLocation,
                              language: settingsProvider.language,
                            ),
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Offline Warning
                                  if (isOffline)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withAlpha(40),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.amber.withAlpha(90)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.wifi_off_rounded, size: 16, color: Colors.amber),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Offline mode — Cached ${DateFormatter.timeAgo(data.updatedAt)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // 1. Hero Weather Card (Morvi / PM2.5 / Cloudy / 28~39°C / 28°C)
                                  RepaintBoundary(
                                    child: CurrentWeatherCard(
                                      data: data,
                                      isFahrenheit: isFahrenheit,
                                      isOffline: isOffline,
                                    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.04, end: 0),
                                  ),

                                  const SizedBox(height: 14),

                                  // 2. Continuous Hourly Temperature Wave Chart
                                  RepaintBoundary(
                                    child: HourlyHorizontalList(
                                      hourlyList: data.hourly,
                                      isFahrenheit: isFahrenheit,
                                    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.04, end: 0),
                                  ),

                                  const SizedBox(height: 16),

                                  // 3. Daily Forecast Card (09/11 Yesterday, 09/12 Today, 09/13 Tomorrow)
                                  RepaintBoundary(
                                    child: DailyForecastSnapshot(
                                      forecastList: data.forecast,
                                      isFahrenheit: isFahrenheit,
                                      onViewDetails: widget.onOpenForecast,
                                    ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.04, end: 0),
                                  ),

                                  const SizedBox(height: 16),

                                   // 4. Past 7 Days Historical Weather Card
                                   RepaintBoundary(
                                     child: const Past7DaysCard()
                                         .animate().fadeIn(delay: 320.ms).slideY(begin: 0.04, end: 0),
                                   ),

                                  const SizedBox(height: 16),

                                  // 5. Today's Highlight Card
                                  RepaintBoundary(
                                    child: TodaysInsightCard(data: data)
                                        .animate().fadeIn(delay: 380.ms).slideY(begin: 0.04, end: 0),
                                  ),

                                  const SizedBox(height: 16),

                                  // 6. Conditions & Sensors Grid
                                  RepaintBoundary(
                                    child: CompactMetricsGrid(data: data)
                                        .animate().fadeIn(delay: 440.ms).slideY(begin: 0.04, end: 0),
                                  ),

                                  const SizedBox(height: 16),

                                  // 7. Air Quality Index Summary
                                  if (data.airQuality != null) ...[
                                    RepaintBoundary(
                                      child: AqiSummaryCard(airQuality: data.airQuality)
                                          .animate().fadeIn(delay: 500.ms).slideY(begin: 0.04, end: 0),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    LocationProvider locProvider,
    WeatherProvider weatherProvider,
  ) {
    final currentLoc = locProvider.currentLocation;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // City Name at top-left with auto-truncation
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final selected = await Navigator.push<WeatherLocation>(
                  context,
                  MaterialPageRoute(builder: (_) => const LocationSearchScreen()),
                );
                if (selected != null) {
                  locProvider.selectLocation(selected);
                  weatherProvider.fetchWeather(location: selected);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      currentLoc.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Right Utility Actions: Search, GPS
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search City Button
              IconButton(
                icon: const Icon(Icons.search_rounded, color: Colors.white, size: 21),
                tooltip: 'Search City',
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: const EdgeInsets.all(6),
                onPressed: () async {
                  final selected = await Navigator.push<WeatherLocation>(
                    context,
                    MaterialPageRoute(builder: (_) => const LocationSearchScreen()),
                  );
                  if (selected != null) {
                    locProvider.selectLocation(selected);
                    weatherProvider.fetchWeather(location: selected);
                  }
                },
              ),

              const SizedBox(width: 2),

              // GPS Auto-detect Button
              IconButton(
                icon: locProvider.isLocating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.my_location_rounded, color: Colors.white, size: 21),
                tooltip: 'Current GPS',
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: const EdgeInsets.all(6),
                onPressed: locProvider.isLocating
                    ? null
                    : () async {
                        final success = await locProvider.detectCurrentGPSLocation();
                        if (success) {
                          weatherProvider.fetchWeather(location: locProvider.currentLocation);
                        }
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterBar() {
    return Container(
      height: 32,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _quickFilters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedFilterIndex == index;
          return GestureDetector(
            onTap: () => _onFilterTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withAlpha(50) : Colors.white.withAlpha(18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.white.withAlpha(140) : Colors.white.withAlpha(25),
                ),
              ),
              child: Center(
                child: Text(
                  _quickFilters[index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter that creates photorealistic, soft fluffy cloud formations across the sky
/// Optimized with GPU-accelerated RadialGradient shaders instead of expensive software blur filters.
class _SkyCloudAtmospherePainter extends CustomPainter {
  final bool isDark;

  const _SkyCloudAtmospherePainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final baseAlpha = isDark ? 20 : 42;
    final brightAlpha = isDark ? 30 : 58;

    void drawCloudPuff(Offset center, double radiusX, double radiusY, int alpha) {
      final rect = Rect.fromCenter(center: center, width: radiusX * 2, height: radiusY * 2);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withAlpha(alpha),
            Colors.white.withAlpha(0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(rect);
      canvas.drawOval(rect, paint);
    }

    // Layer 1: Wide background puffs
    drawCloudPuff(Offset(size.width * 0.25, 60), 110, 55, baseAlpha);
    drawCloudPuff(Offset(size.width * 0.75, 45), 130, 65, baseAlpha);

    // Layer 2: Foreground brighter wisps
    drawCloudPuff(Offset(size.width * 0.15, 40), 70, 38, brightAlpha);
    drawCloudPuff(Offset(size.width * 0.85, 35), 80, 42, brightAlpha);
    drawCloudPuff(Offset(size.width * 0.50, 20), 90, 35, brightAlpha);
  }

  @override
  bool shouldRepaint(covariant _SkyCloudAtmospherePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
