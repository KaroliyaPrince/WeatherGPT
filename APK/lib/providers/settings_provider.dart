import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService;

  late bool _isFahrenheit;
  late String _language;

  SettingsProvider(this._storageService) {
    _isFahrenheit = _storageService.isFahrenheit;
    _language = _storageService.language;
  }

  bool get isFahrenheit => _isFahrenheit;

  ThemeMode get themeMode => ThemeMode.dark;

  String get themeModeString => 'dark';
  String get language => _language;

  Future<void> toggleTemperatureUnit() async {
    _isFahrenheit = !_isFahrenheit;
    await _storageService.setFahrenheit(_isFahrenheit);
    notifyListeners();
  }

  Future<void> setFahrenheit(bool value) async {
    _isFahrenheit = value;
    await _storageService.setFahrenheit(value);
    notifyListeners();
  }

  Future<void> setThemeMode(String mode) async {
    await _storageService.setThemeMode('dark');
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _storageService.setLanguage(lang);
    notifyListeners();
  }
}
