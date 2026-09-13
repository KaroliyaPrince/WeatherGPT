import '../models/location_model.dart';
import '../models/past_day_weather.dart';
import '../models/weather_data.dart';
import '../services/storage_service.dart';
import '../services/weather_api_service.dart';

class WeatherRepository {
  final WeatherApiService apiService;
  final StorageService storageService;

  WeatherRepository({
    required this.apiService,
    required this.storageService,
  });

  WeatherData? getCachedWeather() {
    return storageService.getCachedWeather();
  }

  /// Fetch weather with offline caching strategy
  Future<WeatherData> getWeather({
    WeatherLocation? location,
    String language = 'en',
    bool forceRefresh = false,
  }) async {
    final targetLoc = location ?? WeatherLocation.defaultLocation;

    try {
      final freshData = await apiService.fetchWeather(
        latitude: targetLoc.latitude,
        longitude: targetLoc.longitude,
        cityName: targetLoc.name,
        language: language,
      );

      // Save to local cache on success
      await storageService.saveCachedWeather(freshData);
      return freshData;
    } catch (e) {
      // If network fails, return offline cached data if available
      final cached = storageService.getCachedWeather();
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  /// Fetch past 7 days historical weather
  Future<List<PastDayWeather>> getPast7DaysWeather({
    WeatherLocation? location,
  }) async {
    final targetLoc = location ?? WeatherLocation.defaultLocation;
    return await apiService.fetchPast7DaysWeather(
      latitude: targetLoc.latitude,
      longitude: targetLoc.longitude,
    );
  }

  /// Get saved favorite locations
  List<WeatherLocation> getFavorites() {
    return storageService.getFavorites();
  }

  /// Save or update favorite locations
  Future<void> saveFavorites(List<WeatherLocation> favorites) async {
    await storageService.saveFavorites(favorites);
  }

  /// Get recent searches
  List<WeatherLocation> getRecentSearches() {
    return storageService.getRecentSearches();
  }

  /// Add to recent searches
  Future<void> addRecentSearch(WeatherLocation location) async {
    final recents = storageService.getRecentSearches();
    recents.removeWhere((loc) => loc.name.toLowerCase() == location.name.toLowerCase());
    recents.insert(0, location);
    if (recents.length > 10) recents.removeLast();
    await storageService.saveRecentSearches(recents);
  }

  Future<void> clearRecentSearches() async {
    await storageService.clearRecentSearches();
  }
}
