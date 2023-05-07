import 'package:flutter/material.dart';
import 'package:locus/services/location_point_service.dart';

class LocationDetails extends StatelessWidget {
  final LocationPointService location;
  final bool isPreview;

  const LocationDetails({
    required this.location,
    required this.isPreview,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPreview ? null : () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "${location.latitude}, ${location.longitude}",
          ),
        ],
      ),
    );
  }
}
