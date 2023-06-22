import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/services/settings_service.dart';
import 'package:locus/utils/load_status.dart';
import 'package:locus/utils/show_message.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/RequestLocationPermissionMixin.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/widgets/WarningText.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../widgets/PlatformFlavorWidget.dart';

enum CheckMethod {
  usingBestLocation,
  usingWorstLocation,
  usingAndroidLocationManager,
}

const TIMEOUT_DURATION = Duration(minutes: 1);

class CheckLocationScreen extends StatefulWidget {
  const CheckLocationScreen({super.key});

  @override
  State<CheckLocationScreen> createState() => _CheckLocationScreenState();
}

class _CheckLocationScreenState extends State<CheckLocationScreen>
    with RequestLocationPermissionMixin {
  LoadStatus status = LoadStatus.idle;
  CheckMethod? method;

  Future<Position?> _getLocation(final CheckMethod method) async {
    setState(() {
      this.method = method;
    });

    try {
      switch (method) {
        case CheckMethod.usingBestLocation:
          final result = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
            forceAndroidLocationManager: false,
            timeLimit: TIMEOUT_DURATION,
          );
          return result;
        case CheckMethod.usingWorstLocation:
          final result = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.lowest,
            forceAndroidLocationManager: false,
            timeLimit: TIMEOUT_DURATION,
          );
          return result;
        case CheckMethod.usingAndroidLocationManager:
          final result = await Geolocator.getCurrentPosition(
            forceAndroidLocationManager: true,
            timeLimit: TIMEOUT_DURATION,
          );
          return result;
      }
    } catch (_) {
      return null;
    }
  }

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
    setState(() {
      status = LoadStatus.loading;
      method = null;
    });

    final hasGrantedPermissions = await showLocationPermissionDialog();

    if (!hasGrantedPermissions) {
      setState(() {
        status = LoadStatus.error;
      });
      return;
    }

    final hasEnabledGPS = await Geolocator.isLocationServiceEnabled();

    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context);

    if (!hasEnabledGPS) {
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

    final location = await (() async {
      final bestLocation = await _getLocation(CheckMethod.usingBestLocation);

      if (bestLocation != null) {
        return bestLocation;
      }

      final worstLocation = await _getLocation(CheckMethod.usingWorstLocation);

      if (worstLocation != null) {
        return worstLocation;
      }

      return await _getLocation(CheckMethod.usingAndroidLocationManager);
    })();

    if (location == null) {
      setState(() {
        status = LoadStatus.error;
      });
      return;
    }

    if (!mounted) {
      return;
    }

    _showSuccessDialog(location);
  }

  Map<CheckMethod, String> getNamesForCheckMethodMap() {
    final l10n = AppLocalizations.of(context);

    return {
      CheckMethod.usingBestLocation:
          l10n.checkLocation_values_usingBestLocation,
      CheckMethod.usingWorstLocation:
          l10n.checkLocation_values_usingWorstLocation,
      CheckMethod.usingAndroidLocationManager:
          l10n.checkLocation_values_usingAndroidLocationManager,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final namesForCheckMethodMap = getNamesForCheckMethodMap();

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(l10n.checkLocation_title),
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
                        CheckMethod.values.length * TIMEOUT_DURATION.inMinutes,
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
                            setState(() {
                              status = LoadStatus.error;
                            });
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
                          "${method!.index + 1} / ${CheckMethod.values.length}",
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
