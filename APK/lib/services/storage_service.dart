import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_model.dart';
import '../models/weather_data.dart';
import '../models/chat_session.dart';

class StorageService {
  static const String _keyCachedWeather = 'weathergpt_cached_weather';
  static const String _keyFavorites = 'weathergpt_favorite_locations';
  static const String _keyRecents = 'weathergpt_recent_searches';
  static const String _keyIsFahrenheit = 'weathergpt_is_fahrenheit';
  static const String _keyThemeMode = 'weathergpt_theme_mode';
  static const String _keyLanguage = 'weathergpt_language';
  static const String _keyConversationId = 'weathergpt_conversation_id';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- Weather Caching ---
  Future<void> saveCachedWeather(WeatherData data) async {
    final jsonStr = jsonEncode(data.toJson());
    await _prefs.setString(_keyCachedWeather, jsonStr);
  }

  WeatherData? getCachedWeather() {
    final str = _prefs.getString(_keyCachedWeather);
    if (str == null || str.isEmpty) return null;
    try {
      final json = jsonDecode(str) as Map<String, dynamic>;
      return WeatherData.fromApiResponse(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCachedWeather() async {
    await _prefs.remove(_keyCachedWeather);
  }

  // --- Favorite Locations ---
  Future<void> saveFavorites(List<WeatherLocation> favorites) async {
    final list = favorites.map((loc) => jsonEncode(loc.toJson())).toList();
    await _prefs.setStringList(_keyFavorites, list);
  }

  List<WeatherLocation> getFavorites() {
    final list = _prefs.getStringList(_keyFavorites);
    if (list == null) {
      // Default favorites
      return [WeatherLocation.defaultLocation];
    }
    try {
      return list
          .map((item) => WeatherLocation.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [WeatherLocation.defaultLocation];
    }
  }

  // --- Recent Searches ---
  Future<void> saveRecentSearches(List<WeatherLocation> recents) async {
    final list = recents.map((loc) => jsonEncode(loc.toJson())).toList();
    await _prefs.setStringList(_keyRecents, list);
  }

  List<WeatherLocation> getRecentSearches() {
    final list = _prefs.getStringList(_keyRecents);
    if (list == null) return [];
    try {
      return list
          .map((item) => WeatherLocation.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearRecentSearches() async {
    await _prefs.remove(_keyRecents);
  }

  // --- Settings: Temperature Unit ---
  bool get isFahrenheit => _prefs.getBool(_keyIsFahrenheit) ?? false;

  Future<void> setFahrenheit(bool value) async {
    await _prefs.setBool(_keyIsFahrenheit, value);
  }

  // --- Settings: Theme Mode ---
  String get themeMode => _prefs.getString(_keyThemeMode) ?? 'system';

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
  }

  // --- Settings: Language (Default: 'auto') ---
  String get language => _prefs.getString(_keyLanguage) ?? 'auto';

  Future<void> setLanguage(String lang) async {
    await _prefs.setString(_keyLanguage, lang);
  }

  // --- Conversation ID ---
  String? get conversationId => _prefs.getString(_keyConversationId);

  Future<void> setConversationId(String id) async {
    await _prefs.setString(_keyConversationId, id);
  }

  Future<void> clearConversationId() async {
    await _prefs.remove(_keyConversationId);
  }

  // --- User Profile ---
  static const String _keyUserName = 'weathergpt_user_name';
  static const String _keyUserBio = 'weathergpt_user_bio';
  static const String _keyUserEmail = 'weathergpt_user_email';
  static const String _keyUserAvatar = 'weathergpt_user_avatar';

  String get userName => _prefs.getString(_keyUserName) ?? 'Sharad Patel';
  String get userBio => _prefs.getString(_keyUserBio) ?? 'Meteorological AI Researcher';
  String get userEmail => _prefs.getString(_keyUserEmail) ?? 'sharad.weather@smartindia.org';
  String get userAvatar => _prefs.getString(_keyUserAvatar) ?? '👨‍💻';

  Future<void> saveUserProfile({
    required String name,
    required String bio,
    required String email,
    required String avatar,
  }) async {
    await _prefs.setString(_keyUserName, name);
    await _prefs.setString(_keyUserBio, bio);
    await _prefs.setString(_keyUserEmail, email);
    await _prefs.setString(_keyUserAvatar, avatar);
  }

  // --- Map Theme Persistence (Default: 'dark') ---
  static const String _keyMapTheme = 'weathergpt_map_theme';
  String get mapTheme => _prefs.getString(_keyMapTheme) ?? 'dark';
  Future<void> saveMapTheme(String theme) async {
    await _prefs.setString(_keyMapTheme, theme);
  }

  // --- Chat Sessions Persistence ---
  static const String _keyChatSessions = 'weathergpt_chat_sessions';

  Future<void> saveChatSessions(List<ChatSession> sessions) async {
    final list = sessions.map((s) => jsonEncode(s.toJson())).toList();
    await _prefs.setStringList(_keyChatSessions, list);
  }

  List<ChatSession> getChatSessions() {
    final list = _prefs.getStringList(_keyChatSessions);
    if (list == null) return [];
    try {
      return list
          .map((item) => ChatSession.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearChatSessions() async {
    await _prefs.remove(_keyChatSessions);
  }
}

