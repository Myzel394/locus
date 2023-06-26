import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/values.dart';

Future<Map<String, dynamic>> getLocusVerification(
  final String origin,
) async {
  final response = await http
      .get(
        Uri.parse(
          "$origin/.well-known/locus.json",
        ),
      )
      .timeout(HTTP_TIMEOUT);

  return jsonDecode(response.body);
}
