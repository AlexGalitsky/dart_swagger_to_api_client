import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/config.dart';
import '../generators/api_client_class_generator.dart';
import '../generators/endpoint_method_generator.dart';
import 'spec_loader.dart';

/// High-level API for generating API clients from OpenAPI/Swagger specs.
///
/// At v0.1 this is intentionally minimal: we only wire through spec loading
/// and validate that we can see basic OpenAPI structure. Actual Dart code
/// generation will be implemented in subsequent iterations.
class ApiClientGenerator {
  /// Generates API client Dart files into [outputDir].
  ///
  /// - [inputSpecPath]: path to OpenAPI/Swagger spec (yaml/json)
  /// - [outputDir]: directory where client code will be written
  /// - [config]: optional configuration (base URL, auth, HTTP adapter hints)
  /// - [projectDir]: project root, to resolve relative paths if needed
  static Future<void> generateClient({
    required String inputSpecPath,
    required String outputDir,
    ApiClientConfig? config,
    String? projectDir,
  }) async {
    // 1. Load spec (YAML/JSON → Map<String, dynamic>).
    final spec = await SpecLoader.load(inputSpecPath);

    // 2. For v0.1, just ensure we can see some fundamental OpenAPI keys.
    final hasPaths = spec['paths'] is Map;
    if (!hasPaths) {
      // We keep this message simple for now; future versions will provide
      // proper diagnostics and linting.
      throw StateError(
        'Spec does not contain a valid "paths" section. '
        'OpenAPI/Swagger paths are required for client generation.',
      );
    }

    // 3. Ensure output directory exists.
    final outputDirectory = Directory(outputDir);
    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }

    // 4. Generate methods for `DefaultApi` from simple GET operations.
    final endpointGenerator = EndpointMethodGenerator();
    final defaultApiMethods =
        endpointGenerator.generateDefaultApiMethods(spec).trimRight();

    // 5. Generate a minimal `api_client.dart` file.
    //
    // We import the main package entrypoint so that generated code can use
    // `ApiClientConfig` and HTTP abstractions.
    final packageImport = 'package:dart_swagger_to_api_client/dart_swagger_to_api_client.dart';
    final clientSource = ApiClientClassGenerator.generate(
      packageImport: packageImport,
      defaultApiMethods: defaultApiMethods.isEmpty
          ? '  // No suitable GET endpoints with operationId were found in the spec.\n'
          : '$defaultApiMethods\n',
    );

    final outputPath = p.join(outputDir, 'api_client.dart');
    final outputFile = File(outputPath);
    await outputFile.writeAsString(clientSource);

    // `config` and `projectDir` are intentionally unused for v0.1 but are
    // part of the API so that CLI and examples can already depend on the
    // stable signature.
  }
}

