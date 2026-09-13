import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/utils/weather_utils.dart';
import 'package:weather_app/models/location_model.dart';
import 'package:weather_app/models/weather_data.dart';
import 'package:weather_app/models/chat_session.dart';
import 'package:weather_app/models/chat_message.dart';
import 'package:weather_app/models/route_weather_model.dart';
import 'package:weather_app/services/weather_gpt_ai_service.dart';
import 'package:weather_app/services/tts_service.dart';
import 'package:weather_app/services/voice_recorder/voice_recorder.dart';
import 'package:weather_app/core/constants/api_constants.dart';
import 'package:weather_app/services/image_compressor/image_compressor.dart';
import 'package:weather_app/features/chatbot/live_call_screen.dart';
import 'package:weather_app/models/past_day_weather.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/services/storage_service.dart';
import 'package:weather_app/providers/settings_provider.dart';
import 'package:weather_app/services/location_service.dart';
void main() {
  group('WeatherGPT Unit & Model Tests', () {
    test('WeatherUtils converts Celsius to Fahrenheit accurately', () {
      expect(WeatherUtils.cToF(0), 32.0);
      expect(WeatherUtils.cToF(100), 212.0);
      expect(WeatherUtils.cToF(28).round(), 82);

      expect(WeatherUtils.formatTemp(28, isFahrenheit: false), '28°');
      expect(WeatherUtils.formatTemp(28, isFahrenheit: true), '82°');
      expect(WeatherUtils.formatTemp(28, isFahrenheit: false, showUnit: true), '28°C');
      expect(WeatherUtils.formatTemp(28, isFahrenheit: true, showUnit: true), '82°F');
    });

    test('WeatherLocation serialization works correctly', () {
      const loc = WeatherLocation(
        name: 'Rajkot',
        state: 'Gujarat',
        country: 'India',
        latitude: 22.3039,
        longitude: 70.8022,
        isFavorite: true,
      );

      final json = loc.toJson();
      final fromJson = WeatherLocation.fromJson(json);

      expect(fromJson.name, 'Rajkot');
      expect(fromJson.state, 'Gujarat');
      expect(fromJson.country, 'India');
      expect(fromJson.latitude, 22.3039);
      expect(fromJson.longitude, 70.8022);
      expect(fromJson.isFavorite, true);
      expect(fromJson.displayName, 'Rajkot, Gujarat');
    });

    test('WeatherData parses API response correctly', () {
      final mockApiResponse = {
        'location': {
          'name': 'Mumbai',
          'country': 'India',
          'state': 'Maharashtra',
          'latitude': 19.0760,
          'longitude': 72.8777,
        },
        'weather': {
          'temperature': 30,
          'apparentTemperature': 34,
          'condition': 'Partly cloudy',
          'humidity': 65,
          'windSpeed': 12,
          'windDirection': 'SW',
          'pressure': 1010,
          'visibility': 8,
          'uvIndex': 7,
          'cloudCover': 40,
          'rain_probability': 30,
          'tempMax': 33,
          'tempMin': 27,
          'sunrise': '06:20 AM',
          'sunset': '06:40 PM',
        },
        'timeline': {
          'hours': [
            {
              'hourLabel': 'Now',
              'temperature': 30,
              'apparentTemperature': 34,
              'conditionEmoji': '⛅',
              'rainProbability': 30,
              'humidity': 65,
              'windSpeed': 12,
              'riskLevel': 'safe',
            },
          ],
        },
        'forecast': [
          {
            'day': 'Today',
            'date': '2026-09-11',
            'maxTemp': 33,
            'minTemp': 27,
            'condition': 'Partly cloudy',
            'rainProbability': 30,
          },
        ],
        'airQuality': {
          'aqi': 55,
          'category': 'Moderate',
          'pm2_5': 14,
          'pm10': 28,
          'co': 450,
          'no2': 18,
          'o3': 30,
          'healthAdvice': 'Air quality is moderate.',
        },
      };

      final weather = WeatherData.fromApiResponse(mockApiResponse);

      expect(weather.location.name, 'Mumbai');
      expect(weather.temperature, 30);
      expect(weather.apparentTemperature, 34);
      expect(weather.condition, 'Partly cloudy');
      expect(weather.humidity, 65);
      expect(weather.windSpeed, 12);
      expect(weather.airQuality?.aqi, 55);
      expect(weather.hourly.length, 1);
      expect(weather.hourly.first.hourLabel, 'Now');
      expect(weather.forecast.length, 1);
      expect(weather.forecast.first.day, 'Today');
    });

    test('WeatherData parses weathergpt-back-end live payload correctly', () {
      final livePayload = {
        'location': {
          'name': 'Rajkot',
          'region': 'Gujarat',
          'country': 'India',
          'lat': 22.3,
          'lon': 70.8,
        },
        'current': {
          'temperature_c': 28,
          'feels_like_c': 30.6,
          'humidity': 69,
          'dew_point_c': 21.8,
          'wind_kph': 8.6,
          'wind_direction': 280,
          'pressure_mb': 1004,
          'visibility_km': 16,
          'uv_index': 0,
          'cloud_cover': 42,
          'precipitation_mm': 0,
          'rain_probability': 0,
          'condition': {
            'text': 'Partly Cloudy',
            'icon': 'cloud-sun',
            'code': 1101,
          },
        },
        'hourly': [
          {
            'time': '2026-09-11T17:00:00Z',
            'temperature_c': 28,
            'feels_like_c': 30.6,
            'humidity': 69,
            'wind_kph': 8.6,
            'wind_direction': 280,
            'precipitation_probability': 0,
            'precipitation_mm': 0,
            'cloud_cover': 42,
            'uv_index': 0,
            'condition': {
              'text': 'Partly Cloudy',
              'icon': 'cloud-sun',
              'code': 1101,
            },
          },
        ],
        'daily': [
          {
            'date': '2026-09-11',
            'temperature_max_c': 35.6,
            'temperature_min_c': 24.1,
            'temperature_avg_c': 26.3,
            'precipitation_probability': 0,
            'precipitation_mm': 0,
            'wind_kph': 7.9,
            'humidity': 83,
            'uv_index': 9,
            'condition': {
              'text': 'Cloudy',
              'icon': 'cloud',
              'code': 1001,
            },
          },
        ],
        'alerts': [],
        'metadata': {'units': 'metric', 'updated_at': '2026-09-11T17:30:00Z'},
      };

      final data = WeatherData.fromApiResponse(livePayload);
      expect(data.location.name, 'Rajkot');
      expect(data.temperature, 28);
      expect(data.apparentTemperature, 30.6);
      expect(data.condition, 'Partly Cloudy');
      expect(data.humidity, 69);
      expect(data.windSpeed, 8.6);
      expect(data.pressure, 1004);
      expect(data.tempMax, 35.6);
      expect(data.tempMin, 24.1);
      expect(data.hourly.length, 1);
      expect(data.hourly.first.temperature, 28);
      expect(data.hourly.first.conditionEmoji, '☁️');
      expect(data.forecast.length, 1);
      expect(data.forecast.first.maxTemp, 35.6);
      expect(data.forecast.first.minTemp, 24.1);
    });

    test('WeatherGptAiResponse parses AI ask response correctly', () {
      final jsonPayload = {
        'success': true,
        'answer': 'Today in Morbi the weather is pleasant with clear skies at 28°C.',
        'language': 'en',
        'conversationId': 'conv-morbi-100',
        'location': {
          'name': 'Morbi',
          'country': 'India',
          'state': 'Gujarat',
        },
        'weather': {
          'temperature': 28,
          'condition': 'Clear',
          'rain_probability': 0,
          'humidity': 69,
          'windSpeed': 10.7,
        },
      };

      final response = WeatherGptAiResponse.fromJson(jsonPayload);

      expect(response.success, true);
      expect(response.answer, 'Today in Morbi the weather is pleasant with clear skies at 28°C.');
      expect(response.language, 'en');
      expect(response.conversationId, 'conv-morbi-100');
      expect(response.location?['name'], 'Morbi');
      expect(response.weather?['temperature'], 28);
      expect(response.weather?['condition'], 'Clear');
      expect(response.weather?['rain_probability'], 0);
    });

    test('ChatSession serializes and deserializes correctly', () {
      final session = ChatSession(
        id: 'session_123',
        title: 'Rajkot Rain Advisory',
        createdAt: DateTime(2026, 9, 12, 10, 0),
        updatedAt: DateTime(2026, 9, 12, 10, 30),
        messages: [
          ChatMessage(
            id: 'm1',
            role: 'user',
            content: 'Will it rain today in Rajkot?',
            timestamp: DateTime(2026, 9, 12, 10, 0),
          ),
          ChatMessage(
            id: 'm2',
            role: 'assistant',
            content: 'No rain expected today.',
            timestamp: DateTime(2026, 9, 12, 10, 1),
          ),
        ],
      );

      final json = session.toJson();
      expect(json['id'], 'session_123');
      expect(json['title'], 'Rajkot Rain Advisory');
      expect((json['messages'] as List).length, 2);

      final decoded = ChatSession.fromJson(json);
      expect(decoded.id, 'session_123');
      expect(decoded.title, 'Rajkot Rain Advisory');
      expect(decoded.messages.length, 2);
      expect(decoded.messages.first.content, 'Will it rain today in Rajkot?');
      expect(decoded.messages.last.content, 'No rain expected today.');
    });

    test('RoutePlace and RouteWeatherInfo parse user exact JSON schema', () {
      final userExactJson = {
        "name": "Vejalpur",
        "type": "route_place",
        "latitude": 22.98814,
        "longitude": 72.5075,
        "distance_from_start_km": 190.1,
        "estimated_arrival": "2026-09-12T13:47:00.290Z",
        "weather": {
          "temp_c": 33.7,
          "temperature_c": 33.7,
          "condition": {
            "text": "Overcast",
            "icon": "cloud",
            "code": 1001
          },
          "weather_code": 1001,
          "wind_kph": 10.8,
          "wind_speed_kph": 10.8,
          "wind_direction": 285,
          "humidity": 55,
          "feelslike_c": 38.2,
          "uv": 0,
          "uv_index": 0,
          "visibility_km": 23.3,
          "pressure_mb": 999,
          "precip_mm": 0,
          "precipitation_mm": 0,
          "rain_probability": 0
        }
      };

      final place = RoutePlace.fromJson(userExactJson);
      expect(place.name, "Vejalpur");
      expect(place.type, "route_place");
      expect(place.latitude, 22.98814);
      expect(place.longitude, 72.5075);
      expect(place.distanceFromStartKm, 190.1);
      expect(place.weather.temperatureC, 33.7);
      expect(place.weather.feelslikeC, 38.2);
      expect(place.weather.humidity, 55);
      expect(place.weather.windSpeedKph, 10.8);
      expect(place.weather.windDirection, 285);
      expect(place.weather.condition.text, "Overcast");
      expect(place.weather.condition.code, 1001);
      expect(place.weather.visibilityKm, 23.3);
      expect(place.weather.pressureMb, 999);

      final encoded = place.toJson();
      expect(encoded['name'], "Vejalpur");
      expect(encoded['distance_from_start_km'], 190.1);
      expect(encoded['weather']['temp_c'], 33.7);
      expect(encoded['weather']['humidity'], 55);
      expect(encoded['weather']['condition']['text'], "Overcast");
    });

    test('TtsService uses backend OpenAI MP3 voice API endpoint', () {
      expect(TtsService.voiceApiUrl, 'https://weathergpt-backend-46or.onrender.com/api/voice/speak');
      final tts = TtsService();
      expect(tts.isPlaying, isFalse);
    });

    test('PlatformVoiceRecorder starts, stops, and returns voice answer', () async {
      final recorder = getVoiceRecorder();
      expect(recorder.isRecording, isFalse);

      bool started = false;
      await recorder.startRecording(
        onStarted: () => started = true,
        onSoundLevel: (_) {},
        onError: (_) {},
      );
      expect(started, isTrue);
      expect(recorder.isRecording, isTrue);

      final result = await recorder.stopAndAsk(language: 'gu');
      expect(recorder.isRecording, isFalse);
      expect(result, isNotNull);
      expect(result!.success, isTrue);
      expect(result.answer, isNotEmpty);
    });

    test('WeatherLens endpoint is direct dedicated backend URL', () {
      expect(
        ApiConstants.weatherLensEndpoint,
        'https://weathergpt-backend-46or.onrender.com/api/weather/lens',
      );
    });

    test('PlatformImageCompressor compresses bytes to base64 data string', () async {
      final compressor = getImageCompressor();
      final dummyBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final compressed = await compressor.compressImage(
        dummyBytes,
        maxWidth: 800,
        maxHeight: 800,
        quality: 0.6,
      );
      expect(compressed, isNotEmpty);
      expect(compressed.contains('base64'), isTrue);
    });

    test('WeatherLens API response parsing extracts answer and lensData accurately', () {
      final mockBackendResponse = {
        "success": true,
        "weatherLens": {
          "detectedCloudType": "Cumulus",
          "skyCondition": "Scattered Fluffy Cumulus Clouds",
          "estimatedCloudCoverPercentage": 35,
          "liveRainProbability": 26,
          "aiConfidence": 88,
          "apiVerificationStatus": "VERIFIED_WITH_OPEN_METEO",
          "answer": "📸 કેમેરા ફોટો વિશ્લેષણ મુજબ, આકાશમાં **Scattered Fluffy Cumulus Clouds** દર્શાય છે...",
          "advisory": "☀️ વાતાવરણ અનુકૂળ છે..."
        }
      };

      final lensMap = mockBackendResponse['weatherLens'] as Map<String, dynamic>;
      final answer = lensMap['answer'] as String;
      expect(answer, contains('કેમેરા ફોટો વિશ્લેષણ'));
      expect(lensMap['detectedCloudType'], 'Cumulus');
      expect(lensMap['liveRainProbability'], 26);
      expect(lensMap['aiConfidence'], 88);
    });

    test('RouteWeather API response parses user exact Morbi to Rajkot JSON and alerts', () {
      expect(
        ApiConstants.routeWeatherEndpoint,
        'https://weathergpt-back-end.onrender.com/api/route-weather',
      );

      final userExactBackendJson = {
        "success": true,
        "route": {
          "source": {
            "name": "Morbi",
            "latitude": 22.8004,
            "longitude": 70.8862
          },
          "destination": {
            "name": "Rajkot",
            "latitude": 22.3053,
            "longitude": 70.8028
          },
          "distance_km": 70.7,
          "duration_minutes": 109,
          "departure_time": "2026-09-12T11:30:00.000Z"
        },
        "places": [
          {
            "name": "Morbi",
            "type": "source",
            "latitude": 22.8004,
            "longitude": 70.8862,
            "distance_from_start_km": 0,
            "estimated_arrival": "2026-09-12T11:30:00.000Z",
            "weather": {
              "temperature_c": 33.8,
              "condition": {
                "text": "Clear / Sunny",
                "icon": "sunny",
                "code": 1000
              },
              "rain_probability": 0,
              "wind_speed_kph": 12.5,
              "humidity": 55
            }
          },
          {
            "name": "Tankara",
            "type": "route_place",
            "latitude": 22.6562,
            "longitude": 70.7495,
            "distance_from_start_km": 27.7,
            "estimated_arrival": "2026-09-12T12:13:00.000Z",
            "weather": {
              "temperature_c": 33.3,
              "condition": {
                "text": "Clear / Sunny",
                "icon": "sunny",
                "code": 1000
              },
              "rain_probability": 0,
              "wind_speed_kph": 11.2,
              "humidity": 58
            }
          },
          {
            "name": "Rajkot",
            "type": "destination",
            "latitude": 22.3053,
            "longitude": 70.8028,
            "distance_from_start_km": 70.7,
            "estimated_arrival": "2026-09-12T13:19:00.000Z",
            "weather": {
              "temperature_c": 34.1,
              "condition": {
                "text": "Clear / Sunny",
                "icon": "sunny",
                "code": 1000
              },
              "rain_probability": 0,
              "wind_speed_kph": 13.1,
              "humidity": 52
            }
          }
        ],
        "alerts": [
          {
            "type": "heavy_rain",
            "title": "Heavy Rain Expected",
            "place": "Tankara",
            "startTime": "2026-09-12T12:13:00.000Z",
            "endTime": "2026-09-12T13:13:00.000Z",
            "severity": "Warning",
            "description": "High probability of rainfall (80%, 5mm) expected near Tankara."
          }
        ]
      };

      final plan = RoutePlan.fromApiResponse(userExactBackendJson);
      expect(plan.source, 'Morbi');
      expect(plan.destination, 'Rajkot');
      expect(plan.totalDistanceKm, 70.7);
      expect(plan.totalDurationMinutes, 109);
      expect(plan.places.length, 3);
      expect(plan.places[0].name, 'Morbi');
      expect(plan.places[0].type, 'source');
      expect(plan.places[0].weather.temperatureC, 33.8);
      expect(plan.places[1].name, 'Tankara');
      expect(plan.places[1].distanceFromStartKm, 27.7);
      expect(plan.places[2].name, 'Rajkot');
      expect(plan.places[2].type, 'destination');

      // Alerts
      expect(plan.alerts.length, 1);
      final alert = plan.alerts.first;
      expect(alert.type, 'heavy_rain');
      expect(alert.title, 'Heavy Rain Expected');
      expect(alert.place, 'Tankara');
      expect(alert.severity, 'Warning');
      expect(alert.description, contains('80%, 5mm'));
    });

    test('LiveCallTurn and TtsService support Gujarati multilingual audio flow', () {
      final turnUser = LiveCallTurn(sender: 'user', text: 'રાજકોટમાં વરસાદ પડશે?');
      expect(turnUser.sender, 'user');
      expect(turnUser.text, 'રાજકોટમાં વરસાદ પડશે?');
      expect(turnUser.isStreaming, false);

      final turnAi = LiveCallTurn(sender: 'ai', text: 'હા, સાંજે વરસાદની શક્યતા છે.', isStreaming: true);
      expect(turnAi.sender, 'ai');
      expect(turnAi.text, 'હા, સાંજે વરસાદની શક્યતા છે.');
      expect(turnAi.isStreaming, true);

      final tts = TtsService();
      expect(tts.isPlaying, false);
    });

    test('PastDayWeather parses Open-Meteo historical daily data correctly', () {
      final pastDay = PastDayWeather.fromOpenMeteo(
        dateStr: '2026-09-11',
        maxTemp: 34.8,
        minTemp: 24.4,
        weatherCode: 51,
        precipitation: 1.3,
        windSpeed: 14.5,
      );

      expect(pastDay.date, '2026-09-11');
      expect(pastDay.maxTemp, 34.8);
      expect(pastDay.minTemp, 24.4);
      expect(pastDay.weatherCode, 51);
      expect(pastDay.condition, 'Light Drizzle');
      expect(pastDay.conditionEmoji, '🌦️');
      expect(pastDay.precipitationMm, 1.3);
      expect(pastDay.windSpeedKph, 14.5);
      expect(pastDay.formattedDate, '11 Sep');
    });

    test('PlatformVoiceRecorder executes 3-step sequential pipeline callbacks', () async {
      final recorder = getVoiceRecorder();
      String? updatedStatus;
      String? transcribedText;
      String? answeredText;

      final result = await recorder.stopAndProcessPipeline(
        defaultLanguage: 'gu',
        onStatusUpdate: (status) => updatedStatus = status,
        onTranscriptionReady: (text, lang) => transcribedText = text,
        onAnswerReady: (ans) => answeredText = ans,
      );

      expect(result, isNotNull);
      expect(result!.success, true);
      expect(result.question, isNotEmpty);
      expect(result.answer, isNotEmpty);
      expect(updatedStatus, isNotNull);
      expect(transcribedText, isNotNull);
      expect(answeredText, isNotNull);
    });

    test('SettingsProvider initializes with auto language by default', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final settings = SettingsProvider(storage);

      expect(settings.language, 'auto');

      await settings.setLanguage('gu');
      expect(settings.language, 'gu');

      await settings.setLanguage('auto');
      expect(settings.language, 'auto');
    });

    test('LocationService search and popular cities return valid locations', () async {
      expect(LocationService.popularCities.isNotEmpty, true);
      expect(LocationService.popularCities.any((c) => c.name == 'Morbi'), true);
      expect(LocationService.popularCities.any((c) => c.name == 'Rajkot'), true);
      expect(LocationService.popularCities.any((c) => c.name == 'Ahmedabad'), true);

      final results = await LocationService.searchLocations('Rajkot');
      expect(results.isNotEmpty, true);
      expect(results.first.name.toLowerCase(), contains('rajkot'));
      expect(results.first.latitude, isNotNull);
      expect(results.first.longitude, isNotNull);
    });
  });
}


