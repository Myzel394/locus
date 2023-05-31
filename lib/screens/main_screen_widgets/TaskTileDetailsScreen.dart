import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/MaybeMaterial.dart';

import '../../services/location_point_service.dart';
import '../../widgets/LocationsMap.dart';
import '../../widgets/Paper.dart';

class TaskTileDetailsScreen extends StatefulWidget {
  final Task task;

  const TaskTileDetailsScreen({
    required this.task,
    Key? key,
  }) : super(key: key);

  @override
  State<TaskTileDetailsScreen> createState() => _TaskTileDetailsScreenState();
}

class _TaskTileDetailsScreenState extends State<TaskTileDetailsScreen> {
  void Function()? _unsubscribeGetLocations;
  final LocationsMapController _controller = LocationsMapController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    addListener();
  }

  @override
  void dispose() {
    _unsubscribeGetLocations?.call();
    _controller.dispose();

    super.dispose();
  }

  addListener() async {
    _unsubscribeGetLocations = await widget.task.getLocations(
      onlyLatestPosition: true,
      onLocationFetched: (final LocationPointService location) {
        if (!mounted) {
          return;
        }

        _controller.add(location);
        setState(() {});
      },
      onEnd: () {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: <Widget>[
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Container(
              color: Colors.transparent,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: MEDIUM_SPACE),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 400,
                    maxHeight: 800,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: <Widget>[
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: Hero(
                              tag: "${widget.task.id}:paper",
                              child: Paper(
                                child: Container(),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(MEDIUM_SPACE),
                            child: Container(
                              child: Column(
                                children: <Widget>[
                                  Hero(
                                    tag: "${widget.task.id}:title",
                                    child: MaybeMaterial(
                                      color: Colors.transparent,
                                      child: Text(
                                        widget.task.name,
                                        textAlign: TextAlign.center,
                                        style: getTitle2TextStyle(context),
                                      ),
                                    ),
                                  ),
                                  Hero(
                                    tag: "${widget.task.id}:padding1",
                                    child: SizedBox(height: MEDIUM_SPACE),
                                  ),
                                  Hero(
                                    tag: "${widget.task.id}:switch",
                                    child: FutureBuilder<bool>(
                                      future: widget.task.isRunning(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return MaybeMaterial(
                                            color: Colors.transparent,
                                            child: PlatformSwitch(
                                              value: snapshot.data!,
                                              onChanged: (value) async {},
                                            ),
                                          );
                                        }

                                        return const SizedBox();
                                      },
                                    ),
                                  ),
                                  /*
                                  if (_isLoading)
                                    Center(
                                      child: PlatformCircularProgressIndicator(),
                                    )
                                  else
                                    SizedBox(
                                      width: double.infinity,
                                      height: 200,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(MEDIUM_SPACE),
                                        child: LocationsMap(
                                          controller: _controller,
                                        ),
                                      ),
                                    ),*/
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
