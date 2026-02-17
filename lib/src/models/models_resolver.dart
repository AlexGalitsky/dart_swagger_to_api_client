/// Resolves OpenAPI `$ref` references to Dart type names.
///
/// This is a placeholder interface for future integration with
/// `dart_swagger_to_models`. At v0.1 we don't actually resolve to real
/// model types, but this interface establishes the contract for when
/// we add that capability.
abstract class ModelsResolver {
  /// Resolves an OpenAPI `$ref` to a Dart type name.
  ///
  /// Example: `#/components/schemas/User` → `User`
  ///
  /// Returns `null` if the reference cannot be resolved or if the
  /// corresponding model doesn't exist.
  String? resolveRefToType(String ref);

  /// Gets the import path for a model type.
  ///
  /// Example: `User` → `package:my_app/models/user.dart`
  ///
  /// Returns `null` if the type is not found or doesn't need an import
  /// (e.g., built-in types).
  String? getImportPath(String typeName);

  /// Checks if a type name corresponds to a generated model.
  ///
  /// This is useful to distinguish between:
  /// - Generated models (e.g., `User`, `Order`)
  /// - Built-in types (e.g., `String`, `int`, `Map<String, dynamic>`)
  bool isModelType(String typeName);
}

/// Placeholder implementation that doesn't resolve anything.
///
/// This is used by default in v0.1 when we don't have access to
/// `dart_swagger_to_models` configuration. All methods return `null`/`false`,
/// meaning we continue to use `Map<String, dynamic>` instead of real types.
class NoOpModelsResolver implements ModelsResolver {
  const NoOpModelsResolver();

  @override
  String? resolveRefToType(String ref) => null;

  @override
  String? getImportPath(String typeName) => null;

  @override
  bool isModelType(String typeName) => false;
}
