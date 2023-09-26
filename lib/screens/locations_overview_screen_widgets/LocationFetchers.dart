import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/services/location_fetcher_service/Fetcher.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/view_service/index.dart';

class LocationFetchers extends ChangeNotifier {
  final Set<Fetcher> _fetchers = {};

  UnmodifiableSetView<Fetcher> get fetchers => UnmodifiableSetView(_fetchers);

  LocationFetchers(final List<TaskView> views,) {
    addAll(views);
  }

  void addLocationUpdatesListener(final VoidCallback callback,) {
    for (final fetcher in _fetchers) {
      fetcher.addListener(callback);
    }
  }

  void removeLocationUpdatesListener(final VoidCallback callback,) {
    for (final fetcher in _fetchers) {
      fetcher.removeListener(callback);
    }
  }

  void add(final TaskView view) {
    if (_fetchers.any((fetcher) => fetcher.view == view)) {
      return;
    }

    _fetchers.add(Fetcher(view));
  }

  void remove(final TaskView view) {
    final fetcher = findFetcher(view);

    if (fetcher != null) {
      fetcher.dispose();
      _fetchers.remove(fetcher);
    }
  }

  void addAll(final List<TaskView> views) {
    for (final view in views) {
      add(view);
    }
  }

  void fetchPreviewLocations() {
    FlutterLogs.logInfo(
      LOG_TAG,
      "Location Fetchers",
      "Fetching preview locations for ${_fetchers.length} tasks...",
    );

    for (final fetcher in _fetchers) {
      if (!fetcher.hasFetchedPreviewLocations) {
        fetcher.fetchPreviewLocations();
      }
    }
  }

  Fetcher? findFetcher(final TaskView view) {
    return _fetchers.firstWhereOrNull((fetcher) => fetcher.view == view);
  }

  List<LocationPointService> getLocations(final TaskView view) {
    return findFetcher(view)?.sortedLocations ?? [];
  }
}
