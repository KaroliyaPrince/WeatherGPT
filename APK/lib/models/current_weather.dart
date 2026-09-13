import 'condition_model.dart';

class CurrentWeather {
  final num temperatureC;
  final num feelsLikeC;
  final num humidity;
  final num windKph;
  final String windDirection;
  final num windGustKph;
  final num pressureMb;
  final num visibilityKm;
  final num cloudCover;
  final num uvIndex;
  final num precipitationProbability;
  final num precipitationIntensity;
  final num rainAccumulationMm;
  final ConditionModel condition;

  const CurrentWeather({
    required this.temperatureC,
    required this.feelsLikeC,
    required this.humidity,
    required this.windKph,
    required this.windDirection,
    required this.windGustKph,
    required this.pressureMb,
    required this.visibilityKm,
    required this.cloudCover,
    required this.uvIndex,
    required this.precipitationProbability,
    required this.precipitationIntensity,
    required this.rainAccumulationMm,
    required this.condition,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperatureC: json['temperature_c'] as num? ??
          json['temp_c'] as num? ??
          json['temperature'] as num? ??
          0,
      feelsLikeC: json['feels_like_c'] as num? ??
          json['feelslike_c'] as num? ??
          json['apparentTemperature'] as num? ??
          0,
      humidity: json['humidity'] as num? ?? 0,
      windKph: json['wind_kph'] as num? ??
          json['windSpeed'] as num? ??
          0,
      windDirection: json['wind_direction']?.toString() ??
          json['windDirection']?.toString() ??
          'N',
      windGustKph: json['wind_gust_kph'] as num? ??
          json['windGust'] as num? ??
          0,
      pressureMb: json['pressure_mb'] as num? ??
          json['pressure'] as num? ??
          1013,
      visibilityKm: json['visibility_km'] as num? ??
          json['visibility'] as num? ??
          10,
      cloudCover: json['cloud_cover'] as num? ??
          json['cloudCover'] as num? ??
          0,
      uvIndex: json['uv_index'] as num? ??
          json['uv'] as num? ??
          json['uvIndex'] as num? ??
          0,
      precipitationProbability: json['precipitation_probability'] as num? ??
          json['rain_probability'] as num? ??
          json['rainProbability'] as num? ??
          0,
      precipitationIntensity: json['precipitation_intensity'] as num? ?? 0,
      rainAccumulationMm: json['rain_accumulation_mm'] as num? ?? 0,
      condition: ConditionModel.fromJson(json['condition']),
    );
  }

  Map<String, dynamic> toJson() => {
        'temperature_c': temperatureC,
        'feels_like_c': feelsLikeC,
        'humidity': humidity,
        'wind_kph': windKph,
        'wind_direction': windDirection,
        'wind_gust_kph': windGustKph,
        'pressure_mb': pressureMb,
        'visibility_km': visibilityKm,
        'cloud_cover': cloudCover,
        'uv_index': uvIndex,
        'precipitation_probability': precipitationProbability,
        'precipitation_intensity': precipitationIntensity,
        'rain_accumulation_mm': rainAccumulationMm,
        'condition': condition.toJson(),
      };
}
