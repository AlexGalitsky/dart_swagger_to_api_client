/// Example demonstrating request/response transformer middleware usage.
///
/// Transformers allow you to modify requests and responses on the fly,
/// such as adding headers, modifying URLs, or transforming data.

import 'package:dart_swagger_to_api_client/dart_swagger_to_api_client.dart';

void main() {
  // Example 1: Add custom headers to all requests
  final headerTransformer = TransformerInterceptor(
    requestTransformer: RequestTransformers.addHeaders({
      'X-Request-ID': DateTime.now().millisecondsSinceEpoch.toString(),
      'X-Client-Version': '1.0.0',
    }),
  );

  // Example 2: Modify URL (add query parameter)
  final urlTransformer = TransformerInterceptor(
    requestTransformer: RequestTransformers.modifyUrl((url) {
      return url.replace(queryParameters: {
        ...url.queryParameters,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      });
    }),
  );

  // Example 3: Transform response body (e.g., wrap in envelope)
  final responseTransformer = TransformerInterceptor(
    responseTransformer: ResponseTransformers.transformBody((body) {
      // Example: wrap response in envelope
      return '{"data": $body, "meta": {"timestamp": "${DateTime.now().toIso8601String()}"}}';
    }),
  );

  // Example 4: Normalize status codes
  final statusCodeTransformer = TransformerInterceptor(
    responseTransformer: ResponseTransformers.normalizeStatusCodes({
      201: 200, // Map 201 Created to 200 OK
      204: 200, // Map 204 No Content to 200 OK
    }),
  );

  // Example 5: Custom request transformation
  final customTransformer = TransformerInterceptor(
    requestTransformer: (request) async {
      // Add authentication header based on request URL
      final newHeaders = Map<String, String>.from(request.headers);
      if (request.url.path.startsWith('/api/v2/')) {
        newHeaders['X-API-Version'] = '2.0';
      }
      
      return HttpRequest(
        method: request.method,
        url: request.url,
        headers: newHeaders,
        body: request.body,
        timeout: request.timeout,
      );
    },
    responseTransformer: (response) async {
      // Log response size
      print('Response size: ${response.body.length} bytes');
      
      return response;
    },
  );

  // Create API client config with transformers
  final config = ApiClientConfig(
    baseUrl: Uri.parse('https://api.example.com'),
    requestInterceptors: [
      headerTransformer,
      urlTransformer,
      customTransformer,
    ],
    responseInterceptors: [
      responseTransformer,
      statusCodeTransformer,
      customTransformer,
    ],
  );

  // Use the client (assuming it's generated)
  // final client = ApiClient(config);
  // try {
  //   final users = await client.defaultApi.getUsers();
  //   print('Users: $users');
  // } finally {
  //   await client.close();
  // }

  print('Transformer example configured successfully!');
  print('Request interceptors: ${config.requestInterceptors.length}');
  print('Response interceptors: ${config.responseInterceptors.length}');
}
