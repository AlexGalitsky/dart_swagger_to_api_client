/// Base class for all API client-related exceptions.
class ApiClientException implements Exception {
  ApiClientException(
    this.message, {
    this.statusCode,
    this.context,
    this.cause,
  });

  /// Human-readable description of the error.
  final String message;

  /// Optional HTTP status code associated with the error.
  final int? statusCode;

  /// Additional context about where the error occurred.
  final Map<String, dynamic>? context;

  /// The underlying exception that caused this error (if any).
  final Object? cause;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('ApiClientException');
    if (statusCode != null) {
      buffer.write(' (status: $statusCode)');
    }
    buffer.write(': $message');
    
    if (context != null && context!.isNotEmpty) {
      buffer.write('\nContext:');
      context!.forEach((key, value) {
        buffer.write('\n  $key: $value');
      });
    }
    
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
      if (cause is Error) {
        buffer.write('\n${(cause as Error).stackTrace}');
      }
    }
    
    return buffer.toString();
  }
}

/// Represents 5xx HTTP errors returned by the server.
class ApiServerException extends ApiClientException {
  ApiServerException(
    super.message, {
    super.statusCode,
    super.context,
    super.cause,
  });
}

/// Represents authentication/authorization errors (401/403).
class ApiAuthException extends ApiClientException {
  ApiAuthException(
    super.message, {
    super.statusCode,
    super.context,
    super.cause,
  });
}

/// Represents timeout errors.
class TimeoutException extends ApiClientException {
  TimeoutException(
    super.message,
    Duration timeout, {
    Map<String, dynamic>? context,
    super.cause,
  }) : super(
          statusCode: null,
          context: {
            ...?context,
            'timeout': timeout.inSeconds,
          },
        );
}

/// Represents errors during code generation.
class GenerationException implements Exception {
  GenerationException(
    this.message, {
    this.path,
    this.context,
    this.cause,
  });

  /// Human-readable description of the error.
  final String message;

  /// Path in the spec where the error occurred (e.g., '/paths/users/get').
  final String? path;

  /// Additional context about where the error occurred.
  final Map<String, dynamic>? context;

  /// The underlying exception that caused this error (if any).
  final Object? cause;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('GenerationException: $message');
    
    if (path != null) {
      buffer.write('\nPath: $path');
    }
    
    if (context != null && context!.isNotEmpty) {
      buffer.write('\nContext:');
      context!.forEach((key, value) {
        buffer.write('\n  $key: $value');
      });
    }
    
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
      if (cause is Error) {
        buffer.write('\n${(cause as Error).stackTrace}');
      } else if (cause is Exception) {
        buffer.write('\n${StackTrace.current}');
      }
    } else {
      // Include stack trace for generation errors
      buffer.write('\n${StackTrace.current}');
    }
    
    return buffer.toString();
  }
}

/// Represents configuration validation errors.
class ConfigValidationException implements Exception {
  ConfigValidationException(
    this.message, {
    this.field,
    this.context,
    this.cause,
  });

  /// Human-readable description of the error.
  final String message;

  /// Field name that failed validation.
  final String? field;

  /// Additional context about the validation error.
  final Map<String, dynamic>? context;

  /// The underlying exception that caused this error (if any).
  final Object? cause;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('ConfigValidationException: $message');
    
    if (field != null) {
      buffer.write('\nField: $field');
    }
    
    if (context != null && context!.isNotEmpty) {
      buffer.write('\nContext:');
      context!.forEach((key, value) {
        buffer.write('\n  $key: $value');
      });
    }
    
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
      if (cause is Error) {
        buffer.write('\n${(cause as Error).stackTrace}');
      }
    }
    
    return buffer.toString();
  }
}
