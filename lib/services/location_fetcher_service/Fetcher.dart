import 'package:flutter/foundation.dart';
import 'package:locus/services/location_fetcher_service/Locations.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/view_service.dart';

class Fetcher extends ChangeNotifier {
  final TaskView view;
  final Locations _locations = Locations();

  final List<VoidCallback> _getLocationsUnsubscribers = [];

  bool _isMounted = true;
  bool _isLoading = false;
  bool _hasFetchedPreviewLocations = false;
  bool _hasFetchedAllLocations = false;

  List<LocationPointService> get locations => _locations.locations;

  bool get isLoading => _isLoading;

  bool get hasFetchedPreviewLocations => _hasFetchedPreviewLocations;

  bool get hasFetchedAllLocations => _hasFetchedAllLocations;

  Fetcher(this.view);

  void _getLocations({
    final DateTime? from,
    final DateTime? until,
    final int? limit,
    final VoidCallback? onEmptyEnd,
    final VoidCallback? onEnd,
    final void Function(LocationPointService)? onLocationFetched,
  }) {
    _isLoading = true;

    notifyListeners();

    final unsubscriber = view.getLocations(
      limit: limit,
      until: until,
      from: from,
      onLocationFetched: (location) {
        if (!_isMounted) {
          return;
        }

        _locations.add(location);
        onLocationFetched?.call(location);
        notifyListeners();
      },
      onEnd: () {
        if (!_isMounted) {
          return;
        }

        _isLoading = false;
        onEnd?.call();
        notifyListeners();
      },
      onEmptyEnd: () {
        if (!_isMounted) {
          return;
        }

        _isLoading = false;
        onEmptyEnd?.call();
        notifyListeners();
      },
    );

    _getLocationsUnsubscribers.add(unsubscriber);
  }

  void fetchPreviewLocations() {
    _getLocations(
      from: DateTime.now().subtract(const Duration(hours: 24)),
      onEnd: () {
        if (!_isMounted) {
          return;
        }

        _hasFetchedPreviewLocations = true;
      },
      onEmptyEnd: () {
        if (!_isMounted) {
          return;
        }

        _getLocations(
          limit: 1,
          onEnd: () {
            _hasFetchedPreviewLocations = true;
          },
          onEmptyEnd: () {
            _hasFetchedPreviewLocations = true;
          },
        );
      },
    );
  }

  void fetchMoreLocations([
    int limit = 100,
  ]) {
    final earliestLocation = _locations.locations.first;

    _getLocations(
      limit: limit,
      until: earliestLocation.createdAt,
      onEmptyEnd: () {
        if (!_isMounted) {
          return;
        }

        _hasFetchedAllLocations = true;
      },
    );
  }

  void fetchAllLocations() {
    _getLocations();
  }

  @override
  void dispose() {
    _isMounted = false;

    for (final unsubscriber in _getLocationsUnsubscribers) {
      unsubscriber();
    }

    super.dispose();
  }
}
