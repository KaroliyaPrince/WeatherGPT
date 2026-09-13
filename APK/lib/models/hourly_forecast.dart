class HourlyForecast {
  final String hourLabel;
  final num temperature;
  final num apparentTemperature;
  final String conditionEmoji;
  final num rainProbability;
  final num humidity;
  final num windSpeed;
  final String riskLevel;

  const HourlyForecast({
    required this.hourLabel,
    required this.temperature,
    required this.apparentTemperature,
    required this.conditionEmoji,
    required this.rainProbability,
    required this.humidity,
    required this.windSpeed,
    required this.riskLevel,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    String label = json['hourLabel']?.toString() ?? '';
    if (label.isEmpty && json['time'] != null) {
      final rawTime = json['time'].toString();
      try {
        final dt = DateTime.parse(rawTime).toLocal();
        final hour = dt.hour;
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        label = '$displayHour $period';
      } catch (_) {
        label = rawTime;
      }
    }

    String emoji = json['conditionEmoji']?.toString() ?? '';
    if (emoji.isEmpty && json['condition'] != null) {
      final condText = json['condition'] is Map
          ? (json['condition']['text']?.toString() ?? '')
          : json['condition'].toString();
      final lower = condText.toLowerCase();
      if (lower.contains('rain') || lower.contains('shower')) {
        emoji = '🌧️';
      } else if (lower.contains('thunder') || lower.contains('storm')) {
        emoji = '⛈️';
      } else if (lower.contains('snow')) {
        emoji = '❄️';
      } else if (lower.contains('cloud')) {
        emoji = '☁️';
      } else {
        emoji = '☀️';
      }
    }
    if (emoji.isEmpty) emoji = '☀️';

    return HourlyForecast(
      hourLabel: label.isEmpty ? 'Now' : label,
      temperature: json['temperature'] as num? ??
          json['temperature_c'] as num? ??
          json['temp_c'] as num? ??
          0,
      apparentTemperature: json['apparentTemperature'] as num? ??
          json['feels_like_c'] as num? ??
          json['feelslike_c'] as num? ??
          0,
      conditionEmoji: emoji,
      rainProbability: json['rainProbability'] as num? ??
          json['precipitation_probability'] as num? ??
          json['chance_of_rain'] as num? ??
          0,
      humidity: json['humidity'] as num? ?? 0,
      windSpeed: json['windSpeed'] as num? ?? json['wind_kph'] as num? ?? 0,
      riskLevel: json['riskLevel']?.toString() ?? 'safe',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hourLabel': hourLabel,
      'temperature': temperature,
      'apparentTemperature': apparentTemperature,
      'conditionEmoji': conditionEmoji,
      'rainProbability': rainProbability,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'riskLevel': riskLevel,
    };
  }
}
