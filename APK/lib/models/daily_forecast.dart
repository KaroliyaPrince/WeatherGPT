class DailyForecast {
  final String day;
  final String date;
  final num maxTemp;
  final num minTemp;
  final String condition;
  final num rainProbability;
  final num? humidity;
  final num? windSpeed;
  final String? sunrise;
  final String? sunset;

  const DailyForecast({
    required this.day,
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.condition,
    required this.rainProbability,
    this.humidity,
    this.windSpeed,
    this.sunrise,
    this.sunset,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    String dayName = json['day']?.toString() ?? '';
    final dateStr = json['date']?.toString() ?? '';
    if (dayName.isEmpty && dateStr.isNotEmpty) {
      try {
        final dt = DateTime.parse(dateStr);
        final now = DateTime.now();
        if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
          dayName = 'Today';
        } else {
          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          dayName = days[dt.weekday - 1];
        }
      } catch (_) {
        dayName = dateStr;
      }
    }

    String condText = 'Sunny';
    if (json['condition'] != null) {
      if (json['condition'] is Map) {
        condText = json['condition']['text']?.toString() ?? 'Sunny';
      } else {
        condText = json['condition'].toString();
      }
    }

    return DailyForecast(
      day: dayName.isEmpty ? 'Today' : dayName,
      date: dateStr,
      maxTemp: json['maxTemp'] as num? ??
          json['max_temp'] as num? ??
          json['temperature_max_c'] as num? ??
          0,
      minTemp: json['minTemp'] as num? ??
          json['min_temp'] as num? ??
          json['temperature_min_c'] as num? ??
          0,
      condition: condText,
      rainProbability: json['rainProbability'] as num? ??
          json['precipitation_probability'] as num? ??
          json['chance_of_rain'] as num? ??
          0,
      humidity: json['humidity'] as num?,
      windSpeed: json['windSpeed'] as num? ?? json['wind_kph'] as num?,
      sunrise: json['sunrise']?.toString(),
      sunset: json['sunset']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'date': date,
      'maxTemp': maxTemp,
      'minTemp': minTemp,
      'condition': condition,
      'rainProbability': rainProbability,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'sunrise': sunrise,
      'sunset': sunset,
    };
  }
}
