import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/services/task_service.dart';
import 'package:nostr/nostr.dart';

import 'CreateTaskScreen.dart';

class MainScreen extends StatefulWidget {
  final String nostrPrivateKey;
  final String pgpPrivateKey;
  final String pgpPublicKey;
  final List<String> relays;

  const MainScreen({
    required this.nostrPrivateKey,
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
    socket = await WebSocket.connect(
      widget.relays[0],
    );

    await Future.delayed(Duration(seconds: 10));

    socket.listen((rawEvent) async {
      final event = Message.deserialize(rawEvent);
      print(event);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: FutureBuilder<TaskService>(
                future: TaskService.restore(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                      itemCount: snapshot.data!.tasks.length,
                      itemBuilder: (context, index) {
                        final task = snapshot.data!.tasks[index];

                        return ListTile(
                          title: Text(task.name),
                          subtitle: Text(task.frequency.toString()),
                          leading: FutureBuilder<bool>(
                            future: task.isRunning(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return PlatformSwitch(
                                  value: snapshot.data!,
                                  onChanged: (value) async {
                                    if (value) {
                                      await task.start();
                                    } else {
                                      await task.stop();
                                    }
                                  },
                                );
                              }

                              return const SizedBox();
                            },
                          ),
                        );
                      },
                    );
                  }

                  return PlatformCircularProgressIndicator();
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to CreateTaskScreen

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CreateTaskScreen(),
                  ),
                );
              },
              child: Text("Send event"),
            ),
          ],
        ),
      ),
    );
  }
}
