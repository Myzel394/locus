import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/task_service.dart';
import 'package:nostr/nostr.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({
    required this.task,
    Key? key,
  }) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late final WebSocket _socket;
  late final MapController _controller;
  bool _isLoading = true;
  List<LocationPointService> _locations = [];

  get nostrPublicKey => Keychain(widget.task.nostrPrivateKey).public;

  @override
  void initState() {
    super.initState();

    _controller = MapController(
      initMapWithUserPosition: true,
    );

    registerListener();
  }

  @override
  void dispose() {
    _socket.close();
    _controller.dispose();

    super.dispose();
  }

  void registerListener() async {
    final request = Request(generate64RandomHexChars(), [
      Filter(
        kinds: [1000],
        authors: [nostrPublicKey],
      ),
    ]);

    _socket = await WebSocket.connect(
      widget.task.relays.first,
    );

    _socket.add(request.serialize());

    _socket.listen((rawEvent) async {
      final event = Message.deserialize(rawEvent);

      switch (event.type) {
        case "EVENT":
          final location = await LocationPointService.fromEncrypted(
            event.message.content,
            widget.task.pgpPrivateKey,
          );

          // We need to access `_locations` earlier than the UI updates.
          _locations.add(location);
          drawPoints();
          setState(() {});
          break;
        case "EOSE":
          _socket.close();

          setState(() {
            _isLoading = false;
          });
          break;
      }
    });
  }

  void drawPoints() {
    LocationPointService? previousLocation;
    _controller.removeAllCircle();
    _controller.clearAllRoads();

    for (final location in _locations) {
      _controller.drawCircle(
        CircleOSM(
          key: "circle_${location.latitude}:${location.longitude}",
          centerPoint: GeoPoint(
            latitude: location.latitude,
            longitude: location.longitude,
          ),
          radius: 200,
          color: Colors.blue,
          strokeWidth: location.accuracy < 10 ? 1 : 3,
        ),
      );

      /*
      if (previousLocation != null) {
        _controller.drawRoad(
          GeoPoint(
            latitude: previousLocation.latitude,
            longitude: previousLocation.longitude,
          ),
          GeoPoint(
            latitude: location.latitude,
            longitude: location.longitude,
          ),
          roadType: RoadType.car,
          roadOption: RoadOption(
            roadWidth: 10,
            roadColor: Colors.red,
            zoomInto: true,
          ),
        );
      }

      previousLocation = location;*/
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(widget.task.name),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          child: Column(
            children: <Widget>[
              Expanded(
                child: ListView.builder(
                  itemCount: _locations.length,
                  itemBuilder: (context, index) {
                    final location = _locations[index];

                    return Text(location.accuracy.toString());
                  },
                ),
              ),
              Expanded(
                child: OSMFlutter(
                  controller: _controller,
                  initZoom: 12,
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(height: MEDIUM_SPACE),
                PlatformCircularProgressIndicator(),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
