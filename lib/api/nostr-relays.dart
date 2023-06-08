import 'dart:convert';

import "package:http/http.dart" as http;
import 'package:locus/constants/apis.dart';

Future<Map<String, dynamic>> getNostrRelays() async {
  final response = await http.get(Uri.parse(NOSTR_LIST_URI));

  return {
    "relays": List<String>.from(jsonDecode(response.body)),
  };
}
