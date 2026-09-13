import 'package:flutter/material.dart';
import '../core/network/api_exceptions.dart';
import '../models/location_model.dart';
import '../models/past_day_weather.dart';
import '../models/weather_data.dart';
import '../repositories/weather_repository.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherRepository _repository;

  WeatherData? _weatherData;
  List<PastDayWeather> _past7Days = [];
  bool _isLoading = false;
  bool _isLoadingPast7Days = false;
  String? _errorMessage;
  bool _isOffline = false;

  WeatherProvider(this._repository) {
    // Load initial cached weather if available
    _weatherData = _repository.getCachedWeather();
  }

  WeatherData? get weatherData => _weatherData;
  List<PastDayWeather> get past7Days => _past7Days;
  bool get isLoading => _isLoading;
  bool get isLoadingPast7Days => _isLoadingPast7Days;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;

  Future<void> fetchPast7Days({WeatherLocation? location}) async {
    _isLoadingPast7Days = true;
    notifyListeners();
    try {
      final list = await _repository.getPast7DaysWeather(location: location);
      _past7Days = list;
    } catch (_) {
      // Keep existing
    } finally {
      _isLoadingPast7Days = false;
      notifyListeners();
    }
  }

  Future<void> fetchWeather({
    WeatherLocation? location,
    String language = 'en',
    bool forceRefresh = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Concurrently fetch past 7 days weather
    fetchPast7Days(location: location);

    try {
      final data = await _repository.getWeather(
        location: location,
        language: language,
        forceRefresh: forceRefresh,
      );

      _weatherData = data;
      _isOffline = false;
      _errorMessage = null;
    } on InvalidLocationException catch (e) {
      _errorMessage = e.message;
    } on NoInternetException catch (e) {
      if (_weatherData != null) {
        _isOffline = true;
      } else {
        _errorMessage = e.message;
      }
    } on TimeoutApiException catch (e) {
      if (_weatherData != null) {
        _isOffline = true;
      } else {
        _errorMessage = e.message;
      }
    } catch (e) {
      if (_weatherData != null) {
        _isOffline = true;
      } else {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh({WeatherLocation? location, String language = 'en'}) async {
    await fetchWeather(
      location: location,
      language: language,
      forceRefresh: true,
    );
  }
}
