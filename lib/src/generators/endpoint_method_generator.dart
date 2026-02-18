import '../models/models_resolver.dart';
import '../core/security_schemes_parser.dart';

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

    // Parse security schemes from spec
    final securitySchemes = _parseSecuritySchemes(spec);
    final globalSecurity = SecuritySchemesParser.parseGlobalSecurity(spec);

    final buffer = StringBuffer();
    final imports = <String>{};
    bool needsBase64Import = false;

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
        final headerParams = params.values
            .where((p) => p.location == 'header')
            .toList(growable: false);
        final cookieParams = params.values
            .where((p) => p.location == 'cookie')
            .toList(growable: false);

        // All path params must be required and have a supported primitive type.
        // Additionally, if the path contains placeholders (`{id}`) but we have
        // no matching path parameters (e.g. missing schema), we skip the endpoint.
        final hasPathPlaceholders = rawPath.contains('{');
        if (hasPathPlaceholders) {
          if (pathParams.isEmpty ||
              pathParams.any((p) => !p.required || p.dartType == null)) {
            continue;
          }
        } else {
          if (pathParams.any((p) => !p.required || p.dartType == null)) {
            continue;
          }
        }

        // For v1.1.1 we support primitive, array, and object query params.
        // Skip only if we can't determine the type at all.
        if (queryParams.any((p) => p.dartType == null && !p.isArray && !p.isObject)) continue;

        // Header and cookie params must have supported primitive types.
        if (headerParams.any((p) => p.dartType == null)) continue;
        if (cookieParams.any((p) => p.dartType == null)) continue;

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

        // Parse security for this operation
        final operationSecurity = SecuritySchemesParser.parseOperationSecurity(rawOperation as Map<String, dynamic>);
        final effectiveSecurity = operationSecurity.isNotEmpty ? operationSecurity : globalSecurity;
        
        // Check if we need to add API key to query parameters from security schemes
        String? apiKeyQueryName;
        if (effectiveSecurity.isNotEmpty) {
          final securityRequirement = effectiveSecurity.first;
          for (final entry in securityRequirement.entries) {
            final schemeName = entry.key;
            final scheme = securitySchemes[schemeName];
            if (scheme != null) {
              final schemeType = SecuritySchemesParser.getSchemeType(scheme);
              if (schemeType == 'apiKey') {
                final location = SecuritySchemesParser.getApiKeyLocation(scheme);
                if (location == 'query') {
                  apiKeyQueryName = SecuritySchemesParser.getApiKeyName(scheme);
                  break; // Found API key in query, no need to continue
                }
              }
            }
          }
        }

        final responseTypeInfo = await _classifyResponse(rawOperation);
        final requestBodyType = await _getRequestBodyType(rawOperation);
        final requestBodyContentType = _getRequestBodyContentType(rawOperation);
        
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
          headerParams: headerParams,
          cookieParams: cookieParams,
          responseTypeInfo: responseTypeInfo,
          requestBodyType: requestBodyType,
          requestBodyContentType: requestBodyContentType,
          hasBody: hasBody,
        );
        final pathExpression = _buildInterpolatedPath(rawPath, pathParams);

        if (pathExpression == null) continue;

        // Detect pagination patterns
        final hasPagination = _detectPagination(queryParams);
        
        buffer.writeln('  /// Generated from ${httpMethod.toUpperCase()} $rawPath');
        if (hasPagination) {
          buffer.writeln('  ///');
          buffer.writeln('  /// This endpoint supports pagination via query parameters.');
        }
        buffer.writeln('  $methodSignature {');
        buffer.writeln("    const _rawPath = '$rawPath';");
        buffer.writeln('    final _path = $pathExpression;');
        buffer.writeln();

        // Check if we need to handle arrays with explode (multiple query params with same name)
        final hasExplodedArrays = queryParams.any((p) => p.isArray && p.explode && p.style == 'form');
        
        // Check if we need query parameters (from params or API key in query from security scheme)
        final needsQueryParams = queryParams.isNotEmpty || hasExplodedArrays || apiKeyQueryName != null;
        
        if (needsQueryParams) {
          if (hasExplodedArrays) {
            // Use queryParametersAll for arrays with explode
            buffer.writeln(
              '    final queryParametersAll = <String, List<String>>{};',
            );
            buffer.writeln(
              '    final queryParameters = <String, String>{};',
            );
            
            for (final p in queryParams) {
              final name = p.name;
              final paramName = p.dartName;
              
              if (p.isArray) {
                if (p.explode && p.style == 'form') {
                  // form + explode: need to add multiple values
                  if (p.required) {
                    buffer.writeln('    if ($paramName.isNotEmpty) {');
                  } else {
                    buffer.writeln("    if ($paramName != null && $paramName.isNotEmpty) {");
                  }
                  buffer.writeln(
                    "      queryParametersAll['$name'] = $paramName.map((e) => e.toString()).toList();",
                  );
                  buffer.writeln('    }');
                } else {
                  // Other array styles: single value
                  if (p.required) {
                    buffer.writeln('    if ($paramName.isNotEmpty) {');
                  } else {
                    buffer.writeln("    if ($paramName != null && $paramName.isNotEmpty) {");
                  }
                  buffer.writeln(_generateArraySerialization(p, paramName, name));
                  buffer.writeln('    }');
                }
              } else if (p.isObject) {
                // Handle object parameters
                if (p.required) {
                  buffer.writeln('    {');
                } else {
                  buffer.writeln("    if ($paramName != null) {");
                }
                buffer.writeln(_generateObjectSerialization(p, paramName, name));
                buffer.writeln('    }');
              } else {
                // Handle primitive parameters
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
            }
            
            buffer.writeln('    final auth = _config.auth;');
            // Add API key from security scheme or config
            if (apiKeyQueryName != null) {
              buffer.writeln('    if (auth?.apiKey != null) {');
              buffer.writeln("      queryParametersAll['$apiKeyQueryName'] = [auth!.apiKey!];");
              buffer.writeln('    }');
            } else {
              buffer.writeln(
                '    if (auth?.apiKeyQuery != null && auth?.apiKey != null) {',
              );
              buffer.writeln(
                '      queryParametersAll[auth!.apiKeyQuery!] = [auth.apiKey!];',
              );
              buffer.writeln('    }');
            }
            
            // Build URI with queryParametersAll
            buffer.writeln('    final uriBuilder = _config.baseUrl.replace(path: _path);');
            buffer.writeln('    final allQueryParams = <String, List<String>>{};');
            buffer.writeln('    queryParametersAll.forEach((key, values) {');
            buffer.writeln('      allQueryParams[key] = values;');
            buffer.writeln('    });');
            buffer.writeln('    queryParameters.forEach((key, value) {');
            buffer.writeln('      allQueryParams[key] = [value];');
            buffer.writeln('    });');
            buffer.writeln('    final uri = uriBuilder.replace(');
            buffer.writeln('      queryParametersAll: allQueryParams.isEmpty ? null : allQueryParams,');
            buffer.writeln('    );');
          } else {
            // Standard case: no exploded arrays
            buffer.writeln(
              '    final queryParameters = <String, String>{};',
            );
            for (final p in queryParams) {
              final name = p.name;
              final paramName = p.dartName;
              
              if (p.isArray) {
                // Handle array parameters
                if (p.required) {
                  buffer.writeln('    if ($paramName.isNotEmpty) {');
                } else {
                  buffer.writeln("    if ($paramName != null && $paramName.isNotEmpty) {");
                }
                buffer.writeln(_generateArraySerialization(p, paramName, name));
                buffer.writeln('    }');
              } else if (p.isObject) {
                // Handle object parameters
                if (p.required) {
                  buffer.writeln('    {');
                } else {
                  buffer.writeln("    if ($paramName != null) {");
                }
                buffer.writeln(_generateObjectSerialization(p, paramName, name));
                buffer.writeln('    }');
              } else {
                // Handle primitive parameters
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
            }
            buffer.writeln('    final auth = _config.auth;');
            // Add API key from security scheme or config
            if (apiKeyQueryName != null) {
              buffer.writeln('    if (auth?.apiKey != null) {');
              buffer.writeln("      queryParameters['$apiKeyQueryName'] = auth!.apiKey!;");
              buffer.writeln('    }');
            } else {
              buffer.writeln(
                '    if (auth?.apiKeyQuery != null && auth?.apiKey != null) {',
              );
              buffer.writeln(
                '      queryParameters[auth!.apiKeyQuery!] = auth.apiKey!;',
              );
              buffer.writeln('    }');
            }
            buffer.writeln(
              '    final uri = _config.baseUrl.replace('
              'path: _path, '
              'queryParameters: queryParameters.isEmpty ? null : queryParameters,'
              ');',
            );
          }
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
        
        // Add header parameters
        if (headerParams.isNotEmpty) {
          for (final p in headerParams) {
            if (p.required) {
              buffer.writeln("    headers['${p.name}'] = ${p.dartName}.toString();");
            } else {
              buffer.writeln("    if (${p.dartName} != null) {");
              buffer.writeln("      headers['${p.name}'] = ${p.dartName}!.toString();");
              buffer.writeln('    }');
            }
          }
        }
        
        // Add cookie parameters (as Cookie header)
        if (cookieParams.isNotEmpty) {
          buffer.writeln('    final cookieParts = <String>[];');
          for (final p in cookieParams) {
            if (p.required) {
              buffer.writeln(
                "    cookieParts.add('${p.name}=\${Uri.encodeComponent(${p.dartName}.toString())}');",
              );
            } else {
              buffer.writeln("    if (${p.dartName} != null) {");
              buffer.writeln(
                "      cookieParts.add('${p.name}=\${Uri.encodeComponent(${p.dartName}!.toString())}');",
              );
              buffer.writeln('    }');
            }
          }
          buffer.writeln("    if (cookieParts.isNotEmpty) {");
          buffer.writeln("      headers['Cookie'] = cookieParts.join('; ');");
          buffer.writeln('    }');
        }
        
        // Apply security schemes (skip API key in query as it's already handled above)
        // Note: effectiveSecurity is already computed above
        
        if (effectiveSecurity.isNotEmpty) {
          // Use first security requirement (OpenAPI allows multiple alternatives)
          final securityRequirement = effectiveSecurity.first;
          // Filter out API key in query as it's already handled
          final filteredRequirement = Map<String, List<String>>.fromEntries(
            securityRequirement.entries.where((entry) {
              final scheme = securitySchemes[entry.key];
              if (scheme == null) return true;
              final schemeType = SecuritySchemesParser.getSchemeType(scheme);
              if (schemeType == 'apiKey') {
                final location = SecuritySchemesParser.getApiKeyLocation(scheme);
                return location != 'query'; // Skip query API keys, already handled
              }
              return true;
            }),
          );
          
          if (filteredRequirement.isNotEmpty) {
            final needsBase64 = _generateSecurityCode(buffer, filteredRequirement, securitySchemes);
            if (needsBase64 && !needsBase64Import) {
              needsBase64Import = true;
              imports.add('dart:convert');
            }
          }
        } else {
          // Fallback to legacy auth config for backward compatibility
          buffer.writeln('    final auth = _config.auth;');
          buffer.writeln('    if (auth != null) {');
          buffer.writeln('      final bearerToken = auth.resolveBearerToken();');
          buffer.writeln('      if (bearerToken != null) {');
          buffer.writeln(
            "        headers['Authorization'] = 'Bearer \$bearerToken';",
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
        }
        buffer.writeln();
        // Serialize body if present
        String? bodyExpression;
        if (hasBody) {
          if (requestBodyContentType == 'multipart/form-data') {
            // Multipart/form-data: body is Map<String, dynamic> where values can be
            // String, File, or List<int>. The adapter will handle conversion to MultipartRequest.
            // We store the body as-is and let the adapter detect and handle multipart.
            bodyExpression = 'body';
            // Don't set Content-Type header - adapter will set it with boundary for multipart
            // For now, we'll pass the body as Map and adapter will check for File/List<int>
          } else if (requestBodyContentType == 'application/x-www-form-urlencoded') {
            // Form-urlencoded: convert Map to query string
            buffer.writeln('    final formData = body.entries');
            buffer.writeln(
              "        .map((e) => '\${Uri.encodeComponent(e.key)}=\${Uri.encodeComponent(e.value)}')",
            );
            buffer.writeln("        .join('&');");
            bodyExpression = 'formData';
            // Set Content-Type header for form-urlencoded
            buffer.writeln(
              "    headers['Content-Type'] = 'application/x-www-form-urlencoded';",
            );
          } else {
            // JSON content type (default)
            if (requestBodyType != null) {
              // Model type - serialize using toJson()
              buffer.writeln('    final bodyJson = jsonEncode(body.toJson());');
            } else {
              // Map type - serialize directly
              buffer.writeln('    final bodyJson = jsonEncode(body);');
            }
            bodyExpression = 'bodyJson';
            buffer.writeln("    headers['Content-Type'] = 'application/json';");
          }
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
          "      throw ApiAuthException('Unauthorized request to \$_rawPath',",
        );
        buffer.writeln(
          '          statusCode: response.statusCode);',
        );
        buffer.writeln('    }');
        buffer.writeln(
          '    if (response.statusCode >= 500) {',
        );
        buffer.writeln(
          "      throw ApiServerException('Server error on \$_rawPath',",
        );
        buffer.writeln(
          '          statusCode: response.statusCode);',
        );
        buffer.writeln('    }');
        buffer.writeln(
          '    if (response.statusCode < 200 || response.statusCode >= 300) {',
        );
        buffer.writeln(
          "      throw ApiClientException('Request failed for \$_rawPath',",
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

      // Support path, query, header, and cookie parameters
      if (!['path', 'query', 'header', 'cookie'].contains(location)) {
        continue; // Skip unsupported parameter locations
      }

      final schema = rawParam['schema'] as Map<String, dynamic>?;
      if (schema == null) continue;

      // Extract style and explode (with defaults per OpenAPI spec)
      String style = rawParam['style'] as String? ?? _getDefaultStyle(location);
      bool explode = rawParam['explode'] as bool? ?? _getDefaultExplode(style);

      // Check if it's an array
      final type = schema['type'] as String?;
      final isArray = type == 'array';
      
      // Check if it's an object
      final isObject = type == 'object' || schema.containsKey('properties');

      String? dartType;
      String? arrayItemType;
      
      if (isArray) {
        final items = schema['items'] as Map<String, dynamic>?;
        if (items != null) {
          final itemType = items['type'] as String?;
          arrayItemType = _mapOpenApiTypeToDart(itemType);
          dartType = arrayItemType != null ? 'List<$arrayItemType>' : 'List<dynamic>';
        } else {
          dartType = 'List<dynamic>';
        }
      } else if (isObject) {
        // For objects, we'll use Map<String, dynamic> for now
        // Future versions could use generated model types
        dartType = 'Map<String, dynamic>';
      } else {
        dartType = _mapOpenApiTypeToDart(type);
      }

      // Path parameters are always required, others depend on 'required' field
      final required = rawParam['required'] == true || location == 'path';

      final key = _ParamKey(name: name, location: location);
      result[key] = _Param(
        name: name,
        dartName: _toCamelCase(name),
        location: location,
        required: required,
        dartType: dartType,
        isArray: isArray,
        arrayItemType: arrayItemType,
        isObject: isObject,
        style: style,
        explode: explode,
        schema: schema,
      );
    }

    return result;
  }

  /// Returns default style for a parameter location per OpenAPI spec.
  String _getDefaultStyle(String location) {
    switch (location) {
      case 'path':
        return 'simple';
      case 'query':
        return 'form';
      case 'header':
        return 'simple';
      case 'cookie':
        return 'form';
      default:
        return 'form';
    }
  }

  /// Returns default explode value for a style per OpenAPI spec.
  bool _getDefaultExplode(String style) {
    switch (style) {
      case 'form':
        return true;
      case 'simple':
      case 'spaceDelimited':
      case 'pipeDelimited':
      case 'deepObject':
        return false;
      default:
        return true;
    }
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

  /// Generates code to serialize an array parameter according to OpenAPI style rules.
  String _generateArraySerialization(_Param param, String paramName, String paramKey) {
    final style = param.style;
    final explode = param.explode;
    
    if (style == 'form') {
      if (explode) {
        // form + explode: handled separately with queryParametersAll
        // This should not be called for exploded form arrays
        return "      queryParameters['$paramKey'] = $paramName"
            ".map((e) => e.toString()).join(',');";
      } else {
        // form + no explode: ?id=1,2,3 (comma-separated)
        return "      queryParameters['$paramKey'] = $paramName"
            ".map((e) => e.toString()).join(',');";
      }
    } else if (style == 'spaceDelimited') {
      // spaceDelimited: ?id=1 2 3 (space-separated, explode has no effect)
      return "      queryParameters['$paramKey'] = $paramName"
          ".map((e) => e.toString()).join(' ');";
    } else if (style == 'pipeDelimited') {
      // pipeDelimited: ?id=1|2|3 (pipe-separated, explode has no effect)
      return "      queryParameters['$paramKey'] = $paramName"
          ".map((e) => e.toString()).join('|');";
    } else {
      // simple style (for path/header, but handle gracefully)
      if (explode) {
        // simple + explode: 1,2,3 (comma-separated)
        return "      queryParameters['$paramKey'] = $paramName"
            ".map((e) => e.toString()).join(',');";
      } else {
        // simple + no explode: 1,2,3 (comma-separated, same as explode)
        return "      queryParameters['$paramKey'] = $paramName"
            ".map((e) => e.toString()).join(',');";
      }
    }
  }

  /// Generates code to serialize an object parameter according to OpenAPI style rules.
  String _generateObjectSerialization(_Param param, String paramName, String paramKey) {
    final style = param.style;
    final explode = param.explode;
    
    if (style == 'deepObject') {
      // deepObject: ?user[name]=John&user[age]=30 (always exploded)
      return "      $paramName.forEach((key, value) {"
          " queryParameters['$paramKey[\$key]'] = value.toString(); });";
    } else if (style == 'form') {
      if (explode) {
        // form + explode: ?name=John&age=30
        return "      $paramName.forEach((key, value) {"
            " queryParameters[key] = value.toString(); });";
      } else {
        // form + no explode: ?user=name,John,age,30 (comma-separated)
        return "      final objParts = <String>[];"
            " $paramName.forEach((key, value) {"
            " objParts.addAll([key, value.toString()]); });"
            " queryParameters['$paramKey'] = objParts.join(',');";
      }
    } else {
      // simple style (for path/header, but handle gracefully)
      if (explode) {
        // simple + explode: name=John,age=30 (comma-separated key=value pairs)
        return "      queryParameters['$paramKey'] = $paramName.entries"
            ".map((e) => '\${e.key}=\${e.value}').join(',');";
      } else {
        // simple + no explode: name,John,age,30 (comma-separated values)
        return "      final objParts = <String>[];"
            " $paramName.forEach((key, value) {"
            " objParts.addAll([key, value.toString()]); });"
            " queryParameters['$paramKey'] = objParts.join(',');";
      }
    }
  }

  /// Detects pagination patterns in query parameters.
  ///
  /// Returns true if the endpoint has typical pagination parameters:
  /// - `page` or `offset` (for page-based or offset-based pagination)
  /// - `limit` or `per_page` (for page size)
  bool _detectPagination(List<_Param> queryParams) {
    final paramNames = queryParams.map((p) => p.name.toLowerCase()).toSet();
    
    // Check for page-based pagination
    final hasPageParam = paramNames.contains('page') || paramNames.contains('offset');
    final hasLimitParam = paramNames.contains('limit') || 
                         paramNames.contains('per_page') || 
                         paramNames.contains('perpage') ||
                         paramNames.contains('page_size') ||
                         paramNames.contains('pagesize');
    
    return hasPageParam && hasLimitParam;
  }

  String _buildMethodSignature(
    String methodName,
    List<_Param> pathParams,
    List<_Param> queryParams, {
    List<_Param> headerParams = const [],
    List<_Param> cookieParams = const [],
    required _ResponseTypeInfo responseTypeInfo,
    String? requestBodyType,
    String? requestBodyContentType,
    required bool hasBody,
  }) {
    final buffer = StringBuffer();
    buffer.write('Future<${responseTypeInfo.dartType}> $methodName({');

    final params = <String>[];
    for (final p in pathParams) {
      params.add('required ${p.dartType} ${p.dartName}');
    }
    for (final p in queryParams) {
      String type;
      if (p.isArray) {
        type = p.required ? p.dartType! : '${p.dartType}?';
      } else if (p.isObject) {
        type = p.required ? p.dartType! : '${p.dartType}?';
      } else {
        type = p.required ? p.dartType! : '${p.dartType}?';
      }
      final modifier = p.required ? 'required ' : '';
      params.add('$modifier$type ${p.dartName}');
    }
    for (final p in headerParams) {
      final type = p.required ? p.dartType! : '${p.dartType}?';
      final modifier = p.required ? 'required ' : '';
      params.add('$modifier$type ${p.dartName}');
    }
    for (final p in cookieParams) {
      final type = p.required ? p.dartType! : '${p.dartType}?';
      final modifier = p.required ? 'required ' : '';
      params.add('$modifier$type ${p.dartName}');
    }
    if (hasBody) {
      // For form-urlencoded, use Map<String, String>
      // For multipart/form-data, use Map<String, dynamic> (can contain String, File, List<int>)
      // For JSON, use model type or Map<String, dynamic>
      final bodyType = requestBodyContentType == 'application/x-www-form-urlencoded'
          ? 'Map<String, String>'
          : (requestBodyContentType == 'multipart/form-data'
              ? 'Map<String, dynamic>'
              : (requestBodyType ?? 'Map<String, dynamic>'));
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
      // Check if there's application/json, application/x-www-form-urlencoded, or multipart/form-data
      if (content.containsKey('application/json') ||
          content.containsKey('application/x-www-form-urlencoded') ||
          content.containsKey('multipart/form-data')) {
        return true;
      }
    }

    return false;
  }

  /// Gets the content type for requestBody.
  ///
  /// Returns 'application/json', 'application/x-www-form-urlencoded', 'multipart/form-data',
  /// or null if not found.
  String? _getRequestBodyContentType(Map<dynamic, dynamic> operation) {
    final requestBody = operation['requestBody'];
    if (requestBody is! Map) return null;

    final content = requestBody['content'];
    if (content is Map && content.isNotEmpty) {
      // Priority: multipart/form-data > application/x-www-form-urlencoded > application/json
      if (content.containsKey('multipart/form-data')) {
        return 'multipart/form-data';
      }
      if (content.containsKey('application/x-www-form-urlencoded')) {
        return 'application/x-www-form-urlencoded';
      }
      if (content.containsKey('application/json')) {
        return 'application/json';
      }
    }

    return null;
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
  ///
  /// Only works for JSON content types. Form-urlencoded always uses Map&lt;String, String&gt;.
  Future<String?> _getRequestBodyType(Map<dynamic, dynamic> operation) async {
    final requestBody = operation['requestBody'];
    if (requestBody is! Map) return null;

    final content = requestBody['content'];
    if (content is Map && content.isNotEmpty) {
      // Only resolve model types for JSON, not for form-urlencoded
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

  /// Parses security schemes from OpenAPI/Swagger spec.
  Map<String, Map<String, dynamic>> _parseSecuritySchemes(Map<String, dynamic> spec) {
    // Detect OpenAPI version
    if (spec.containsKey('openapi')) {
      return SecuritySchemesParser.parseOpenApi3(spec);
    } else if (spec.containsKey('swagger')) {
      return SecuritySchemesParser.parseSwagger2(spec);
    }
    return {};
  }

  /// Generates authentication code based on security schemes.
  ///
  /// Returns true if base64 encoding is needed (for Basic auth).
  bool _generateSecurityCode(
    StringBuffer buffer,
    Map<String, List<String>> securityRequirement,
    Map<String, Map<String, dynamic>> securitySchemes,
  ) {
    bool needsBase64 = false;
    buffer.writeln('    final auth = _config.auth;');
    buffer.writeln('    if (auth != null) {');

    for (final entry in securityRequirement.entries) {
      final schemeName = entry.key;
      final scopes = entry.value;
      final scheme = securitySchemes[schemeName];

      if (scheme == null) continue;

      final schemeType = SecuritySchemesParser.getSchemeType(scheme);

      switch (schemeType) {
        case 'apiKey':
          _generateApiKeyAuth(buffer, scheme);
          break;
        case 'http':
          final needs = _generateHttpAuth(buffer, scheme);
          if (needs) needsBase64 = true;
          break;
        case 'oauth2':
          _generateOAuth2Auth(buffer, scheme, scopes);
          break;
        case 'openIdConnect':
          _generateOpenIdConnectAuth(buffer, scheme, scopes);
          break;
      }
    }

    buffer.writeln('    }');
    return needsBase64;
  }

  /// Generates API key authentication code.
  void _generateApiKeyAuth(
    StringBuffer buffer,
    Map<String, dynamic> scheme,
  ) {
    final location = SecuritySchemesParser.getApiKeyLocation(scheme);
    final name = SecuritySchemesParser.getApiKeyName(scheme);

    if (name == null) return;

    switch (location) {
      case 'header':
        buffer.writeln('      if (auth.apiKeyHeader != null && auth.apiKey != null) {');
        buffer.writeln("        headers[auth.apiKeyHeader!] = auth.apiKey!;");
        buffer.writeln('      }');
        break;
      case 'query':
        // API key in query is handled in query parameters section
        // The name from security scheme should match apiKeyQuery in config
        // This is already handled in the query parameters section above
        break;
      case 'cookie':
        buffer.writeln('      if (auth.apiKeyCookie != null && auth.apiKey != null) {');
        buffer.writeln("        final cookieValue = '\${auth.apiKeyCookie!}=\${Uri.encodeComponent(auth.apiKey!)}';");
        buffer.writeln("        if (headers.containsKey('Cookie')) {");
        buffer.writeln("          headers['Cookie'] = '\${headers['Cookie']}; \$cookieValue';");
        buffer.writeln('        } else {');
        buffer.writeln("          headers['Cookie'] = cookieValue;");
        buffer.writeln('        }');
        buffer.writeln('      }');
        break;
    }
  }

  /// Generates HTTP authentication code (Basic, Bearer, Digest).
  ///
  /// Returns true if base64 encoding is needed.
  bool _generateHttpAuth(
    StringBuffer buffer,
    Map<String, dynamic> scheme,
  ) {
    bool needsBase64 = false;
    final httpScheme = SecuritySchemesParser.getHttpScheme(scheme);

    switch (httpScheme) {
      case 'basic':
        needsBase64 = true;
        buffer.writeln('      final basicUsername = auth.resolveBasicAuthUsername();');
        buffer.writeln('      final basicPassword = auth.resolveBasicAuthPassword();');
        buffer.writeln('      if (basicUsername != null && basicPassword != null) {');
        buffer.writeln('        final credentials = base64Encode(utf8.encode(\'\$basicUsername:\$basicPassword\'));');
        buffer.writeln("        headers['Authorization'] = 'Basic \$credentials';");
        buffer.writeln('      }');
        break;
      case 'bearer':
        final bearerFormat = SecuritySchemesParser.getBearerFormat(scheme);
        buffer.writeln('      final bearerToken = auth.resolveBearerToken();');
        buffer.writeln('      if (bearerToken != null) {');
        if (bearerFormat != null && bearerFormat != 'JWT') {
          buffer.writeln("        headers['Authorization'] = '\$bearerFormat \$bearerToken';");
        } else {
          buffer.writeln("        headers['Authorization'] = 'Bearer \$bearerToken';");
        }
        buffer.writeln('      }');
        break;
      case 'digest':
        // Digest authentication is complex and typically requires challenge-response
        // For now, we'll generate a placeholder
        buffer.writeln('      // Digest authentication requires challenge-response flow');
        buffer.writeln('      // This is not yet fully implemented');
        break;
    }
    return needsBase64;
  }

  /// Generates OAuth2 authentication code.
  void _generateOAuth2Auth(
    StringBuffer buffer,
    Map<String, dynamic> scheme,
    List<String> scopes,
  ) {
    buffer.writeln('      final oauth2Token = auth.resolveOAuth2AccessToken();');
    buffer.writeln('      if (oauth2Token != null) {');
    buffer.writeln("        headers['Authorization'] = 'Bearer \$oauth2Token';");
    buffer.writeln('      }');
    // Note: OAuth2 client credentials flow would require token endpoint
    // This is typically handled at runtime, not in generated code
  }

  /// Generates OpenID Connect authentication code.
  void _generateOpenIdConnectAuth(
    StringBuffer buffer,
    Map<String, dynamic> scheme,
    List<String> scopes,
  ) {
    buffer.writeln('      final oidcToken = auth.resolveOpenIdConnectToken();');
    buffer.writeln('      if (oidcToken != null) {');
    buffer.writeln("        headers['Authorization'] = 'Bearer \$oidcToken';");
    buffer.writeln('      }');
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
    this.isArray = false,
    this.arrayItemType,
    this.isObject = false,
    this.style = 'form',
    this.explode = true,
    this.schema,
  });

  final String name;
  final String dartName;
  final String location; // 'path', 'query', 'header', 'cookie'
  final bool required;
  final String? dartType;
  final bool isArray;
  final String? arrayItemType; // Type of array items (e.g., 'String', 'int')
  final bool isObject;
  final String style; // 'form', 'spaceDelimited', 'pipeDelimited', 'deepObject'
  final bool explode;
  final Map<String, dynamic>? schema; // Full schema for complex types
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
