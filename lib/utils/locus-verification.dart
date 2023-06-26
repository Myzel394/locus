import 'package:flutter_logs/flutter_logs.dart';

import '../api/get-locus-verification.dart';
import '../constants/values.dart';

Future<bool> verifyServerOrigin(final String origin) async {
  try {
    final response = await getLocusVerification(origin);

    FlutterLogs.logInfo(
      LOG_TAG,
      "Server Origin",
      "Received response.",
    );

    if (response["origin"] != origin) {
      FlutterLogs.logError(
        LOG_TAG,
        "Server Origin",
        "Received response with invalid origin.",
      );

      return false;
    }

    if (!List<String>.from(response["allowedScopes"]).contains("link")) {
      FlutterLogs.logError(
        LOG_TAG,
        "Server Origin",
        "Received response with invalid scopes.",
      );

      return false;
    }

    return true;
  } on FormatException {
    FlutterLogs.logError(
      LOG_TAG,
      "Server Origin",
      "Received response with invalid format.",
    );

    return false;
  }
}
