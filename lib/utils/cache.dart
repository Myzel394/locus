import 'package:cache_manager/cache_manager.dart';

Future<T> Function() withCache<T extends Map<String, dynamic>>(
  Future<T> Function() callback,
  final String key,
) {
  return () async {
    try {
      final cachedValue = await ReadCache.getJson(key: key);
      if (cachedValue != null) {
        return cachedValue;
      }
    } catch (_) {}

    final value = await callback();
    await WriteCache.setJson(
      key: key,
      value: value,
    );

    return value;
  };
}
