import 'package:latlong2/latlong.dart';

class RouteWeatherCondition {
  final String text;
  final String icon;
  final int code;

  const RouteWeatherCondition({
    required this.text,
    required this.icon,
    required this.code,
  });

  factory RouteWeatherCondition.fromJson(Map<String, dynamic> json) {
    return RouteWeatherCondition(
      text: json['text']?.toString() ?? 'Clear',
      icon: json['icon']?.toString() ?? 'sun',
      code: (json['code'] as num?)?.toInt() ?? 1000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'icon': icon,
      'code': code,
    };
  }
}

class RouteWeatherInfo {
  final double tempC;
  final double temperatureC;
  final RouteWeatherCondition condition;
  final int weatherCode;
  final double windKph;
  final double windSpeedKph;
  final int windDirection;
  final int humidity;
  final double feelslikeC;
  final double uv;
  final double uvIndex;
  final double visibilityKm;
  final int pressureMb;
  final double precipMm;
  final double precipitationMm;
  final int rainProbability;

  const RouteWeatherInfo({
    required this.tempC,
    required this.temperatureC,
    required this.condition,
    required this.weatherCode,
    required this.windKph,
    required this.windSpeedKph,
    required this.windDirection,
    required this.humidity,
    required this.feelslikeC,
    required this.uv,
    required this.uvIndex,
    required this.visibilityKm,
    required this.pressureMb,
    required this.precipMm,
    required this.precipitationMm,
    required this.rainProbability,
  });

  factory RouteWeatherInfo.fromJson(Map<String, dynamic> json) {
    final condJson = json['condition'] as Map<String, dynamic>? ?? {};
    final tC = (json['temperature_c'] ?? json['temp_c'] ?? 25.0) as num;
    final wKph = (json['wind_speed_kph'] ?? json['wind_kph'] ?? 10.0) as num;
    final uvVal = (json['uv_index'] ?? json['uv'] ?? 0.0) as num;
    final prMm = (json['precipitation_mm'] ?? json['precip_mm'] ?? 0.0) as num;

    return RouteWeatherInfo(
      tempC: tC.toDouble(),
      temperatureC: tC.toDouble(),
      condition: RouteWeatherCondition.fromJson(condJson),
      weatherCode: (json['weather_code'] as num?)?.toInt() ?? 1000,
      windKph: wKph.toDouble(),
      windSpeedKph: wKph.toDouble(),
      windDirection: (json['wind_direction'] as num?)?.toInt() ?? 0,
      humidity: (json['humidity'] as num?)?.toInt() ?? 50,
      feelslikeC: ((json['feelslike_c'] ?? tC) as num).toDouble(),
      uv: uvVal.toDouble(),
      uvIndex: uvVal.toDouble(),
      visibilityKm: ((json['visibility_km'] ?? 10.0) as num).toDouble(),
      pressureMb: (json['pressure_mb'] as num?)?.toInt() ?? 1013,
      precipMm: prMm.toDouble(),
      precipitationMm: prMm.toDouble(),
      rainProbability: (json['rain_probability'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temp_c': tempC,
      'temperature_c': temperatureC,
      'condition': condition.toJson(),
      'weather_code': weatherCode,
      'wind_kph': windKph,
      'wind_speed_kph': windSpeedKph,
      'wind_direction': windDirection,
      'humidity': humidity,
      'feelslike_c': feelslikeC,
      'uv': uv,
      'uv_index': uvIndex,
      'visibility_km': visibilityKm,
      'pressure_mb': pressureMb,
      'precip_mm': precipMm,
      'precipitation_mm': precipitationMm,
      'rain_probability': rainProbability,
    };
  }
}

class RoutePlace {
  final String name;
  final String type; // 'source' | 'destination' | 'route_place'
  final double latitude;
  final double longitude;
  final double distanceFromStartKm;
  final DateTime estimatedArrival;
  final RouteWeatherInfo weather;

  const RoutePlace({
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.distanceFromStartKm,
    required this.estimatedArrival,
    required this.weather,
  });

  LatLng get coordinates => LatLng(latitude, longitude);

  factory RoutePlace.fromJson(Map<String, dynamic> json) {
    return RoutePlace(
      name: json['name']?.toString() ?? 'Unknown Place',
      type: json['type']?.toString() ?? 'route_place',
      latitude: ((json['latitude'] ?? 0.0) as num).toDouble(),
      longitude: ((json['longitude'] ?? 0.0) as num).toDouble(),
      distanceFromStartKm: ((json['distance_from_start_km'] ?? 0.0) as num).toDouble(),
      estimatedArrival: json['estimated_arrival'] != null
          ? DateTime.tryParse(json['estimated_arrival'].toString()) ?? DateTime.now()
          : DateTime.now(),
      weather: RouteWeatherInfo.fromJson(json['weather'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'distance_from_start_km': distanceFromStartKm,
      'estimated_arrival': estimatedArrival.toIso8601String(),
      'weather': weather.toJson(),
    };
  }
}

class RouteWeatherAlert {
  final String type;
  final String title;
  final String place;
  final DateTime? startTime;
  final DateTime? endTime;
  final String severity;
  final String description;

  const RouteWeatherAlert({
    required this.type,
    required this.title,
    required this.place,
    this.startTime,
    this.endTime,
    required this.severity,
    required this.description,
  });

  factory RouteWeatherAlert.fromJson(Map<String, dynamic> json) {
    return RouteWeatherAlert(
      type: json['type']?.toString() ?? 'alert',
      title: json['title']?.toString() ?? 'Weather Alert',
      place: json['place']?.toString() ?? '',
      startTime: json['startTime'] != null ? DateTime.tryParse(json['startTime'].toString()) : null,
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime'].toString()) : null,
      severity: json['severity']?.toString() ?? 'Warning',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'place': place,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'severity': severity,
      'description': description,
    };
  }
}

class RoutePlan {
  final String source;
  final String destination;
  final double totalDistanceKm;
  final int totalDurationMinutes;
  final DateTime? departureTime;
  final LatLng? sourceCoord;
  final LatLng? destCoord;
  final List<LatLng> polylinePoints;
  final List<RoutePlace> places;
  final List<RouteWeatherAlert> alerts;

  const RoutePlan({
    required this.source,
    required this.destination,
    required this.totalDistanceKm,
    required this.totalDurationMinutes,
    this.departureTime,
    this.sourceCoord,
    this.destCoord,
    required this.polylinePoints,
    required this.places,
    this.alerts = const [],
  });

  factory RoutePlan.fromApiResponse(Map<String, dynamic> json) {
    final route = json['route'] as Map<String, dynamic>? ?? {};
    final srcObj = route['source'] as Map<String, dynamic>? ?? {};
    final dstObj = route['destination'] as Map<String, dynamic>? ?? {};

    final srcName = srcObj['name']?.toString() ?? 'Source';
    final dstName = dstObj['name']?.toString() ?? 'Destination';

    final srcCoord = (srcObj['latitude'] != null && srcObj['longitude'] != null)
        ? LatLng((srcObj['latitude'] as num).toDouble(), (srcObj['longitude'] as num).toDouble())
        : null;
    final dstCoord = (dstObj['latitude'] != null && dstObj['longitude'] != null)
        ? LatLng((dstObj['latitude'] as num).toDouble(), (dstObj['longitude'] as num).toDouble())
        : null;

    final distanceKm = ((route['distance_km'] ?? 0.0) as num).toDouble();
    final durationMin = ((route['duration_minutes'] ?? 0) as num).round();
    final depTime = route['departure_time'] != null
        ? DateTime.tryParse(route['departure_time'].toString())
        : null;

    final rawPlaces = json['places'] as List? ?? [];
    final places = rawPlaces.map((p) => RoutePlace.fromJson(p as Map<String, dynamic>)).toList();

    final rawAlerts = json['alerts'] as List? ?? [];
    final alerts = rawAlerts.map((a) => RouteWeatherAlert.fromJson(a as Map<String, dynamic>)).toList();

    final polyline = places.map((p) => p.coordinates).toList();

    return RoutePlan(
      source: srcName,
      destination: dstName,
      totalDistanceKm: distanceKm,
      totalDurationMinutes: durationMin,
      departureTime: depTime,
      sourceCoord: srcCoord,
      destCoord: dstCoord,
      polylinePoints: polyline,
      places: places,
      alerts: alerts,
    );
  }

  RoutePlan copyWith({
    String? source,
    String? destination,
    double? totalDistanceKm,
    int? totalDurationMinutes,
    DateTime? departureTime,
    LatLng? sourceCoord,
    LatLng? destCoord,
    List<LatLng>? polylinePoints,
    List<RoutePlace>? places,
    List<RouteWeatherAlert>? alerts,
  }) {
    return RoutePlan(
      source: source ?? this.source,
      destination: destination ?? this.destination,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      totalDurationMinutes: totalDurationMinutes ?? this.totalDurationMinutes,
      departureTime: departureTime ?? this.departureTime,
      sourceCoord: sourceCoord ?? this.sourceCoord,
      destCoord: destCoord ?? this.destCoord,
      polylinePoints: polylinePoints ?? this.polylinePoints,
      places: places ?? this.places,
      alerts: alerts ?? this.alerts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'destination': destination,
      'total_distance_km': totalDistanceKm,
      'total_duration_minutes': totalDurationMinutes,
      'departure_time': departureTime?.toIso8601String(),
      'places': places.map((p) => p.toJson()).toList(),
      'alerts': alerts.map((a) => a.toJson()).toList(),
    };
  }
}
