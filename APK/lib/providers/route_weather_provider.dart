import 'package:flutter/material.dart';
import '../models/route_weather_model.dart';
import '../services/route_weather_service.dart';

class RouteWeatherProvider extends ChangeNotifier {
  final RouteWeatherService _service;

  String _source = 'Rajkot';
  String _destination = 'Ahmedabad';
  bool _isLoading = false;
  String? _error;
  RoutePlan? _routePlan;
  RoutePlace? _selectedPlace;
  bool _isRouteModeActive = false;

  RouteWeatherProvider(this._service);

  String get source => _source;
  String get destination => _destination;
  bool get isLoading => _isLoading;
  String? get error => _error;
  RoutePlan? get routePlan => _routePlan;
  RoutePlace? get selectedPlace => _selectedPlace;
  bool get isRouteModeActive => _isRouteModeActive;

  void setRouteMode(bool active) {
    _isRouteModeActive = active;
    notifyListeners();
    if (active && _routePlan == null) {
      calculateRoute();
    }
  }

  void toggleRouteMode() {
    setRouteMode(!_isRouteModeActive);
  }

  void setSource(String s) {
    _source = s;
    notifyListeners();
  }

  void setDestination(String d) {
    _destination = d;
    notifyListeners();
  }

  void swapSourceAndDestination() {
    final temp = _source;
    _source = _destination;
    _destination = temp;
    notifyListeners();
    calculateRoute();
  }

  void selectPlace(RoutePlace? place) {
    _selectedPlace = place;
    notifyListeners();
  }

  Future<void> calculateRoute({String? sourceOverride, String? destOverride}) async {
    if (sourceOverride != null) _source = sourceOverride;
    if (destOverride != null) _destination = destOverride;

    if (_source.trim().isEmpty || _destination.trim().isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final plan = await _service.getRouteWeather(
        source: _source.trim(),
        destination: _destination.trim(),
      );
      _routePlan = plan;
      if (plan.places.isNotEmpty) {
        _selectedPlace = plan.places.first;
      }
    } catch (e) {
      _error = 'Unable to calculate route weather: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
