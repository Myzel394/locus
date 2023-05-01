import 'dart:math';
import 'dart:ui';

import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:locus/constants/app.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/QRScannerOverlayShape.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQRCode extends StatefulWidget {
  final void Function() onAbort;
  final void Function(String) onURLDetected;

  const ScanQRCode({
    required this.onAbort,
    required this.onURLDetected,
    Key? key,
  }) : super(key: key);

  @override
  State<ScanQRCode> createState() => _ScanQRCodeState();
}

class _ScanQRCodeState extends State<ScanQRCode> {
  final controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool hasTorch = false;
  bool torchEnabled = false;
  String message = "";

  @override
  void initState() {
    super.initState();

    controller.hasTorchState.addListener(() {
      setState(() {
        hasTorch = controller.hasTorch;
      });
    });

    showHint();
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  Future<void> showHint() async {
    await Future.delayed(10.seconds);

    setState(() {
      message = "Try moving back and fourth";
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeColor =
        isMaterial(context) ? Colors.amber : CupertinoColors.systemYellow;
    final size = min(
      MediaQuery.of(context).size.width * 0.7,
      MediaQuery.of(context).size.height * 0.7,
    );

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: MobileScanner(
              controller: controller,
              fit: BoxFit.cover,
              onDetect: (capture) {
                for (final code in capture.barcodes) {
                  if (code.url?.url == null) {
                    continue;
                  }

                  final parsedURL = Uri.tryParse(code.url!.url!);

                  if (parsedURL == null) {
                    continue;
                  }

                  if (parsedURL.host != APP_URL_DOMAIN ||
                      !parsedURL.hasAbsolutePath) {
                    continue;
                  }

                  // URL seems to be valid
                  widget.onURLDetected(code.url!.url!);
                }
              },
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: ShapeDecoration(
                shape: QrScannerOverlayShape(
                  borderColor: Colors.white,
                  borderRadius: SMALL_SPACE,
                  borderLength: min(size, 50),
                  borderWidth: 7,
                  cutOutSize: size,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(MEDIUM_SPACE),
              child: SafeArea(
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Row(
                        children: <Widget>[
                          PlatformIconButton(
                            icon: Icon(context.platformIcons.back),
                            onPressed: widget.onAbort,
                            padding: const EdgeInsets.all(SMALL_SPACE),
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    hasTorch
                        ? Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                PlatformIconButton(
                                  icon: Icon(context.platformIcons.brightness),
                                  onPressed: () {
                                    controller.toggleTorch();

                                    setState(() {
                                      torchEnabled = !torchEnabled;
                                    });
                                  },
                                  padding: const EdgeInsets.all(MEDIUM_SPACE),
                                  color:
                                      torchEnabled ? activeColor : Colors.white,
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                    message.isNotEmpty
                        ? Positioned(
                            top: HUGE_SPACE,
                            left: 0,
                            right: 0,
                            child: Text(
                              message,
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(duration: 1.seconds),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
