import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_swagger_to_api_client/dart_swagger_to_api_client.dart';
import 'package:dart_swagger_to_api_client/src/config/config_loader.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'input',
      abbr: 'i',
      help: 'Path to OpenAPI/Swagger spec (YAML or JSON).',
    )
    ..addOption(
      'output-dir',
      help: 'Directory where client code will be generated.',
    )
    ..addOption(
      'config',
      abbr: 'c',
      help: 'Path to dart_swagger_to_api_client.yaml (optional).',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show usage information.',
    );

  late ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln();
    _printUsage(parser);
    exitCode = 64; // EX_USAGE
    return;
  }

  if (argResults['help'] == true) {
    _printUsage(parser);
    return;
  }

  final configPath = argResults['config'] as String?;

  ApiGeneratorConfig? fileConfig;
  if (configPath != null && configPath.isNotEmpty) {
    try {
      fileConfig = await ConfigLoader.load(configPath);
    } catch (e) {
      stderr.writeln('Failed to load config from $configPath: $e');
      exitCode = 1;
      return;
    }
  }

  final input = (argResults['input'] as String?) ?? fileConfig?.input;
  final outputDir =
      (argResults['output-dir'] as String?) ?? fileConfig?.outputDir;

  if (input == null || input.isEmpty) {
    stderr.writeln('Error: --input is required.');
    stderr.writeln();
    _printUsage(parser);
    exitCode = 64; // EX_USAGE
    return;
  }

  if (outputDir == null || outputDir.isEmpty) {
    stderr.writeln('Error: --output-dir is required.');
    stderr.writeln();
    _printUsage(parser);
    exitCode = 64; // EX_USAGE
    return;
  }

  try {
    // For v0.1 we ignore config/projectDir and just ensure that spec loading
    // and basic structure checks succeed. The generator-level config is
    // parsed and merged here for future use.
    await ApiClientGenerator.generateClient(
      inputSpecPath: input,
      outputDir: outputDir,
      config: null,
      projectDir: Directory.current.path,
    );
  } catch (e, stackTrace) {
    stderr.writeln('Generation failed: $e');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}

void _printUsage(ArgParser parser) {
  stdout.writeln('dart_swagger_to_api_client');
  stdout.writeln();
  stdout.writeln('Usage:');
  stdout.writeln(
    '  dart run dart_swagger_to_api_client:dart_swagger_to_api_client '
    '--input api.yaml --output-dir lib/api_client',
  );
  stdout.writeln();
  stdout.writeln('Options:');
  stdout.writeln(parser.usage);
}

