import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/services/task_service.dart';
import 'package:nostr/nostr.dart';
import 'package:openpgp/openpgp.dart';
import 'package:provider/provider.dart';

import '../api/nostr-events.dart';
import 'CreateTaskScreen.dart';

class MainScreen extends StatefulWidget {
  final String nostrPrivateKey;
  final String nostrPublicKey;
  final String pgpPrivateKey;
  final String pgpPublicKey;
  final List<String> relays;

  const MainScreen({
    required this.nostrPrivateKey,
    required this.nostrPublicKey,
    required this.pgpPublicKey,
    required this.pgpPrivateKey,
    required this.relays,
    Key? key,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final WebSocket socket;

  @override
  void initState() {
    super.initState();

    registerListener();
  }

  @override
  void dispose() {
    socket.close();
    super.dispose();
  }

  registerListener() async {
    final request = Request(generate64RandomHexChars(), [
      Filter(
        kinds: [1000],
        authors: [widget.nostrPublicKey],
        since: 1679242255,
      ),
    ]);

    socket = await WebSocket.connect(
      widget.relays[0],
    );

    socket.add(request.serialize());

    await Future.delayed(Duration(seconds: 1));

    socket.listen((rawEvent) async {
      final event = Message.deserialize(rawEvent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskService = context.watch<TaskService>();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CreateTaskScreen(),
            ),
          );
        },
        child: Icon(context.platformIcons.add),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                final data = {
                  "time": DateTime.now().toIso8601String(),
                };
                final encryptedData = await OpenPGP.encrypt(
                  jsonEncode(data),
                  widget.pgpPublicKey,
                );

                final manager = NostrEventsManager(
                  privateKey: widget.nostrPrivateKey,
                  relays: widget.relays,
                  socket: socket,
                );
                await manager.publishEvent(encryptedData);
              },
              child: Text("Send event"),
            ),
          ],
        ),
      ),
    );
  }
}
