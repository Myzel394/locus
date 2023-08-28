import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'location-map.dart';

// Returns the current location that should be shown if no location is
// available.
// This will return the country of the current locale
// Falls back to Poland if no country is available - Decided to use Poland
// because US is so big, which doesn't look nice and Poland is in the middle of
// Europe. Since most users are from US or Europe, we decided to go with Europe.
// From https://gist.github.com/tadast/8827699
LatLng getFallbackLocation(
  final BuildContext context, [
  final String fallback = "PL",
]) {
  final locale = Localizations.localeOf(context);
  final countryCode = locale.countryCode ?? fallback;

  return LOCATION_LATLNG_MAP[countryCode] ?? LOCATION_LATLNG_MAP[fallback]!;
}
