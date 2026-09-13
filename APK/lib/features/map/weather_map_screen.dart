import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_assets.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/weather_utils.dart';
import '../../models/location_model.dart';
import '../../models/weather_data.dart';
import '../../providers/location_provider.dart';
import '../../providers/route_weather_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/location_service.dart';
import '../../services/storage_service.dart';
import '../../services/weather_api_service.dart';
import 'widgets/route_header_bar.dart';
import 'widgets/route_weather_panel.dart';
import 'widgets/city_weather_zoom_dialog.dart';

enum MapThemeOption {
  dark(
    id: 'dark',
    label: 'Dark Mode',
    sublabel: 'Default Midnight',
    icon: Icons.dark_mode_rounded,
    url: ApiConstants.darkMapTileUrl,
    previewColors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    previewIcon: Icons.nightlight_round,
    isDarkBg: true,
  ),
  starlight(
    id: 'starlight',
    label: 'Starlight',
    sublabel: 'Satellite Photo',
    icon: Icons.satellite_alt_rounded,
    url: ApiConstants.satelliteTileUrl,
    previewColors: [Color(0xFF0C4A6E), Color(0xFF065F46)],
    previewIcon: Icons.satellite_rounded,
    isDarkBg: true,
  ),
  hybrid(
    id: 'hybrid',
    label: 'Hybrid',
    sublabel: 'Sat + Roads',
    icon: Icons.alt_route_rounded,
    url: ApiConstants.satelliteTileUrl,
    previewColors: [Color(0xFF1E3A8A), Color(0xFF0EA5E9)],
    previewIcon: Icons.layers_rounded,
    isDarkBg: true,
  ),
  terrain(
    id: 'terrain',
    label: 'Terrain',
    sublabel: '3D Elevation',
    icon: Icons.terrain_rounded,
    url: ApiConstants.terrainTileUrl,
    previewColors: [Color(0xFF78350F), Color(0xFF15803D)],
    previewIcon: Icons.landscape_rounded,
    isDarkBg: false,
  ),
  standard(
    id: 'standard',
    label: 'Default',
    sublabel: 'Clean Streets',
    icon: Icons.map_rounded,
    url: ApiConstants.osmTileUrl,
    previewColors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
    previewIcon: Icons.map_rounded,
    isDarkBg: false,
  ),
  nightLights(
    id: 'night_lights',
    label: 'Night Earth',
    sublabel: 'NASA City Lights',
    icon: Icons.auto_awesome_rounded,
    url: ApiConstants.starlightNightTileUrl,
    previewColors: [Color(0xFF020617), Color(0xFF1E1B4B)],
    previewIcon: Icons.stars_rounded,
    isDarkBg: true,
  );

  final String id;
  final String label;
  final String sublabel;
  final IconData icon;
  final String url;
  final List<Color> previewColors;
  final IconData previewIcon;
  final bool isDarkBg;

  const MapThemeOption({
    required this.id,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.url,
    required this.previewColors,
    required this.previewIcon,
    required this.isDarkBg,
  });

  static MapThemeOption fromId(String id) {
    return MapThemeOption.values.firstWhere(
      (e) => e.id == id,
      orElse: () => MapThemeOption.dark,
    );
  }
}

class WeatherMapScreen extends StatefulWidget {
  final VoidCallback? onSwitchToHome;

  const WeatherMapScreen({super.key, this.onSwitchToHome});

  @override
  State<WeatherMapScreen> createState() => _WeatherMapScreenState();
}

class _WeatherMapScreenState extends State<WeatherMapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final WeatherApiService _apiService = WeatherApiService();

  LatLng _selectedLatLng = const LatLng(22.3039, 70.8022); // Default Rajkot
  LatLng? _userGpsLocation;
  WeatherLocation? _selectedPlace;
  WeatherData? _mapWeather;
  bool _isLoadingWeather = false;
  bool _isSearching = false;
  MapThemeOption _currentTheme = MapThemeOption.dark; // Default: Dark theme
  bool _showLabels = true;
  bool _showRadar = false;
  bool _showWeatherCard = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final storage = StorageService(prefs);
        final savedTheme = MapThemeOption.fromId(storage.mapTheme);
        if (mounted) {
          setState(() => _currentTheme = savedTheme);
        }
      } catch (_) {}

      if (!mounted) return;
      final loc = context.read<LocationProvider>().currentLocation;
      setState(() {
        _selectedLatLng = LatLng(loc.latitude, loc.longitude);
        _selectedPlace = loc;
      });
      _fetchWeatherForCoordinates(loc.latitude, loc.longitude);

      // Attempt to silently get current user GPS position to draw the blue dot
      try {
        final pos = await LocationService.getCurrentPosition();
        if (pos != null && mounted) {
          setState(() {
            _userGpsLocation = LatLng(pos.latitude, pos.longitude);
          });
        }
      } catch (_) {}
    });
  }

  Future<void> _setMapTheme(MapThemeOption theme) async {
    setState(() => _currentTheme = theme);
    try {
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
      await storage.saveMapTheme(theme.id);
    } catch (_) {}
  }

  Future<void> _fetchWeatherForCoordinates(double lat, double lon) async {
    setState(() => _isLoadingWeather = true);
    try {
      // 1. Reverse geocode
      final loc = await LocationService.reverseGeocode(lat, lon);
      if (loc != null && mounted) {
        setState(() {
          _selectedPlace = loc;
        });
      }

      // 2. Fetch live weather
      final weather = await _apiService.fetchWeather(
        latitude: lat,
        longitude: lon,
        cityName: _selectedPlace?.name,
      );

      if (mounted) {
        setState(() {
          _mapWeather = weather;
          _isLoadingWeather = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingWeather = false);
      }
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    // Dismiss keyboard if open so route panel can reappear
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedLatLng = point;
      _showWeatherCard = true;
      _selectedPlace = WeatherLocation(
        name: '${point.latitude.toStringAsFixed(2)}°, ${point.longitude.toStringAsFixed(2)}°',
        country: '',
        latitude: point.latitude,
        longitude: point.longitude,
      );
    });
    _mapController.move(point, _mapController.camera.zoom);
    _fetchWeatherForCoordinates(point.latitude, point.longitude);
  }

  Future<void> _onSearchSubmitted(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);

    try {
      final results = await LocationService.searchLocations(query);
      if (!mounted) return;
      if (results.isNotEmpty) {
        final loc = results.first;
        final target = LatLng(loc.latitude, loc.longitude);
        setState(() {
          _selectedLatLng = target;
          _selectedPlace = loc;
          _isSearching = false;
          _showWeatherCard = true;
        });
        _mapController.move(target, 12);
        _fetchWeatherForCoordinates(loc.latitude, loc.longitude);
      } else {
        setState(() => _isSearching = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No location found. Try another city name or coordinates.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _moveToCurrentLocation() async {
    setState(() => _isLoadingWeather = true);
    try {
      final pos = await LocationService.getCurrentPosition();
      if (!mounted) return;
      if (pos != null) {
        final latLng = LatLng(pos.latitude, pos.longitude);
        _userGpsLocation = latLng;

        // 1. Reverse geocode to get real human readable city name
        final reversed = await LocationService.reverseGeocode(pos.latitude, pos.longitude);
        final loc = reversed ??
            WeatherLocation(
              name: '${pos.latitude.toStringAsFixed(2)}°, ${pos.longitude.toStringAsFixed(2)}°',
              country: '',
              latitude: pos.latitude,
              longitude: pos.longitude,
            );

        if (mounted) {
          // Sync with global location provider
          context.read<LocationProvider>().selectLocation(loc);
        }

        _mapController.move(latLng, 13.5);
        setState(() {
          _selectedLatLng = latLng;
          _showWeatherCard = true;
          _selectedPlace = loc;
        });

        await _fetchWeatherForCoordinates(pos.latitude, pos.longitude);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.gps_fixed, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text('Moved to ${loc.name}'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() => _isLoadingWeather = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not obtain current GPS location. Please check location permissions.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[WeatherMapScreen] _moveToCurrentLocation error: $e');
      if (mounted) {
        setState(() => _isLoadingWeather = false);
      }
    }
  }


  Widget _buildQuickCityChip(String label, {double? lat, double? lon, bool isGps = false}) {
    return GestureDetector(
      onTap: () {
        if (isGps) {
          _moveToCurrentLocation();
        } else if (lat != null && lon != null) {
          final target = LatLng(lat, lon);
          _mapController.move(target, 12);
          setState(() {
            _selectedLatLng = target;
            _selectedPlace = WeatherLocation(
              name: label,
              country: 'India',
              latitude: lat,
              longitude: lon,
            );
          });
          _fetchWeatherForCoordinates(lat, lon);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
          border: Border.all(
            color: isGps ? const Color(0xFF0EA5E9) : Theme.of(context).dividerColor.withAlpha(25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isGps) ...[
              const Icon(Icons.near_me_rounded, size: 14, color: Color(0xFF0EA5E9)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isGps ? const Color(0xFF0EA5E9) : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteToggleChip(RouteWeatherProvider routeProv) {
    final isActive = routeProv.isRouteModeActive;
    return GestureDetector(
      onTap: () {
        routeProv.toggleRouteMode();
        if (routeProv.isRouteModeActive && routeProv.routePlan == null) {
          routeProv.calculateRoute();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0EA5E9) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x18000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
          border: Border.all(
            color: const Color(0xFF0EA5E9),
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.alt_route_rounded,
              size: 14,
              color: isActive ? Colors.white : const Color(0xFF0EA5E9),
            ),
            const SizedBox(width: 5),
            Text(
              isActive ? 'Route: Active' : '🛣️ Highway Route',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isActive ? Colors.white : const Color(0xFF0EA5E9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeChip() {
    return GestureDetector(
      onTap: _showMapThemeModal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x18000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
          border: Border.all(
            color: const Color(0xFF0EA5E9),
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _currentTheme.icon,
              size: 14,
              color: const Color(0xFF0EA5E9),
            ),
            const SizedBox(width: 5),
            Text(
              _currentTheme.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0EA5E9),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: Color(0xFF0EA5E9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleMapTypeCard(MapThemeOption theme, StateSetter setSheetState) {
    final isSelected = _currentTheme == theme;

    return GestureDetector(
      onTap: () {
        _setMapTheme(theme);
        setSheetState(() {});
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 98,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.previewColors,
              ),
              border: Border.all(
                color: isSelected ? const Color(0xFF0EA5E9) : Colors.transparent,
                width: isSelected ? 3.0 : 0.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0xFF0EA5E9).withAlpha(80)
                      : const Color(0x18000000),
                  blurRadius: isSelected ? 12 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  theme.previewIcon,
                  size: 28,
                  color: theme.isDarkBg ? Colors.white.withAlpha(210) : Colors.black.withAlpha(170),
                ),
                if (theme == MapThemeOption.dark)
                  Positioned(
                    top: 4,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(230),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        'DEFAULT',
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                if (isSelected)
                  const Positioned(
                    top: 4,
                    right: 4,
                    child: CircleAvatar(
                      radius: 9,
                      backgroundColor: Color(0xFF0EA5E9),
                      child: Icon(Icons.check, size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            theme.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF0EA5E9)
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            theme.sublabel,
            style: const TextStyle(
              fontSize: 9.5,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleMapDetailButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? const Color(0xFF0EA5E9).withAlpha(30)
                  : (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E293B)
                      : Colors.grey.shade100),
              border: Border.all(
                color: isActive ? const Color(0xFF0EA5E9) : Colors.grey.withAlpha(40),
                width: isActive ? 2.0 : 1.0,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0EA5E9).withAlpha(50),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: 24,
              color: isActive ? const Color(0xFF0EA5E9) : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive
                  ? const Color(0xFF0EA5E9)
                  : Theme.of(context).colorScheme.onSurface.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }

  void _showMapThemeModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modalBg = isDark ? const Color(0xFF0F172A) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: modalBg,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: modalBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top drag pill
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Header with close (X) button like Google Maps
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Map type',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 22),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Google Maps Style Cards (Row 1: Dark Mode, Starlight, Hybrid)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildGoogleMapTypeCard(MapThemeOption.dark, setSheetState),
                          _buildGoogleMapTypeCard(MapThemeOption.starlight, setSheetState),
                          _buildGoogleMapTypeCard(MapThemeOption.hybrid, setSheetState),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Google Maps Style Cards (Row 2: Terrain, Standard, Starlight Night)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildGoogleMapTypeCard(MapThemeOption.terrain, setSheetState),
                          _buildGoogleMapTypeCard(MapThemeOption.standard, setSheetState),
                          _buildGoogleMapTypeCard(MapThemeOption.nightLights, setSheetState),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // Google Maps Section: Map details & overlays
                      const Text(
                        'Map details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Detail 1: Weather Radar (Rain)
                          _buildGoogleMapDetailButton(
                            icon: Icons.water_drop_rounded,
                            label: 'Weather radar',
                            isActive: _showRadar,
                            onTap: () {
                              setState(() => _showRadar = !_showRadar);
                              setSheetState(() {});
                            },
                          ),

                          // Detail 2: Map Labels
                          _buildGoogleMapDetailButton(
                            icon: Icons.label_rounded,
                            label: 'Roads & labels',
                            isActive: _showLabels,
                            onTap: () {
                              setState(() => _showLabels = !_showLabels);
                              setSheetState(() {});
                            },
                          ),

                          // Detail 3: 3D Contours / Relief
                          _buildGoogleMapDetailButton(
                            icon: Icons.landscape_rounded,
                            label: '3D Terrain',
                            isActive: _currentTheme == MapThemeOption.terrain,
                            onTap: () {
                              _setMapTheme(MapThemeOption.terrain);
                              setSheetState(() {});
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final routeProv = context.watch<RouteWeatherProvider>();
    final isFahrenheit = settingsProvider.isFahrenheit;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // FlutterMap OpenStreetMap layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLatLng,
              initialZoom: 9.0,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                key: ValueKey('base_${_currentTheme.id}'),
                urlTemplate: _currentTheme.url,
                userAgentPackageName: 'com.weathergpt.weather_app',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              if (_showRadar)
                TileLayer(
                  key: const ValueKey('radar_overlay'),
                  urlTemplate: ApiConstants.rainRadarTileUrl,
                  userAgentPackageName: 'com.weathergpt.weather_app',
                ),
              if (_showLabels && _currentTheme == MapThemeOption.dark)
                TileLayer(
                  key: const ValueKey('dark_labels_overlay'),
                  urlTemplate: ApiConstants.darkMapReferenceTileUrl,
                  userAgentPackageName: 'com.weathergpt.weather_app',
                ),
              if (_showLabels &&
                  (_currentTheme == MapThemeOption.starlight ||
                      _currentTheme == MapThemeOption.hybrid ||
                      _currentTheme == MapThemeOption.nightLights ||
                      _currentTheme == MapThemeOption.terrain))
                TileLayer(
                  key: const ValueKey('labels_overlay'),
                  urlTemplate: ApiConstants.mapLabelsOverlayUrl,
                  userAgentPackageName: 'com.weathergpt.weather_app',
                  subdomains: const ['a', 'b', 'c', 'd'],
                ),
              // Route Polylines & Markers when Route Mode is Active
              if (routeProv.isRouteModeActive && routeProv.routePlan != null) ...[
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routeProv.routePlan!.polylinePoints,
                      strokeWidth: 8.0,
                      color: const Color(0xFF0284C7).withAlpha(110),
                    ),
                    Polyline(
                      points: routeProv.routePlan!.polylinePoints,
                      strokeWidth: 4.5,
                      color: const Color(0xFF0EA5E9),
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: routeProv.routePlan!.places.map((place) {
                    final isSource = place.type == 'source';
                    final isDest = place.type == 'destination';
                    final isSelected = routeProv.selectedPlace?.name == place.name;
                    final pinColor = isSource
                        ? const Color(0xFF10B981) // emerald green
                        : isDest
                            ? const Color(0xFFEF4444) // red
                            : (isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF0EA5E9));

                    return Marker(
                      point: place.coordinates,
                      width: 130,
                      height: 70,
                      child: GestureDetector(
                        onTap: () {
                          routeProv.selectPlace(place);
                          _mapController.move(place.coordinates, 12.0);
                          final plan = routeProv.routePlan;
                          if (plan != null) {
                            final idx = plan.places.indexWhere((p) => p.name == place.name);
                            showCityZoomCard(
                              context,
                              place: place,
                              index: idx >= 0 ? idx : 0,
                              totalCount: plan.places.length,
                              allPlaces: plan.places,
                              alerts: plan.alerts,
                              onCenterMap: (p) {
                                _mapController.move(p.coordinates, 12.0);
                              },
                            );
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: pinColor,
                                  width: isSelected ? 2.2 : 1.2,
                                ),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x38000000), blurRadius: 8, offset: Offset(0, 2)),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      place.name,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${place.weather.temperatureC.toStringAsFixed(0)}°',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      color: pinColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Icon(
                              isSource
                                  ? Icons.trip_origin_rounded
                                  : isDest
                                      ? Icons.flag_rounded
                                      : Icons.location_on_rounded,
                              color: pinColor,
                              size: isSelected ? 28 : 22,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ] else
                MarkerLayer(
                markers: [
                  // Live User Location GPS Blue Dot Marker
                  if (_userGpsLocation != null)
                    Marker(
                      point: _userGpsLocation!,
                      width: 44,
                      height: 44,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0EA5E9).withAlpha(40),
                            ),
                          ),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF0EA5E9),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Marker(
                    point: _selectedLatLng,
                    width: 220,
                    height: 100,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Google Maps Location Badge Bubble with Live Weather
                        GestureDetector(
                          onTap: () {
                            setState(() => _showWeatherCard = !_showWeatherCard);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(color: Color(0x38000000), blurRadius: 10, offset: Offset(0, 3)),
                              ],
                              border: Border.all(color: const Color(0xFF0EA5E9), width: 1.4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF0EA5E9)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _selectedPlace?.name ?? 'Selected',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_mapWeather != null) ...[
                                  const SizedBox(width: 5),
                                  Text(
                                    '• ${WeatherUtils.formatTemp(_mapWeather!.temperature, isFahrenheit: isFahrenheit)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0EA5E9),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Icon(
                                    AppAssets.getConditionIcon(_mapWeather!.condition),
                                    size: 13,
                                    color: const Color(0xFF0EA5E9),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Pulsing Pin
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0EA5E9).withAlpha(50),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0EA5E9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(50),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Bottom Sheet: Route Weather Panel or Single Location Weather Card
          // (Rendered BEFORE header bar so header always has higher z-index)
          if (routeProv.isRouteModeActive)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: RouteWeatherPanel(
                onPlaceSelected: (place) {
                  _mapController.move(place.coordinates, 12.0);
                },
                onClose: () {
                  routeProv.toggleRouteMode();
                },
              ),
            )
          else ...[
            if (_isLoadingWeather)
              Positioned(
                left: 16,
                right: 16,
                bottom: 90,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(color: Color(0x28000000), blurRadius: 16, offset: Offset(0, 4)),
                    ],
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                      width: 1.2,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 12),
                      Text('Loading weather for pin point...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              )
            else if (_showWeatherCard && _mapWeather != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 96,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Color(0x38000000), blurRadius: 20, offset: Offset(0, 6)),
                    ],
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top header: drag pill + dismiss close button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 28),
                          Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Dismiss Weather Card',
                            onPressed: () => setState(() => _showWeatherCard = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Weather icon
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0x1A0EA5E9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              AppAssets.getConditionIcon(_mapWeather!.condition),
                              size: 28,
                              color: const Color(0xFF0EA5E9),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Place name and condition
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedPlace?.displayName ?? _mapWeather!.location.displayName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${_mapWeather!.condition}  •  Rain: ${_mapWeather!.rainProbability}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 11,
                                      color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Observed: ${DateFormatter.formatTime(_mapWeather!.updatedAt)} (${DateFormatter.timeAgo(_mapWeather!.updatedAt)})',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Temperature
                          Text(
                            WeatherUtils.formatTemp(_mapWeather!.temperature, isFahrenheit: isFahrenheit),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
              ),
          ],

          // Controls on right: Map Theme Layers, Zoom In & Zoom Out
          Positioned(
            right: 16,
            bottom: routeProv.isRouteModeActive
                ? (MediaQuery.of(context).size.height * 0.46)
                : ((_showWeatherCard && _mapWeather != null) ? 190 : 110),
            child: Column(
              children: [
                // Map Theme / Style Layers FAB
                FloatingActionButton.small(
                  heroTag: 'map_theme_fab',
                  backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                  foregroundColor: const Color(0xFF0EA5E9),
                  elevation: 4,
                  tooltip: 'Map Theme: ${_currentTheme.label}',
                  onPressed: _showMapThemeModal,
                  child: const Icon(Icons.layers_rounded, size: 20),
                ),
                const SizedBox(height: 8),
                // Zoom in
                FloatingActionButton.small(
                  heroTag: 'map_zoom_in_btn',
                  backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  elevation: 4,
                  onPressed: () {
                    final zoom = _mapController.camera.zoom + 1;
                    _mapController.move(_selectedLatLng, zoom);
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                // Zoom out
                FloatingActionButton.small(
                  heroTag: 'map_zoom_out_btn',
                  backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  elevation: 4,
                  onPressed: () {
                    final zoom = _mapController.camera.zoom - 1;
                    _mapController.move(_selectedLatLng, zoom);
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // Top Floating Bar: RouteHeaderBar in Route Mode, otherwise Google Maps Style Search Bar
          // (Rendered LAST in Stack for highest z-index — never obscured by bottom panel)
          if (routeProv.isRouteModeActive)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: RouteHeaderBar(
                onClose: () => routeProv.toggleRouteMode(),
              ),
            )
          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Search Input Box
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1E000000),
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onSubmitted: _onSearchSubmitted,
                              decoration: InputDecoration(
                                hintText: 'Search city or place on map...',
                                hintStyle: const TextStyle(fontSize: 13.5),
                                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0EA5E9)),
                                suffixIcon: _isSearching
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      )
                                    : _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear_rounded, size: 18),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() {});
                                            },
                                          )
                                        : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onChanged: (text) => setState(() {}),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Current Location GPS Button on Right Side of Search Bar
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(25),
                            onTap: _moveToCurrentLocation,
                            child: Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x24000000),
                                    blurRadius: 14,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.my_location_rounded,
                                color: Color(0xFF0EA5E9),
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Google Maps Style Quick Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildRouteToggleChip(routeProv),
                          const SizedBox(width: 8),
                          _buildThemeChip(),
                          const SizedBox(width: 8),
                          _buildQuickCityChip('📍 Current Location', isGps: true),
                          const SizedBox(width: 8),
                          _buildQuickCityChip('Rajkot', lat: 22.3039, lon: 70.8022),
                          const SizedBox(width: 8),
                          _buildQuickCityChip('Ahmedabad', lat: 23.0225, lon: 72.5714),
                          const SizedBox(width: 8),
                          _buildQuickCityChip('Surat', lat: 21.1702, lon: 72.8311),
                          const SizedBox(width: 8),
                          _buildQuickCityChip('Mumbai', lat: 19.0760, lon: 72.8777),
                          const SizedBox(width: 8),
                          _buildQuickCityChip('Delhi', lat: 28.6139, lon: 77.2090),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
