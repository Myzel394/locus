import 'dart:async';

import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart'
    hide PlatformListTile;
import 'package:geolocator/geolocator.dart';
import 'package:locus/screens/view_alarm_screen_widgets/ViewAlarmScreen.dart';
import 'package:locus/screens/view_details_screen_widgets/LocationPointsList.dart';
import 'package:locus/screens/view_details_screen_widgets/ViewLocationPointsScreen.dart';
import 'package:locus/services/location_alarm_service.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/utils/PageRoute.dart';
import 'package:locus/utils/bunny.dart';
import 'package:locus/utils/permissions/has-granted.dart';
import 'package:locus/utils/permissions/request.dart';
import 'package:locus/widgets/EmptyLocationsThresholdScreen.dart';
import 'package:locus/widgets/FillUpPaint.dart';
import 'package:locus/widgets/LocationFetchEmpty.dart';
import 'package:locus/widgets/LocationsMap.dart';
import 'package:locus/widgets/OpenInMaps.dart';
import 'package:locus/widgets/Paper.dart';
import 'package:locus/widgets/PlatformFlavorWidget.dart';
import 'package:locus/widgets/PlatformPopup.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

import '../constants/spacing.dart';
import '../services/location_fetch_controller.dart';
import '../services/location_point_service.dart';
import '../utils/theme.dart';
import '../widgets/LocationFetchError.dart';
import '../widgets/LocationStillFetchingBanner.dart';
import '../widgets/LocationsLoadingScreen.dart';
import '../widgets/PlatformListTile.dart';
import 'locations_overview_screen_widgets/LocationFetchers.dart';

const DEBOUNCE_DURATION = Duration(seconds: 2);

class ViewDetailsScreen extends StatefulWidget {
  final TaskView view;

  const ViewDetailsScreen({
    super.key,
    required this.view,
  });

  @override
  State<ViewDetailsScreen> createState() => _ViewDetailsScreenState();
}

class _ViewDetailsScreenState extends State<ViewDetailsScreen> {
  bool showAlarms = true;

  @override
  Widget build(BuildContext context) {
    final locationFetcher = context.watch<LocationFetchers>();

    final locations = locationFetcher.getLocations(widget.view);
    final l10n = AppLocalizations.of(context);

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(l10n.viewDetails_title),
        trailingActions: <Widget>[
          if (widget.view.alarms.isNotEmpty)
            Tooltip(
              message: showAlarms
                  ? l10n.viewDetails_actions_showAlarms_hide
                  : l10n.viewDetails_actions_showAlarms_show,
              child: PlatformTextButton(
                cupertino: (_, __) => CupertinoTextButtonData(
                  padding: EdgeInsets.zero,
                ),
                onPressed: () {
                  setState(() {
                    showAlarms = !showAlarms;
                  });
                },
                child: PlatformFlavorWidget(
                  material: (_, __) => showAlarms
                      ? const Icon(Icons.alarm_rounded)
                      : const Icon(Icons.alarm_off_rounded),
                  cupertino: (_, __) => showAlarms
                      ? const Icon(CupertinoIcons.alarm)
                      : const Icon(Icons.alarm_off_rounded),
                ),
              ),
            ),
          Padding(
            padding: isMaterial(context)
                ? const EdgeInsets.all(SMALL_SPACE)
                : EdgeInsets.zero,
            child: PlatformPopup<String>(
              cupertinoButtonPadding: EdgeInsets.zero,
              type: PlatformPopupType.tap,
              items: [
                PlatformPopupMenuItem(
                    label: PlatformListTile(
                      leading: PlatformFlavorWidget(
                        cupertino: (_, __) => const Icon(CupertinoIcons.alarm),
                        material: (_, __) => const Icon(Icons.alarm_rounded),
                      ),
                      title: Text(l10n.location_manageAlarms_title),
                      trailing: const SizedBox.shrink(),
                    ),
                    onPressed: () {
                      if (isCupertino(context)) {
                        Navigator.of(context).push(
                          MaterialWithModalsPageRoute(
                            builder: (_) => ViewAlarmScreen(view: widget.view),
                          ),
                        );
                      } else {
                        Navigator.of(context).push(
                          NativePageRoute(
                            context: context,
                            builder: (_) => ViewAlarmScreen(view: widget.view),
                          ),
                        );
                      }
                    }),
                if (locations.isNotEmpty)
                  PlatformPopupMenuItem(
                    label: PlatformListTile(
                      leading: Icon(context.platformIcons.location),
                      trailing: const SizedBox.shrink(),
                      title: Text(l10n.viewDetails_actions_openLatestLocation),
                    ),
                    onPressed: () => showPlatformModalSheet(
                      context: context,
                      material: MaterialModalSheetData(),
                      builder: (context) => OpenInMaps(
                        destination: locations.last.asCoords(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        material: (_, __) => MaterialAppBarData(
          centerTitle: true,
        ),
        cupertino: (_, __) => CupertinoNavigationBarData(
          backgroundColor: getCupertinoAppBarColorForMapScreen(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          child: Column(
            children: <Widget>[
              Paper(
                child: LocationPointsList(
                  view: widget.view,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
