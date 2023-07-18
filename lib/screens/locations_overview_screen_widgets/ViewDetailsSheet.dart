import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/screens/locations_overview_screen_widgets/ViewDetails.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/widgets/ModalSheet.dart';

import '../../constants/spacing.dart';
import '../../widgets/SimpleAddressFetcher.dart';

class ViewDetailsSheet extends StatefulWidget {
  final TaskView? view;
  final List<LocationPointService>? locations;
  final void Function(LatLng position) onGoToPosition;

  const ViewDetailsSheet({
    required this.view,
    required this.locations,
    required this.onGoToPosition,
    super.key,
  });

  @override
  State<ViewDetailsSheet> createState() => _ViewDetailsSheetState();
}

class _ViewDetailsSheetState extends State<ViewDetailsSheet> {
  final containerKey = GlobalKey();

  final DraggableScrollableController controller =
      DraggableScrollableController();

  // Index starting from last element
  int locationIndex = 0;

  LocationPointService? get currentLocation => widget.locations == null
      ? null
      : widget.locations![widget.locations!.length - 1 - locationIndex];

  @override
  void initState() {
    super.initState();

    controller.addListener(() {
      // I don't know why, but this is required
      print(controller.size);
      // User should not be able to close the sheet when a view is selected.
      // Dynamically changing the snap sizes doesn't seem to work.
      // Instead we will simply reopen the sheet if the user tries to close it.
      if (controller.size == 0.0 && widget.view != null) {
        controller.animateTo(
          0.22,
          duration: const Duration(milliseconds: 750),
          curve: Curves.bounceOut,
        );
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ViewDetailsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.view != widget.view) {
      if (widget.view == null) {
        controller.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeIn,
        );
      } else {
        controller.animateTo(
          0.22,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeIn,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: controller,
      minChildSize: 0.0,
      initialChildSize: 0.0,
      snapAnimationDuration: const Duration(milliseconds: 100),
      snap: true,
      snapSizes: const [
        0.0,
        0.15,
        0.22,
        1,
      ],
      builder: (context, scrollController) => ModalSheet(
        miuiIsGapless: true,
        materialPadding: EdgeInsets.zero,
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            children: [
              if (widget.locations != null) ...[
                const SizedBox(height: LARGE_SPACE),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.circle_rounded,
                      size: 20,
                      color: widget.view!.color,
                    ),
                    const SizedBox(width: SMALL_SPACE),
                    Text(widget.view!.name),
                  ],
                ),
                const SizedBox(height: LARGE_SPACE),
                SizedBox(
                  height: 120,
                  child: PageView.builder(
                    onPageChanged: (index) {
                      setState(() {
                        locationIndex = index;
                      });
                    },
                    reverse: true,
                    itemCount: widget.locations!.length,
                    itemBuilder: (context, index) => Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(MEDIUM_SPACE),
                        color: platformThemeData(
                          context,
                          material: (data) => data.colorScheme.surfaceVariant,
                          cupertino: (data) => data.scaffoldBackgroundColor,
                        ),
                      ),
                      margin:
                          const EdgeInsets.symmetric(horizontal: MEDIUM_SPACE),
                      padding: const EdgeInsets.all(MEDIUM_SPACE),
                      child: Center(
                        child: SimpleAddressFetcher(
                          location: widget.locations![index].asLatLng(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: MEDIUM_SPACE),
                Padding(
                  padding: const EdgeInsets.all(MEDIUM_SPACE),
                  child: ViewDetails(
                    location: currentLocation,
                    view: widget.view,
                    onGoToPosition: (position) {
                      controller.animateTo(
                        0.22,
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.fastLinearToSlowEaseIn,
                      );
                      widget.onGoToPosition(position);
                    },
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
