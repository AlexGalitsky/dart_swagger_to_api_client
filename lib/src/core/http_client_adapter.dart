import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Abstraction over concrete HTTP implementations (`http`, `dio`, custom).
///
/// Generated clients should depend only on this interface (plus
/// [HttpRequest]/[HttpResponse]) so that the actual HTTP stack can be
/// swapped without regenerating code.

/// HTTP request model used by generated clients.
class HttpRequest {
  final String method;
  final Uri url;
  final Map<String, String> headers;
  final Object? body;
  final Duration? timeout;

  const HttpRequest({
    required this.method,
    required this.url,
    this.headers = const {},
    this.body,
    this.timeout,
  });
}

/// HTTP response model returned by [HttpClientAdapter].
class HttpResponse {
  final int statusCode;
  final Map<String, String> headers;
  final String body;

  const HttpResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
  });
}

/// Abstraction over a concrete HTTP client implementation.
abstract class HttpClientAdapter {
  Future<HttpResponse> send(HttpRequest request);

  /// Optional hook for cleaning up underlying resources.
  Future<void> close() async {}
}

/// Default implementation based on `package:http`.
///
/// This is the only concrete adapter we ship in v0.1. Future versions
/// may add `dio` and other adapters.
class HttpHttpClientAdapter implements HttpClientAdapter {
  HttpHttpClientAdapter({http.Client? httpClient})
      : _client = httpClient ?? http.Client(),
        _ownClient = httpClient == null;

  final http.Client _client;
  final bool _ownClient;

  @override
  Future<HttpResponse> send(HttpRequest request) async {
    // Check if body is a Map that might contain files (multipart/form-data)
    if (request.body is Map<String, dynamic>) {
      final bodyMap = request.body as Map<String, dynamic>;
      // Check if map contains File or List<int> (indicating multipart/form-data)
      final hasFiles = bodyMap.values.any((value) =>
          value is File || value is List<int>);
      
      if (hasFiles) {
        // Create multipart request
        final multipartRequest = http.MultipartRequest(
          request.method,
          request.url,
        );
        multipartRequest.headers.addAll(request.headers);
        
        // Add fields and files
        for (final entry in bodyMap.entries) {
          final key = entry.key;
          final value = entry.value;
          if (value is File) {
            final file = await http.MultipartFile.fromPath(key, value.path);
            multipartRequest.files.add(file);
          } else if (value is List<int>) {
            multipartRequest.files.add(
              http.MultipartFile.fromBytes(key, value),
            );
          } else {
            multipartRequest.fields[key] = value.toString();
          }
        }
        
        // Apply timeout if specified
        Future<http.StreamedResponse> sendFuture = _client.send(multipartRequest);
        if (request.timeout != null) {
          sendFuture = sendFuture.timeout(
            request.timeout!,
            onTimeout: () {
              throw TimeoutException(
                'Request to ${request.url} timed out after ${request.timeout}',
                request.timeout!,
              );
            },
          );
        }
        
        final streamed = await sendFuture;
        final response = await http.Response.fromStream(streamed);
        
        return HttpResponse(
          statusCode: response.statusCode,
          headers: Map.unmodifiable(response.headers),
          body: response.body,
        );
      }
    }
    
    // Regular request (JSON, form-urlencoded, or plain text)
    final httpRequest = http.Request(request.method, request.url)
      ..headers.addAll(request.headers);

    if (request.body != null) {
      // Body is already correctly encoded (e.g. JSON string, form-urlencoded string).
      httpRequest.body = request.body.toString();
    }

    // Apply timeout if specified in the request.
    Future<http.StreamedResponse> sendFuture = _client.send(httpRequest);
    if (request.timeout != null) {
      sendFuture = sendFuture.timeout(
        request.timeout!,
        onTimeout: () {
          throw TimeoutException(
            'Request to ${request.url} timed out after ${request.timeout}',
            request.timeout!,
          );
        },
      );
    }

    final streamed = await sendFuture;
    final response = await http.Response.fromStream(streamed);

    return HttpResponse(
      statusCode: response.statusCode,
      headers: Map.unmodifiable(response.headers),
      body: response.body,
    );
  }

  @override
  Future<void> close() async {
    if (_ownClient) {
      _client.close();
    }
  }
}

