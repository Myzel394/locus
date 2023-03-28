import 'dart:collection';
import 'dart:io';

import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/task_detail_screen_widgets/Details.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/utils/theme.dart';
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
  final PageController _pageController = PageController();
  bool _isLoading = true;
  bool _isShowingDetails = false;
  final List<LocationPointService> _locations = [];

  @override
  void initState() {
    super.initState();

    if (![TaskType.self, TaskType.share].contains(widget.task.type)) {
      Navigator.of(context).pop();
      return;
    }

    _controller = MapController(
      initMapWithUserPosition: true,
    );

    registerListener();

    _pageController.addListener(() {
      if (_pageController.page == 0) {
        setState(() {
          _isShowingDetails = false;
        });
      } else {
        setState(() {
          _isShowingDetails = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _socket.close();
    _controller.dispose();
    _pageController.dispose();

    super.dispose();
  }

  void registerListener() async {
    final request = Request(generate64RandomHexChars(), [
      Filter(
        kinds: [1000],
        authors: [widget.task.nostrPublicKey],
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
            widget.task.viewPGPPrivateKey!,
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
        title: Text(
          _isShowingDetails ? "Details" : widget.task.name,
        ),
        material: (_, __) => MaterialAppBarData(
          centerTitle: true,
        ),
      ),
      body: Builder(
        builder: (context) => Center(
          child: _isLoading
              ? Padding(
                  padding: const EdgeInsets.all(MEDIUM_SPACE),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Text(
                              "Loading locations: ${_locations.length}",
                              style: getTitleTextStyle(context),
                            ),
                            const SizedBox(height: MEDIUM_SPACE),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _locations.length,
                                itemBuilder: (context, index) {
                                  final location = _locations[index];

                                  return Text(
                                    "${location.latitude}, ${location.longitude}",
                                    style: getBodyTextTextStyle(context),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      PlatformCircularProgressIndicator()
                    ],
                  ),
                )
              : PageView(
                  physics:
                      _isShowingDetails ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  controller: _pageController,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(
                          flex: 9,
                          child: OSMFlutter(
                            controller: _controller,
                            initZoom: 15,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: PlatformTextButton(
                            material: (_, __) => MaterialTextButtonData(
                              style: ButtonStyle(
                                // Not rounded, but square
                                shape: MaterialStateProperty.all(
                                  const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ),
                              ),
                            ),
                            child: Text("View Details"),
                            onPressed: () {
                              _pageController.animateToPage(
                                1,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Details(
                            locations: UnmodifiableListView<LocationPointService>(_locations),
                            task: widget.task,
                            onGoBack: () {
                              _pageController.animateToPage(
                                0,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            }),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
