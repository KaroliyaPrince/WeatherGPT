import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/location_model.dart';

class LocationService {
  /// Request GPS location safely with multi-tiered fallback (LastKnown -> Medium Accuracy -> Low Accuracy)
  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Still attempt to get cached position if available
        try {
          final cached = await Geolocator.getLastKnownPosition();
          if (cached != null) return cached;
        } catch (_) {}
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return await Geolocator.getLastKnownPosition();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return await Geolocator.getLastKnownPosition();
      }

      // 1. Check last known position for instant responsiveness
      Position? lastKnown;
      try {
        lastKnown = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      // 2. Try fetching fresh position with balanced accuracy (fast satellite/network fix)
      try {
        final freshPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
        return freshPos;
      } catch (e) {
        debugPrint('[LocationService] Fresh GPS timeout/error: $e. Using last known fallback.');
        if (lastKnown != null) return lastKnown;
      }

      // 3. Last attempt with low accuracy if no position acquired yet
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 5),
          ),
        );
      } catch (_) {
        return lastKnown;
      }
    } catch (e) {
      debugPrint('[LocationService] General getCurrentPosition exception: $e');
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  static const List<WeatherLocation> _curatedCities = [
    WeatherLocation(name: 'Morbi', state: 'Gujarat', country: 'India', latitude: 22.8228, longitude: 70.8384),
    WeatherLocation(name: 'Rajkot', state: 'Gujarat', country: 'India', latitude: 22.3039, longitude: 70.8022),
    WeatherLocation(name: 'Ahmedabad', state: 'Gujarat', country: 'India', latitude: 23.0225, longitude: 72.5714),
    WeatherLocation(name: 'Surat', state: 'Gujarat', country: 'India', latitude: 21.1702, longitude: 72.8311),
    WeatherLocation(name: 'Vadodara', state: 'Gujarat', country: 'India', latitude: 22.3072, longitude: 73.1812),
    WeatherLocation(name: 'Gandhinagar', state: 'Gujarat', country: 'India', latitude: 23.2156, longitude: 72.6369),
    WeatherLocation(name: 'Bhavnagar', state: 'Gujarat', country: 'India', latitude: 21.7645, longitude: 72.1519),
    WeatherLocation(name: 'Jamnagar', state: 'Gujarat', country: 'India', latitude: 22.4707, longitude: 70.0577),
    WeatherLocation(name: 'Junagadh', state: 'Gujarat', country: 'India', latitude: 21.5222, longitude: 70.4579),
    WeatherLocation(name: 'Mumbai', state: 'Maharashtra', country: 'India', latitude: 19.0760, longitude: 72.8777),
    WeatherLocation(name: 'Pune', state: 'Maharashtra', country: 'India', latitude: 18.5204, longitude: 73.8567),
    WeatherLocation(name: 'Delhi', state: 'Delhi', country: 'India', latitude: 28.6139, longitude: 77.2090),
    WeatherLocation(name: 'Bengaluru', state: 'Karnataka', country: 'India', latitude: 12.9716, longitude: 77.5946),
    WeatherLocation(name: 'Hyderabad', state: 'Telangana', country: 'India', latitude: 17.3850, longitude: 78.4867),
    WeatherLocation(name: 'Chennai', state: 'Tamil Nadu', country: 'India', latitude: 13.0827, longitude: 80.2707),
    WeatherLocation(name: 'Kolkata', state: 'West Bengal', country: 'India', latitude: 22.5726, longitude: 88.3639),
    WeatherLocation(name: 'Jaipur', state: 'Rajasthan', country: 'India', latitude: 26.9124, longitude: 75.7873),
    WeatherLocation(name: 'Udaipur', state: 'Rajasthan', country: 'India', latitude: 24.5854, longitude: 73.7125),
    WeatherLocation(name: 'London', state: 'England', country: 'United Kingdom', latitude: 51.5074, longitude: -0.1278),
    WeatherLocation(name: 'Dubai', state: 'Dubai', country: 'United Arab Emirates', latitude: 25.2048, longitude: 55.2708),
    WeatherLocation(name: 'New York', state: 'New York', country: 'United States', latitude: 40.7128, longitude: -74.0060),
    WeatherLocation(name: 'Tokyo', state: 'Tokyo', country: 'Japan', latitude: 35.6762, longitude: 139.6503),
  ];

  static List<WeatherLocation> get popularCities => _curatedCities;

  /// Search city or location using Open-Meteo, Photon, Curated database, and Nominatim
  static Future<List<WeatherLocation>> searchLocations(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    // 1. Direct Coordinate search support (e.g. "23.02, 72.57" or "23.02 72.57")
    final coordMatch = RegExp(r'^([-+]?\d{1,2}(?:\.\d+)?)[,\s]+([-+]?\d{1,3}(?:\.\d+)?)$').firstMatch(trimmed);
    if (coordMatch != null) {
      final lat = double.tryParse(coordMatch.group(1)!);
      final lon = double.tryParse(coordMatch.group(2)!);
      if (lat != null && lon != null && lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
        final reversed = await reverseGeocode(lat, lon);
        return [
          reversed ??
              WeatherLocation(
                name: '${lat.toStringAsFixed(2)}°, ${lon.toStringAsFixed(2)}°',
                country: '',
                latitude: lat,
                longitude: lon,
              ),
        ];
      }
    }

    // 2. Primary: Open-Meteo Geocoding API (Fast, Free, No API key, No 429 rate limits)
    try {
      final uri = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(trimmed)}&count=10&language=en&format=json',
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['results'] is List) {
          final List results = data['results'];
          final list = results.map((item) {
            final name = item['name']?.toString() ?? 'Unknown';
            final state = item['admin1']?.toString() ?? item['admin2']?.toString();
            final country = item['country']?.toString() ?? item['country_code']?.toString() ?? '';
            final lat = double.tryParse(item['latitude']?.toString() ?? '') ?? 0.0;
            final lon = double.tryParse(item['longitude']?.toString() ?? '') ?? 0.0;
            return WeatherLocation(
              name: name,
              state: state,
              country: country,
              latitude: lat,
              longitude: lon,
            );
          }).where((loc) => loc.latitude != 0.0 && loc.longitude != 0.0).toList();

          if (list.isNotEmpty) return list;
        }
      }
    } catch (e) {
      debugPrint('[LocationService] Open-Meteo geocoding error: $e');
    }

    // 3. Secondary: Photon Komoot Geocoder (High quality OSM search)
    try {
      final uri = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(trimmed)}&limit=10',
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['features'] is List) {
          final List features = data['features'];
          final list = features.map((f) {
            final props = f['properties'] as Map<String, dynamic>? ?? {};
            final geom = f['geometry'] as Map<String, dynamic>? ?? {};
            final coords = geom['coordinates'] as List? ?? [0.0, 0.0];
            final name = props['name']?.toString() ?? props['city']?.toString() ?? 'Unknown';
            final state = props['state']?.toString();
            final country = props['country']?.toString() ?? '';
            final lon = coords.isNotEmpty ? (double.tryParse(coords[0].toString()) ?? 0.0) : 0.0;
            final lat = coords.length > 1 ? (double.tryParse(coords[1].toString()) ?? 0.0) : 0.0;
            return WeatherLocation(
              name: name,
              state: state,
              country: country,
              latitude: lat,
              longitude: lon,
            );
          }).where((loc) => loc.latitude != 0.0 && loc.longitude != 0.0).toList();

          if (list.isNotEmpty) return list;
        }
      }
    } catch (e) {
      debugPrint('[LocationService] Photon geocoding error: $e');
    }

    // 4. Tertiary: Instant Local Curated Database Filter
    final localMatches = _curatedCities.where((c) {
      final q = trimmed.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          (c.state?.toLowerCase().contains(q) ?? false) ||
          c.country.toLowerCase().contains(q);
    }).toList();

    if (localMatches.isNotEmpty) return localMatches;

    // 5. Quaternary: OpenStreetMap Nominatim
    try {
      final uri = Uri.parse(
        '${ApiConstants.nominatimSearchUrl}?format=json&q=${Uri.encodeComponent(trimmed)}&limit=8&addressdetails=1',
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json', 'User-Agent': 'WeatherGPT-Flutter/2.0'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body) as List;
        return data.map((item) {
          final addr = item['address'] as Map<String, dynamic>? ?? {};
          final name = addr['city'] ??
              addr['town'] ??
              addr['village'] ??
              addr['municipality'] ??
              addr['county'] ??
              item['display_name']?.toString().split(',').first.trim() ??
              'Unknown';
          final state = addr['state'] ?? addr['state_district'];
          final country = addr['country'] ?? '';

          return WeatherLocation(
            name: name.toString(),
            state: state?.toString(),
            country: country.toString(),
            latitude: double.tryParse(item['lat'].toString()) ?? 0.0,
            longitude: double.tryParse(item['lon'].toString()) ?? 0.0,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('[LocationService] searchLocations error: $e');
    }

    return [];
  }

  /// Reverse geocode coordinates to human-readable city name with dual-provider fallback
  static Future<WeatherLocation?> reverseGeocode(double lat, double lon) async {
    // 1. Try OpenStreetMap Nominatim
    try {
      final uri = Uri.parse(
        '${ApiConstants.nominatimReverseUrl}?format=json&lat=$lat&lon=$lon&zoom=14&addressdetails=1',
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json', 'User-Agent': 'WeatherGPT-Flutter/2.0'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        final name = addr['city'] ??
            addr['town'] ??
            addr['village'] ??
            addr['suburb'] ??
            addr['municipality'] ??
            addr['county'] ??
            data['display_name']?.toString().split(',').first.trim();

        if (name != null && name.toString().isNotEmpty) {
          final state = addr['state'] ?? addr['state_district'];
          final country = addr['country'] ?? '';

          return WeatherLocation(
            name: name.toString(),
            state: state?.toString(),
            country: country.toString(),
            latitude: lat,
            longitude: lon,
          );
        }
      }
    } catch (e) {
      debugPrint('[LocationService] Nominatim reverseGeocode error: $e');
    }

    // 2. Try BigDataCloud Reverse Geocode Client (fast, unthrottled global fallback)
    try {
      final bdcUri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lon&localityLanguage=en',
      );
      final bdcRes = await http.get(bdcUri).timeout(const Duration(seconds: 4));
      if (bdcRes.statusCode == 200) {
        final data = jsonDecode(bdcRes.body) as Map<String, dynamic>;
        final city = data['city']?.toString() ??
            data['locality']?.toString() ??
            data['principalSubdivision']?.toString() ??
            '';
        final state = data['principalSubdivision']?.toString();
        final country = data['countryName']?.toString() ?? '';
        if (city.isNotEmpty) {
          return WeatherLocation(
            name: city,
            state: state,
            country: country,
            latitude: lat,
            longitude: lon,
          );
        }
      }
    } catch (e) {
      debugPrint('[LocationService] BigDataCloud reverseGeocode error: $e');
    }

    // 3. Fallback: return formatted coordinates location
    return WeatherLocation(
      name: '${lat.toStringAsFixed(2)}°, ${lon.toStringAsFixed(2)}°',
      country: '',
      latitude: lat,
      longitude: lon,
    );
  }
}
