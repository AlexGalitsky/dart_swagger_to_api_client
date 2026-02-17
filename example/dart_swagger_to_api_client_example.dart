import 'dart:convert';

import 'package:dart_swagger_to_api_client/dart_swagger_to_api_client.dart';

/// Very small manual prototype of how a generated client might look.
///
/// This lives in `example/` and is not part of the public API – its only
/// purpose is to validate the configuration + HTTP abstractions.
class UsersApi {
  UsersApi(this._config);

  final ApiClientConfig _config;

  Future<Map<String, dynamic>> getUserRaw(String id) async {
    final uri = _config.baseUrl.replace(path: '/users/$id');

    final request = HttpRequest(
      method: 'GET',
      url: uri,
      headers: _config.defaultHeaders,
    );

    final response = await _config.httpClientAdapter.send(request);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Request failed with status ${response.statusCode}: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json;
  }
}

class ApiClient {
  ApiClient(this._config);

  final ApiClientConfig _config;

  UsersApi get users => UsersApi(_config);
}

Future<void> main() async {
  final config = ApiClientConfig(
    baseUrl: Uri.parse('https://api.example.com'),
    defaultHeaders: const {
      'User-Agent': 'dart_swagger_to_api_client-example/0.1.0',
    },
  );

  final client = ApiClient(config);

  // This is just a prototype call; in a real project, the spec + generator
  // would produce an equivalent client in the target project.
  try {
    final user = await client.users.getUserRaw('123');
    print('User: $user');
  } catch (e) {
    print('Request failed: $e');
  } finally {
    await config.httpClientAdapter.close();
  }
}

