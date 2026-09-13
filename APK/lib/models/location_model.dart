typedef LocationModel = WeatherLocation;

class WeatherLocation {
  final String name;
  final String? state;
  final String country;
  final double latitude;
  final double longitude;
  final bool isFavorite;

  const WeatherLocation({
    required this.name,
    this.state,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.isFavorite = false,
  });

  String get displayName {
    if (state != null && state!.isNotEmpty && state != name) {
      return '$name, $state';
    }
    if (country.isNotEmpty) {
      return '$name, $country';
    }
    return name;
  }

  WeatherLocation copyWith({
    String? name,
    String? state,
    String? country,
    double? latitude,
    double? longitude,
    bool? isFavorite,
  }) {
    return WeatherLocation(
      name: name ?? this.name,
      state: state ?? this.state,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory WeatherLocation.fromJson(Map<String, dynamic> json) {
    return WeatherLocation(
      name: json['name']?.toString() ?? 'Unknown',
      state: json['state']?.toString(),
      country: json['country']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      isFavorite: json['isFavorite'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'state': state,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'isFavorite': isFavorite,
    };
  }

  static const WeatherLocation defaultLocation = WeatherLocation(
    name: 'Rajkot',
    state: 'Gujarat',
    country: 'India',
    latitude: 22.3039,
    longitude: 70.8022,
  );
}
