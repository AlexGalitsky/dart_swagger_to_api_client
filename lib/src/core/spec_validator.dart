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
