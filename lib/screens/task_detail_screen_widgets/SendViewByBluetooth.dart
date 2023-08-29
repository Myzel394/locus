import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/models/log.dart';
import 'package:locus/utils/import_export_handler.dart';
import 'package:locus/utils/permissions/mixins.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/BluetoothPermissionRequiredScreen.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:nearby_connections/nearby_connections.dart';

import '../../widgets/ModalSheet.dart';

class EndpointInformation {
  final String id;
  final String name;

  EndpointInformation({
    required this.id,
    required this.name,
  }) : super();
}

class SendViewByBluetooth extends StatefulWidget {
  final String data;

  const SendViewByBluetooth({
    required this.data,
    Key? key,
  }) : super(key: key);

  @override
  State<SendViewByBluetooth> createState() => _SendViewByBluetoothState();
}

class _SendViewByBluetoothState extends State<SendViewByBluetooth>
    with BluetoothPermissionMixin {
  final id = uuid.v4();
  final List<EndpointInformation> endpoints = [];

  // List of endpoints from which we have been rejected
  final List<String> rejectedEndpoints = [];
  String? attemptConnectionID;

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
    final baseServiceID = await getBluetoothServiceID();
    final serviceID = "$baseServiceID-share-task";

    Nearby().startDiscovery(
      id,
      Strategy.P2P_POINT_TO_POINT,
      onEndpointFound: (endpointID, endpointName, serviceId) {
        setState(() {
          endpoints.add(
            EndpointInformation(
              id: endpointID,
              name: endpointName,
            ),
          );
        });
      },
      onEndpointLost: (endpointID) {
        final index =
            endpoints.indexWhere((element) => element.id == endpointID);

        setState(() {
          rejectedEndpoints.remove(endpointID);
          endpoints.removeAt(index);
        });
      },
      serviceId: serviceID,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ModalSheet(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: MEDIUM_SPACE),
        child: (() {
          if (!hasGrantedBluetoothPermission) {
            return BluetoothPermissionRequiredScreen(
                onRequest: checkBluetoothPermission);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Lottie.asset(
                "assets/lotties/radar.json",
                height: 200,
                frameRate: FrameRate.max,
                repeat: true,
              ),
              const SizedBox(height: MEDIUM_SPACE),
              Text(
                l10n.importTask_bluetooth_send_title,
                style: getTitle2TextStyle(context),
              ),
              const SizedBox(height: MEDIUM_SPACE),
              Text(l10n.importTask_bluetooth_send_description),
              if (endpoints.isNotEmpty) ...[
                const SizedBox(height: LARGE_SPACE),
                ListView.builder(
                  itemCount: endpoints.length,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final endpoint = endpoints[index];
                    final shouldDisable =
                        rejectedEndpoints.contains(endpoint.id) ||
                            attemptConnectionID != null;

                    return PlatformListTile(
                        title: Text(endpoint.name),
                        leading: const Icon(Icons.smartphone),
                        trailing: (() {
                          if (rejectedEndpoints.contains(endpoint.id)) {
                            return Icon(
                              Icons.error,
                              color: getErrorColor(context),
                            );
                          }

                          if (attemptConnectionID == endpoint.id) {
                            return SizedBox.square(
                              dimension: 20,
                              child: PlatformCircularProgressIndicator(),
                            );
                          }
                        })(),
                        onTap: shouldDisable
                            ? null
                            : (() async {
                                setState(() {
                                  attemptConnectionID = endpoint.id;
                                });

                                try {
                                  await Nearby().requestConnection(
                                    id,
                                    endpoint.id,
                                    onConnectionInitiated: (_, __) async {
                                      await Nearby().acceptConnection(
                                        endpoint.id,
                                        onPayLoadRecieved: (_, payload) {
                                          if (listEquals(payload.bytes,
                                              TRANSFER_SUCCESS_MESSAGE)) {
                                            Navigator.of(context).pop();
                                          }
                                        },
                                      );
                                    },
                                    onConnectionResult: (_, status) {
                                      setState(() {
                                        attemptConnectionID = null;
                                      });

                                      if (status == Status.REJECTED) {
                                        setState(() {
                                          rejectedEndpoints.add(endpoint.id);
                                        });
                                      } else if (status == Status.CONNECTED) {
                                        final bytes = const Utf8Encoder()
                                            .convert(widget.data);

                                        Nearby().sendBytesPayload(
                                            endpoint.id, bytes);
                                      }
                                    },
                                    onDisconnected: (id) {
                                      setState(() {
                                        attemptConnectionID = null;
                                        rejectedEndpoints.remove(id);
                                      });
                                    },
                                  );
                                } catch (error) {
                                  setState(() {
                                    attemptConnectionID = null;
                                  });
                                }
                              }));
                  },
                ),
              ],
            ],
          );
        })(),
      ),
    );
  }
}
