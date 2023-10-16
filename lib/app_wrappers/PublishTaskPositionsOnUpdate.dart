import 'dart:async';

import 'package:flutter/material.dart';
import 'package:locus/services/current_location_service.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/task_service/index.dart';
import 'package:provider/provider.dart';

class PublishTaskPositionsOnUpdate extends StatefulWidget {
  const PublishTaskPositionsOnUpdate({super.key});

  @override
  State<PublishTaskPositionsOnUpdate> createState() =>
      _PublishTaskPositionsOnUpdateState();
}

class _PublishTaskPositionsOnUpdateState
    extends State<PublishTaskPositionsOnUpdate> {
  late final CurrentLocationService _currentLocation;
  late final StreamSubscription _stream;

  @override
  void initState() {
    super.initState();

    _currentLocation = context.read<CurrentLocationService>();

    _stream = _currentLocation.stream.listen((position) async {
      final taskService = context.read<TaskService>();

      final runningTasks = await taskService.getRunningTasks().toList();

      if (runningTasks.isEmpty) {
        return;
      }

      final locationData = await LocationPointService.fromPosition(position);

      for (final task in runningTasks) {
        await task.publisher.publishOutstandingPositions();
        await task.publisher.publishLocation(
          locationData.copyWithDifferentId(),
        );
      }
    });
  }

  @override
  void dispose() {
    _stream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
