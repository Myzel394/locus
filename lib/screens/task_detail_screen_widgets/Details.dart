import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/api/get-address.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/RelaySelectSheet.dart';
import 'package:provider/provider.dart';

class Details extends StatefulWidget {
  final UnmodifiableListView<LocationPointService> locations;
  final Task task;

  const Details({
    required this.locations,
    required this.task,
    Key? key,
  }) : super(key: key);

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  @override
  Widget build(BuildContext context) {
    final taskService = context.watch<TaskService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              "Last known location",
              textAlign: TextAlign.start,
              style: getSubTitleTextStyle(context),
            ),
            const SizedBox(height: MEDIUM_SPACE),
            Container(
              padding: const EdgeInsets.all(MEDIUM_SPACE),
              decoration: BoxDecoration(
                color: Theme.of(context).dialogBackgroundColor,
                borderRadius: BorderRadius.circular(
                  MEDIUM_SPACE,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FutureBuilder<String>(
                    future: getAddress(widget.locations.last.latitude,
                        widget.locations.last.longitude),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: snapshot.data!,
                                style: getBodyTextTextStyle(context),
                              ),
                              TextSpan(
                                text:
                                    " (${widget.locations.last.latitude}, ${widget.locations.last.longitude})",
                                style: getCaptionTextStyle(context),
                              ),
                            ],
                          ),
                        );
                      }

                      return Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              "${widget.locations.last.latitude}, ${widget.locations.last.longitude}",
                              style: getBodyTextTextStyle(context),
                              overflow: TextOverflow.clip,
                            ),
                          ),
                          const SizedBox(width: SMALL_SPACE),
                          SizedBox.square(
                            dimension: getIconSizeForBodyText(context),
                            child: PlatformCircularProgressIndicator(
                              material: (_, __) =>
                                  MaterialProgressIndicatorData(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: MEDIUM_SPACE),
                  Tooltip(
                    message: "Most recent location point",
                    textAlign: TextAlign.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          context.platformIcons.time,
                          size: getIconSizeForBodyText(context),
                        ),
                        const SizedBox(width: TINY_SPACE),
                        Text(
                          widget.locations.last.createdAt.toString(),
                          style: getBodyTextTextStyle(context),
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: LARGE_SPACE),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              "Location details",
              textAlign: TextAlign.start,
              style: getSubTitleTextStyle(context),
            ),
            const SizedBox(height: MEDIUM_SPACE),
            Container(
              padding: const EdgeInsets.all(MEDIUM_SPACE),
              decoration: BoxDecoration(
                color: Theme.of(context).dialogBackgroundColor,
                borderRadius: BorderRadius.circular(
                  MEDIUM_SPACE,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    "${widget.locations.length} location points saved",
                    style: getBodyTextTextStyle(context),
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: LARGE_SPACE),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              "Nostr Relays",
              textAlign: TextAlign.start,
              style: getSubTitleTextStyle(context),
            ),
            const SizedBox(height: MEDIUM_SPACE),
            Container(
              padding: const EdgeInsets.all(MEDIUM_SPACE),
              decoration: BoxDecoration(
                color: Theme.of(context).dialogBackgroundColor,
                borderRadius: BorderRadius.circular(
                  MEDIUM_SPACE,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                      for (final relay in widget.task.relays)
                        ListTile(
                          title: Text(
                            relay,
                          ),
                        ),
                    ] +
                    [
                      PlatformTextButton(
                        material: (_, __) => MaterialTextButtonData(
                          icon: Icon(context.platformIcons.edit),
                        ),
                        child: Text("Edit relays"),
                        onPressed: () async {
                          final newRelays = await showPlatformModalSheet(
                            context: context,
                            material: MaterialModalSheetData(
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              isDismissible: true,
                            ),
                            builder: (context) => RelaySelectSheet(
                              selectedRelays: widget.task.relays,
                            ),
                          );

                          if (newRelays != null) {
                            widget.task.update(relays: newRelays);

                            taskService.update(widget.task);
                          }
                        },
                      ),
                    ],
              ),
            ),
          ],
        ),
        const SizedBox(height: LARGE_SPACE),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              "Task status",
              textAlign: TextAlign.start,
              style: getSubTitleTextStyle(context),
            ),
            const SizedBox(height: MEDIUM_SPACE),
            Container(
              padding: const EdgeInsets.all(MEDIUM_SPACE),
              decoration: BoxDecoration(
                color: Theme.of(context).dialogBackgroundColor,
                borderRadius: BorderRadius.circular(
                  MEDIUM_SPACE,
                ),
              ),
              child: FutureBuilder<Map<String, dynamic>>(
                future: (() async {
                  final status = await widget.task.getStatus();

                  if (status == null) {
                    return {} as Map<String, dynamic>;
                  }

                  return status;
                })(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData) {
                      return Text(
                        "Task started at ${snapshot.data!["startedAt"]} with a frequency of ${snapshot.data!["runFrequency"]}.",
                      );
                    } else {
                      return Text("Task is not running.");
                    }
                  }

                  return Center(
                    child: PlatformCircularProgressIndicator(),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: LARGE_SPACE),
        PlatformTextButton(
          child: Text("Delete task"),
          material: (_, __) => MaterialTextButtonData(
            icon: Icon(context.platformIcons.delete),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).errorColor,
            ),
          ),
          cupertino: (_, __) => CupertinoTextButtonData(
            color: Theme.of(context).errorColor,
          ),
          onPressed: () async {
            final confirmed = await showPlatformDialog(
              context: context,
              builder: (context) => PlatformAlertDialog(
                title: Text("Delete task"),
                content: Text(
                  "Are you sure you want to delete this task? This means that no more locations will be saved for this task. Existing locations will not be deleted. This action cannot be undone.",
                ),
                actions: <Widget>[
                  PlatformDialogAction(
                    child: Text("Cancel"),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  PlatformDialogAction(
                    child: Text("Delete"),
                    onPressed: () => Navigator.of(context).pop(true),
                    material: (_, __) => MaterialDialogActionData(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).errorColor,
                      ),
                    ),
                    cupertino: (_, __) => CupertinoDialogActionData(
                      isDestructiveAction: true,
                    ),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              await widget.task.stop();
              taskService.remove(widget.task);
              await taskService.save();

              Navigator.of(context).pop();
            }
          },
        )
      ],
    );
  }
}
