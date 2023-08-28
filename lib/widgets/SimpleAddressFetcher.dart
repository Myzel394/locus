import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import "package:latlong2/latlong.dart";
import 'package:locus/utils/location/index.dart';

import '../constants/spacing.dart';
import '../utils/theme.dart';
import 'AddressFetcher.dart';

/// An opinionated address fetcher that automatically adds a loading indicator
/// and formats the address.
class SimpleAddressFetcher extends StatelessWidget {
  final LatLng location;

  const SimpleAddressFetcher({
    required this.location,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AddressFetcher(
      latitude: location.latitude,
      longitude: location.longitude,
      builder: (address) => Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: address,
              style: getBodyTextTextStyle(context),
            ),
            TextSpan(
              text: " (${formatRawAddress(location)})",
              style: getCaptionTextStyle(context),
            ),
          ],
        ),
      ),
      rawLocationBuilder: (isLoading) => Row(
        children: <Widget>[
          if (isLoading) ...[
            PlatformCircularProgressIndicator(),
            const SizedBox(width: SMALL_SPACE),
          ],
          Text(
            formatRawAddress(location),
            style: getBodyTextTextStyle(context),
          ),
        ],
      ),
    );
  }
}
