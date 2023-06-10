import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:locus/constants/values.dart';
import 'package:version/version.dart';

Future<Version> getNewestVersion() async {
  final response = await http
      .get(
        Uri.parse("https://api.github.com/repos/Myzel394/locus/releases?per_page=1"),
      )
      .timeout(HTTP_TIMEOUT);

  final rawVersion = (jsonDecode(response.body)[0]["tag_name"] as String).substring(1);

  return Version.parse(rawVersion);
}
