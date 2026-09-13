import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/route_weather_model.dart';

/// Shows a smooth animated city-detail zoom card.
void showCityZoomCard(
  BuildContext context, {
  required RoutePlace place,
  required int index,
  required int totalCount,
  required List<RoutePlace> allPlaces,
  required List<RouteWeatherAlert> alerts,
  Function(RoutePlace)? onCenterMap,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'CityZoomCard',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 350),
    transitionBuilder: (ctx, anim, secondAnim, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return ScaleTransition(
        scale: curved,
        child: FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
          child: child,
        ),
      );
    },
    pageBuilder: (ctx, anim, secondAnim) {
      return _CityZoomCardContent(
        initialIndex: index,
        totalCount: totalCount,
        allPlaces: allPlaces,
        alerts: alerts,
        onCenterMap: onCenterMap,
      );
    },
  );
}

class _CityZoomCardContent extends StatefulWidget {
  final int initialIndex;
  final int totalCount;
  final List<RoutePlace> allPlaces;
  final List<RouteWeatherAlert> alerts;
  final Function(RoutePlace)? onCenterMap;

  const _CityZoomCardContent({
    required this.initialIndex,
    required this.totalCount,
    required this.allPlaces,
    required this.alerts,
    this.onCenterMap,
  });

  @override
  State<_CityZoomCardContent> createState() => _CityZoomCardContentState();
}

class _CityZoomCardContentState extends State<_CityZoomCardContent> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  RoutePlace get _place => widget.allPlaces[_currentIndex];
  bool get _isSource => _currentIndex == 0;
  bool get _isDest => _currentIndex == widget.totalCount - 1;

  String get _typeLabel {
    if (_isSource) return 'Source';
    if (_isDest) return 'Destination';
    return 'Highway Stop $_currentIndex of ${widget.totalCount - 2}';
  }

  Color get _badgeColor {
    if (_isSource) return const Color(0xFF10B981);
    if (_isDest) return const Color(0xFFEF4444);
    return const Color(0xFF0EA5E9);
  }

  IconData _getConditionIcon(String icon) {
    if (icon.contains('sun') || icon.contains('clear')) return Icons.wb_sunny_rounded;
    if (icon.contains('rain-heavy') || icon.contains('thunder')) return Icons.thunderstorm_rounded;
    if (icon.contains('rain')) return Icons.water_drop_rounded;
    if (icon.contains('cloud')) return Icons.cloud_rounded;
    if (icon.contains('fog')) return Icons.foggy;
    return Icons.wb_cloudy_rounded;
  }

  List<RouteWeatherAlert> get _cityAlerts => widget.alerts
      .where((a) => a.place.toLowerCase() == _place.name.toLowerCase())
      .toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final w = _place.weather;
    final cityAlerts = _cityAlerts;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.80,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 32,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // === Header Row: Badge, City Name, Close ===
                      Row(
                        children: [
                          // Previous arrow
                          if (_currentIndex > 0)
                            _navArrow(Icons.chevron_left_rounded, () {
                              setState(() => _currentIndex--);
                            })
                          else
                            const SizedBox(width: 32),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _badgeColor.withAlpha(30),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _badgeColor.withAlpha(100)),
                                  ),
                                  child: Text(
                                    _typeLabel,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: _badgeColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _place.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Next arrow
                          if (_currentIndex < widget.totalCount - 1)
                            _navArrow(Icons.chevron_right_rounded, () {
                              setState(() => _currentIndex++);
                            })
                          else
                            const SizedBox(width: 32),
                          const SizedBox(width: 4),
                          // Close button
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded, size: 22),
                            style: IconButton.styleFrom(
                              backgroundColor: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF1F5F9),
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(36, 36),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // === Primary Weather Hero ===
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF0EA5E9).withAlpha(isDark ? 40 : 20),
                              const Color(0xFF6366F1).withAlpha(isDark ? 30 : 15),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF0EA5E9).withAlpha(60),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Condition Icon
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0EA5E9).withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getConditionIcon(w.condition.icon),
                                size: 32,
                                color: const Color(0xFF0EA5E9),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    w.condition.text,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Feels like ${w.feelslikeC.toStringAsFixed(1)}°C',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white54 : Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Large Temperature
                            Text(
                              '${w.temperatureC.toStringAsFixed(1)}°',
                              style: const TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // === Journey Info Row ===
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            _journeyChip(
                              Icons.route_rounded,
                              _isSource
                                  ? 'Start Point'
                                  : '${_place.distanceFromStartKm} km',
                              const Color(0xFF0EA5E9),
                            ),
                            const Spacer(),
                            _journeyChip(
                              Icons.schedule_rounded,
                              DateFormat('hh:mm a').format(_place.estimatedArrival),
                              const Color(0xFF6366F1),
                            ),
                            const Spacer(),
                            _journeyChip(
                              Icons.pin_drop_outlined,
                              '${_place.latitude.toStringAsFixed(2)}°, ${_place.longitude.toStringAsFixed(2)}°',
                              Colors.grey,
                            ),
                          ],
                        ),
                      ),

                      // === Severe Alert Banner ===
                      if (cityAlerts.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...cityAlerts.map((alert) => Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withAlpha(isDark ? 35 : 20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber.shade700.withAlpha(120),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 18, color: Colors.amber.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alert.title,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.amber.shade700,
                                      ),
                                    ),
                                    if (alert.description.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          alert.description,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.white70 : Colors.black54,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],

                      const SizedBox(height: 14),

                      // === Weather Metrics Grid ===
                      Text(
                        'Weather Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white70 : Colors.black54,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: [
                          _metricTile(
                            Icons.water_drop_outlined,
                            'Rain',
                            '${w.rainProbability}%',
                            const Color(0xFF3B82F6),
                            isDark,
                          ),
                          _metricTile(
                            Icons.air_rounded,
                            'Wind',
                            '${w.windSpeedKph} km/h',
                            const Color(0xFF10B981),
                            isDark,
                          ),
                          _metricTile(
                            Icons.explore_outlined,
                            'Direction',
                            '${w.windDirection}°',
                            const Color(0xFF8B5CF6),
                            isDark,
                          ),
                          _metricTile(
                            Icons.opacity_rounded,
                            'Humidity',
                            '${w.humidity}%',
                            const Color(0xFF0EA5E9),
                            isDark,
                          ),
                          _metricTile(
                            Icons.wb_sunny_outlined,
                            'UV Index',
                            w.uvIndex.toStringAsFixed(1),
                            const Color(0xFFF59E0B),
                            isDark,
                          ),
                          _metricTile(
                            Icons.visibility_outlined,
                            'Visibility',
                            '${w.visibilityKm} km',
                            const Color(0xFF6366F1),
                            isDark,
                          ),
                          _metricTile(
                            Icons.speed_rounded,
                            'Pressure',
                            '${w.pressureMb} mb',
                            const Color(0xFFEC4899),
                            isDark,
                          ),
                          _metricTile(
                            Icons.grain_rounded,
                            'Precip.',
                            '${w.precipitationMm} mm',
                            const Color(0xFF14B8A6),
                            isDark,
                          ),
                          _metricTile(
                            Icons.thermostat_outlined,
                            'Feels',
                            '${w.feelslikeC.toStringAsFixed(1)}°C',
                            const Color(0xFFEF4444),
                            isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // === Focus on Map Button ===
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onCenterMap?.call(_place);
                          },
                          icon: const Icon(Icons.my_location_rounded, size: 18),
                          label: const Text(
                            'Focus on Map',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0EA5E9),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navArrow(IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF0EA5E9)),
      ),
    );
  }

  Widget _journeyChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _metricTile(
    IconData icon,
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 25 : 12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                color: isDark ? Colors.white54 : Colors.black45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
