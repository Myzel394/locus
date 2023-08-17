import 'dart:convert';

import 'package:flutter_logs/flutter_logs.dart';
import "package:http/http.dart" as http;
import 'package:locus/constants/apis.dart';
import 'package:locus/constants/values.dart';

import '../widgets/RelaySelectSheet.dart';

final RELAY_FETCHER_FUNCTIONS = [
  NostrWatchAPI.getPublicNostrRelays,
  NostrBandAPI.getTrendingProfiles,
  NostrWatchAPI.getAllNostrRelays,
  () => Future.value(FALLBACK_RELAYS),
];

// Tries each of the fallback relays until one works
Future<Map<String, List<String>>> getNostrRelays() async {
  FlutterLogs.logInfo(LOG_TAG, "Get Nostr Relays", "Fetching Nostr Relays");

  for (final fetch in RELAY_FETCHER_FUNCTIONS) {
    FlutterLogs.logInfo(LOG_TAG, "Get Nostr Relays", "Trying method $fetch");

    try {
      final relays = await fetch();

      return {
        "relays": relays,
      };
    } catch (error) {
      FlutterLogs.logError(
        LOG_TAG,
        "Get Nostr Relays",
        "Failed to fetch relays: $error",
      );
    }
  }

  FlutterLogs.logWarn(
    LOG_TAG,
    "Get Nostr Relays",
    "Failed to fetch relays. Falling back to default relays",
  );

  return {
    "relays": FALLBACK_RELAYS,
  };
}

class NostrWatchAPI {
  static Future<List<String>> getPublicNostrRelays() async {
    final response = await http
        .get(Uri.parse(NOSTR_PUBLIC_RELAYS_LIST_URI))
        .timeout(HTTP_TIMEOUT);

    return List<String>.from(jsonDecode(response.body));
  }

  static Future<List<String>> getAllNostrRelays() async {
    final response = await http
        .get(Uri.parse(NOSTR_ONLINE_RELAYS_LIST_URI))
        .timeout(HTTP_TIMEOUT);

    return List<String>.from(jsonDecode(response.body));
  }
}

class NostrBandAPI {
  static Future<List<String>> getTrendingProfiles() async {
    final response = await http
        .get(Uri.parse(NOSTR_TRENDING_PROFILES_URI))
        .timeout(HTTP_TIMEOUT);

    return List<String>.from(
        List<dynamic>.from(jsonDecode(response.body)["profiles"])
            .map((e) => e["relays"])
            .expand((element) => element)
            .toSet()
            .map((element) {
      final rawDomain = DOMAIN_REPLACE_REGEX.firstMatch(element);

      if (rawDomain == null) {
        return null;
      }

      return addProtocol(rawDomain.group(1)!);
    }).where((element) => element != null));
  }
}
