import 'package:enough_platform_widgets/platform.dart';
import 'package:flutter/material.dart';
import 'package:locus/screens/task_detail_screen_widgets/LocationDetails.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/utils/theme.dart';

import '../services/location_point_service.dart';
import '../widgets/Paper.dart';

class LocationPointsDetailsScreen extends StatelessWidget {
  final List<LocationPointService> locations;
  final bool isPreview;

  const LocationPointsDetailsScreen({
    required this.locations,
    required this.isPreview,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final locationElements = locations.isEmpty
        ? Text(
            l10n.taskDetails_noLocations,
            style: getBodyTextTextStyle(context),
          )
        : ListView.builder(
            shrinkWrap: isPreview,
            physics: isPreview ? const NeverScrollableScrollPhysics() : null,
            itemCount: locations.length,
            itemBuilder: (_, index) => LocationDetails(
              location: locations[index],
              isPreview: isPreview,
            ),
          );
    final content = Hero(
      tag: "container",
      child: Material(
        color: Colors.transparent,
        child: Paper(
          roundness: isPreview ? null : 0,
          constraints: isPreview
              ? const BoxConstraints(
                  maxHeight: 300,
                )
              : null,
          child: locationElements,
        ),
      ),
    );

    if (isPreview) {
      return content;
    }

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(
          "Location Points",
        ),
      ),
      body: SafeArea(
        child: content,
      ),
    );
  }
}
