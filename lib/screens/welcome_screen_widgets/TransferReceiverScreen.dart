import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/bluetooth.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/PINView.dart';
import 'package:lottie/lottie.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../constants/app.dart';
import '../../constants/values.dart';
import '../../utils/import_export_handler.dart';

class TransferReceiverScreen extends StatefulWidget {
  final void Function(String rawData) onContentReceived;

  const TransferReceiverScreen({
    required this.onContentReceived,
    Key? key,
  }) : super(key: key);

  @override
  State<TransferReceiverScreen> createState() => _TransferReceiverScreenState();
}

class _TransferReceiverScreenState extends State<TransferReceiverScreen> {
  bool connectionEstablished = false;
  String? connectionID;
  int? connectionPIN;
  double? progress;
  bool hasGrantedPermissions = false;

  @override
  void initState() {
    super.initState();

    checkPermissions();
  }

  @override
  dispose() {
    Nearby().stopAdvertising();
    Nearby().stopAllEndpoints();

    super.dispose();
  }

  checkPermissions() async {
    final hasGranted = await checkIfHasBluetoothPermission();

    if (hasGranted) {
      setState(() {
        hasGrantedPermissions = true;
      });

      startAdvertising();
    }
  }

  startAdvertising() async {
    final serviceID = await getBluetoothServiceID();

    Nearby().askBluetoothPermission();

    await Nearby().startAdvertising(
      PACKAGE_NAME,
      Strategy.P2P_POINT_TO_POINT,
      onConnectionInitiated: (id, info) {
        setState(() {
          connectionID = id;
          connectionPIN = int.parse(info.endpointName);
        });
      },
      onConnectionResult: (id, status) {
        if (status == Status.CONNECTED) {
          setState(() {
            connectionEstablished = true;
          });
        }
      },
      onDisconnected: (id) {
        setState(() {
          connectionEstablished = false;
          connectionID = null;
          connectionPIN = null;
        });
      },
      serviceId: serviceID,
    );
  }

  acceptConnection() {
    Nearby().acceptConnection(
      connectionID!,
      onPayLoadRecieved: (_, payload) async {
        await Nearby().sendBytesPayload(connectionID!, TRANSFER_SUCCESS_MESSAGE);

        widget.onContentReceived(
          const Utf8Decoder().convert(payload.bytes!),
        );
      },
      onPayloadTransferUpdate: (_, update) {
        setState(() {
          progress = update.totalBytes / update.bytesTransferred;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(l10n.welcomeScreen_import_transfer),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          child: Center(
            child: (() {
              if (!hasGrantedPermissions) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.bluetooth_audio_rounded, size: 60),
                    const SizedBox(height: MEDIUM_SPACE),
                    Text(l10n.grantBluetoothPermission),
                    const SizedBox(height: MEDIUM_SPACE),
                    PlatformElevatedButton(
                      onPressed: checkPermissions,
                      child: Text(l10n.grantPermission),
                    ),
                  ],
                );
              }
              if (progress != null) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    CircularProgressIndicator(
                      value: progress,
                    ),
                    const SizedBox(height: MEDIUM_SPACE),
                    Text(
                      l10n.transferScreen_receive_connected_label,
                    ),
                  ],
                );
              }

              if (connectionEstablished) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.smartphone, size: 60),
                    const SizedBox(height: MEDIUM_SPACE),
                    Text(
                      l10n.transferScreen_receive_connected_label,
                    ),
                  ],
                );
              }

              if (connectionID == null) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Lottie.asset(
                      "assets/lotties/bluetooth.json",
                      frameRate: FrameRate.max,
                      repeat: true,
                    ),
                    Text(
                      l10n.transferScreen_receive_awaiting_label,
                      style: getBodyTextTextStyle(context),
                    ),
                  ],
                );
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    l10n.transferScreen_receive_connect_description,
                  ),
                  const SizedBox(height: MEDIUM_SPACE),
                  PINView(
                    pin: connectionPIN!,
                  ),
                  const SizedBox(height: MEDIUM_SPACE),
                  PlatformElevatedButton(
                    onPressed: acceptConnection,
                    child: Text("Connect"),
                  ),
                ],
              );
            })(),
          ),
        ),
      ),
    );
  }
}
