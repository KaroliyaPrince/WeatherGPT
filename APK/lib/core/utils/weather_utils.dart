class WeatherUtils {
  // Convert Celsius to Fahrenheit
  static double cToF(double celsius) {
    return (celsius * 9 / 5) + 32;
  }

  // Format temperature according to isFahrenheit setting
  static String formatTemp(num? celsius, {required bool isFahrenheit, bool showUnit = false}) {
    if (celsius == null) return '--';
    final val = isFahrenheit ? cToF(celsius.toDouble()) : celsius.toDouble();
    final unit = showUnit ? (isFahrenheit ? '°F' : '°C') : '°';
    return '${val.round()}$unit';
  }

  // UV Index categorization
  static String getUvCategory(num? uv) {
    if (uv == null) return 'Low';
    if (uv <= 2) return 'Low';
    if (uv <= 5) return 'Moderate';
    if (uv <= 7) return 'High';
    if (uv <= 10) return 'Very High';
    return 'Extreme';
  }

  // Humidity status
  static String getHumidityStatus(num? humidity) {
    if (humidity == null) return 'Comfortable';
    if (humidity < 30) return 'Dry air';
    if (humidity <= 60) return 'Pleasant';
    if (humidity <= 80) return 'Humid';
    return 'Very humid';
  }

  // Visibility status
  static String getVisibilityStatus(num? visibilityKm) {
    if (visibilityKm == null) return 'Good';
    if (visibilityKm >= 10) return 'Clear';
    if (visibilityKm >= 5) return 'Moderate';
    return 'Low visibility';
  }

  // Pressure status
  static String getPressureStatus(num? pressureMb) {
    if (pressureMb == null) return 'Normal';
    if (pressureMb > 1015) return 'High';
    if (pressureMb < 1005) return 'Low';
    return 'Normal';
  }
}
