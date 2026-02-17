import '../models/models_resolver.dart';

/// Generates endpoint methods for API client classes.
///
/// At v0.1 this supports GET/POST/PUT/DELETE/PATCH operations with
/// path/query parameters and requestBody. Future versions will use
/// [modelsResolver] to generate type-safe methods with real model types
/// instead of `Map<String, dynamic>`.
class EndpointMethodGenerator {
  const EndpointMethodGenerator({
    ModelsResolver? modelsResolver,
  }) : _modelsResolver = modelsResolver ?? const NoOpModelsResolver();

  final ModelsResolver _modelsResolver;

  /// Generates Dart method declarations to be placed inside `DefaultApi`.
  ///
  /// Returns a tuple of (methods code, imports set).
  Future<({String methods, Set<String> imports})> generateDefaultApiMethods(
    Map<String, dynamic> spec,
  ) async {
    final paths = spec['paths'];
    if (paths is! Map) {
      return (methods: '', imports: <String>{});
    }

    final buffer = StringBuffer();
    final imports = <String>{};

    // Process paths sequentially to allow async operations
    for (final pathEntry in paths.entries) {
      final rawPath = pathEntry.key;
      final rawPathItem = pathEntry.value;
      if (rawPath is! String || rawPathItem is! Map) continue;

      final pathItemParameters = _collectParameters(rawPathItem['parameters']);

      // Process methods sequentially to allow async operations
      for (final methodEntry in rawPathItem.entries) {
        final rawMethod = methodEntry.key;
        final rawOperation = methodEntry.value;
        if (rawMethod is! String || rawOperation is! Map) continue;
        final httpMethod = rawMethod.toLowerCase();
        // Support GET, POST, PUT, DELETE, PATCH
        if (!['get', 'post', 'put', 'delete', 'patch'].contains(httpMethod)) {
          continue;
        }

        final operationId = rawOperation['operationId'];
        if (operationId is! String || operationId.isEmpty) continue;

        final methodName = _sanitizeMethodName(operationId);
        if (methodName == null) continue;

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
        if (pathParams.any((p) => !p.required || p.dartType == null)) continue;

        // For v0.1 we only support primitive query params as well.
        if (queryParams.any((p) => p.dartType == null)) continue;

        // Check for requestBody (only for POST/PUT/PATCH, DELETE typically doesn't have body)
        final hasBody = _hasRequestBody(rawOperation);
        if (hasBody && !['post', 'put', 'patch'].contains(httpMethod)) {
          // Skip methods that have requestBody but shouldn't (e.g., GET with body)
          continue;
        }
        // For POST/PUT/PATCH, require requestBody in v0.1
        if (['post', 'put', 'patch'].contains(httpMethod) && !hasBody) {
          continue;
        }

        final responseTypeInfo = await _classifyResponse(rawOperation);
        final requestBodyType = await _getRequestBodyType(rawOperation);
        
        // Collect imports for model types
        if (responseTypeInfo.modelType != null) {
          final importPath = await _modelsResolver.getImportPath(responseTypeInfo.modelType!);
          if (importPath != null) {
            imports.add(importPath);
          }
        }
        if (requestBodyType != null) {
          final importPath = await _modelsResolver.getImportPath(requestBodyType);
          if (importPath != null) {
            imports.add(importPath);
          }
        }
        
        final methodSignature = _buildMethodSignature(
          methodName,
          pathParams,
          queryParams,
          responseTypeInfo: responseTypeInfo,
          requestBodyType: requestBodyType,
          hasBody: hasBody,
        );
        final pathExpression = _buildInterpolatedPath(rawPath, pathParams);

        if (pathExpression == null) continue;

        buffer.writeln('  /// Generated from ${httpMethod.toUpperCase()} $rawPath');
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
        // Serialize body if present
        String? bodyExpression;
        if (hasBody) {
          if (requestBodyType != null) {
            // Model type - serialize using toJson()
            buffer.writeln('    final bodyJson = jsonEncode(body.toJson());');
          } else {
            // Map type - serialize directly
            buffer.writeln('    final bodyJson = jsonEncode(body);');
          }
          bodyExpression = 'bodyJson';
        }

        buffer.writeln('    final request = HttpRequest(');
        buffer.writeln("      method: '${httpMethod.toUpperCase()}',");
        buffer.writeln('      url: uri,');
        buffer.writeln('      headers: headers,');
        if (bodyExpression != null) {
          buffer.writeln('      body: $bodyExpression,');
        }
        buffer.writeln('      timeout: _config.timeout,');
        buffer.writeln('    );');
        buffer.writeln();
        buffer.writeln(
          '    final response = await _config.httpClientAdapter.send(request);',
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
        if (responseTypeInfo.kind == _ResponseKind.voidResponse) {
          buffer.writeln('    return;');
        } else if (responseTypeInfo.modelType != null) {
          // Generate deserialization for model type
          if (responseTypeInfo.isList) {
            buffer.writeln(
              '    final list = jsonDecode(response.body) as List<dynamic>;',
            );
            buffer.writeln(
              '    return list.map((json) => ${responseTypeInfo.modelType}.fromJson(json as Map<String, dynamic>)).toList();',
            );
          } else {
            buffer.writeln(
              '    final json = jsonDecode(response.body) as Map<String, dynamic>;',
            );
            buffer.writeln(
              '    return ${responseTypeInfo.modelType}.fromJson(json);',
            );
          }
        } else if (responseTypeInfo.kind == _ResponseKind.mapResponse) {
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
      }
    }

    return (methods: buffer.toString(), imports: imports);
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
    List<_Param> queryParams, {
    required _ResponseTypeInfo responseTypeInfo,
    String? requestBodyType,
    required bool hasBody,
  }) {
    final buffer = StringBuffer();
    buffer.write('Future<${responseTypeInfo.dartType}> $methodName({');

    final params = <String>[];
    for (final p in pathParams) {
      params.add('required ${p.dartType} ${p.dartName}');
    }
    for (final p in queryParams) {
      final type = p.required ? p.dartType! : '${p.dartType}?';
      final modifier = p.required ? 'required ' : '';
      params.add('$modifier$type ${p.dartName}');
    }
    if (hasBody) {
      final bodyType = requestBodyType ?? 'Map<String, dynamic>';
      params.add('required $bodyType body');
    }

    buffer.write(params.join(', '));
    buffer.write('}) async');
    return buffer.toString();
  }

  bool _hasRequestBody(Map<dynamic, dynamic> operation) {
    final requestBody = operation['requestBody'];
    if (requestBody is! Map) return false;

    final content = requestBody['content'];
    if (content is Map && content.isNotEmpty) {
      // Check if there's application/json content type
      if (content.containsKey('application/json')) {
        return true;
      }
    }

    return false;
  }

  Future<_ResponseTypeInfo> _classifyResponse(
    Map<dynamic, dynamic> operation,
  ) async {
    final responses = operation['responses'];
    if (responses is! Map) {
      return _ResponseTypeInfo.mapResponse;
    }

    // Explicit 204 response is treated as void.
    if (responses.containsKey('204')) {
      return _ResponseTypeInfo.voidResponse;
    }

    // Otherwise, check primary success response (200/201/202).
    final success = responses['200'] ?? responses['201'] ?? responses['202'];
    if (success is! Map) {
      return _ResponseTypeInfo.mapResponse;
    }

    final content = success['content'];
    if (content is! Map || content.isEmpty) {
      return _ResponseTypeInfo.voidResponse;
    }

    // Look at the first media type schema.
    final firstMedia = content.values.first;
    if (firstMedia is Map) {
      final schema = firstMedia['schema'];
      if (schema is Map) {
        // Check for $ref
        final ref = schema['\$ref'];
        if (ref is String) {
          final modelType = await _modelsResolver.resolveRefToType(ref);
          if (modelType != null) {
            final type = schema['type'];
            if (type == 'array') {
              return _ResponseTypeInfo(
                kind: _ResponseKind.listOfMapsResponse,
                modelType: modelType,
                isList: true,
              );
            }
            return _ResponseTypeInfo(
              kind: _ResponseKind.mapResponse,
              modelType: modelType,
            );
          }
        }

        // Check for array type
        final type = schema['type'];
        if (type == 'array') {
          // Check if array items have $ref
          final items = schema['items'];
          if (items is Map) {
            final itemsRef = items['\$ref'];
            if (itemsRef is String) {
              final modelType = await _modelsResolver.resolveRefToType(itemsRef);
              if (modelType != null) {
                return _ResponseTypeInfo(
                  kind: _ResponseKind.listOfMapsResponse,
                  modelType: modelType,
                  isList: true,
                );
              }
            }
          }
          return _ResponseTypeInfo.listOfMapsResponse;
        }
      }
    }

    return _ResponseTypeInfo.mapResponse;
  }

  /// Gets the Dart type for requestBody, if it can be resolved from $ref.
  Future<String?> _getRequestBodyType(Map<dynamic, dynamic> operation) async {
    final requestBody = operation['requestBody'];
    if (requestBody is! Map) return null;

    final content = requestBody['content'];
    if (content is! Map && content.isNotEmpty) {
      final jsonContent = content['application/json'];
      if (jsonContent is Map) {
        final schema = jsonContent['schema'];
        if (schema is Map) {
          final ref = schema['\$ref'];
          if (ref is String) {
            return await _modelsResolver.resolveRefToType(ref);
          }
        }
      }
    }

    return null;
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

/// Information about the response type for a generated method.
class _ResponseTypeInfo {
  const _ResponseTypeInfo({
    required this.kind,
    this.modelType,
    this.isList = false,
  });

  final _ResponseKind kind;
  final String? modelType; // Dart type name if resolved from $ref
  final bool isList; // true if response is List<ModelType>

  static const voidResponse = _ResponseTypeInfo(kind: _ResponseKind.voidResponse);
  static const mapResponse = _ResponseTypeInfo(kind: _ResponseKind.mapResponse);
  static const listOfMapsResponse = _ResponseTypeInfo(kind: _ResponseKind.listOfMapsResponse, isList: true);

  String get dartType {
    switch (kind) {
      case _ResponseKind.voidResponse:
        return 'void';
      case _ResponseKind.mapResponse:
        if (modelType != null) {
          return modelType!;
        }
        return 'Map<String, dynamic>';
      case _ResponseKind.listOfMapsResponse:
        if (modelType != null) {
          return 'List<$modelType>';
        }
        return 'List<Map<String, dynamic>>';
    }
  }
}

enum _ResponseKind {
  voidResponse,
  mapResponse,
  listOfMapsResponse,
}
