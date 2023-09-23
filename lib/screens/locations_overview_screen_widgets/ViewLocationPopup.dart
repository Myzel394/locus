import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/services/view_service/index.dart';
import 'package:locus/widgets/Paper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/widgets/SimpleAddressFetcher.dart';
import 'package:map_launcher/map_launcher.dart';
import "package:latlong2/latlong.dart";

import '../../constants/spacing.dart';
import '../../widgets/OpenInMaps.dart';

class ViewLocationPopup extends StatelessWidget {
  final TaskView view;
  final LatLng location;
  final VoidCallback onShowDetails;

  const ViewLocationPopup({
    required this.view,
    required this.location,
    required this.onShowDetails,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery
            .of(context)
            .size
            .width * 0.8,
      ),
      child: Paper(
        width: null,
        child: Padding(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.circle_rounded,
                    size: 20,
                    color: view.color,
                  ),
                  const SizedBox(width: SMALL_SPACE),
                  Text(view.name),
                ],
              ),
              const SizedBox(height: SMALL_SPACE),
              SimpleAddressFetcher(location: location),
              const SizedBox(height: MEDIUM_SPACE),
              Row(
                children: [
                  Flexible(
                    child: PlatformElevatedButton(
                      material: (_, __) =>
                          MaterialElevatedButtonData(
                            icon: const Icon(Icons.directions_rounded),
                          ),
                      child: Text(l10n.openInMaps),
                      onPressed: () {
                        showPlatformModalSheet(
                          context: context,
                          material: MaterialModalSheetData(
                            backgroundColor: Colors.transparent,
                          ),
                          builder: (context) =>
                              OpenInMaps(
                                destination: Coords(
                                  location.latitude,
                                  location.longitude,
                                ),
                              ),
                        );
                      },
                    ),
                  ),
                  Flexible(
                    child: PlatformTextButton(
                      onPressed: onShowDetails,
                      child: Text(l10n.showDetailsLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
