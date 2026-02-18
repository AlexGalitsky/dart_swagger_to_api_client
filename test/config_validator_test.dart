import 'package:dart_swagger_to_api_client/dart_swagger_to_api_client.dart';
import 'package:dart_swagger_to_api_client/src/config/config_loader.dart';
import 'package:dart_swagger_to_api_client/src/config/config_validator.dart';
import 'package:test/test.dart';

void main() {
  group('ConfigValidator', () {
    test('validates valid configuration', () {
      final config = ApiGeneratorConfig(
        baseUrl: Uri.parse('https://api.example.com'),
        auth: AuthConfig(
          bearerToken: 'token',
        ),
        httpAdapter: 'http',
      );

      expect(() => ConfigValidator.validate(config), returnsNormally);
    });

    test('validates baseUrl with scheme and authority', () {
      final config1 = ApiGeneratorConfig(
        baseUrl: Uri.parse('https://api.example.com'),
      );
      expect(() => ConfigValidator.validate(config1), returnsNormally);

      final config2 = ApiGeneratorConfig(
        baseUrl: Uri.parse('api.example.com'), // Missing scheme
      );
      expect(
        () => ConfigValidator.validate(config2),
        throwsA(isA<ConfigValidationException>()),
      );
    });

    test('validates API key configuration', () {
      // Valid: apiKey with apiKeyHeader
      final config1 = ApiGeneratorConfig(
        auth: AuthConfig(
          apiKey: 'key',
          apiKeyHeader: 'X-API-Key',
        ),
      );
      expect(() => ConfigValidator.validate(config1), returnsNormally);

      // Invalid: apiKey without apiKeyHeader or apiKeyQuery
      final config2 = ApiGeneratorConfig(
        auth: AuthConfig(
          apiKey: 'key',
        ),
      );
      expect(
        () => ConfigValidator.validate(config2),
        throwsA(isA<ConfigValidationException>()),
      );

      // Invalid: apiKeyHeader without apiKey
      final config3 = ApiGeneratorConfig(
        auth: AuthConfig(
          apiKeyHeader: 'X-API-Key',
        ),
      );
      expect(
        () => ConfigValidator.validate(config3),
        throwsA(isA<ConfigValidationException>()),
      );
    });

    test('validates bearer token configuration', () {
      // Valid: only bearerToken
      final config1 = ApiGeneratorConfig(
        auth: AuthConfig(
          bearerToken: 'token',
        ),
      );
      expect(() => ConfigValidator.validate(config1), returnsNormally);

      // Valid: only bearerTokenEnv
      final config2 = ApiGeneratorConfig(
        auth: AuthConfig(
          bearerTokenEnv: 'TOKEN_ENV',
        ),
      );
      expect(() => ConfigValidator.validate(config2), returnsNormally);

      // Invalid: both bearerToken and bearerTokenEnv
      final config3 = ApiGeneratorConfig(
        auth: AuthConfig(
          bearerToken: 'token',
          bearerTokenEnv: 'TOKEN_ENV',
        ),
      );
      expect(
        () => ConfigValidator.validate(config3),
        throwsA(isA<ConfigValidationException>()),
      );
    });

    test('validates HTTP adapter configuration', () {
      // Valid adapters
      for (final adapter in ['http', 'dio', 'custom']) {
        final config = ApiGeneratorConfig(
          httpAdapter: adapter,
          customAdapterType: adapter == 'custom' ? 'MyAdapter' : null,
        );
        expect(() => ConfigValidator.validate(config), returnsNormally);
      }

      // Invalid adapter
      final config1 = ApiGeneratorConfig(
        httpAdapter: 'invalid',
      );
      expect(
        () => ConfigValidator.validate(config1),
        throwsA(isA<ConfigValidationException>()),
      );

      // Custom adapter without customAdapterType
      final config2 = ApiGeneratorConfig(
        httpAdapter: 'custom',
      );
      expect(
        () => ConfigValidator.validate(config2),
        throwsA(isA<ConfigValidationException>()),
      );

      // customAdapterType without custom adapter
      final config3 = ApiGeneratorConfig(
        httpAdapter: 'http',
        customAdapterType: 'MyAdapter',
      );
      expect(
        () => ConfigValidator.validate(config3),
        throwsA(isA<ConfigValidationException>()),
      );
    });

    test('validates environment profiles', () {
      final config = ApiGeneratorConfig(
        environments: {
          'dev': EnvironmentProfile(
            baseUrl: Uri.parse('https://dev-api.example.com'),
          ),
          'invalid': EnvironmentProfile(
            baseUrl: Uri.parse('dev-api.example.com'), // Missing scheme
          ),
        },
      );

      expect(
        () => ConfigValidator.validate(config),
        throwsA(isA<ConfigValidationException>()),
      );
    });
  });
}
