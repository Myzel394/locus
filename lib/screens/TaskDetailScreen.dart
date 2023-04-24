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
import 'package:locus/widgets/LocationsLoadingScreen.dart';

import '../api/get-locations.dart';

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
  void Function()? _unsubscribeGetLocations;
  bool _isLoading = true;
  bool _isShowingDetails = false;
  final List<LocationPointService> _locations = [];

  @override
  void initState() {
    super.initState();

    _controller = MapController(
      initMapWithUserPosition: true,
    );

    addListener();

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

    _unsubscribeGetLocations?.call();

    super.dispose();
  }

  void addListener() async {
    _unsubscribeGetLocations = await getLocations(
      viewPrivateKey: widget.task.viewPGPPrivateKey,
      signPublicKey: widget.task.signPGPPublicKey,
      nostrPublicKey: widget.task.nostrPublicKey,
      relays: widget.task.relays,
      onLocationFetched: (final LocationPointService location) {
        _locations.add(location);
        setState(() {});
      },
      onEnd: () {
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  void drawPoints() {
    _controller.removeAllCircle();

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final shades = getPrimaryColorShades(context);

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
                  child: LocationsLoadingScreen(
                    locations: _locations,
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
