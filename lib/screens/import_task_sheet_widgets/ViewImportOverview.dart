import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart'
    hide PlatformListTile;
import 'package:locus/screens/locations_overview_screen_widgets/LocationFetchers.dart';
import 'package:locus/services/view_service/index.dart';
import 'package:provider/provider.dart';

import '../../constants/spacing.dart';
import '../../utils/theme.dart';
import '../../widgets/LocationsMap.dart';
import '../../widgets/PlatformListTile.dart';

class ViewImportOverview extends StatefulWidget {
  final TaskView view;
  final void Function() onImport;

  const ViewImportOverview({
    required this.view,
    required this.onImport,
    Key? key,
  }) : super(key: key);

  @override
  State<ViewImportOverview> createState() => _ViewImportOverviewState();
}

class _ViewImportOverviewState extends State<ViewImportOverview> {
  final LocationsMapController _controller = LocationsMapController();
  final bool _isError = false;

  double timeOffset = 0;

  @override
  void initState() {
    super.initState();

    final fetchers = context.read<LocationFetchers>();
    final lastLocation = fetchers.getLocations(widget.view).lastOrNull;

    if (lastLocation != null) {
      _controller.add(lastLocation);
    }
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          "Do you want to import this task?",
          textAlign: TextAlign.center,
          style: getTitle2TextStyle(context),
        ),
        ListView(
          shrinkWrap: true,
          children: <Widget>[
            PlatformListTile(
              title: Text(widget.view.relays.join(", ")),
              subtitle: Text(l10n.nostrRelaysLabel),
              leading: const Icon(Icons.dns_rounded),
              trailing: const SizedBox.shrink(),
            ),
            PlatformListTile(
              title: Text(widget.view.nostrPublicKey),
              subtitle: Text(l10n.nostrPublicKeyLabel),
              leading: const Icon(Icons.key),
              trailing: const SizedBox.shrink(),
            ),
          ],
        ),
        if (_isError)
          Text(
            l10n.locationsLoadingError,
            style: TextStyle(
              color: getErrorColor(context),
            ),
          )
        else ...[
          Text(
            l10n.sharesOverviewScreen_importTask_importOverview_lastPosition,
            textAlign: TextAlign.center,
            style: getSubTitleTextStyle(context),
          ),
          const SizedBox(height: MEDIUM_SPACE),
          SizedBox(
            width: double.infinity,
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(MEDIUM_SPACE),
              child: LocationsMap(
                controller: _controller,
              ),
            ),
          ),
        ],
        const SizedBox(height: MEDIUM_SPACE),
        PlatformElevatedButton(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          onPressed: widget.onImport,
          material: (_, __) => MaterialElevatedButtonData(
            icon: const Icon(Icons.file_download_outlined),
          ),
          child: Text(l10n.sharesOverviewScreen_importTask_importLabel),
        ),
      ],
    );
  }
}
