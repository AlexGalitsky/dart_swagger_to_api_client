import 'dart:io';

import 'package:dart_swagger_to_api_client/src/models/models_config.dart';
import 'package:dart_swagger_to_api_client/src/models/models_config_loader.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('ModelsConfigLoader', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('models_config_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('returns null when config file does not exist', () async {
      final config = await ModelsConfigLoader.load(tempDir.path);
      expect(config, isNull);
    });

    test('loads basic config with outputDir and defaultStyle', () async {
      final configFile = File(p.join(tempDir.path, 'dart_swagger_to_models.yaml'));
      await configFile.writeAsString('''
outputDir: lib/generated/models
defaultStyle: json_serializable
''');

      final config = await ModelsConfigLoader.load(tempDir.path);
      expect(config, isNotNull);
      expect(config!.outputDir, equals('lib/generated/models'));
      expect(config.defaultStyle, equals('json_serializable'));
      expect(config.schemas, isEmpty);
    });

    test('loads config with schema overrides', () async {
      final configFile = File(p.join(tempDir.path, 'dart_swagger_to_models.yaml'));
      await configFile.writeAsString('''
outputDir: lib/models
defaultStyle: plain_dart
schemas:
  User:
    className: CustomUser
    fieldNames:
      user_id: userId
      user_name: userName
    typeMapping:
      string: MyString
  Order:
    className: PurchaseOrder
''');

      final config = await ModelsConfigLoader.load(tempDir.path);
      expect(config, isNotNull);
      expect(config!.outputDir, equals('lib/models'));
      expect(config.defaultStyle, equals('plain_dart'));

      expect(config.schemas, hasLength(2));
      expect(config.schemas.containsKey('User'), isTrue);
      expect(config.schemas.containsKey('Order'), isTrue);

      final userOverride = config.schemas['User']!;
      expect(userOverride.className, equals('CustomUser'));
      expect(userOverride.fieldNames, equals({'user_id': 'userId', 'user_name': 'userName'}));
      expect(userOverride.typeMapping, equals({'string': 'MyString'}));

      final orderOverride = config.schemas['Order']!;
      expect(orderOverride.className, equals('PurchaseOrder'));
      expect(orderOverride.fieldNames, isEmpty);
      expect(orderOverride.typeMapping, isEmpty);
    });

    test('throws FormatException for invalid YAML', () async {
      final configFile = File(p.join(tempDir.path, 'dart_swagger_to_models.yaml'));
      await configFile.writeAsString('invalid: yaml: content: [unclosed');

      expect(
        () => ModelsConfigLoader.load(tempDir.path),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException for non-map YAML', () async {
      final configFile = File(p.join(tempDir.path, 'dart_swagger_to_models.yaml'));
      await configFile.writeAsString('- item1\n- item2');

      expect(
        () => ModelsConfigLoader.load(tempDir.path),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('top-level mapping'),
        )),
      );
    });
  });
}
