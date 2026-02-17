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
  String generateDefaultApiMethods(Map<String, dynamic> spec) {
    final paths = spec['paths'];
    if (paths is! Map) return '';

    final buffer = StringBuffer();

    paths.forEach((rawPath, rawPathItem) {
      if (rawPath is! String || rawPathItem is! Map) return;

      final pathItemParameters = _collectParameters(rawPathItem['parameters']);

      rawPathItem.forEach((rawMethod, rawOperation) {
        if (rawMethod is! String || rawOperation is! Map) return;
        if (rawMethod.toLowerCase() != 'get') return;

        final operationId = rawOperation['operationId'];
        if (operationId is! String || operationId.isEmpty) return;

        final methodName = _sanitizeMethodName(operationId);
        if (methodName == null) return;

        final operationParameters =
            _collectParameters(rawOperation['parameters']);

        // Merge path-level and operation-level parameters,
        // letting operation-level override by (name, in).
        final params = <_ParamKey, _Param>{}
          ..addAll(pathItemParameters)
          ..addAll(operationParameters);

        final pathParams = params.values
            .where((p) => p.location == 'path')
            .toList(growable: false);
        final queryParams = params.values
            .where((p) => p.location == 'query')
            .toList(growable: false);

        // All path params must be required and have a supported primitive type.
        if (pathParams.any((p) => !p.required || p.dartType == null)) return;

        // For v0.1 we only support primitive query params as well.
        if (queryParams.any((p) => p.dartType == null)) return;

        final responseKind = _classifyResponse(rawOperation);
        final methodSignature = _buildMethodSignature(
          methodName,
          pathParams,
          queryParams,
          responseKind: responseKind,
        );
        final pathExpression = _buildInterpolatedPath(rawPath, pathParams);

        if (pathExpression == null) return;

        buffer.writeln('  /// Generated from GET $rawPath');
        buffer.writeln('  $methodSignature {');
        buffer.writeln("    const _rawPath = '$rawPath';");
        buffer.writeln('    final _path = $pathExpression;');
        buffer.writeln();

        if (queryParams.isNotEmpty) {
          buffer.writeln(
            '    final queryParameters = <String, String>{};',
          );
          for (final p in queryParams) {
            final name = p.name;
            final paramName = p.dartName;
            if (p.required) {
              buffer.writeln(
                "    queryParameters['$name'] = $paramName.toString();",
              );
            } else {
              buffer.writeln(
                "    if ($paramName != null) {"
                " queryParameters['$name'] = $paramName.toString(); }",
              );
            }
          }
          buffer.writeln('    final auth = _config.auth;');
          buffer.writeln(
            '    if (auth?.apiKeyQuery != null && auth?.apiKey != null) {',
          );
          buffer.writeln(
            '      queryParameters[auth!.apiKeyQuery!] = auth.apiKey!;',
          );
          buffer.writeln('    }');
          buffer.writeln(
            '    final uri = _config.baseUrl.replace('
            'path: _path, '
            'queryParameters: queryParameters.isEmpty ? null : queryParameters,'
            ');',
          );
        } else {
          buffer.writeln(
            '    final auth = _config.auth;',
          );
          buffer.writeln(
            '    final queryParameters = <String, String>{};',
          );
          buffer.writeln(
            '    if (auth?.apiKeyQuery != null && auth?.apiKey != null) {',
          );
          buffer.writeln(
            '      queryParameters[auth!.apiKeyQuery!] = auth.apiKey!;',
          );
          buffer.writeln('    }');
          buffer.writeln(
            '    final uri = _config.baseUrl.replace('
            'path: _path, '
            'queryParameters: queryParameters.isEmpty ? null : queryParameters,'
            ');',
          );
        }

        buffer.writeln();
        buffer.writeln('    final headers = <String, String>{');
        buffer.writeln('      ..._config.defaultHeaders,');
        buffer.writeln('    };');
        buffer.writeln('    final auth = _config.auth;');
        buffer.writeln('    if (auth != null) {');
        buffer.writeln('      if (auth.bearerToken != null) {');
        buffer.writeln(
          "        headers['Authorization'] = 'Bearer \${auth.bearerToken}';",
        );
        buffer.writeln('      }');
        buffer.writeln(
          '      if (auth.apiKeyHeader != null && auth.apiKey != null) {',
        );
        buffer.writeln(
          '        headers[auth.apiKeyHeader!] = auth.apiKey!;',
        );
        buffer.writeln('      }');
        buffer.writeln('    }');
        buffer.writeln();
        buffer.writeln('    final request = HttpRequest(');
        buffer.writeln("      method: 'GET',");
        buffer.writeln('      url: uri,');
        buffer.writeln('      headers: headers,');
        buffer.writeln('    );');
        buffer.writeln();
        buffer.writeln(
          '    final response = await _config.httpClientAdapter',
        );
        buffer.writeln(
          '        .send(request).timeout(_config.timeout);',
        );
        buffer.writeln();
        buffer.writeln(
          '    if (response.statusCode == 401 || response.statusCode == 403) {',
        );
        buffer.writeln(
          "      throw ApiAuthException('Unauthorized request to \$ _rawPath',",
        );
        buffer.writeln(
          '          statusCode: response.statusCode);',
        );
        buffer.writeln('    }');
        buffer.writeln(
          '    if (response.statusCode >= 500) {',
        );
        buffer.writeln(
          "      throw ApiServerException('Server error on \$ _rawPath',",
        );
        buffer.writeln(
          '          statusCode: response.statusCode);',
        );
        buffer.writeln('    }');
        buffer.writeln(
          '    if (response.statusCode < 200 || response.statusCode >= 300) {',
        );
        buffer.writeln(
          "      throw ApiClientException('Request failed for \$ _rawPath',",
        );
        buffer.writeln(
          '          statusCode: response.statusCode);',
        );
        buffer.writeln('    }');
        buffer.writeln();
        if (responseKind == _ResponseKind.voidResponse) {
          buffer.writeln('    return;');
        } else if (responseKind == _ResponseKind.mapResponse) {
          buffer.writeln(
            '    final json = jsonDecode(response.body) as Map<String, dynamic>;',
          );
          buffer.writeln('    return json;');
        } else {
          buffer.writeln(
            '    final list = jsonDecode(response.body) as List<dynamic>;',
          );
          buffer.writeln(
            '    return list.cast<Map<String, dynamic>>();',
          );
        }
        buffer.writeln('  }');
        buffer.writeln();
      });
    });

    return buffer.toString();
  }

  Map<_ParamKey, _Param> _collectParameters(dynamic node) {
    if (node is! List) return const {};

    final result = <_ParamKey, _Param>{};
    for (final rawParam in node) {
      if (rawParam is! Map) continue;

      final name = rawParam['name'];
      final location = rawParam['in'];
      if (name is! String || location is! String) continue;

      final schema = rawParam['schema'];
      String? type;
      if (schema is Map) {
        final t = schema['type'];
        if (t is String) type = t;
      }

      final dartType = _mapOpenApiTypeToDart(type);
      final required = rawParam['required'] == true || location == 'path';

      final key = _ParamKey(name: name, location: location);
      result[key] = _Param(
        name: name,
        dartName: _toCamelCase(name),
        location: location,
        required: required,
        dartType: dartType,
      );
    }

    return result;
  }

  String? _mapOpenApiTypeToDart(String? type) {
    switch (type) {
      case 'string':
        return 'String';
      case 'integer':
      case 'number':
        return 'num';
      case 'boolean':
        return 'bool';
      default:
        return null;
    }
  }

  String _buildMethodSignature(
    String methodName,
    List<_Param> pathParams,
    List<_Param> queryParams,
    {required _ResponseKind responseKind}) {
    final buffer = StringBuffer();
    if (responseKind == _ResponseKind.voidResponse) {
      buffer.write('Future<void> $methodName({');
    } else if (responseKind == _ResponseKind.mapResponse) {
      buffer.write('Future<Map<String, dynamic>> $methodName({');
    } else {
      buffer.write('Future<List<Map<String, dynamic>>> $methodName({');
    }

    final params = <String>[];
    for (final p in pathParams) {
      params.add('required ${p.dartType} ${p.dartName}');
    }
    for (final p in queryParams) {
      final type = p.required ? p.dartType! : '${p.dartType}?';
      final modifier = p.required ? 'required ' : '';
      params.add('$modifier$type ${p.dartName}');
    }

    buffer.write(params.join(', '));
    buffer.write('}) async');
    return buffer.toString();
  }

  _ResponseKind _classifyResponse(Map<dynamic, dynamic> operation) {
    final responses = operation['responses'];
    if (responses is! Map) return _ResponseKind.mapResponse;

    // Explicit 204 response is treated as void.
    if (responses.containsKey('204')) {
      return _ResponseKind.voidResponse;
    }

    // Otherwise, check primary success response (200/201/202).
    final success = responses['200'] ?? responses['201'] ?? responses['202'];
    if (success is! Map) return _ResponseKind.mapResponse;

    final content = success['content'];
    if (content is! Map || content.isEmpty) {
      return _ResponseKind.voidResponse;
    }

    // Look at the first media type schema.
    final firstMedia = content.values.first;
    if (firstMedia is Map) {
      final schema = firstMedia['schema'];
      if (schema is Map) {
        final type = schema['type'];
        if (type == 'array') {
          return _ResponseKind.listOfMapsResponse;
        }
      }
    }

    return _ResponseKind.mapResponse;
  }

  String? _buildInterpolatedPath(String rawPath, List<_Param> pathParams) {
    var result = rawPath;
    for (final p in pathParams) {
      final placeholder = '{${p.name}}';
      if (!result.contains(placeholder)) {
        // If placeholder is missing, bail out to avoid generating wrong paths.
        return null;
      }
      result = result.replaceAll(placeholder, '\${${p.dartName}}');
    }
    return "'$result'";
  }

  String _toCamelCase(String input) {
    final parts = input.split(RegExp(r'[_\-\s]+'));
    if (parts.isEmpty) return input;
    final first = parts.first.toLowerCase();
    final rest = parts.skip(1).map((p) {
      if (p.isEmpty) return '';
      return p[0].toUpperCase() + p.substring(1).toLowerCase();
    }).join();
    return '$first$rest';
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

class _ParamKey {
  const _ParamKey({required this.name, required this.location});

  final String name;
  final String location;

  @override
  bool operator ==(Object other) {
    return other is _ParamKey &&
        other.name == name &&
        other.location == location;
  }

  @override
  int get hashCode => Object.hash(name, location);
}

class _Param {
  const _Param({
    required this.name,
    required this.dartName,
    required this.location,
    required this.required,
    required this.dartType,
  });

  final String name;
  final String dartName;
  final String location; // 'path' or 'query'
  final bool required;
  final String? dartType;
}

enum _ResponseKind {
  voidResponse,
  mapResponse,
  listOfMapsResponse,
}
