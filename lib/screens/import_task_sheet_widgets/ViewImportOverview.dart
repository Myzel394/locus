import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/services/view_service.dart';
import 'package:openpgp/openpgp.dart';

import '../../api/get-locations.dart';
import '../../constants/spacing.dart';
import '../../services/location_point_service.dart';
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
  void Function()? _unsubscribeGetLocations;
  final LocationsMapController _controller = LocationsMapController();
  bool _isLoading = true;
  bool _isError = false;

  double timeOffset = 0;

  @override
  void initState() {
    super.initState();

    addListener();
  }

  @override
  void dispose() {
    _unsubscribeGetLocations?.call();
    _controller.dispose();

    super.dispose();
  }

  addListener() async {
    _unsubscribeGetLocations = await getLocations(
      viewPrivateKey: widget.view.viewPrivateKey,
      signPublicKey: widget.view.signPublicKey,
      nostrPublicKey: widget.view.nostrPublicKey,
      relays: widget.view.relays,
      onlyLatestPosition: true,
      onLocationFetched: (final LocationPointService location) {
        if (!mounted) {
          return;
        }

        _controller.add(location);
        setState(() {});
      },
      onEnd: () {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  Future<String> getFingerprintFromKey(final String key) async {
    final metadata = await OpenPGP.getPublicKeyMetadata(key);

    return metadata.fingerprint;
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
            PlatformListTile(
              title: FutureBuilder<String>(
                  future: getFingerprintFromKey(widget.view.signPublicKey),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(snapshot.data!);
                    } else {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  }),
              subtitle: Text(l10n.signPublicKeyLabel),
              leading: Icon(context.platformIcons.pen),
              trailing: const SizedBox.shrink(),
            )
          ],
        ),
        if (_isLoading)
          const Padding(
            padding: const EdgeInsets.all(MEDIUM_SPACE),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (_isError)
          Text(
            l10n.locationsLoadingError,
            style: TextStyle(
              color: getErrorColor(context),
            ),
          )
        else ...[
          Text(
            l10n.mainScreen_importTask_importOverview_lastPosition,
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
          child: Text(l10n.mainScreen_importTask_importLabel),
        ),
      ],
    );
  }
}
