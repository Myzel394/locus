import 'package:flutter/foundation.dart';

import '../../services/location_point_service.dart';
import '../../services/view_service.dart';

class ViewLocationFetcher extends ChangeNotifier {
  final Iterable<TaskView> views;
  final Map<TaskView, List<LocationPointService>> _locations = {};
  final List<VoidCallback> _getLocationsUnsubscribers = [];

  bool _mounted = true;

  Map<TaskView, List<LocationPointService>> get locations => _locations;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  ViewLocationFetcher(this.views);

  bool get hasMultipleLocationViews => _locations.keys.length > 1;

  // If _fetchLast24Hours fails (no location fetched), we want to get the last location
  void _fetchLastLocation(final TaskView view) {
    _getLocationsUnsubscribers.add(
      view.getLocations(
        limit: 1,
        onLocationFetched: (location) {
          if (!_mounted) {
            return;
          }

          _locations[view] = [
            ...(locations[view] ?? []),
            location,
          ];
        },
        onEnd: () {
          if (!_mounted) {
            return;
          }

          _locations[view] = _locations[view]!
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

          _setIsLoading(_locations.keys.length == views.length);
        },
      ),
    );
  }

  void _fetchView(
    final TaskView view, {
    final DateTime? from,
    final int? limit,
  }) {
    assert(!_locations.containsKey(view));

    _getLocationsUnsubscribers.add(
      view.getLocations(
        from: from,
        limit: limit,
        onLocationFetched: (location) {
          if (!_mounted) {
            return;
          }

          _locations[view] = List<LocationPointService>.from(
            [..._locations[view] ?? [], location],
          );
        },
        onEnd: () {
          if (!_mounted) {
            return;
          }

          _locations[view] = _locations[view]!
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

          _setIsLoading(_locations.keys.length == views.length);
        },
        onEmptyEnd: () {
          _fetchLastLocation(view);
        },
      ),
    );
  }

  void _fetchLast24Hours() {
    for (final view in views) {
      _fetchView(
        view,
        from: DateTime.now().subtract(const Duration(hours: 24)),
      );
    }
  }

  void fetchLocations() {
    _setIsLoading(true);

    _fetchLast24Hours();
  }

  void _setIsLoading(final bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  void addView(final TaskView view) {
    _setIsLoading(true);

    _fetchView(
      view,
      from: DateTime.now().subtract(const Duration(hours: 24)),
    );
  }

  @override
  void dispose() {
    for (final unsubscribe in _getLocationsUnsubscribers) {
      unsubscribe();
    }

    _mounted = false;
    super.dispose();
  }
}
