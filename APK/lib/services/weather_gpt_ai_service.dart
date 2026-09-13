import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Structured response from the WeatherGPT AI API
class WeatherGptAiResponse {
  final bool success;
  final String answer;
  final String? language;
  final String? conversationId;
  final Map<String, dynamic>? location;
  final Map<String, dynamic>? weather;
  final Map<String, dynamic>? raw;

  const WeatherGptAiResponse({
    required this.success,
    required this.answer,
    this.language,
    this.conversationId,
    this.location,
    this.weather,
    this.raw,
  });

  factory WeatherGptAiResponse.fromJson(Map<String, dynamic> json) {
    // Extract conversationId from root or nested conversationContext
    String? convId = json['conversationId']?.toString();
    if (convId == null && json['conversationContext'] is Map) {
      convId = json['conversationContext']['id']?.toString();
    }

    // Extract answer text
    final answerText = json['answer']?.toString() ??
        json['message']?.toString() ??
        json['response']?.toString() ??
        '';

    return WeatherGptAiResponse(
      success: json['success'] == true || (json['answer'] != null && json['answer'].toString().isNotEmpty),
      answer: answerText,
      language: json['language']?.toString() ?? 'en',
      conversationId: convId,
      location: json['location'] as Map<String, dynamic>? ??
          (json['conversationContext']?['resolvedLocation'] as Map<String, dynamic>?),
      weather: json['weather'] as Map<String, dynamic>?,
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'answer': answer,
        'language': language,
        'conversationId': conversationId,
        'location': location,
        'weather': weather,
      };
}

/// Custom exception for WeatherGPT AI service errors
class WeatherGptAiException implements Exception {
  final String message;
  final int? statusCode;

  const WeatherGptAiException(this.message, {this.statusCode});

  @override
  String toString() => 'WeatherGptAiException: $message ${statusCode != null ? "(Status: $statusCode)" : ""}';
}

/// WeatherGPT AI API Service
class WeatherGptAiService {
  final http.Client _client;

  // Endpoint configuration (https://weathergpt-backend-46or.onrender.com/api/ask is the verified working endpoint)
  static const String defaultBaseUrl = 'https://weathergpt-backend-46or.onrender.com';
  static const String primaryEndpoint = '$defaultBaseUrl/api/ask';
  static const String fallbackEndpoint = '$defaultBaseUrl/api/ask';

  WeatherGptAiService({http.Client? client}) : _client = client ?? http.Client();

  /// Makes a POST request to the WeatherGPT AI API.
  ///
  /// - [question]: Natural language question (English, Gujarati, Hindi, etc.)
  /// - [latitude]: Optional GPS latitude
  /// - [longitude]: Optional GPS longitude
  /// - [name]: Optional ambient location name
  /// - [conversationId]: Optional ID to maintain conversational thread context
  Future<WeatherGptAiResponse> askWeatherGpt({
    required String question,
    double? latitude,
    double? longitude,
    String? name,
    String? conversationId,
    String language = 'en',
    String persona = 'general',
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final trimmedQuestion = question.trim();
    if (trimmedQuestion.isEmpty) {
      throw const WeatherGptAiException('Question cannot be empty.');
    }

    // Format prompt to enforce the user's chosen language
    String prompt = trimmedQuestion;
    if (language == 'gu' && !prompt.contains('ગુજરાતી')) {
      prompt = '$prompt\n(કૃપા કરીને સંપૂર્ણ જવાબ ગુજરાતી ભાષામાં આપો)';
    } else if (language == 'hi' && !prompt.contains('हिंदी')) {
      prompt = '$prompt\n(कृपया पूरा उत्तर हिंदी भाषा में दें)';
    }

    // 1. Build request payload according to documentation
    final Map<String, dynamic> requestBody = {
      'question': prompt,
      'language': language,
      'persona': persona,
    };

    if (latitude != null || longitude != null || (name != null && name.trim().isNotEmpty)) {
      final Map<String, dynamic> loc = {};
      if (latitude != null) loc['latitude'] = latitude;
      if (longitude != null) loc['longitude'] = longitude;
      if (name != null && name.trim().isNotEmpty) loc['name'] = name.trim();
      requestBody['location'] = loc;
    }

    if (conversationId != null && conversationId.trim().isNotEmpty) {
      requestBody['conversationId'] = conversationId.trim();
    }

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final encodedBody = jsonEncode(requestBody);

    // 2. Execute POST request with error handling & fallback
    try {
      return await _postToEndpoint(primaryEndpoint, headers, encodedBody, timeout);
    } catch (e) {
      // If primary endpoint returns 404 or fails, try fallback endpoint
      if (e is WeatherGptAiException && e.statusCode == 404) {
        try {
          return await _postToEndpoint(fallbackEndpoint, headers, encodedBody, timeout);
        } catch (fallbackError) {
          rethrow;
        }
      }
      rethrow;
    }
  }

  Future<WeatherGptAiResponse> _postToEndpoint(
    String endpointUrl,
    Map<String, String> headers,
    String body,
    Duration timeout,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse(endpointUrl),
            headers: headers,
            body: body,
          )
          .timeout(timeout);

      final statusCode = response.statusCode;

      if (statusCode >= 200 && statusCode < 300) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return WeatherGptAiResponse.fromJson(decoded);
        } else {
          throw const WeatherGptAiException('Invalid response format received from server.');
        }
      } else if (statusCode == 404) {
        throw const WeatherGptAiException('WeatherGPT AI endpoint not found on server.', statusCode: 404);
      } else if (statusCode >= 500) {
        throw WeatherGptAiException(
          'WeatherGPT AI service is temporarily unavailable. Please try again shortly.',
          statusCode: statusCode,
        );
      } else {
        String errorMsg = 'Request failed with status: $statusCode';
        try {
          final errBody = jsonDecode(response.body);
          if (errBody is Map && errBody['error'] != null) {
            errorMsg = errBody['error'].toString();
          }
        } catch (_) {}
        throw WeatherGptAiException(errorMsg, statusCode: statusCode);
      }
    } on SocketException {
      throw const WeatherGptAiException(
        'Unable to connect to WeatherGPT AI. Please check your internet connection.',
      );
    } on TimeoutException {
      throw const WeatherGptAiException(
        'WeatherGPT AI request timed out. The server is taking longer than expected.',
      );
    } on FormatException {
      throw const WeatherGptAiException(
        'Failed to process WeatherGPT server response.',
      );
    }
  }
}
