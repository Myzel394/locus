import 'dart:convert';

import 'package:http/http.dart' as http;

Future<String> getNewestVersion() async {
  final response = await http.get(
    Uri.parse(
        "https://api.github.com/repos/Myzel394/locus/releases?per_page=1"),
  );

  return jsonDecode(response.body)[0]["tag_name"];
}
