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
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show detailed output including warnings.',
    )
    ..addFlag(
      'quiet',
      abbr: 'q',
      negatable: false,
      help: 'Show only errors, suppress warnings.',
    )
    ..addOption(
      'env',
      help: 'Environment profile to use (e.g., dev, staging, prod).',
    )
    ..addFlag(
      'watch',
      abbr: 'w',
      negatable: false,
      help: 'Watch the input specification and config files for changes and regenerate client automatically.',
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

  final verbose = argResults['verbose'] == true;
  final quiet = argResults['quiet'] == true;
  final env = argResults['env'] as String?;
  final watch = argResults['watch'] == true;

  // Resolve environment profile if specified
  EnvironmentProfile? selectedProfile;
  if (env != null && env.isNotEmpty) {
    if (fileConfig == null) {
      stderr.writeln(
        'Warning: --env specified but no config file found. '
        'Environment profiles are only available when using --config.',
      );
    } else {
      selectedProfile = fileConfig.environments[env];
      if (selectedProfile == null) {
        stderr.writeln(
          'Warning: Environment profile "$env" not found in config. '
          'Available profiles: ${fileConfig.environments.keys.join(", ")}',
        );
      } else if (verbose) {
        stdout.writeln('Using environment profile: $env');
      }
    }
  }

  // Build ApiClientConfig from config file and selected profile
  ApiClientConfig? clientConfig;
  if (fileConfig != null || selectedProfile != null) {
    // Merge base config with environment profile (profile overrides base)
    final effectiveBaseUrl =
        selectedProfile?.baseUrl ?? fileConfig?.baseUrl;
    final effectiveHeaders = <String, String>{
      ...(fileConfig?.headers ?? {}),
      ...(selectedProfile?.headers ?? {}),
    };
    final effectiveAuth = selectedProfile?.auth ?? fileConfig?.auth;

    if (effectiveBaseUrl != null) {
      clientConfig = ApiClientConfig(
        baseUrl: effectiveBaseUrl,
        defaultHeaders: effectiveHeaders,
        auth: effectiveAuth,
      );
    }
  }

  // Extract custom adapter type from config if using custom adapter
  String? customAdapterType;
  if (fileConfig?.httpAdapter == 'custom') {
    customAdapterType = fileConfig?.customAdapterType;
    if (customAdapterType == null || customAdapterType.isEmpty) {
      stderr.writeln(
        'Warning: Custom adapter specified but customAdapterType is not set. '
        'Custom adapter documentation will not be included.',
      );
    }
  }

  // Function to run generation once
  Future<void> runOnce() async {
    try {
      await ApiClientGenerator.generateClient(
        inputSpecPath: input,
        outputDir: outputDir,
        config: clientConfig,
        projectDir: Directory.current.path,
        onWarning: quiet
            ? null
            : (verbose
                ? (msg) => stdout.writeln(msg)
                : null), // In non-verbose mode, warnings are suppressed
        customAdapterType: customAdapterType,
      );

      if (verbose) {
        stdout.writeln('✓ Client generated successfully in $outputDir');
      } else if (!quiet) {
        stdout.writeln('✓ Client regenerated');
      }
    } catch (e, stackTrace) {
      stderr.writeln('Generation failed: $e');
      if (verbose) {
        stderr.writeln(stackTrace);
      }
      exitCode = 1;
    }
  }

  // Run generation once
  await runOnce();

  // If watch mode is enabled, watch for changes
  if (watch) {
    // Check if input is a local file (watch mode doesn't support URLs)
    if (input.startsWith('http://') || input.startsWith('https://')) {
      stderr.writeln(
        'Error: --watch mode is only supported for local files. '
        'The current input is a URL: $input',
      );
      exitCode = 64; // EX_USAGE
      return;
    }

    final specFile = File(input);
    if (!await specFile.exists()) {
      stderr.writeln('Error: Specification file not found for watch mode: $input');
      exitCode = 66; // EX_NOINPUT
      return;
    }

    // Also watch config file if specified
    File? configFile;
    if (configPath != null && configPath.isNotEmpty) {
      configFile = File(configPath);
      if (!await configFile.exists()) {
        if (verbose) {
          stderr.writeln(
            'Warning: Config file not found for watch mode: $configPath',
          );
        }
      }
    }

    if (!quiet) {
      stdout.writeln('Watch mode enabled. Press Ctrl+C to stop.');
      if (verbose) {
        stdout.writeln('Watching: $input');
        if (configFile != null && await configFile.exists()) {
          stdout.writeln('Watching: ${configFile.path}');
        }
      }
    }

    DateTime lastRun = DateTime.now();
    const debounceDuration = Duration(milliseconds: 500);

    // Function to handle file change
    Future<void> handleFileChange(String path) async {
      final now = DateTime.now();
      if (now.difference(lastRun) < debounceDuration) {
        return;
      }
      lastRun = now;

      // Reload config if config file changed
      if (configFile != null &&
          path == configFile.path &&
          await configFile.exists()) {
        try {
          fileConfig = await ConfigLoader.load(configFile.path);
          
          // Re-resolve environment profile if specified
          if (env != null && env.isNotEmpty && fileConfig != null) {
            selectedProfile = fileConfig!.environments[env];
          }

          // Rebuild client config
          if (fileConfig != null || selectedProfile != null) {
            final effectiveBaseUrl =
                selectedProfile?.baseUrl ?? fileConfig?.baseUrl;
            final effectiveHeaders = <String, String>{
              ...(fileConfig?.headers ?? {}),
              ...(selectedProfile?.headers ?? {}),
            };
            final effectiveAuth = selectedProfile?.auth ?? fileConfig?.auth;

            if (effectiveBaseUrl != null) {
              clientConfig = ApiClientConfig(
                baseUrl: effectiveBaseUrl,
                defaultHeaders: effectiveHeaders,
                auth: effectiveAuth,
              );
            }
          }

          // Re-extract custom adapter type
          if (fileConfig?.httpAdapter == 'custom') {
            customAdapterType = fileConfig?.customAdapterType;
          } else {
            customAdapterType = null;
          }

          if (verbose) {
            stdout.writeln('Config reloaded from ${configFile.path}');
          }
        } catch (e) {
          stderr.writeln('Failed to reload config: $e');
          return;
        }
      }

      if (!quiet) {
        stdout.writeln('Change detected in $path, regenerating...');
      }

      await runOnce();
    }

    // Watch spec file
    final specWatcher = specFile.watch(events: FileSystemEvent.modify);
    
    // Watch config file if it exists
    Stream<FileSystemEvent>? configWatcher;
    if (configFile != null && await configFile.exists()) {
      configWatcher = configFile.watch(events: FileSystemEvent.modify);
    }

    // Listen for changes from spec file
    specWatcher.listen((event) async {
      if (event.type == FileSystemEvent.delete) {
        return;
      }
      await handleFileChange(event.path);
    });

    // Listen for changes from config file if it exists
    if (configWatcher != null) {
      configWatcher.listen((event) async {
        if (event.type == FileSystemEvent.delete) {
          return;
        }
        await handleFileChange(event.path);
      });
    }

    // Keep the process alive
    await Future.delayed(Duration(days: 365));
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

