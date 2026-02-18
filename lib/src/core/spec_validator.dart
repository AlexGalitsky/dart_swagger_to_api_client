/// Validates OpenAPI/Swagger specifications and provides helpful error messages.
///
/// This validator checks for common issues and unsupported features,
/// helping users understand why certain endpoints might not be generated.
class SpecValidator {
  /// Validates the spec and returns a list of warnings/errors.
  ///
  /// Returns empty list if spec is valid.
  static List<SpecIssue> validate(Map<String, dynamic> spec) {
    final issues = <SpecIssue>[];

    // Check OpenAPI version and compatibility
    final openApiVersion = spec['openapi'] as String?;
    final swaggerVersion = spec['swagger'] as String?;
    
    if (openApiVersion != null) {
      final version = _parseVersion(openApiVersion);
      if (version != null) {
        if (version.major == 3) {
          if (version.minor > 1) {
            issues.add(SpecIssue(
              severity: IssueSeverity.warning,
              message: 'OpenAPI $openApiVersion may not be fully supported. '
                  'This package is tested with OpenAPI 3.0.0 and 3.1.0.',
              path: '/openapi',
            ));
          }
        } else if (version.major < 3) {
          issues.add(SpecIssue(
            severity: IssueSeverity.warning,
            message: 'OpenAPI $openApiVersion is deprecated. '
                'Consider upgrading to OpenAPI 3.0.0 or later.',
            path: '/openapi',
          ));
        }
      }
    } else if (swaggerVersion != null) {
      final version = _parseVersion(swaggerVersion);
      if (version != null && version.major == 2) {
        issues.add(SpecIssue(
          severity: IssueSeverity.warning,
          message: 'Swagger 2.0 is supported but deprecated. '
              'Consider migrating to OpenAPI 3.0.0 or later.',
          path: '/swagger',
        ));
      }
    } else {
      issues.add(SpecIssue(
        severity: IssueSeverity.warning,
        message: 'Spec does not declare OpenAPI or Swagger version. '
            'Assuming OpenAPI 3.0.0 compatibility.',
        path: '/',
      ));
    }

    // Check for required top-level keys
    if (!spec.containsKey('paths') || spec['paths'] is! Map) {
      issues.add(SpecIssue(
        severity: IssueSeverity.error,
        message: 'Spec must contain a "paths" section with at least one endpoint.',
        path: '/',
      ));
      return issues; // Can't continue validation without paths
    }

    final paths = spec['paths'] as Map;
    if (paths.isEmpty) {
      issues.add(SpecIssue(
        severity: IssueSeverity.warning,
        message: 'Spec contains no paths. No API methods will be generated.',
        path: '/paths',
      ));
    }

    // Check for deprecated features
    _checkDeprecatedFeatures(spec, issues);

    // Validate each path
    paths.forEach((pathKey, pathItem) {
      if (pathKey is! String || pathItem is! Map) return;

      final pathIssues = _validatePath(pathKey, pathItem as Map<String, dynamic>);
      issues.addAll(pathIssues);
    });

    return issues;
  }

  static List<SpecIssue> _validatePath(String path, Map<String, dynamic> pathItem) {
    final issues = <SpecIssue>[];

    pathItem.forEach((method, operation) {
      if (operation is! Map<String, dynamic>) return;

      final httpMethod = method.toLowerCase();
      if (!['get', 'post', 'put', 'delete', 'patch', 'head', 'options'].contains(httpMethod)) {
        return; // Skip unknown methods
      }

      final op = operation;
      final pathToOperation = '/paths/$path/$method';

      // Check for operationId (required for generation)
      if (!op.containsKey('operationId') || op['operationId'] is! String) {
        issues.add(SpecIssue(
          severity: IssueSeverity.warning,
          message: 'Operation "$httpMethod $path" is missing "operationId". '
              'It will be skipped during generation.',
          path: pathToOperation,
        ));
      }

      // Check for unsupported requestBody content types
      final requestBody = op['requestBody'];
      if (requestBody is Map) {
        final content = requestBody['content'];
        if (content is Map && content.isNotEmpty) {
          final supportedTypes = [
            'application/json',
            'application/x-www-form-urlencoded',
            'multipart/form-data',
          ];
          final unsupportedTypes = content.keys
              .where((key) => key is String && !supportedTypes.contains(key))
              .toList();
          if (unsupportedTypes.isNotEmpty) {
            issues.add(SpecIssue(
              severity: IssueSeverity.warning,
              message: 'Operation "$httpMethod $path" uses unsupported content types: '
                  '${unsupportedTypes.join(", ")}. Only "application/json" and '
                  '"application/x-www-form-urlencoded" are supported. '
                  'The operation will be skipped if it requires requestBody.',
              path: pathToOperation,
            ));
          }
        }
      }

      // Check for unsupported parameter locations
      final parameters = op['parameters'];
      if (parameters is List) {
        for (var i = 0; i < parameters.length; i++) {
          final param = parameters[i];
          if (param is Map) {
            final location = param['in'];
            if (location is String &&
                !['path', 'query', 'header', 'cookie'].contains(location)) {
              issues.add(SpecIssue(
                severity: IssueSeverity.warning,
                message: 'Parameter "${param['name']}" in operation "$httpMethod $path" '
                    'uses unsupported location "$location". Only "path", "query", '
                    '"header", and "cookie" parameters are supported. '
                    'This parameter will be ignored.',
                path: '$pathToOperation/parameters[$i]',
              ));
            }
          }
        }
      }
    });

    return issues;
  }

  /// Checks for deprecated OpenAPI features.
  static void _checkDeprecatedFeatures(
    Map<String, dynamic> spec,
    List<SpecIssue> issues,
  ) {
    // Check for deprecated 'consumes' and 'produces' (Swagger 2.0)
    if (spec.containsKey('consumes')) {
      issues.add(SpecIssue(
        severity: IssueSeverity.warning,
        message: 'Top-level "consumes" is deprecated in OpenAPI 3.0. '
            'Use "requestBody.content" instead.',
        path: '/consumes',
      ));
    }

    if (spec.containsKey('produces')) {
      issues.add(SpecIssue(
        severity: IssueSeverity.warning,
        message: 'Top-level "produces" is deprecated in OpenAPI 3.0. '
            'Use "responses.*.content" instead.',
        path: '/produces',
      ));
    }

    // Check for deprecated 'host', 'basePath', 'schemes' (Swagger 2.0)
    if (spec.containsKey('host')) {
      issues.add(SpecIssue(
        severity: IssueSeverity.warning,
        message: 'Top-level "host" is deprecated in OpenAPI 3.0. '
            'Use "servers" array instead.',
        path: '/host',
      ));
    }

    if (spec.containsKey('basePath')) {
      issues.add(SpecIssue(
        severity: IssueSeverity.warning,
        message: 'Top-level "basePath" is deprecated in OpenAPI 3.0. '
            'Use "servers" array instead.',
        path: '/basePath',
      ));
    }

    if (spec.containsKey('schemes')) {
      issues.add(SpecIssue(
        severity: IssueSeverity.warning,
        message: 'Top-level "schemes" is deprecated in OpenAPI 3.0. '
            'Use "servers" array instead.',
        path: '/schemes',
      ));
    }
  }

  /// Parses a version string (e.g., "3.0.0") into a Version object.
  static _Version? _parseVersion(String versionString) {
    try {
      final parts = versionString.split('.');
      if (parts.length >= 2) {
        final major = int.parse(parts[0]);
        final minor = int.parse(parts[1]);
        final patch = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
        return _Version(major, minor, patch);
      }
    } catch (_) {
      // Invalid version format
    }
    return null;
  }
}

/// Represents a version number.
class _Version {
  _Version(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  @override
  String toString() => '$major.$minor.$patch';
}

/// Represents a validation issue found in the spec.
class SpecIssue {
  SpecIssue({
    required this.severity,
    required this.message,
    required this.path,
  });

  final IssueSeverity severity;
  final String message;
  final String path;

  @override
  String toString() {
    final severityLabel = severity == IssueSeverity.error ? 'ERROR' : 'WARNING';
    return '[$severityLabel] $path: $message';
  }
}

enum IssueSeverity {
  error,
  warning,
}
