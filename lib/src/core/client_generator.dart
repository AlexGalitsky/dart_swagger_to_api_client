import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/config.dart';
import 'errors.dart';
import 'spec_cache.dart';
import '../generators/api_client_class_generator.dart';
import '../generators/endpoint_method_generator.dart';
import '../models/file_based_models_resolver.dart';
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
  /// - [customAdapterType]: optional custom adapter type name (for custom adapters)
  /// - [enableCache]: whether to enable spec parsing cache (default: true)
  static Future<void> generateClient({
    required String inputSpecPath,
    required String outputDir,
    ApiClientConfig? config,
    String? projectDir,
    void Function(String message)? onWarning,
    String? customAdapterType,
    bool enableCache = true,
  }) async {
    try {
      // 0. Validate configuration if provided
      if (config != null) {
        try {
          // Note: ApiClientConfig validation would go here if we add it
          // For now, we validate generator config in ConfigLoader
        } catch (e) {
          throw GenerationException(
            'Invalid client configuration',
            context: {'error': e.toString()},
            cause: e,
          );
        }
      }

      // 1. Load spec (YAML/JSON → Map<String, dynamic>) with optional caching.
      final cacheDir = projectDir != null
          ? p.join(projectDir, '.dart_tool', 'dart_swagger_to_api_client')
          : p.join(Directory.current.path, '.dart_tool', 'dart_swagger_to_api_client');
      
      final cache = enableCache ? SpecCache(cacheDir: cacheDir) : null;
      final loader = SpecLoader(cache: cache);
      
      Map<String, dynamic> spec;
      try {
        spec = await loader.load(inputSpecPath);
      } catch (e) {
        if (e is GenerationException) {
          rethrow;
        }
        throw GenerationException(
          'Failed to load OpenAPI specification',
          path: inputSpecPath,
          context: {
            'inputPath': inputSpecPath,
            'absolutePath': File(inputSpecPath).absolute.path,
          },
          cause: e,
        );
      }

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
      throw GenerationException(
        'OpenAPI specification validation failed',
        path: inputSpecPath,
        context: {
          'errorCount': errors.length,
          'warningCount': warnings.length,
          'errors': errors.map((e) => e.message).toList(),
          'errorDetails': errors.map((e) => e.toString()).toList(),
        },
      );
    }

    // 3. Ensure output directory exists.
    final outputDirectory = Directory(outputDir);
    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }

    // 4. Try to load models configuration and create resolver.
    //    If models config is found, use FileBasedModelsResolver to resolve
    //    $ref to real model types. Otherwise, use NoOpModelsResolver.
    final effectiveProjectDir = projectDir ?? Directory.current.path;
    final modelsConfig = await ModelsConfigLoader.load(effectiveProjectDir);
    final modelsResolver = modelsConfig != null
        ? FileBasedModelsResolver(
            projectDir: effectiveProjectDir,
            modelsConfig: modelsConfig,
          )
        : const NoOpModelsResolver();

    // 5. Generate methods for `DefaultApi` from operations.
    final endpointGenerator = EndpointMethodGenerator(modelsResolver: modelsResolver);
    final result = await endpointGenerator.generateDefaultApiMethods(spec);
    final defaultApiMethods = result.methods.trimRight();
    final modelImports = result.imports;

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
      modelImports: modelImports,
      customAdapterType: customAdapterType,
    );

    final outputPath = p.join(outputDir, 'api_client.dart');
    final outputFile = File(outputPath);
    
    try {
      await outputFile.writeAsString(clientSource);
    } catch (e) {
      throw GenerationException(
        'Failed to write generated client code',
        path: outputPath,
        context: {
          'outputDir': outputDir,
          'outputPath': outputPath,
          'fileSize': clientSource.length,
        },
        cause: e,
      );
    }
    } catch (e) {
      if (e is GenerationException || e is ConfigValidationException) {
        rethrow;
      }
      throw GenerationException(
        'Unexpected error during client generation',
        context: {
          'inputPath': inputSpecPath,
          'outputDir': outputDir,
        },
        cause: e,
      );
    }
  }
}

