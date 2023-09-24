Future<dynamic> repeatedlyCheckForSuccess(
  final Future<dynamic> Function() check, [
  final Duration interval = const Duration(milliseconds: 500),
  final Duration timeout = const Duration(seconds: 30),
]) async {
  final stopwatch = Stopwatch()..start();

  while (stopwatch.elapsed < timeout) {
    final result = await check();

    if (result != null) {
      return result;
    }

    await Future.delayed(interval);
  }

  return;
}
