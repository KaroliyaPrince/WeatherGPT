import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../core/constants/api_constants.dart';
import '../models/route_weather_model.dart';

class RouteWeatherService {
  final http.Client _client;

  RouteWeatherService({http.Client? client}) : _client = client ?? http.Client();

  // Known city fallback coordinates for fast lookups
  static final Map<String, LatLng> _cityCoordinates = {
    'rajkot': const LatLng(22.3039, 70.8022),
    'ahmedabad': const LatLng(23.0225, 72.5714),
    'vejalpur': const LatLng(22.98814, 72.5075),
    'vadodara': const LatLng(22.3072, 73.1812),
    'surat': const LatLng(21.1702, 72.8311),
    'gandhinagar': const LatLng(23.2156, 72.6369),
    'jamnagar': const LatLng(22.4707, 70.0577),
    'bhavnagar': const LatLng(21.7645, 72.1519),
    'junagadh': const LatLng(21.5222, 70.4579),
    'anand': const LatLng(22.5645, 72.9289),
    'chotila': const LatLng(22.4223, 71.1963),
    'limbdi': const LatLng(22.5658, 71.8082),
    'bagodara': const LatLng(22.6842, 72.1384),
    'bavla': const LatLng(22.8354, 72.3619),
    'sarkhej': const LatLng(22.9882, 72.4975),
    'morbi': const LatLng(22.8120, 70.8378),
    'mumbai': const LatLng(19.0760, 72.8777),
    'pune': const LatLng(18.5204, 73.8567),
    'delhi': const LatLng(28.6139, 77.2090),
    'jaipur': const LatLng(26.9124, 75.7873),
    'agra': const LatLng(27.1767, 78.0081),
    'bengaluru': const LatLng(12.9716, 77.5946),
  };

  /// Geocode city name to LatLng
  Future<LatLng?> geocode(String city) async {
    final normalized = city.trim().toLowerCase();
    if (_cityCoordinates.containsKey(normalized)) {
      return _cityCoordinates[normalized];
    }

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(city)}&format=json&limit=1',
      );
      final response = await _client.get(
        uri,
        headers: {'User-Agent': 'WeatherGPT-FlutterApp/1.0'},
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        if (list.isNotEmpty) {
          final lat = double.tryParse(list[0]['lat'].toString());
          final lon = double.tryParse(list[0]['lon'].toString());
          if (lat != null && lon != null) {
            return LatLng(lat, lon);
          }
        }
      }
    } catch (_) {}

    return null;
  }

  /// Reverse geocode LatLng to city/place name
  Future<String> reverseGeocode(LatLng point) async {
    // 1. Fast local match against known cities and highway towns within ~8 km
    const distanceCalc = Distance();
    for (final entry in _cityCoordinates.entries) {
      if (distanceCalc.as(LengthUnit.Kilometer, point, entry.value) < 8.0) {
        final name = entry.key;
        return name[0].toUpperCase() + name.substring(1);
      }
    }

    // 2. Query Nominatim reverse geocode
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${point.latitude}&lon=${point.longitude}&format=json',
      );
      final response = await _client.get(
        uri,
        headers: {'User-Agent': 'WeatherGPT-FlutterApp/1.0'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        final name = addr['suburb'] ??
            addr['city_district'] ??
            addr['town'] ??
            addr['village'] ??
            addr['neighbourhood'] ??
            addr['city'] ??
            data['name'];

        if (name != null && name.toString().trim().isNotEmpty) {
          return name.toString().trim();
        }
      }
    } catch (_) {}

    return 'Highway Stop (${point.latitude.toStringAsFixed(2)}, ${point.longitude.toStringAsFixed(2)})';
  }

  /// Main method: Calculate route and fetch intermediate city-wise weather
  /// Prioritizes live Express.js backend endpoint: GET /api/route-weather?source=...&destination=...
  Future<RoutePlan> getRouteWeather({
    required String source,
    required String destination,
    LatLng? sourceCoord,
    LatLng? destCoord,
  }) async {
    // 1. Primary: Query the live Express.js backend API
    try {
      final backendUri = Uri.parse(
        '${ApiConstants.routeWeatherEndpoint}?source=${Uri.encodeComponent(source.trim())}&destination=${Uri.encodeComponent(destination.trim())}',
      );
      final response = await _client.get(
        backendUri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['success'] == true && data['places'] != null) {
          final plan = RoutePlan.fromApiResponse(data);

          // Enrich with smooth road polyline if coordinates available
          if (plan.sourceCoord != null && plan.destCoord != null) {
            final roadPolyline = await _fetchDrivingPolyline(plan.sourceCoord!, plan.destCoord!);
            if (roadPolyline.isNotEmpty) {
              return plan.copyWith(polylinePoints: roadPolyline);
            }
          }
          return plan;
        }
      }
    } catch (_) {
      // Gracefully fall back to local computation if backend is unreachable
    }

    // 2. Fallback: Local geocoding, OSRM highway polyline & coordinate weather
    final from = sourceCoord ?? await geocode(source) ?? const LatLng(22.3039, 70.8022);
    final to = destCoord ?? await geocode(destination) ?? const LatLng(23.0225, 72.5714);

    double totalDistanceKm = 0.0;
    int totalDurationMinutes = 0;
    List<LatLng> polylinePoints = await _fetchDrivingPolyline(from, to);

    if (polylinePoints.isNotEmpty) {
      totalDistanceKm = const Distance().as(LengthUnit.Kilometer, from, to);
      totalDurationMinutes = (totalDistanceKm / 60 * 60).round();
    } else {
      polylinePoints = _interpolatePoints(from, to, 30);
      totalDistanceKm = const Distance().as(LengthUnit.Kilometer, from, to);
      totalDurationMinutes = (totalDistanceKm / 60 * 60).round();
    }

    // Sample intermediate stops along the highway
    final places = await _sampleAndFetchRoutePlaces(
      from: from,
      to: to,
      polyline: polylinePoints,
      totalDistanceKm: totalDistanceKm,
      totalDurationMinutes: totalDurationMinutes,
      sourceName: source,
      destName: destination,
    );

    return RoutePlan(
      source: source,
      destination: destination,
      totalDistanceKm: double.parse(totalDistanceKm.toStringAsFixed(1)),
      totalDurationMinutes: totalDurationMinutes,
      polylinePoints: polylinePoints,
      places: places,
    );
  }

  Future<List<LatLng>> _fetchDrivingPolyline(LatLng from, LatLng to) async {
    try {
      final osrmUrl = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}?overview=full&geometries=geojson',
      );
      final osrmRes = await _client.get(osrmUrl).timeout(const Duration(seconds: 8));
      if (osrmRes.statusCode == 200) {
        final data = jsonDecode(osrmRes.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final coords = data['routes'][0]['geometry']['coordinates'] as List;
          return coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Sample waypoints along the route and fetch weather for each in parallel
  Future<List<RoutePlace>> _sampleAndFetchRoutePlaces({
    required LatLng from,
    required LatLng to,
    required List<LatLng> polyline,
    required double totalDistanceKm,
    required int totalDurationMinutes,
    required String sourceName,
    required String destName,
  }) async {
    final now = DateTime.now();
    final List<Map<String, dynamic>> rawStops = [];

    // Stop 0: Source City
    rawStops.add({
      'name': sourceName,
      'type': 'source',
      'coord': from,
      'distanceKm': 0.0,
      'arrival': now,
    });

    // Intermediate stops (e.g. 5 balanced points along highway)
    const numIntermediate = 5;
    if (polyline.length > numIntermediate + 2) {
      final step = (polyline.length / (numIntermediate + 1)).floor();
      for (int i = 1; i <= numIntermediate; i++) {
        final idx = (i * step).clamp(0, polyline.length - 1);
        final pt = polyline[idx];
        final fraction = i / (numIntermediate + 1);
        final dist = totalDistanceKm * fraction;
        final minutes = (totalDurationMinutes * fraction).round();

        rawStops.add({
          'name': '', // will resolve via reverse geocoding
          'type': 'route_place',
          'coord': pt,
          'distanceKm': dist,
          'arrival': now.add(Duration(minutes: minutes)),
        });
      }
    }

    // Final Stop: Destination City
    rawStops.add({
      'name': destName,
      'type': 'destination',
      'coord': to,
      'distanceKm': totalDistanceKm,
      'arrival': now.add(Duration(minutes: totalDurationMinutes)),
    });

    // Parallel reverse-geocode and parallel weather fetching
    final results = await Future.wait(rawStops.map((stop) async {
      final coord = stop['coord'] as LatLng;
      String name = stop['name'] as String;

      if (name.isEmpty) {
        name = await reverseGeocode(coord);
      }

      final weather = await fetchWeatherForCoordinate(coord.latitude, coord.longitude);

      return RoutePlace(
        name: name,
        type: stop['type'] as String,
        latitude: coord.latitude,
        longitude: coord.longitude,
        distanceFromStartKm: double.parse((stop['distanceKm'] as double).toStringAsFixed(1)),
        estimatedArrival: stop['arrival'] as DateTime,
        weather: weather,
      );
    }));

    return results;
  }

  /// Fetch real-time weather from Open-Meteo matching the exact user schema
  Future<RouteWeatherInfo> fetchWeatherForCoordinate(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,surface_pressure,wind_speed_10m,wind_direction_10m,uv_index,visibility',
      );

      final res = await _client.get(url).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final cur = json['current'] as Map<String, dynamic>? ?? {};

        final tempC = (cur['temperature_2m'] as num?)?.toDouble() ?? 30.0;
        final feelslikeC = (cur['apparent_temperature'] as num?)?.toDouble() ?? tempC;
        final code = (cur['weather_code'] as num?)?.toInt() ?? 0;
        final windKph = (cur['wind_speed_10m'] as num?)?.toDouble() ?? 10.0;
        final windDir = (cur['wind_direction_10m'] as num?)?.toInt() ?? 0;
        final humidity = (cur['relative_humidity_2m'] as num?)?.toInt() ?? 50;
        final precipMm = (cur['precipitation'] as num?)?.toDouble() ?? 0.0;
        final pressureMb = ((cur['surface_pressure'] as num?)?.toDouble() ?? 1013.0).round();
        final uvVal = (cur['uv_index'] as num?)?.toDouble() ?? 0.0;
        final visMeters = (cur['visibility'] as num?)?.toDouble() ?? 20000.0;
        final visKm = (visMeters / 1000).clamp(0.1, 50.0);

        final condition = _mapWeatherCode(code);
        final rainProb = precipMm > 0 ? 80 : (code >= 51 ? 60 : (code >= 1 ? 20 : 0));

        return RouteWeatherInfo(
          tempC: tempC,
          temperatureC: tempC,
          condition: condition,
          weatherCode: code,
          windKph: windKph,
          windSpeedKph: windKph,
          windDirection: windDir,
          humidity: humidity,
          feelslikeC: feelslikeC,
          uv: uvVal,
          uvIndex: uvVal,
          visibilityKm: double.parse(visKm.toStringAsFixed(1)),
          pressureMb: pressureMb,
          precipMm: precipMm,
          precipitationMm: precipMm,
          rainProbability: rainProb,
        );
      }
    } catch (_) {}

    // Safe fallback if offline
    return const RouteWeatherInfo(
      tempC: 32.0,
      temperatureC: 32.0,
      condition: RouteWeatherCondition(text: 'Partly Cloudy', icon: 'cloud-sun', code: 1001),
      weatherCode: 1001,
      windKph: 12.0,
      windSpeedKph: 12.0,
      windDirection: 280,
      humidity: 55,
      feelslikeC: 36.0,
      uv: 3.0,
      uvIndex: 3.0,
      visibilityKm: 20.0,
      pressureMb: 1008,
      precipMm: 0.0,
      precipitationMm: 0.0,
      rainProbability: 10,
    );
  }

  RouteWeatherCondition _mapWeatherCode(int code) {
    if (code == 0) {
      return const RouteWeatherCondition(text: 'Clear Sky', icon: 'sun', code: 1000);
    } else if (code == 1 || code == 2) {
      return const RouteWeatherCondition(text: 'Partly Cloudy', icon: 'cloud-sun', code: 1001);
    } else if (code == 3) {
      return const RouteWeatherCondition(text: 'Overcast', icon: 'cloud', code: 1001);
    } else if (code >= 45 && code <= 48) {
      return const RouteWeatherCondition(text: 'Foggy', icon: 'fog', code: 1002);
    } else if (code >= 51 && code <= 55) {
      return const RouteWeatherCondition(text: 'Drizzle', icon: 'rain-light', code: 1003);
    } else if (code >= 61 && code <= 65) {
      return const RouteWeatherCondition(text: 'Rain', icon: 'rain', code: 1004);
    } else if (code >= 80 && code <= 82) {
      return const RouteWeatherCondition(text: 'Heavy Showers', icon: 'rain-heavy', code: 1005);
    } else if (code >= 95) {
      return const RouteWeatherCondition(text: 'Thunderstorm', icon: 'thunderstorm', code: 1006);
    }
    return const RouteWeatherCondition(text: 'Overcast', icon: 'cloud', code: 1001);
  }

  List<LatLng> _interpolatePoints(LatLng start, LatLng end, int count) {
    final list = <LatLng>[];
    for (int i = 0; i <= count; i++) {
      final f = i / count;
      final lat = start.latitude + (end.latitude - start.latitude) * f;
      final lon = start.longitude + (end.longitude - start.longitude) * f;
      list.add(LatLng(lat, lon));
    }
    return list;
  }
}
