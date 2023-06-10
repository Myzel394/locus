import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:locus/constants/values.dart';

Future<String> getAddressGeocodeMapsCo(
  final double latitude,
  final double longitude,
) async {
  final response = await http
      .get(
        Uri.parse(
          "https://geocode.maps.co/reverse?lat=$latitude&lon=$longitude",
        ),
      )
      .timeout(HTTP_TIMEOUT);

  return jsonDecode(response.body)["display_name"];
}

Future<String> getAddressNominatim(
  final double latitude,
  final double longitude,
) async {
  final response = await http
      .get(
        Uri.parse(
          "https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude",
        ),
      )
      .timeout(HTTP_TIMEOUT);

  return jsonDecode(response.body)["display_name"];
}

Future<String> getAddressSystem(
  final double latitude,
  final double longitude,
) async {
  List<Placemark> placemarks = await placemarkFromCoordinates(52.2165157, 6.9437819);

  for (final placemark in placemarks) {
    final address = [
      placemark.street,
      placemark.subLocality,
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
      placemark.postalCode,
      placemark.country,
    ].where((element) => element != null && element.isNotEmpty).join(", ");

    if (address.isNotEmpty) {
      return address;
    }
  }

  throw Exception("No address found");
}
