import 'dart:convert';

import 'package:flutter_logs/flutter_logs.dart';
import "package:http/http.dart" as http;
import 'package:locus/constants/apis.dart';
import 'package:locus/constants/values.dart';

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
            .toSet());
  }
}

// Top 30 most used free relays
const FALLBACK_RELAYS = [
  "relay.damus.io",
  "eden.nostr.land",
  "nos.lol",
  "relay.snort.social",
  "relay.current.fyi",
  "brb.io",
  "nostr.orangepill.dev",
  "nostr-pub.wellorder.net",
  "nostr.bitcoiner.social",
  "nostr.wine",
  "nostr.oxtr.dev",
  "relay.nostr.bg",
  "nostr.mom",
  "nostr.fmt.wiz.biz",
  "relay.nostr.band",
  "nostr-pub.semisol.dev",
  "nostr.milou.lol",
  "nostr.onsats.org",
  "relay.nostr.info",
  "puravida.nostr.land",
  "offchain.pub",
  "relay.orangepill.dev",
  "no.str.cr",
  "nostr.zebedee.cloud",
  "atlas.nostr.land",
  "nostr-relay.wlvs.space",
  "relay.nostrati.com",
  "relay.nostr.com.au",
  "relay.inosta.cc",
  "nostr.rocks",
];
