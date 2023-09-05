import 'package:flutter/cupertino.dart';

import '../widgets/LocationsMap.dart';
import 'task_service/mixins.dart';
import 'location_point_service.dart';

const INITIAL_LOAD_AMOUNT = 10;
const LOAD_MORE_AMOUNT = 100;

class LocationFetcher extends ChangeNotifier {
  final LocationBase location;
  final LocationsMapController controller;
  final Set<String> _locationIDS = {};

  final void Function(LocationPointService) onLocationFetched;
  final int? limit;
  final DateTime? from;

  VoidCallback? _getLocationsUnsubscribe;

  bool _hasLoaded = false;

  // There can be an edge case, where there are exactly as many locations
  // available as the limit.
  // Here we save the amount of locations fetched during a fetch.
  // If it is 0, we know that there are no more locations available.
  int _moreFetchAmount = 0;

  LocationFetcher({
    required this.location,
    required this.onLocationFetched,
    this.limit,
    this.from,
  })  : controller = LocationsMapController(),
        super();

  DateTime? get earliestDate =>
      controller.locations.isEmpty ? null : controller.locations.last.createdAt;

  bool get canFetchMore =>
      _hasLoaded &&
      _moreFetchAmount != 0 &&
      (controller.locations.length - INITIAL_LOAD_AMOUNT) % LOAD_MORE_AMOUNT ==
          0 &&
      // Make sure `earliestDate` is after `from`, if both are set
      (from == null || earliestDate == null || earliestDate!.isAfter(from!));

  bool get isLoading => !_hasLoaded;

  void fetchMore({
    required void Function() onEnd,
  }) {
    _hasLoaded = false;
    // If `from` is specified, we don't want to limit the amount of locations
    // by default
    final fetchMoreLimit = from == null
        ? controller.locations.isEmpty
            ? INITIAL_LOAD_AMOUNT
            : controller.locations.length + LOAD_MORE_AMOUNT
        : null;
    _moreFetchAmount = 0;

    _getLocationsUnsubscribe = location.getLocations(
      onEnd: () {
        _hasLoaded = true;
        controller.sort();

        notifyListeners();

        onEnd();
      },
      onLocationFetched: (final location) {
        if (_locationIDS.contains(location.id)) {
          return;
        }

        _moreFetchAmount++;

        controller.add(location);
        _locationIDS.add(location.id);
        onLocationFetched(location);
      },
      limit: limit ?? fetchMoreLimit,
      from: from,
    );

    notifyListeners();
  }

  @override
  void dispose() {
    controller.dispose();
    _getLocationsUnsubscribe?.call();

    super.dispose();
  }
}
