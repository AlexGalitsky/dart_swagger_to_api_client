import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Cache for parsed OpenAPI specifications to improve performance.
///
/// This cache stores the parsed spec along with its hash to avoid
/// re-parsing unchanged files.
class SpecCache {
  SpecCache({required String cacheDir}) : _cacheDir = Directory(cacheDir);

  final Directory _cacheDir;
  static const String _cacheFileName = '.api_client_spec_cache.json';

  /// Gets the cached spec if it exists and matches the current file hash.
  Future<Map<String, dynamic>?> getCachedSpec(String specPath) async {
    try {
      if (!await _cacheDir.exists()) {
        await _cacheDir.create(recursive: true);
      }

      final cacheFile = File(p.join(_cacheDir.path, _cacheFileName));
      if (!await cacheFile.exists()) {
        return null;
      }

      final specFile = File(specPath);
      if (!await specFile.exists()) {
        return null;
      }

      // Calculate current file hash
      final currentHash = await _calculateFileHash(specFile);

      // Load cache
      final cacheContent = await cacheFile.readAsString();
      final cache = jsonDecode(cacheContent) as Map<String, dynamic>;

      // Check if cached spec matches current file
      final cachedPath = cache['path'] as String?;
      final cachedHash = cache['hash'] as String?;
      final cachedSpec = cache['spec'] as Map<String, dynamic>?;

      if (cachedPath == specPath &&
          cachedHash == currentHash &&
          cachedSpec != null) {
        return cachedSpec;
      }
    } catch (_) {
      // If cache is corrupted or invalid, ignore it
    }

    return null;
  }

  /// Stores the parsed spec in cache.
  Future<void> cacheSpec(
    String specPath,
    Map<String, dynamic> spec,
  ) async {
    try {
      if (!await _cacheDir.exists()) {
        await _cacheDir.create(recursive: true);
      }

      final specFile = File(specPath);
      if (!await specFile.exists()) {
        return;
      }

      final hash = await _calculateFileHash(specFile);

      final cacheFile = File(p.join(_cacheDir.path, _cacheFileName));
      final cache = {
        'path': specPath,
        'hash': hash,
        'spec': spec,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await cacheFile.writeAsString(
        jsonEncode(cache),
        mode: FileMode.write,
      );
    } catch (_) {
      // If caching fails, continue without cache
    }
  }

  /// Clears the cache.
  Future<void> clear() async {
    try {
      final cacheFile = File(p.join(_cacheDir.path, _cacheFileName));
      if (await cacheFile.exists()) {
        await cacheFile.delete();
      }
    } catch (_) {
      // Ignore errors when clearing cache
    }
  }

  /// Calculates SHA-256 hash of a file.
  Future<String> _calculateFileHash(File file) async {
    final content = await file.readAsBytes();
    final hash = sha256.convert(content);
    return hash.toString();
  }
}
