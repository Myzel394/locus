import 'dart:convert';

import "package:http/http.dart" as http;
import 'package:locus/constants/apis.dart';

Future<List<String>> getNostrRelays() async {
  final response = await http.get(Uri.parse(NOSTR_LIST_URI));

  return List<String>.from(jsonDecode(response.body));
}
