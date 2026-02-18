
/// Parses security schemes from OpenAPI/Swagger specification.
///
/// Supports OpenAPI 3.x and Swagger 2.0 security definitions.
class SecuritySchemesParser {
  /// Extracts security schemes from OpenAPI 3.x spec.
  ///
  /// Returns a map of scheme name to scheme definition.
  static Map<String, Map<String, dynamic>> parseOpenApi3(
    Map<String, dynamic> spec,
  ) {
    final components = spec['components'] as Map<String, dynamic>?;
    if (components == null) return {};

    final securitySchemes = components['securitySchemes'] as Map<String, dynamic>?;
    if (securitySchemes == null) return {};

    return Map<String, Map<String, dynamic>>.from(
      securitySchemes.map((key, value) {
        if (value is Map) {
          return MapEntry(key, Map<String, dynamic>.from(value));
        }
        return MapEntry(key, <String, dynamic>{});
      }),
    );
  }

  /// Extracts security definitions from Swagger 2.0 spec.
  ///
  /// Returns a map of scheme name to scheme definition.
  static Map<String, Map<String, dynamic>> parseSwagger2(
    Map<String, dynamic> spec,
  ) {
    final securityDefinitions = spec['securityDefinitions'] as Map<String, dynamic>?;
    if (securityDefinitions == null) return {};

    return Map<String, Map<String, dynamic>>.from(
      securityDefinitions.map((key, value) {
        if (value is Map) {
          return MapEntry(key, Map<String, dynamic>.from(value));
        }
        return MapEntry(key, <String, dynamic>{});
      }),
    );
  }

  /// Extracts security requirements for an operation.
  ///
  /// Returns a list of security requirement maps (each map represents
  /// alternative security options, where keys are scheme names and values
  /// are scopes/requirements).
  static List<Map<String, List<String>>> parseOperationSecurity(
    Map<String, dynamic> operation,
  ) {
    final security = operation['security'] as List?;
    if (security == null) return [];

    return security.map((item) {
      if (item is Map) {
        return Map<String, List<String>>.from(
          item.map((key, value) {
            if (value is List) {
              return MapEntry(
                key.toString(),
                value.map((v) => v.toString()).toList(),
              );
            }
            return MapEntry(key.toString(), <String>[]);
          }),
        );
      }
      return <String, List<String>>{};
    }).toList();
  }

  /// Extracts global security requirements from spec.
  ///
  /// Returns a list of security requirement maps.
  static List<Map<String, List<String>>> parseGlobalSecurity(
    Map<String, dynamic> spec,
  ) {
    final security = spec['security'] as List?;
    if (security == null) return [];

    return security.map((item) {
      if (item is Map) {
        return Map<String, List<String>>.from(
          item.map((key, value) {
            if (value is List) {
              return MapEntry(
                key.toString(),
                value.map((v) => v.toString()).toList(),
              );
            }
            return MapEntry(key.toString(), <String>[]);
          }),
        );
      }
      return <String, List<String>>{};
    }).toList();
  }

  /// Determines the type of security scheme.
  ///
  /// Returns: 'apiKey', 'http', 'oauth2', 'openIdConnect', or null.
  static String? getSchemeType(Map<String, dynamic> scheme) {
    return scheme['type'] as String?;
  }

  /// Gets the location for API key scheme ('query', 'header', 'cookie').
  static String? getApiKeyLocation(Map<String, dynamic> scheme) {
    return scheme['in'] as String?;
  }

  /// Gets the name for API key scheme.
  static String? getApiKeyName(Map<String, dynamic> scheme) {
    return scheme['name'] as String?;
  }

  /// Gets the scheme for HTTP authentication ('basic', 'bearer', 'digest').
  static String? getHttpScheme(Map<String, dynamic> scheme) {
    return scheme['scheme'] as String?;
  }

  /// Gets the bearer format for HTTP bearer authentication.
  static String? getBearerFormat(Map<String, dynamic> scheme) {
    return scheme['bearerFormat'] as String?;
  }

  /// Gets OAuth2 flows configuration.
  static Map<String, dynamic>? getOAuth2Flows(Map<String, dynamic> scheme) {
    final flows = scheme['flows'] as Map<String, dynamic>?;
    return flows;
  }

  /// Gets OpenID Connect URL.
  static String? getOpenIdConnectUrl(Map<String, dynamic> scheme) {
    return scheme['openIdConnectUrl'] as String?;
  }
}
