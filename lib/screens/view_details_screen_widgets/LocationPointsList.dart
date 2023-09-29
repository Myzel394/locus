import 'package:flutter/material.dart';
import 'package:locus/screens/locations_overview_screen_widgets/LocationFetchers.dart';
import 'package:locus/screens/task_detail_screen_widgets/LocationDetails.dart';
import 'package:locus/services/view_service/index.dart';
import 'package:provider/provider.dart';

class LocationPointsList extends StatefulWidget {
  final TaskView view;

  const LocationPointsList({
    super.key,
    required this.view,
  });

  @override
  State<LocationPointsList> createState() => _LocationPointsListState();
}

class _LocationPointsListState extends State<LocationPointsList> {
  final ScrollController controller = ScrollController();
  late final LocationFetchers locationFetchers;

  @override
  void initState() {
    super.initState();

    locationFetchers = context.read<LocationFetchers>();
    final fetcher = locationFetchers.findFetcher(widget.view)!;

    fetcher.addListener(_rebuild);
    controller.addListener(() {
      if (fetcher.hasFetchedAllLocations) {
        return;
      }

      if (controller.position.atEdge) {
        final isTop = controller.position.pixels == 0;

        if (!isTop) {
          fetcher.fetchMoreLocations();
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!fetcher.hasFetchedAllLocations) {
        fetcher.fetchMoreLocations();
      }
    });
  }

  @override
  void dispose() {
    final fetcher = locationFetchers.findFetcher(widget.view)!;

    fetcher.removeListener(_rebuild);

    super.dispose();
  }

  void _rebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final locationFetchers = context.watch<LocationFetchers>();
    final fetcher = locationFetchers.findFetcher(widget.view)!;
    final locations = fetcher.isLoading
        ? fetcher.sortedLocations
        : fetcher.locations.toList();

    return ListView.builder(
      shrinkWrap: true,
      controller: controller,
      itemCount: locations.length + (fetcher.isLoading ? 1 : 0),
      itemBuilder: (_, index) {
        if (index == locations.length) {
          return const Center(
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(),
            ),
          );
        }

        return LocationDetails(
          location: locations[index],
          isPreview: false,
        );
      },
    );
  }
}
