// Haven't found a proper cache library yet
Future<T> Function() withCache<T extends Map<String, dynamic>>(
  Future<T> Function() callback,
  final String key,
) {
  return () async {
    return callback();
  };
}
