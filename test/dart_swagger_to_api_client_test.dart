/// Master test file that imports all test suites.
///
/// This file organizes tests by topic for better maintainability.
/// Run all tests with: dart test test/dart_swagger_to_api_client_test.dart
///
/// For integration tests (require internet), run:
/// dart test --dart-define=ENABLE_INTEGRATION_TESTS=true test/integration_test.dart

import 'api_client_facade_integration_test.dart' as facade_integration_test;
import 'api_client_facade_test.dart' as facade_test;
import 'api_client_generator_test.dart' as generator_test;
import 'auth_config_test.dart' as auth_config_test;
import 'config_integration_test.dart' as config_integration_test;
import 'config_loader_env_test.dart' as config_loader_env_test;
import 'config_loader_test.dart' as config_loader_test;
import 'config_validator_test.dart' as config_validator_test;
import 'custom_adapter_test.dart' as custom_adapter_test;
import 'dart_compatibility_test.dart' as dart_compatibility_test;
import 'dio_http_client_adapter_test.dart' as dio_adapter_test;
import 'multipart_test.dart' as multipart_test;
import 'openapi_versions_test.dart' as openapi_versions_test;
import 'pagination_test.dart' as pagination_test;
import 'performance_test.dart' as performance_test;
import 'edge_cases_test.dart' as edge_cases_test;
import 'endpoint_method_generator_test.dart' as endpoint_generator_test;
import 'file_based_models_resolver_test.dart' as models_resolver_test;
import 'http_client_adapter_test.dart' as http_adapter_test;
import 'models_config_loader_test.dart' as models_config_loader_test;
import 'regression_test.dart' as regression_test;
import 'spec_validator_test.dart' as spec_validator_test;
import 'watch_mode_test.dart' as watch_mode_test;

void main() {
  // Core functionality tests
  generator_test.main();
  endpoint_generator_test.main();
  spec_validator_test.main();

  // Configuration tests
  config_loader_test.main();
  config_loader_env_test.main();
  config_validator_test.main();
  auth_config_test.main();
  models_config_loader_test.main();

  // HTTP adapter tests
  http_adapter_test.main();
  dio_adapter_test.main();
  custom_adapter_test.main();
  multipart_test.main();

  // Models integration tests
  models_resolver_test.main();

  // Facade tests
  facade_test.main();
  facade_integration_test.main();

  // Regression and edge cases
  regression_test.main();
  edge_cases_test.main();
  pagination_test.main();
  watch_mode_test.main();

  // Performance and compatibility tests
  performance_test.main();
  openapi_versions_test.main();
  config_integration_test.main();
  dart_compatibility_test.main();
}
