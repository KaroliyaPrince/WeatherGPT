import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../repositories/weather_repository.dart';
import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  final WeatherRepository _repository;

  WeatherLocation _currentLocation = WeatherLocation.defaultLocation;
  List<WeatherLocation> _favorites = [];
  List<WeatherLocation> _recentSearches = [];
  List<WeatherLocation> _searchResults = [];
  bool _isSearching = false;
  bool _isLocating = false;
  String? _locationError;

  LocationProvider(this._repository) {
    _loadStoredData();
  }

  WeatherLocation get currentLocation => _currentLocation;
  List<WeatherLocation> get favorites => _favorites;
  List<WeatherLocation> get recentSearches => _recentSearches;
  List<WeatherLocation> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  bool get isLocating => _isLocating;
  String? get locationError => _locationError;

  bool isLocationFavorite(WeatherLocation loc) {
    return _favorites.any(
      (f) => f.name.toLowerCase() == loc.name.toLowerCase() && f.country.toLowerCase() == loc.country.toLowerCase(),
    );
  }

  void _loadStoredData() {
    _favorites = _repository.getFavorites();
    _recentSearches = _repository.getRecentSearches();
    notifyListeners();
  }

  void selectLocation(WeatherLocation location) {
    _currentLocation = location;
    _repository.addRecentSearch(location);
    _recentSearches = _repository.getRecentSearches();
    _searchResults = [];
    notifyListeners();
  }

  Future<void> searchLocations(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _locationError = null;
    notifyListeners();

    try {
      _searchResults = await LocationService.searchLocations(query);
    } catch (e) {
      _locationError = 'Search failed. Please try again.';
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<bool> detectCurrentGPSLocation() async {
    _isLocating = true;
    _locationError = null;
    notifyListeners();

    try {
      final pos = await LocationService.getCurrentPosition();
      if (pos != null) {
        final reversed = await LocationService.reverseGeocode(pos.latitude, pos.longitude);
        final loc = reversed ??
            WeatherLocation(
              name: '${pos.latitude.toStringAsFixed(2)}°, ${pos.longitude.toStringAsFixed(2)}°',
              country: '',
              latitude: pos.latitude,
              longitude: pos.longitude,
            );
        selectLocation(loc);
        _isLocating = false;
        notifyListeners();
        return true;
      } else {
        _locationError = 'Location permission denied or GPS turned off.';
      }
    } catch (_) {
      _locationError = 'Failed to retrieve GPS location.';
    } finally {
      _isLocating = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> toggleFavorite(WeatherLocation location) async {
    final index = _favorites.indexWhere(
      (f) => f.name.toLowerCase() == location.name.toLowerCase() && f.country.toLowerCase() == location.country.toLowerCase(),
    );

    if (index >= 0) {
      _favorites.removeAt(index);
    } else {
      _favorites.add(location.copyWith(isFavorite: true));
    }

    await _repository.saveFavorites(_favorites);
    notifyListeners();
  }

  Future<void> clearRecentSearches() async {
    await _repository.clearRecentSearches();
    _recentSearches = [];
    notifyListeners();
  }

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }
}
