import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/config.dart';
import '../generators/api_client_class_generator.dart';
import '../generators/endpoint_method_generator.dart';
import '../models/models_config_loader.dart';
import '../models/models_resolver.dart';
import 'spec_loader.dart';
import 'spec_validator.dart';

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
  /// - [onWarning]: optional callback for warning messages (useful for CLI output)
  static Future<void> generateClient({
    required String inputSpecPath,
    required String outputDir,
    ApiClientConfig? config,
    String? projectDir,
    void Function(String message)? onWarning,
  }) async {
    // 1. Load spec (YAML/JSON → Map<String, dynamic>).
    final spec = await SpecLoader.load(inputSpecPath);

    // 2. Validate spec and collect issues.
    final issues = SpecValidator.validate(spec);
    final errors = issues.where((i) => i.severity == IssueSeverity.error).toList();
    final warnings = issues.where((i) => i.severity == IssueSeverity.warning).toList();

    // Report warnings if callback is provided.
    if (warnings.isNotEmpty && onWarning != null) {
      for (final warning in warnings) {
        onWarning(warning.toString());
      }
    }

    // If there are errors, throw with detailed message.
    if (errors.isNotEmpty) {
      final errorMessages = errors.map((e) => e.toString()).join('\n');
      throw StateError(
        'Spec validation failed:\n$errorMessages',
      );
    }

    // 3. Ensure output directory exists.
    final outputDirectory = Directory(outputDir);
    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }

    // 4. Try to load models configuration (for future integration with
    //    dart_swagger_to_models). If not found, we continue with NoOpModelsResolver.
    //    At v0.1, modelsConfig is loaded but not yet used - this prepares the
    //    infrastructure for v0.4.2 when we'll actually resolve $ref to model types.
    final effectiveProjectDir = projectDir ?? Directory.current.path;
    final modelsConfig = await ModelsConfigLoader.load(effectiveProjectDir);
    final modelsResolver = const NoOpModelsResolver(); // TODO(v0.4.2): implement real resolver when adding dart_swagger_to_models dependency

    // 5. Generate methods for `DefaultApi` from operations.
    final endpointGenerator = EndpointMethodGenerator(modelsResolver: modelsResolver);
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

