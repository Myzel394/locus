import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locus/constants/app.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/services/SettingsService/settings_service.dart';
import 'package:locus/utils/helper_sheet.dart';
import 'package:locus/utils/load_status.dart';
import 'package:locus/utils/location.dart';
import 'package:locus/utils/show_message.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/RequestLocationPermissionMixin.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/widgets/WarningText.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:wakelock/wakelock.dart';

import '../widgets/PlatformFlavorWidget.dart';

const TIMEOUT_DURATION = Duration(minutes: 1);

class CheckLocationScreen extends StatefulWidget {
  const CheckLocationScreen({super.key});

  @override
  State<CheckLocationScreen> createState() => _CheckLocationScreenState();
}

class _CheckLocationScreenState extends State<CheckLocationScreen>
    with RequestLocationPermissionMixin {
  LoadStatus status = LoadStatus.idle;
  LocationMethod? method;

  Future<void> _showSuccessDialog(final Position location) async {
    final l10n = AppLocalizations.of(context);
    final settings = context.read<SettingsService>();

    setState(() {
      status = LoadStatus.idle;
    });

    String address = "";

    try {
      address =
          await settings.getAddress(location.latitude, location.longitude);
    } catch (error) {
      FlutterLogs.logError(
        LOG_TAG,
        "CheckLocationScreen",
        "Error while getting address: $error",
      );
    }

    if (!mounted) {
      return;
    }

    await showPlatformDialog(
      context: context,
      builder: (innerContext) => PlatformAlertDialog(
        title: Text(l10n.checkLocation_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Lottie.asset(
              "assets/lotties/success.json",
              frameRate: FrameRate.max,
              repeat: false,
            ),
            const SizedBox(height: MEDIUM_SPACE),
            Text(
              l10n.checkLocation_successMessage,
            ),
            const SizedBox(height: MEDIUM_SPACE),
            Text(
              address,
              style: getCaptionTextStyle(context),
            ),
          ],
        ),
        actions: [
          PlatformDialogAction(
            onPressed: () {
              Navigator.of(innerContext).pop();
              Navigator.of(context).pop();
            },
            child: Text(l10n.closeNeutralAction),
          )
        ],
      ),
    );
  }

  Future<void> doCheck() async {
    final l10n = AppLocalizations.of(context);

    FlutterLogs.logInfo(
      LOG_TAG,
      "CheckLocationScreen",
      "Running location check now.",
    );

    setState(() {
      status = LoadStatus.loading;
      method = null;
    });

    final hasGrantedPermissions = await showLocationPermissionDialog();

    if (!mounted) {
      return;
    }

    if (!hasGrantedPermissions) {
      FlutterLogs.logInfo(
        LOG_TAG,
        "CheckLocationScreen",
        "Location permission was not granted.",
      );

      setState(() {
        status = LoadStatus.idle;
      });

      await showMessage(
        context,
        l10n.checkLocation_permissionDeniedMessage,
        type: MessageType.error,
      );
      return;
    }

    final hasEnabledGPS = await Geolocator.isLocationServiceEnabled();

    if (!mounted) {
      return;
    }

    if (!hasEnabledGPS) {
      FlutterLogs.logInfo(
        LOG_TAG,
        "CheckLocationScreen",
        "GPS was not enabled.",
      );

      setState(() {
        status = LoadStatus.idle;
      });

      await showMessage(
        context,
        l10n.checkLocation_gpsDisabledMessage,
        type: MessageType.error,
      );
      return;
    }

    try {
      Wakelock.enable();
    } catch (error) {
      FlutterLogs.logError(
        LOG_TAG,
        "CheckLocationScreen",
        "Error while enabling wakelock: $error",
      );
    }

    try {
      final location = await getCurrentPosition(
        onMethodCheck: (method) {
          setState(() {
            this.method = method;
          });
        },
      );

      if (!mounted) {
        return;
      }

      _showSuccessDialog(location);
    } catch (_) {
      failCheck();
      return;
    }
  }

  void failCheck() async {
    try {
      Wakelock.disable();
    } catch (error) {
      FlutterLogs.logError(
        LOG_TAG,
        "CheckLocationScreen",
        "Error while disabling wakelock: $error",
      );
    }

    setState(() {
      status = LoadStatus.idle;
    });

    final l10n = AppLocalizations.of(context);

    await showPlatformDialog(
      context: context,
      builder: (context) => PlatformAlertDialog(
        title: Text(l10n.checkLocation_title),
        content: Text(
          l10n.checkLocation_errorMessage,
        ),
        actions: createCancellableDialogActions(
          context,
          [
            PlatformDialogAction(
              child: Text(l10n.checkLocation_openHelp),
            )
          ],
        ),
      ),
    );
  }

  Map<LocationMethod, String> getNamesForCheckMethodMap() {
    final l10n = AppLocalizations.of(context);

    return {
      LocationMethod.best: l10n.checkLocation_values_usingBestLocation,
      LocationMethod.worst: l10n.checkLocation_values_usingWorstLocation,
      LocationMethod.androidLocationManagerBest:
          l10n.checkLocation_values_usingAndroidLocationManagerBest,
      LocationMethod.androidLocationManagerWorst:
          l10n.checkLocation_values_usingAndroidLocationManagerWorst,
    };
  }

  void showHelp() {
    final l10n = AppLocalizations.of(context);

    showHelperSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            l10n.help_location_preamble,
            style: getBodyTextTextStyle(context),
          ),
          const SizedBox(height: MEDIUM_SPACE),
          Row(
            children: <Widget>[
              Icon(context.platformIcons.home),
              const SizedBox(width: MEDIUM_SPACE),
              Flexible(
                child: Text(l10n.help_location_goOutside),
              ),
            ],
          ),
          const SizedBox(height: MEDIUM_SPACE),
          Row(
            children: <Widget>[
              const Icon(Icons.wifi_rounded),
              const SizedBox(width: MEDIUM_SPACE),
              Flexible(
                child: Text(l10n.help_location_enableScanning),
              ),
              const SizedBox(width: MEDIUM_SPACE),
              PlatformIconButton(
                onPressed: openAppSettings,
                icon: Icon(context.platformIcons.settings),
              )
            ],
          ),
          if (isGMSFlavor) ...[
            const SizedBox(height: MEDIUM_SPACE),
            Row(
              children: <Widget>[
                const Icon(Icons.location_searching_rounded),
                const SizedBox(width: MEDIUM_SPACE),
                Flexible(
                  child: Text(l10n.help_location_enableGoogleLocationServices),
                ),
                const SizedBox(width: MEDIUM_SPACE),
                PlatformIconButton(
                  onPressed: openAppSettings,
                  icon: Icon(context.platformIcons.settings),
                )
              ],
            ),
          ],
          if (Platform.isAndroid && isFLOSSFlavor) ...[
            const SizedBox(height: MEDIUM_SPACE),
            Row(
              children: <Widget>[
                const Icon(Icons.download_rounded),
                const SizedBox(width: MEDIUM_SPACE),
                Flexible(
                  child: Text(l10n.help_location_useGMSVersion),
                ),
                const SizedBox(width: MEDIUM_SPACE),
                PlatformIconButton(
                  onPressed: () {
                    launchUrlString(
                      APK_RELEASES_URL,
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  icon: const Icon(Icons.open_in_new),
                )
              ],
            ),
          ]
        ],
      ),
      title: l10n.help_location_title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final namesForCheckMethodMap = getNamesForCheckMethodMap();

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(l10n.checkLocation_title),
        trailingActions: <Widget>[
          PlatformIconButton(
            cupertino: (_, __) => CupertinoIconButtonData(
              padding: EdgeInsets.zero,
            ),
            icon: Icon(context.platformIcons.help),
            onPressed: showHelp,
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Flexible(child: SizedBox.shrink()),
                Column(
                  children: <Widget>[
                    PlatformFlavorWidget(
                      material: (_, __) =>
                          const Icon(Icons.location_on, size: 100),
                      cupertino: (_, __) =>
                          const Icon(CupertinoIcons.location_fill, size: 100),
                    ),
                    const SizedBox(height: LARGE_SPACE),
                    Text(
                      l10n.checkLocation_description(
                        LocationMethod.values.length *
                            TIMEOUT_DURATION.inMinutes,
                      ),
                      style: getBodyTextTextStyle(context),
                    ),
                  ],
                ),
                if (status == LoadStatus.loading)
                  Column(
                    children: <Widget>[
                      if (method != null) ...[
                        Text(
                          namesForCheckMethodMap[method]!,
                          style: getCaptionTextStyle(context),
                        ),
                        const SizedBox(height: MEDIUM_SPACE),
                      ],
                      TweenAnimationBuilder<double>(
                        key: ValueKey(method),
                        duration:
                            Duration(seconds: TIMEOUT_DURATION.inSeconds + 5),
                        curve: Curves.easeInOut,
                        onEnd: () {
                          if (status == LoadStatus.loading) {
                            failCheck();
                          }
                        },
                        tween: Tween<double>(
                          begin: 1,
                          end: 0,
                        ),
                        builder: (context, value, _) =>
                            LinearProgressIndicator(value: value),
                      ),
                      if (method != null) ...[
                        const SizedBox(height: MEDIUM_SPACE),
                        Text(
                          "${method!.index + 1} / ${LocationMethod.values.length}",
                          style: getCaptionTextStyle(context),
                        ),
                      ]
                    ],
                  ),
                PlatformElevatedButton(
                  padding: const EdgeInsets.all(MEDIUM_SPACE),
                  material: (_, __) => MaterialElevatedButtonData(
                    icon: const Icon(Icons.check),
                  ),
                  onPressed: status == LoadStatus.loading ? null : doCheck,
                  child: Text(l10n.checkLocation_start_label),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
