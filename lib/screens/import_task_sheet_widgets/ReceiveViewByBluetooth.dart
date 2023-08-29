import 'dart:convert';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/extensions/string.dart';
import 'package:locus/utils/permissions/mixins.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/BluetoothPermissionRequiredScreen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/widgets/Paper.dart';
import 'package:lottie/lottie.dart';
import 'package:nearby_connections/nearby_connections.dart';

import '../../services/view_service.dart';
import '../../utils/import_export_handler.dart';

class ReceiveViewByBluetooth extends StatefulWidget {
  final void Function(TaskView view) onImport;

  const ReceiveViewByBluetooth({
    required this.onImport,
    Key? key,
  }) : super(key: key);

  @override
  State<ReceiveViewByBluetooth> createState() => _ReceiveViewByBluetoothState();
}

class _ReceiveViewByBluetoothState extends State<ReceiveViewByBluetooth>
    with BluetoothPermissionMixin {
  final String id = createIdentifier();
  String? connectionID;

  // We do not want to show another dialogue if the user is already confirming a request
  bool isConfirmingRequest = false;

  static String createIdentifier() {
    final wordPair = generateWordPairs().first;

    return "${wordPair.first.capitalize()} ${wordPair.second.capitalize()}";
  }

  @override
  void initState() {
    super.initState();

    checkBluetoothPermission();
  }

  @override
  void dispose() {
    closeBluetooth();

    super.dispose();
  }

  @override
  void onBluetoothPermissionGranted() async {
    final l10n = AppLocalizations.of(context);
    final baseServiceID = await getBluetoothServiceID();
    final serviceID = "$baseServiceID-share-task";

    Nearby().startAdvertising(
      id,
      Strategy.P2P_POINT_TO_POINT,
      onConnectionInitiated: (id, _) async {
        if (isConfirmingRequest) {
          return;
        }

        setState(() {
          isConfirmingRequest = true;
        });

        try {
          final acceptConnection = await showPlatformDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => PlatformAlertDialog(
              title: Text(l10n.importTask_bluetooth_receive_request_title),
              content:
                  Text(l10n.importTask_bluetooth_receive_request_description),
              actions: [
                PlatformDialogAction(
                  onPressed: () => Navigator.of(context).pop(false),
                  material: (_, __) => MaterialDialogActionData(
                    icon: const Icon(Icons.close),
                  ),
                  child:
                      Text(l10n.importTask_bluetooth_receive_request_decline),
                ),
                PlatformDialogAction(
                  onPressed: () => Navigator.of(context).pop(true),
                  material: (_, __) => MaterialDialogActionData(
                    icon: const Icon(Icons.check),
                  ),
                  child: Text(l10n.importTask_bluetooth_receive_request_accept),
                ),
              ],
            ),
          );

          if (acceptConnection) {
            setState(() {
              connectionID = id;
            });

            Nearby().acceptConnection(
              id,
              onPayLoadRecieved: (endPointID, payload) async {
                final rawData = const Utf8Decoder().convert(payload.bytes!);
                final view = TaskView.fromJSON(jsonDecode(rawData));

                await Nearby()
                    .sendBytesPayload(endPointID, TRANSFER_SUCCESS_MESSAGE);

                widget.onImport(view);
              },
            );
          } else {
            Nearby().rejectConnection(id);
          }
        } catch (_) {
        } finally {
          setState(() {
            isConfirmingRequest = false;
          });
        }
      },
      onConnectionResult: (_, __) {},
      onDisconnected: (_) {
        setState(() {
          connectionID = null;
        });
      },
      serviceId: serviceID,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!hasGrantedBluetoothPermission) {
      return BluetoothPermissionRequiredScreen(
          onRequest: checkBluetoothPermission);
    }

    if (connectionID == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Lottie.asset(
            "assets/lotties/bluetooth.json",
            height: 200,
            frameRate: FrameRate.max,
            repeat: true,
          ),
          Text(
            l10n.importTask_bluetooth_receive_title,
            style: getTitle2TextStyle(context),
          ),
          const SizedBox(height: MEDIUM_SPACE),
          Text(l10n.importTask_bluetooth_receive_description),
          const SizedBox(height: LARGE_SPACE),
          Text(
            l10n.importTask_bluetooth_receive_id_description,
            style: getCaptionTextStyle(context),
          ),
          const SizedBox(height: MEDIUM_SPACE),
          Center(
            child: Paper(
              width: null,
              child: Text(
                id,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return Center(
      child: PlatformCircularProgressIndicator(),
    );
  }
}
