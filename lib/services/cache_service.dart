import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

final Map<String, String> _CACHE_VALUES = {};

class CacheManager {
  static Future<void> write(final String key, final dynamic value, {final Duration? lifetime}) async {
    final rawValue = jsonEncode(value);

    if (lifetime == null) {
      _CACHE_VALUES[key] = rawValue;
    } else {
      await storage.write(key: key, value: rawValue);
      await storage.write(key: '$key-lifetime', value: DateTime.now().add(lifetime).toIso8601String());
    }
  }

  static Future<dynamic> read(final String key) async {
    if (_CACHE_VALUES.containsKey(key)) {
      return jsonDecode(_CACHE_VALUES[key]!);
    }

    final lifetime = await storage.read(key: '$key-lifetime');
    if (lifetime == null) {
      return null;
    }

    final lifetimeDate = DateTime.parse(lifetime);
    if (lifetimeDate.isBefore(DateTime.now())) {
      return null;
    }

    final rawValue = await storage.read(key: key);
    if (rawValue == null) {
      return null;
    }

    return jsonDecode(rawValue);
  }

  static Future<void> delete(final String key) async {
    _CACHE_VALUES.remove(key);
    await storage.delete(key: key);
    await storage.delete(key: '$key-lifetime');
  }

  // Create a function that returns a Future<T> and takes key and lifetime as parameters
  static Future<T> Function() withCache<T>(
    Future<T> Function() callback,
    final String key, {
    final Duration? lifetime,
  }) {
    return () async {
      final cachedValue = await read(key);
      if (cachedValue != null) {
        return cachedValue;
      }

      final value = await callback();
      await write(key, value, lifetime: lifetime);

      return value;
    };
  }
}
