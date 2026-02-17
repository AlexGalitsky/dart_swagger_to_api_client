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

  const HttpRequest({
    required this.method,
    required this.url,
    this.headers = const {},
    this.body,
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
    final httpRequest = http.Request(request.method, request.url)
      ..headers.addAll(request.headers);

    if (request.body != null) {
      // For v0.1 we assume body is already correctly encoded (e.g. JSON string).
      httpRequest.body = request.body.toString();
    }

    final streamed = await _client.send(httpRequest);
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

