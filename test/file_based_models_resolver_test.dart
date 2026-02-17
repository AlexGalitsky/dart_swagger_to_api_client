import 'dart:io';

import 'package:dart_swagger_to_api_client/src/models/file_based_models_resolver.dart';
import 'package:dart_swagger_to_api_client/src/models/models_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('FileBasedModelsResolver', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('models_resolver_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('resolves \$ref to class name when model file exists', () async {
      // Create a model file
      final modelsDir = Directory(p.join(tempDir.path, 'lib', 'models'));
      await modelsDir.create(recursive: true);

      final userFile = File(p.join(modelsDir.path, 'user.dart'));
      await userFile.writeAsString('''
// GENERATED CODE
class User {
  final String name;
  const User({required this.name});
}
''');

      final resolver = FileBasedModelsResolver(
        projectDir: tempDir.path,
        modelsConfig: ModelsConfig(outputDir: 'lib/models'),
      );

      final type = await resolver.resolveRefToType('#/components/schemas/User');
      expect(type, equals('User'));
    });

    test('returns null when model file does not exist', () async {
      final resolver = FileBasedModelsResolver(
        projectDir: tempDir.path,
        modelsConfig: ModelsConfig(outputDir: 'lib/models'),
      );

      final type = await resolver.resolveRefToType('#/components/schemas/NonExistent');
      expect(type, isNull);
    });

    test('returns import path for resolved type', () async {
      final modelsDir = Directory(p.join(tempDir.path, 'lib', 'models'));
      await modelsDir.create(recursive: true);

      final userFile = File(p.join(modelsDir.path, 'user.dart'));
      await userFile.writeAsString('''
class User {
  final String name;
  const User({required this.name});
}
''');

      final resolver = FileBasedModelsResolver(
        projectDir: tempDir.path,
        modelsConfig: ModelsConfig(outputDir: 'lib/models'),
      );

      // First resolve the type
      final type = await resolver.resolveRefToType('#/components/schemas/User');
      expect(type, equals('User'));

      // Then get import path
      final importPath = await resolver.getImportPath('User');
      expect(importPath, isNotNull);
      expect(importPath, contains('lib/models/user.dart'));
    });

    test('identifies model types correctly', () async {
      final modelsDir = Directory(p.join(tempDir.path, 'lib', 'models'));
      await modelsDir.create(recursive: true);

      final userFile = File(p.join(modelsDir.path, 'user.dart'));
      await userFile.writeAsString('''
class User {
  final String name;
  const User({required this.name});
}
''');

      final resolver = FileBasedModelsResolver(
        projectDir: tempDir.path,
        modelsConfig: ModelsConfig(outputDir: 'lib/models'),
      );

      expect(await resolver.isModelType('User'), isTrue);
      expect(await resolver.isModelType('String'), isFalse);
      expect(await resolver.isModelType('Map'), isFalse);
    });

    test('handles multiple classes in one file', () async {
      final modelsDir = Directory(p.join(tempDir.path, 'lib', 'models'));
      await modelsDir.create(recursive: true);

      final userFile = File(p.join(modelsDir.path, 'user.dart'));
      await userFile.writeAsString('''
class User {
  final String name;
  const User({required this.name});
}

class UserProfile {
  final User user;
  const UserProfile({required this.user});
}
''');

      final resolver = FileBasedModelsResolver(
        projectDir: tempDir.path,
        modelsConfig: ModelsConfig(outputDir: 'lib/models'),
      );

      expect(await resolver.resolveRefToType('#/components/schemas/User'), equals('User'));
      expect(await resolver.resolveRefToType('#/components/schemas/UserProfile'), equals('UserProfile'));
      expect(await resolver.isModelType('User'), isTrue);
      expect(await resolver.isModelType('UserProfile'), isTrue);
    });

    test('uses default outputDir when not specified in config', () async {
      final modelsDir = Directory(p.join(tempDir.path, 'lib', 'models'));
      await modelsDir.create(recursive: true);

      final userFile = File(p.join(modelsDir.path, 'user.dart'));
      await userFile.writeAsString('''
class User {
  final String name;
  const User({required this.name});
}
''');

      final resolver = FileBasedModelsResolver(
        projectDir: tempDir.path,
        modelsConfig: ModelsConfig(), // No outputDir specified
      );

      final type = await resolver.resolveRefToType('#/components/schemas/User');
      expect(type, equals('User'));
    });
  });
}
