// Haven't found a proper cache library yet
final Map<String, Map<String, dynamic>> _CACHE = {};

Future<T> Function() withCache<T extends Map<String, dynamic>>(
  Future<T> Function() callback,
  final String key,
) {
  return () async {
    if (_CACHE.containsKey(key)) {
      return _CACHE[key] as T;
    }

    final value = await callback();

    _CACHE[key] = value;

    return value;
  };
}
