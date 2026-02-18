import 'config_loader.dart';
import '../core/errors.dart';

/// Validates configuration before generation.
///
/// This validator checks configuration for common issues and provides
/// helpful error messages.
class ConfigValidator {
  /// Validates the generator configuration.
  ///
  /// Throws [ConfigValidationException] if validation fails.
  static void validate(ApiGeneratorConfig config) {
    final errors = <String>[];

    // Validate baseUrl if provided
    if (config.baseUrl != null) {
      if (!config.baseUrl!.hasScheme) {
        errors.add('baseUrl must include a scheme (http:// or https://)');
      }
      if (!config.baseUrl!.hasAuthority) {
        errors.add('baseUrl must include a host');
      }
    }

    // Validate auth configuration
    if (config.auth != null) {
      final auth = config.auth!;
      
      // Check API key configuration
      if (auth.apiKey != null) {
        if (auth.apiKeyHeader == null && auth.apiKeyQuery == null) {
          errors.add(
            'If apiKey is provided, either apiKeyHeader or apiKeyQuery must be specified',
          );
        }
      } else {
        if (auth.apiKeyHeader != null || auth.apiKeyQuery != null) {
          errors.add(
            'apiKeyHeader or apiKeyQuery specified but apiKey is missing',
          );
        }
      }

      // Check bearer token configuration
      if (auth.bearerToken != null && auth.bearerTokenEnv != null) {
        errors.add(
          'Both bearerToken and bearerTokenEnv are specified. '
          'Only one should be provided (bearerToken takes precedence).',
        );
      }
    }

    // Validate HTTP adapter configuration
    if (config.httpAdapter != null) {
      final validAdapters = ['http', 'dio', 'custom'];
      if (!validAdapters.contains(config.httpAdapter)) {
        errors.add(
          'Invalid httpAdapter: "${config.httpAdapter}". '
          'Valid values are: ${validAdapters.join(", ")}',
        );
      }

      // If custom adapter is specified, customAdapterType must be provided
      if (config.httpAdapter == 'custom' && config.customAdapterType == null) {
        errors.add(
          'customAdapterType must be specified when using custom adapter',
        );
      }

      // If customAdapterType is provided, adapter must be 'custom'
      if (config.customAdapterType != null && config.httpAdapter != 'custom') {
        errors.add(
          'customAdapterType is specified but httpAdapter is not "custom"',
        );
      }
    }

    // Validate environment profiles
    for (final entry in config.environments.entries) {
      final envName = entry.key;
      final profile = entry.value;

      if (profile.baseUrl != null) {
        if (!profile.baseUrl!.hasScheme) {
          errors.add(
            'Environment "$envName": baseUrl must include a scheme (http:// or https://)',
          );
        }
        if (!profile.baseUrl!.hasAuthority) {
          errors.add(
            'Environment "$envName": baseUrl must include a host',
          );
        }
      }

      // Validate auth in environment profile
      if (profile.auth != null) {
        final auth = profile.auth!;
        
        if (auth.apiKey != null) {
          if (auth.apiKeyHeader == null && auth.apiKeyQuery == null) {
            errors.add(
              'Environment "$envName": If apiKey is provided, '
              'either apiKeyHeader or apiKeyQuery must be specified',
            );
          }
        }
      }
    }

    // If there are errors, throw exception
    if (errors.isNotEmpty) {
      throw ConfigValidationException(
        'Configuration validation failed:\n${errors.map((e) => '  - $e').join('\n')}',
        context: {
          'errors': errors,
          'config': {
            'hasBaseUrl': config.baseUrl != null,
            'hasAuth': config.auth != null,
            'httpAdapter': config.httpAdapter,
            'customAdapterType': config.customAdapterType,
            'environments': config.environments.keys.toList(),
          },
        },
      );
    }
  }
}
