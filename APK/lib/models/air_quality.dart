class AirQuality {
  final int aqi;
  final String category;
  final num pm2_5;
  final num pm10;
  final num co;
  final num no2;
  final num o3;
  final String healthAdvice;
  final String? badgeColor;

  const AirQuality({
    required this.aqi,
    required this.category,
    required this.pm2_5,
    required this.pm10,
    required this.co,
    required this.no2,
    required this.o3,
    required this.healthAdvice,
    this.badgeColor,
  });

  num get pm25 => pm2_5;
  String get dominantPollutant => pm2_5 > pm10 ? 'PM2.5' : 'PM10';

  factory AirQuality.fromJson(Map<String, dynamic> json) {
    return AirQuality(
      aqi: (json['aqi'] as num?)?.toInt() ?? (json['score'] as num?)?.toInt() ?? 45,
      category: json['category']?.toString() ?? 'Good',
      pm2_5: json['pm2_5'] as num? ?? json['pm25'] as num? ?? 12,
      pm10: json['pm10'] as num? ?? 25,
      co: json['co'] as num? ?? 400,
      no2: json['no2'] as num? ?? 15,
      o3: json['o3'] as num? ?? 35,
      healthAdvice: json['healthAdvice']?.toString() ??
          'Air quality is satisfactory and poses little or no risk.',
      badgeColor: json['badgeColor']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aqi': aqi,
      'category': category,
      'pm2_5': pm2_5,
      'pm10': pm10,
      'co': co,
      'no2': no2,
      'o3': o3,
      'healthAdvice': healthAdvice,
      'badgeColor': badgeColor,
    };
  }
}
