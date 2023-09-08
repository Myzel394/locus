import 'package:battery_plus/battery_plus.dart';

Future<bool> isBatterySaveModeEnabled() async {
  try {
    final value = await Battery().isInBatterySaveMode;
    return value;
  } catch (_) {
    return false;
  }
}
