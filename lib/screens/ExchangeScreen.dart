import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

class ExchangeScreen extends StatefulWidget {
  final String privateKey;
  final String publicKey;
  final String name;

  const ExchangeScreen({required this.privateKey,
    required this.publicKey,
    required this.name,
    Key? key})
      : super(key: key);

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  final String numbers =
  List.generate(8, (index) => Random().nextInt(10)).join("");

  @override
  void initState() {
    super.initState();

    setupWebRTC();
  }

  void setupWebRTC() async {
    _webrtcPeerConnection = WebrtcPeerConnection(
      onSignalingStateChange: (SignalingState state) {},
      onIceGatheringStateChange: (IceGatheringState state) {},
      onIceConnectionStateChange: (IceConnectionState state) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Spacer(),
            Text("Connect to a friend"),
            Spacer(),
            Text(""),
            Spacer(),
            Text(
              widget.name,
            )
          ],
        ),
      ),
    );
  }
}
