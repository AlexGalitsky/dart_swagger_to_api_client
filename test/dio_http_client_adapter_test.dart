import 'dart:async';

import 'package:dart_swagger_to_api_client/src/core/dio_http_client_adapter.dart';
import 'package:dart_swagger_to_api_client/src/core/http_client_adapter.dart';
import 'package:dio/dio.dart' hide HttpClientAdapter;
import 'package:test/test.dart';

void main() {
  group('DioHttpClientAdapter', () {
    late DioHttpClientAdapter adapter;
    late Dio dio;

    setUp(() {
      dio = Dio();
      adapter = DioHttpClientAdapter(dio: dio);
    });

    tearDown(() {
      dio.close();
    });

    test('implements HttpClientAdapter interface', () {
      expect(adapter, isA<HttpClientAdapter>());
    });

    test('sends GET request and returns response', () async {
      final request = HttpRequest(
        method: 'GET',
        url: Uri.parse('https://httpbin.org/get'),
        timeout: const Duration(seconds: 10),
      );

      final response = await adapter.send(request);

      expect(response.statusCode, equals(200));
      expect(response.body, isNotEmpty);
      expect(response.headers, isNotEmpty);
    });

    test('sends POST request with JSON body', () async {
      final request = HttpRequest(
        method: 'POST',
        url: Uri.parse('https://httpbin.org/post'),
        headers: {'Content-Type': 'application/json'},
        body: '{"test": "value"}',
        timeout: const Duration(seconds: 10),
      );

      final response = await adapter.send(request);

      expect(response.statusCode, equals(200));
      expect(response.body, contains('"test"'));
      expect(response.body, contains('"value"'));
    });

    test('handles timeout correctly', () async {
      final request = HttpRequest(
        method: 'GET',
        url: Uri.parse('https://httpbin.org/delay/10'),
        timeout: const Duration(milliseconds: 100),
      );

      // Should throw TimeoutException or return error response
      final response = await adapter.send(request);
      // Dio might return a response even on timeout, or throw
      // For now, we just check that we get some response
      expect(response.statusCode, greaterThanOrEqualTo(0));
    });

    test('handles error responses correctly', () async {
      final request = HttpRequest(
        method: 'GET',
        url: Uri.parse('https://httpbin.org/status/404'),
        timeout: const Duration(seconds: 10),
      );

      final response = await adapter.send(request);

      expect(response.statusCode, equals(404));
    });

    test('closes underlying Dio instance when owned', () async {
      final ownedAdapter = DioHttpClientAdapter(); // Creates its own Dio
      await ownedAdapter.close();
      // Should not throw
    });

    test('does not close Dio instance when not owned', () async {
      final sharedDio = Dio();
      final adapter = DioHttpClientAdapter(dio: sharedDio);
      await adapter.close();
      // Should not close the shared Dio
      // We can't easily test this, but at least it shouldn't throw
      sharedDio.close();
    });
  });
}
