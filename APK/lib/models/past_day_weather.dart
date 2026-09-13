import 'package:intl/intl.dart';

class PastDayWeather {
  final String date;
  final DateTime dateTime;
  final String dayLabel;
  final String formattedDate;
  final num maxTemp;
  final num minTemp;
  final num precipitationMm;
  final num windSpeedKph;
  final int weatherCode;
  final String condition;
  final String conditionEmoji;

  const PastDayWeather({
    required this.date,
    required this.dateTime,
    required this.dayLabel,
    required this.formattedDate,
    required this.maxTemp,
    required this.minTemp,
    required this.precipitationMm,
    required this.windSpeedKph,
    required this.weatherCode,
    required this.condition,
    required this.conditionEmoji,
  });

  factory PastDayWeather.fromOpenMeteo({
    required String dateStr,
    required num maxTemp,
    required num minTemp,
    required int weatherCode,
    required num precipitation,
    required num windSpeed,
  }) {
    DateTime dt;
    try {
      dt = DateTime.parse(dateStr);
    } catch (_) {
      dt = DateTime.now();
    }

    final now = DateTime.now();
    final difference = DateTime(now.year, now.month, now.day)
        .difference(DateTime(dt.year, dt.month, dt.day))
        .inDays;

    String label;
    if (difference == 1) {
      label = 'Yesterday';
    } else {
      label = DateFormat('EEE').format(dt);
    }

    final formatted = DateFormat('d MMM').format(dt);
    final cond = wmoCodeToCondition(weatherCode);
    final emoji = wmoCodeToEmoji(weatherCode);

    return PastDayWeather(
      date: dateStr,
      dateTime: dt,
      dayLabel: label,
      formattedDate: formatted,
      maxTemp: maxTemp,
      minTemp: minTemp,
      precipitationMm: precipitation,
      windSpeedKph: windSpeed,
      weatherCode: weatherCode,
      condition: cond,
      conditionEmoji: emoji,
    );
  }

  factory PastDayWeather.fromJson(Map<String, dynamic> json) {
    DateTime dt;
    try {
      dt = DateTime.parse(json['date']?.toString() ?? '');
    } catch (_) {
      dt = DateTime.now();
    }

    return PastDayWeather(
      date: json['date']?.toString() ?? '',
      dateTime: dt,
      dayLabel: json['dayLabel']?.toString() ?? '',
      formattedDate: json['formattedDate']?.toString() ?? '',
      maxTemp: json['maxTemp'] as num? ?? 0,
      minTemp: json['minTemp'] as num? ?? 0,
      precipitationMm: json['precipitationMm'] as num? ?? 0,
      windSpeedKph: json['windSpeedKph'] as num? ?? 0,
      weatherCode: json['weatherCode'] as int? ?? 0,
      condition: json['condition']?.toString() ?? 'Partly Cloudy',
      conditionEmoji: json['conditionEmoji']?.toString() ?? '🌤️',
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'dayLabel': dayLabel,
        'formattedDate': formattedDate,
        'maxTemp': maxTemp,
        'minTemp': minTemp,
        'precipitationMm': precipitationMm,
        'windSpeedKph': windSpeedKph,
        'weatherCode': weatherCode,
        'condition': condition,
        'conditionEmoji': conditionEmoji,
      };

  static String wmoCodeToCondition(int code) {
    switch (code) {
      case 0:
        return 'Clear Sky';
      case 1:
        return 'Mainly Clear';
      case 2:
        return 'Partly Cloudy';
      case 3:
        return 'Overcast';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
        return 'Light Drizzle';
      case 53:
        return 'Moderate Drizzle';
      case 55:
        return 'Dense Drizzle';
      case 61:
        return 'Light Rain';
      case 63:
        return 'Moderate Rain';
      case 65:
        return 'Heavy Rain';
      case 80:
      case 81:
      case 82:
        return 'Rain Showers';
      case 95:
      case 96:
      case 99:
        return 'Thunderstorm';
      default:
        return 'Partly Cloudy';
    }
  }

  static String wmoCodeToEmoji(int code) {
    switch (code) {
      case 0:
        return '☀️';
      case 1:
      case 2:
        return '🌤️';
      case 3:
        return '☁️';
      case 45:
      case 48:
        return '🌫️';
      case 51:
      case 53:
      case 55:
        return '🌦️';
      case 61:
      case 63:
        return '🌧️';
      case 65:
        return '⛈️';
      case 80:
      case 81:
      case 82:
        return '🌧️';
      case 95:
      case 96:
      case 99:
        return '⛈️';
      default:
        return '🌤️';
    }
  }
}
