import "package:latlong2/latlong.dart";

String formatRawAddress(final LatLng location) =>
    "${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}";
