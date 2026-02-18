/// Base class for all API client-related exceptions.
class ApiClientException implements Exception {
  ApiClientException(this.message, {this.statusCode});

  /// Human-readable description of the error.
  final String message;

  /// Optional HTTP status code associated with the error.
  final int? statusCode;

  @override
  String toString() {
    final code = statusCode != null ? ' (status: $statusCode)' : '';
    return 'ApiClientException$code: $message';
  }
}

/// Represents 5xx HTTP errors returned by the server.
class ApiServerException extends ApiClientException {
  ApiServerException(String message, {int? statusCode})
      : super(message, statusCode: statusCode);
}

/// Represents authentication/authorization errors (401/403).
class ApiAuthException extends ApiClientException {
  ApiAuthException(String message, {int? statusCode})
      : super(message, statusCode: statusCode);
}

/// Represents timeout errors.
class TimeoutException extends ApiClientException {
  TimeoutException(String message, Duration timeout)
      : super(message, statusCode: null);
}
