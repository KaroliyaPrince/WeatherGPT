import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'providers/chat_provider.dart';
import 'providers/location_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/route_weather_provider.dart';
import 'repositories/chat_repository.dart';
import 'repositories/weather_repository.dart';
import 'services/storage_service.dart';
import 'services/weather_api_service.dart';
import 'services/route_weather_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Storage Service
  final storageService = await StorageService.init();
  final apiService = WeatherApiService();
  final routeWeatherService = RouteWeatherService();

  // Initialize Repositories
  final weatherRepo = WeatherRepository(
    apiService: apiService,
    storageService: storageService,
  );
  final chatRepo = ChatRepository(
    apiService: apiService,
    storageService: storageService,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider(storageService)),
        ChangeNotifierProvider(create: (_) => LocationProvider(weatherRepo)),
        ChangeNotifierProvider(create: (_) => WeatherProvider(weatherRepo)),
        ChangeNotifierProvider(create: (_) => ChatProvider(chatRepo)),
        ChangeNotifierProvider(create: (_) => RouteWeatherProvider(routeWeatherService)),
      ],
      child: const WeatherGPTApp(),
    ),
  );
}


class WeatherGPTApp extends StatelessWidget {
  const WeatherGPTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WeatherGPT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
    );
  }
}
