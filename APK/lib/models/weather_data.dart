import 'location_model.dart';
import 'hourly_forecast.dart';
import 'daily_forecast.dart';
import 'air_quality.dart';
import 'condition_model.dart';
import 'current_weather.dart';

class WeatherData {
  final WeatherLocation location;
  final CurrentWeather? currentWeather;
  final num temperature;
  final num apparentTemperature;
  final String condition;
  final num humidity;
  final num windSpeed;
  final String windDirection;
  final num pressure;
  final num visibility;
  final num uvIndex;
  final num cloudCover;
  final num rainProbability;
  final num tempMax;
  final num tempMin;
  final String sunrise;
  final String sunset;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> forecast;
  final AirQuality? airQuality;
  final List<String> disasterAlerts;
  final dynamic explainWhy;
  final DateTime updatedAt;

  const WeatherData({
    required this.location,
    this.currentWeather,
    required this.temperature,
    required this.apparentTemperature,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.pressure,
    required this.visibility,
    required this.uvIndex,
    required this.cloudCover,
    required this.rainProbability,
    required this.tempMax,
    required this.tempMin,
    required this.sunrise,
    required this.sunset,
    required this.hourly,
    required this.forecast,
    this.airQuality,
    this.disasterAlerts = const [],
    this.explainWhy,
    required this.updatedAt,
  });

  num get feelsLike => apparentTemperature;
  num get windGust => currentWeather?.windGustKph ?? 0;
  ConditionModel get conditionModel => currentWeather?.condition ?? ConditionModel.fromJson(condition);

  factory WeatherData.fromApiResponse(Map<String, dynamic> json) {
    // 1. Parse location
    final locJson = json['location'] as Map<String, dynamic>? ?? {};
    final location = WeatherLocation(
      name: locJson['name']?.toString() ?? 'Rajkot',
      state: locJson['state']?.toString() ?? locJson['region']?.toString(),
      country: locJson['country']?.toString() ?? 'India',
      latitude: (locJson['latitude'] as num?)?.toDouble() ?? (locJson['lat'] as num?)?.toDouble() ?? 22.3039,
      longitude: (locJson['longitude'] as num?)?.toDouble() ?? (locJson['lon'] as num?)?.toDouble() ?? 70.8022,
    );

    // 2. Parse current weather
    final wJson = json['weather'] as Map<String, dynamic>? ?? {};
    final current = json['current'] as Map<String, dynamic>? ?? {};
    final currentObj = current.isNotEmpty ? CurrentWeather.fromJson(current) : null;

    final temp = current['temperature_c'] as num? ??
        current['temp_c'] as num? ??
        wJson['temperature'] as num? ??
        wJson['temp_c'] as num? ??
        28;

    final apparent = current['feels_like_c'] as num? ??
        current['feelslike_c'] as num? ??
        wJson['apparentTemperature'] as num? ??
        wJson['feelslike_c'] as num? ??
        (temp + 2);

    final condition = current['condition'] is Map
        ? (current['condition']['text']?.toString() ?? 'Partly cloudy')
        : (current['condition']?.toString() ??
            wJson['condition']?.toString() ??
            'Partly cloudy');

    final humidity = current['humidity'] as num? ?? wJson['humidity'] as num? ?? 58;
    final wind = current['wind_kph'] as num? ?? wJson['windSpeed'] as num? ?? 14;
    final windDir = current['wind_direction'] != null
        ? '${current['wind_direction']}°'
        : (wJson['windDirection']?.toString() ?? 'NW');
    final pressure = current['pressure_mb'] as num? ?? wJson['pressure'] as num? ?? 1012;
    final visibility = current['visibility_km'] as num? ?? wJson['visibility'] as num? ?? 10;
    final uv = current['uv_index'] as num? ?? current['uv'] as num? ?? wJson['uvIndex'] as num? ?? 5;
    final cloud = current['cloud_cover'] as num? ?? current['cloud'] as num? ?? wJson['cloudCover'] as num? ?? 25;
    final rainProb = current['rain_probability'] as num? ??
        current['precipitation_probability'] as num? ??
        wJson['rain_probability'] as num? ??
        15;
    final maxT = wJson['tempMax'] as num? ?? (temp + 4);
    final minT = wJson['tempMin'] as num? ?? (temp - 4);
    final sunrise = wJson['sunrise']?.toString() ?? '06:15 AM';
    final sunset = wJson['sunset']?.toString() ?? '06:45 PM';

    // 3. Parse hourly
    List<HourlyForecast> hourlyList = [];
    final timelineObj = json['timeline'] as Map<String, dynamic>?;
    if (timelineObj != null && timelineObj['hours'] is List) {
      hourlyList = (timelineObj['hours'] as List)
          .map((h) => HourlyForecast.fromJson(h as Map<String, dynamic>))
          .toList();
    } else if (json['hourly'] is List) {
      hourlyList = (json['hourly'] as List)
          .map((h) => HourlyForecast.fromJson(h as Map<String, dynamic>))
          .toList();
    }

    // Fallback if hourly empty
    if (hourlyList.isEmpty) {
      final now = DateTime.now();
      hourlyList = List.generate(8, (i) {
        final h = now.add(Duration(hours: i * 2));
        final hourStr = i == 0 ? 'Now' : '${h.hour > 12 ? h.hour - 12 : h.hour} ${h.hour >= 12 ? 'PM' : 'AM'}';
        return HourlyForecast(
          hourLabel: hourStr,
          temperature: temp + (i == 1 ? 1 : i == 2 ? 2 : -i),
          apparentTemperature: apparent,
          conditionEmoji: '🌤️',
          rainProbability: (10 + (i * 5)).clamp(0, 100),
          humidity: humidity,
          windSpeed: wind,
          riskLevel: 'safe',
        );
      });
    }

    // 4. Parse 7-day forecast
    List<DailyForecast> dailyList = [];
    if (json['daily'] is List) {
      dailyList = (json['daily'] as List)
          .map((d) => DailyForecast.fromJson(d as Map<String, dynamic>))
          .toList();
    } else if (json['forecast'] is List) {
      dailyList = (json['forecast'] as List)
          .map((d) => DailyForecast.fromJson(d as Map<String, dynamic>))
          .toList();
    }

    if (dailyList.isEmpty) {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      dailyList = List.generate(7, (i) {
        return DailyForecast(
          day: i == 0 ? 'Today' : days[(DateTime.now().weekday - 1 + i) % 7],
          date: '',
          maxTemp: maxT + (i % 2 == 0 ? 1 : -1),
          minTemp: minT + (i % 2 == 0 ? 0 : -1),
          condition: i % 3 == 0 ? 'Partly cloudy' : 'Sunny',
          rainProbability: i == 1 ? 40 : 15,
        );
      });
    }

    // 5. Parse Air Quality
    AirQuality? aqi;
    if (json['airQuality'] is Map<String, dynamic>) {
      aqi = AirQuality.fromJson(json['airQuality'] as Map<String, dynamic>);
    }

    // 6. Disaster alerts
    List<String> alerts = [];
    if (json['disasterAlerts'] is List) {
      alerts = (json['disasterAlerts'] as List)
          .map((a) => a is Map ? (a['title'] ?? a['description'] ?? '').toString() : a.toString())
          .where((a) => a.isNotEmpty)
          .toList();
    }

    final actualMaxT = dailyList.isNotEmpty ? dailyList.first.maxTemp : maxT;
    final actualMinT = dailyList.isNotEmpty ? dailyList.first.minTemp : minT;

    return WeatherData(
      location: location,
      currentWeather: currentObj,
      temperature: temp,
      apparentTemperature: apparent,
      condition: condition,
      humidity: humidity,
      windSpeed: wind,
      windDirection: windDir,
      pressure: pressure,
      visibility: visibility,
      uvIndex: uv,
      cloudCover: cloud,
      rainProbability: rainProb,
      tempMax: actualMaxT,
      tempMin: actualMinT,
      sunrise: sunrise,
      sunset: sunset,
      hourly: hourlyList,
      forecast: dailyList,
      airQuality: aqi,
      disasterAlerts: alerts,
      explainWhy: json['explainWhy'],
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location.toJson(),
      'weather': {
        'temperature': temperature,
        'apparentTemperature': apparentTemperature,
        'condition': condition,
        'humidity': humidity,
        'windSpeed': windSpeed,
        'windDirection': windDirection,
        'pressure': pressure,
        'visibility': visibility,
        'uvIndex': uvIndex,
        'cloudCover': cloudCover,
        'rain_probability': rainProbability,
        'tempMax': tempMax,
        'tempMin': tempMin,
        'sunrise': sunrise,
        'sunset': sunset,
      },
      'timeline': {
        'hours': hourly.map((h) => h.toJson()).toList(),
      },
      'forecast': forecast.map((f) => f.toJson()).toList(),
      'airQuality': airQuality?.toJson(),
      'disasterAlerts': disasterAlerts,
      'explainWhy': explainWhy,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
