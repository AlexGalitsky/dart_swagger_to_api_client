import 'package:dart_swagger_to_api_client/src/core/spec_validator.dart';
import 'package:test/test.dart';

void main() {
  group('SpecValidator', () {
    test('returns error when paths section is missing', () {
      final spec = <String, dynamic>{
        'openapi': '3.0.0',
        'info': {'title': 'Test API'},
      };

      final issues = SpecValidator.validate(spec);
      expect(issues, hasLength(1));
      expect(issues.first.severity, equals(IssueSeverity.error));
      expect(issues.first.message, contains('paths'));
    });

    test('returns warning when paths section is empty', () {
      final spec = <String, dynamic>{
        'openapi': '3.0.0',
        'info': {'title': 'Test API'},
        'paths': <String, dynamic>{},
      };

      final issues = SpecValidator.validate(spec);
      expect(issues, hasLength(1));
      expect(issues.first.severity, equals(IssueSeverity.warning));
      expect(issues.first.message, contains('no paths'));
    });

    test('returns warning for operation without operationId', () {
      final spec = <String, dynamic>{
        'openapi': '3.0.0',
        'info': {'title': 'Test API'},
        'paths': {
          '/users': {
            'get': {
              'responses': {'200': {'description': 'OK'}},
            },
          },
        },
      };

      final issues = SpecValidator.validate(spec);
      expect(issues, hasLength(1));
      expect(issues.first.severity, equals(IssueSeverity.warning));
      expect(issues.first.message, contains('operationId'));
      expect(issues.first.message.toLowerCase(), contains('get /users'));
    });

    test('returns warning for unsupported content type in requestBody', () {
      final spec = <String, dynamic>{
        'openapi': '3.0.0',
        'info': {'title': 'Test API'},
        'paths': {
          '/upload': {
            'post': {
              'operationId': 'uploadFile',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {'type': 'object'},
                  },
                },
              },
              'responses': {'200': {'description': 'OK'}},
            },
          },
        },
      };

      final issues = SpecValidator.validate(spec);
      expect(issues, hasLength(1));
      expect(issues.first.severity, equals(IssueSeverity.warning));
      expect(issues.first.message, contains('multipart/form-data'));
      expect(issues.first.message, contains('unsupported'));
    });

    test('returns warning for unsupported parameter location', () {
      final spec = <String, dynamic>{
        'openapi': '3.0.0',
        'info': {'title': 'Test API'},
        'paths': {
          '/users': {
            'get': {
              'operationId': 'getUsers',
              'parameters': [
                {
                  'name': 'X-Custom-Header',
                  'in': 'header',
                  'schema': {'type': 'string'},
                },
              ],
              'responses': {'200': {'description': 'OK'}},
            },
          },
        },
      };

      final issues = SpecValidator.validate(spec);
      expect(issues, hasLength(1));
      expect(issues.first.severity, equals(IssueSeverity.warning));
      expect(issues.first.message, contains('header'));
      expect(issues.first.message, contains('unsupported'));
    });

    test('returns no issues for valid spec', () {
      final spec = <String, dynamic>{
        'openapi': '3.0.0',
        'info': {'title': 'Test API'},
        'paths': {
          '/users': {
            'get': {
              'operationId': 'getUsers',
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {'type': 'object'},
                    },
                  },
                },
              },
            },
          },
        },
      };

      final issues = SpecValidator.validate(spec);
      expect(issues, isEmpty);
    });

    test('validates multiple paths and operations', () {
      final spec = <String, dynamic>{
        'openapi': '3.0.0',
        'info': {'title': 'Test API'},
        'paths': {
          '/users': {
            'get': {
              'operationId': 'getUsers',
              'responses': {'200': {'description': 'OK'}},
            },
            'post': {
              'requestBody': {
                'content': {
                  'application/json': {
                    'schema': {'type': 'object'},
                  },
                },
              },
              'responses': {'201': {'description': 'Created'}},
            },
          },
          '/orders': {
            'get': {
              // Missing operationId
              'responses': {'200': {'description': 'OK'}},
            },
          },
        },
      };

      final issues = SpecValidator.validate(spec);
      // Should have warning for /orders GET (missing operationId)
      // /users POST is missing operationId too
      expect(issues.length, greaterThanOrEqualTo(2));
      expect(
        issues.any((i) =>
            i.message.toLowerCase().contains('get /orders') &&
            i.message.contains('operationId')),
        isTrue,
      );
      expect(
        issues.any((i) =>
            i.message.toLowerCase().contains('post /users') &&
            i.message.contains('operationId')),
        isTrue,
      );
    });
  });
}
