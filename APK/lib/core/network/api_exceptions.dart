class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class NoInternetException extends ApiException {
  NoInternetException([super.message = 'No internet connection. Showing cached weather data.']);
}

class TimeoutApiException extends ApiException {
  TimeoutApiException([super.message = 'Connection timed out. Render backend may be waking up, retrying...']);
}

class ServerApiException extends ApiException {
  ServerApiException(int? statusCode, [String message = 'Server error occurred.'])
      : super(message, statusCode);
}

class InvalidLocationException extends ApiException {
  InvalidLocationException([super.message = 'Location not found (INVALID_LOCATION). Please check the city name or coordinates.']);
}
