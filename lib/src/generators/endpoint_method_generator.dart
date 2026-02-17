/// Minimal per-endpoint method generation for v0.1.
///
/// Right now we purposely support only a very small subset of OpenAPI:
/// - GET operations;
/// - without path parameters (no `{id}` segments);
/// - with a valid `operationId` that can be turned into a Dart method name.
///
/// Everything else is ignored for now. This is good enough to validate the
/// client shape and wire up real methods end-to-end.
class EndpointMethodGenerator {
  const EndpointMethodGenerator();

  /// Generates Dart method declarations to be placed inside `DefaultApi`.
  ///
  /// Each method has the shape:
  ///
  /// ```dart
  /// Future<Map<String, dynamic>> getUser() async { ... }
  /// ```
  ///
  /// and uses the same calling convention as `getRaw`, but with a fixed path
  /// from the OpenAPI spec.
  String generateDefaultApiMethods(Map<String, dynamic> spec) {
    final paths = spec['paths'];
    if (paths is! Map) return '';

    final buffer = StringBuffer();

    paths.forEach((rawPath, rawPathItem) {
      if (rawPath is! String || rawPathItem is! Map) return;

      // For v0.1 we only support paths without path parameters.
      if (rawPath.contains('{')) return;

      rawPathItem.forEach((rawMethod, rawOperation) {
        if (rawMethod is! String || rawOperation is! Map) return;

        if (rawMethod.toLowerCase() != 'get') return;

        final operationId = rawOperation['operationId'];
        if (operationId is! String || operationId.isEmpty) return;

        final methodName = _sanitizeMethodName(operationId);
        if (methodName == null) return;

        buffer.writeln('  /// Generated from GET $rawPath');
        buffer.writeln(
          '  Future<Map<String, dynamic>> $methodName() async {',
        );
        buffer.writeln("    const _path = '$rawPath';");
        buffer.writeln('    final uri = _config.baseUrl.replace(path: _path);');
        buffer.writeln();
        buffer.writeln('    final request = HttpRequest(');
        buffer.writeln("      method: 'GET',");
        buffer.writeln('      url: uri,');
        buffer.writeln('      headers: _config.defaultHeaders,');
        buffer.writeln('    );');
        buffer.writeln();
        buffer.writeln(
          '    final response = await _config.httpClientAdapter.send(request);',
        );
        buffer.writeln();
        buffer.writeln(
          '    if (response.statusCode < 200 || response.statusCode >= 300) {',
        );
        buffer.writeln(
          "      throw Exception('Request failed with status \${response.statusCode}: \${response.body}');",
        );
        buffer.writeln('    }');
        buffer.writeln();
        buffer.writeln(
          '    final json = jsonDecode(response.body) as Map<String, dynamic>;',
        );
        buffer.writeln('    return json;');
        buffer.writeln('  }');
        buffer.writeln();
      });
    });

    return buffer.toString();
  }

  String? _sanitizeMethodName(String operationId) {
    final buffer = StringBuffer();
    final runes = operationId.runes.toList();

    for (var i = 0; i < runes.length; i++) {
      final ch = String.fromCharCode(runes[i]);
      final isLetterOrDigit =
          (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) || // 0-9
              (ch.codeUnitAt(0) >= 65 && ch.codeUnitAt(0) <= 90) || // A-Z
              (ch.codeUnitAt(0) >= 97 && ch.codeUnitAt(0) <= 122); // a-z

      if (i == 0) {
        // First character: must not be a digit.
        if (isLetterOrDigit && (ch.codeUnitAt(0) < 48 || ch.codeUnitAt(0) > 57)) {
          buffer.write(ch.toLowerCase());
        } else if (isLetterOrDigit) {
          buffer.write('m$ch');
        } else {
          buffer.write('_');
        }
      } else {
        buffer.write(isLetterOrDigit ? ch : '_');
      }
    }

    final result = buffer.toString();
    final identifierRegExp = RegExp(r'^[A-Za-z_]\w*$');
    if (!identifierRegExp.hasMatch(result)) {
      return null;
    }
    return result;
  }
}


