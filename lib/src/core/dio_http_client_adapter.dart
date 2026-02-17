import 'dart:async';

import 'package:dio/dio.dart' hide HttpClientAdapter;

import 'http_client_adapter.dart';

/// Dio-based implementation of [HttpClientAdapter].
///
/// This adapter uses `package:dio` for HTTP requests. To use this adapter,
/// you need to add `dio` as a dependency in your `pubspec.yaml`:
///
/// ```yaml
/// dependencies:
///   dio: ^5.0.0
/// ```
///
/// Example usage:
/// ```dart
/// import 'package:dio/dio.dart';
/// import 'package:dart_swagger_to_api_client/dart_swagger_to_api_client.dart';
///
/// final dio = Dio();
/// final adapter = DioHttpClientAdapter(dio: dio);
/// final config = ApiClientConfig(
///   baseUrl: Uri.parse('https://api.example.com'),
///   httpClientAdapter: adapter,
/// );
/// ```
class DioHttpClientAdapter implements HttpClientAdapter {
  /// Creates a DioHttpClientAdapter.
  ///
  /// [dio] is the Dio instance to use. If not provided, a new instance
  /// will be created. You can pass a configured Dio instance with interceptors,
  /// base options, etc.
  DioHttpClientAdapter({Dio? dio})
      : _dio = dio ?? Dio(),
        _ownDio = dio == null;

  final Dio _dio;
  final bool _ownDio;

  @override
  Future<HttpResponse> send(HttpRequest request) async {
    try {
      final url = request.url;

      // Build full URL for Dio (Dio can accept full URLs)
      final fullUrl = url.toString();
      
      // Prepare query parameters (Dio handles them separately if using full URL)
      Map<String, dynamic>? queryParameters;
      if (url.queryParameters.isNotEmpty) {
        queryParameters = Map<String, dynamic>.from(url.queryParameters);
      }

      // Create Dio options
      final options = Options(
        method: request.method,
        headers: Map<String, dynamic>.from(request.headers),
        sendTimeout: request.timeout,
        receiveTimeout: request.timeout,
        followRedirects: true,
      );

      // Send request - Dio can handle full URLs
      final response = await _dio.request(
        fullUrl,
        queryParameters: queryParameters,
        options: options,
        data: request.body,
      );

      // Map Dio response to HttpResponse
      // Dio headers are always Lists
      final responseHeaders = <String, String>{};
      response.headers.map.forEach((key, value) {
        final list = value as List;
        if (list.isNotEmpty) {
          responseHeaders[key] = list.first.toString();
        }
      });

      // Convert response data to string
      final responseData = response.data;
      final body = responseData is String
          ? responseData
          : (responseData != null ? responseData.toString() : '');

      return HttpResponse(
        statusCode: response.statusCode ?? 200,
        headers: Map.unmodifiable(responseHeaders),
        body: body,
      );
    } on DioException catch (e) {
      // Handle Dio-specific errors
      final statusCode = e.response?.statusCode;
      final responseHeaders = <String, String>{};
      String body = '';

      if (e.response != null) {
        // Extract headers from error response
        // Dio headers are always Lists
        e.response!.headers.map.forEach((key, value) {
          final list = value as List;
          if (list.isNotEmpty) {
            responseHeaders[key] = list.first.toString();
          }
        });

        // Extract body from error response
        final errorData = e.response!.data;
        body = errorData is String
            ? errorData
            : (errorData != null ? errorData.toString() : '');
      }

      // Return error response
      return HttpResponse(
        statusCode: statusCode ?? 500,
        headers: Map.unmodifiable(responseHeaders),
        body: body,
      );
    } catch (e) {
      // For other errors, rethrow
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    if (_ownDio) {
      _dio.close();
    }
  }
}
