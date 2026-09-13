import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/route_weather_model.dart';
import '../../../providers/route_weather_provider.dart';
import 'city_weather_zoom_dialog.dart';

class RouteWeatherPanel extends StatefulWidget {
  final Function(RoutePlace place)? onPlaceSelected;
  final VoidCallback? onClose;

  const RouteWeatherPanel({
    super.key,
    this.onPlaceSelected,
    this.onClose,
  });

  @override
  State<RouteWeatherPanel> createState() => _RouteWeatherPanelState();
}

class _RouteWeatherPanelState extends State<RouteWeatherPanel> {
  bool _isExpanded = true;

  String _formatArrival(DateTime dt) {
    return DateFormat('hh:mm a').format(dt);
  }

  IconData _getConditionIcon(String icon) {
    if (icon.contains('sun') || icon.contains('clear')) return Icons.wb_sunny_rounded;
    if (icon.contains('rain-heavy')) return Icons.thunderstorm_rounded;
    if (icon.contains('rain')) return Icons.water_drop_rounded;
    if (icon.contains('cloud')) return Icons.cloud_rounded;
    if (icon.contains('fog')) return Icons.foggy;
    return Icons.wb_cloudy_rounded;
  }

  void _openZoomCard(BuildContext context, RoutePlace place, int index, RoutePlan plan) {
    showCityZoomCard(
      context,
      place: place,
      index: index,
      totalCount: plan.places.length,
      allPlaces: plan.places,
      alerts: plan.alerts,
      onCenterMap: (p) {
        context.read<RouteWeatherProvider>().selectPlace(p);
        widget.onPlaceSelected?.call(p);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RouteWeatherProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plan = provider.routePlan;
    final isLoading = provider.isLoading;

    // Auto-collapse when keyboard is open
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
          width: 1.0,
        ),
      ),
      child: SafeArea(
        top: false,
        child: isKeyboardOpen
            // When keyboard is open, show only a minimal collapsed bar
            ? _buildCollapsedKeyboardBar(isDark, plan)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle & Tap to Expand/Collapse
                  GestureDetector(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Route Summary Bar (Distance • Duration • Cities Count • Expand Toggle)
                  if (plan != null && !isLoading)
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF0EA5E9).withAlpha(25),
                              const Color(0xFF6366F1).withAlpha(25),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF0EA5E9).withAlpha(60)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.straighten_rounded, size: 15, color: Color(0xFF0EA5E9)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '${plan.totalDistanceKm} km',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF6366F1)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '${plan.totalDurationMinutes ~/ 60}h ${plan.totalDurationMinutes % 60}m',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${plan.places.length} Cities',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  _isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                                  size: 17,
                                  color: const Color(0xFF0EA5E9),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Severe Weather Alerts along Route (from backend API)
                  if (plan != null && plan.alerts.isNotEmpty && !isLoading)
                    ...plan.alerts.map((alert) {
                      final isWarning = alert.severity.toLowerCase() == 'warning' || alert.type.contains('rain');
                      final alertColor = isWarning ? Colors.amber.shade700 : Colors.redAccent;
                      return Container(
                        margin: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: alertColor.withAlpha(isDark ? 35 : 20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: alertColor.withAlpha(120), width: 1.2),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Icon(Icons.warning_amber_rounded, color: alertColor, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          alert.title,
                                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: alertColor),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (alert.place.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            '• ${alert.place}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white70 : Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (alert.description.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        alert.description,
                                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                  // Collapsible City-Wise Weather List — Compact Route Stop Cards
                  if (_isExpanded)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.44,
                      ),
                      child: isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(strokeWidth: 2.5),
                                    SizedBox(height: 14),
                                    Text(
                                      'Analyzing highway route & fetching city weather...',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : (plan == null || plan.places.isEmpty)
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                      'Enter source & destination above to view highway weather.',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  key: const PageStorageKey('route_cities_list'),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: plan.places.length,
                                  itemBuilder: (ctx, index) {
                                    final place = plan.places[index];
                                    final isSelected = place.name == provider.selectedPlace?.name;
                                    return _buildCompactCityCard(
                                      context,
                                      place,
                                      index,
                                      plan.places.length,
                                      isSelected,
                                      isDark,
                                      plan,
                                    );
                                  },
                                ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
      ),
    );
  }

  /// Minimal bar shown when keyboard is open so the panel doesn't cover header
  Widget _buildCollapsedKeyboardBar(bool isDark, RoutePlan? plan) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Spacer(),
          if (plan != null) ...[
            const Icon(Icons.straighten_rounded, size: 14, color: Color(0xFF0EA5E9)),
            const SizedBox(width: 4),
            Text(
              '${plan.totalDistanceKm} km • ${plan.places.length} cities',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }

  /// Clean, compact route-stop city card
  Widget _buildCompactCityCard(
    BuildContext context,
    RoutePlace place,
    int index,
    int totalCount,
    bool isSelected,
    bool isDark,
    RoutePlan plan,
  ) {
    final w = place.weather;
    final isSource = index == 0;
    final isDestination = index == totalCount - 1;

    Color badgeColor = const Color(0xFF0EA5E9);
    IconData stepIcon = Icons.circle;
    if (isSource) {
      badgeColor = const Color(0xFF10B981);
      stepIcon = Icons.trip_origin_rounded;
    } else if (isDestination) {
      badgeColor = const Color(0xFFEF4444);
      stepIcon = Icons.flag_rounded;
    }

    final hasAlert = plan.alerts.any(
      (a) => a.place.toLowerCase() == place.name.toLowerCase(),
    );

    return InkWell(
      onTap: () => _openZoomCard(context, place, index, plan),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0EA5E9).withAlpha(isDark ? 40 : 25)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0EA5E9)
                : (isDark ? Colors.white12 : Colors.black12),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            // Step indicator dot/icon
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: badgeColor.withAlpha(25),
                shape: BoxShape.circle,
                border: Border.all(color: badgeColor.withAlpha(100), width: 1.5),
              ),
              child: Icon(stepIcon, size: 14, color: badgeColor),
            ),
            const SizedBox(width: 10),
            // City info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          place.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasAlert) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.amber),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isSource
                        ? 'Start Point • ${_formatArrival(place.estimatedArrival)}'
                        : '${place.distanceFromStartKm} km • ${_formatArrival(place.estimatedArrival)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Rain probability badge
            if (w.rainProbability > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.water_drop, size: 10, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 2),
                    Text(
                      '${w.rainProbability}%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
              ),
            // Condition icon + temp
            Icon(_getConditionIcon(w.condition.icon), size: 16, color: const Color(0xFF0EA5E9)),
            const SizedBox(width: 4),
            Text(
              '${w.temperatureC.toStringAsFixed(1)}°',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 4),
            // Zoom-in icon hint
            Icon(
              Icons.open_in_full_rounded,
              size: 14,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}
