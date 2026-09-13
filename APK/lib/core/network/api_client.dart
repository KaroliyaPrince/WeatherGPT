import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'api_exceptions.dart';

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<dynamic> get(String url, {Map<String, String>? headers}) async {
    try {
      final response = await _client
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              ...?headers,
            },
          )
          .timeout(ApiConstants.receiveTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw NoInternetException();
    } on http.ClientException {
      throw NoInternetException();
    } on TimeoutException {
      throw TimeoutApiException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<dynamic> post(
    String url, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              ...?headers,
            },
            body: jsonEncode(body),
          )
          .timeout(ApiConstants.receiveTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw NoInternetException();
    } on http.ClientException {
      throw NoInternetException();
    } on TimeoutException {
      throw TimeoutApiException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else if (response.statusCode == 400) {
      String msg = 'Location not found (INVALID_LOCATION). Please check the city name or coordinates.';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          if (decoded['error'] == 'INVALID_LOCATION' || decoded['code'] == 'INVALID_LOCATION') {
            throw InvalidLocationException();
          }
          msg = decoded['message']?.toString() ?? decoded['error']?.toString() ?? msg;
        }
      } catch (e) {
        if (e is InvalidLocationException) rethrow;
      }
      throw InvalidLocationException(msg);
    } else if (response.statusCode == 404) {
      throw ServerApiException(404, 'Requested weather resource not found.');
    } else if (response.statusCode == 429) {
      String msg = 'Weather service API rate limit reached (Tomorrow.io). Please wait a moment and try again.';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['error'] is Map) {
          msg = decoded['error']['message']?.toString() ?? msg;
        } else if (decoded is Map && decoded['message'] != null) {
          msg = decoded['message'].toString();
        }
      } catch (_) {}
      throw ServerApiException(429, msg);
    } else if (response.statusCode >= 500) {
      throw ServerApiException(
        response.statusCode,
        'WeatherGPT server is waking up from idle (Render cold start) or temporarily busy. Please retry in a few seconds.',
      );
    } else {
      throw ServerApiException(response.statusCode, 'Request failed with status code ${response.statusCode}');
    }
  }

  void close() {
    _client.close();
  }
}
