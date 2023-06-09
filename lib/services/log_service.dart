import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/log.dart';

const LOGS_LIFETIME = Duration(days: 7);
const storage = FlutterSecureStorage();
const KEY = "_app_logs";

class LogService extends ChangeNotifier {
  late final List<Log> _logs;

  LogService([final List<Log>? logs]) : _logs = logs ?? [];

  static Future<LogService> restore() async {
    final data = await storage.read(key: KEY);

    if (data == null) {
      return LogService();
    }

    return LogService.fromJSON(jsonDecode(data) as Map<String, dynamic>);
  }

  static LogService fromJSON(final Map<String, dynamic> data) => LogService(
        List<Log>.from(
          data['logs'].map(
            (log) => Log.fromJSON(log),
          ),
        ),
      );

  Map<String, dynamic> toJSON() => {
        "logs": List<Map<String, dynamic>>.from(
          logs.map(
            (log) => log.toJSON(),
          ),
        ),
      };

  List<Log> get logs => List.unmodifiable(_logs);

  Future<void> save() => storage.write(
        key: KEY,
        value: jsonEncode(toJSON()),
      );

  void add(final Log log) {
    _logs.add(log);
    notifyListeners();
  }

  // Adds a log entry and saves it to storage
  Future<void> addLog(final Log log) async {
    add(log);
    await save();
  }

  void clear() {
    _logs.clear();
    notifyListeners();
  }

  Future<void> deleteOldLogs() async {
    final terminationDate = DateTime.now().subtract(LOGS_LIFETIME);
    _logs.removeWhere((log) => log.createdAt.isBefore(terminationDate));

    await save();
  }
}
