import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:locus/services/location_fetcher_service/Fetcher.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/view_service.dart';

class LocationFetchers extends ChangeNotifier {
  final Set<Fetcher> _fetchers = {};

  UnmodifiableSetView<Fetcher> get fetchers => UnmodifiableSetView(_fetchers);

  LocationFetchers();

  void enableLocationsUpdates() {
    for (final fetcher in _fetchers) {
      fetcher.addListener(notifyListeners);
    }
  }

  void add(final TaskView view) {
    if (_fetchers.any((fetcher) => fetcher.view == view)) {
      return;
    }

    _fetchers.add(Fetcher(view));
  }

  void addAll(final List<TaskView> views) {
    for (final view in views) {
      add(view);
    }
  }

  void fetchPreviewLocations() {
    for (final fetcher in _fetchers) {
      if (!fetcher.hasFetchedPreviewLocations) {
        fetcher.fetchPreviewLocations();
      }
    }
  }

  Fetcher? _findFetcher(final TaskView view) {
    return _fetchers.firstWhereOrNull((fetcher) => fetcher.view == view);
  }

  List<LocationPointService> getLocations(final TaskView view) {
    return _findFetcher(view)?.locations ?? [];
  }
}
