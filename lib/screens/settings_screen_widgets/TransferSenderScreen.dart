import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/app.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/services/settings_service.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/utils/bluetooth.dart';
import 'package:locus/utils/import_export_handler.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/PINView.dart';
import 'package:lottie/lottie.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../services/view_service.dart';

class TransferSenderScreen extends StatefulWidget {
  const TransferSenderScreen({Key? key}) : super(key: key);

  @override
  State<TransferSenderScreen> createState() => _TransferSenderScreenState();
}

class _TransferSenderScreenState extends State<TransferSenderScreen> with BluetoothPermissionMixin {
  final pin = Random().nextInt(90000) + 10000;
  String? connectionID;
  bool connectionEstablished = false;
  bool isSending = false;

  @override
  void initState() {
    super.initState();

    checkBluetoothPermission();
  }

  @override
  dispose() {
    Nearby().stopDiscovery();
    Nearby().stopAllEndpoints();

    super.dispose();
  }

  @override
  void onBluetoothPermissionGranted() {
    startDiscovery();
  }

  startDiscovery() async {
    final serviceID = await getBluetoothServiceID();

    await Nearby().startDiscovery(
      PACKAGE_NAME,
      Strategy.P2P_POINT_TO_POINT,
      onEndpointFound: (String id, String userName, String serviceId) {
        Nearby().requestConnection(
          pin.toString(),
          id,
          onConnectionInitiated: (id, __) {
            if (connectionID != null) {
              return;
            }

            Nearby().acceptConnection(
              id,
              onPayLoadRecieved: (_, payload) {
                if (listEquals(payload.bytes, TRANSFER_SUCCESS_MESSAGE)) {
                  Navigator.of(context).pop();
                }
              },
            );

            setState(() {
              connectionID = id;
            });
          },
          onConnectionResult: (_, status) {
            if (status == Status.CONNECTED) {
              setState(() {
                connectionEstablished = true;
              });
            }
          },
          onDisconnected: (_) {
            setState(() {
              connectionEstablished = false;
              connectionID = null;
            });
          },
        );
      },
      onEndpointLost: (_) {
        setState(() {
          connectionEstablished = false;
          connectionID = null;
        });
      },
      serviceId: serviceID,
    );
  }

  void sendData() async {
    setState(() {
      isSending = true;
    });

    try {
      final taskService = context.read<TaskService>();
      final viewService = context.read<ViewService>();
      final settings = context.read<SettingsService>();

      final content = jsonEncode(
        await exportToJSON(taskService, viewService, settings),
      );

      final data = Uint8List.fromList(content.codeUnits);

      await Nearby().sendBytesPayload(connectionID!, data);
    } catch (_) {
    } finally {
      setState(() {
        isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(l10n.settingsScreen_settings_importExport_transfer),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          child: Center(
            child: (() {
              if (!hasGrantedBluetoothPermission) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.bluetooth_audio_rounded, size: 60),
                    const SizedBox(height: MEDIUM_SPACE),
                    Text(l10n.grantBluetoothPermission),
                    const SizedBox(height: MEDIUM_SPACE),
                    PlatformElevatedButton(
                      onPressed: checkBluetoothPermission,
                      child: Text(l10n.grantPermission),
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
                    Text(l10n.transferScreen_send_connected_label),
                    const SizedBox(height: MEDIUM_SPACE),
                    PlatformElevatedButton(
                      onPressed: sendData,
                      child: Text(l10n.transferScreen_send_startTransfer),
                    ),
                  ],
                );
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    child: Lottie.asset(
                      "assets/lotties/radar.json",
                      frameRate: FrameRate.max,
                      repeat: true,
                    ),
                  ).animate().fadeIn(duration: 800.ms),
                  Text(l10n.transferScreen_send_awaiting_label),
                  const SizedBox(height: LARGE_SPACE),
                  Text(
                    l10n.transferScreen_send_pin_description,
                    style: getCaptionTextStyle(context),
                  ),
                  const SizedBox(height: SMALL_SPACE),
                  PINView(pin: pin),
                ],
              );
            })(),
          ),
        ),
      ),
    );
  }
}
