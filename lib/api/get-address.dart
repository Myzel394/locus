import 'dart:convert';

import 'package:http/http.dart' as http;

Future<String> getAddress(
  final double latitude,
  final double longitude,
) async {
  final response = await http.get(Uri.parse(
      "https://geocode.maps.co/reverse?lat=$latitude&lon=$longitude"));

  return jsonDecode(response.body)["display_name"];
}
