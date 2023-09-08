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

  List<LocationPointService> get locations => _locations.locations;

  bool get isLoading => _isLoading;

  bool get hasFetchedPreviewLocations => _hasFetchedPreviewLocations;

  Fetcher(this.view);

  void _getLocations({
    final DateTime? from,
    final int? limit,
    final VoidCallback? onEmptyEnd,
    final VoidCallback? onEnd,
    final void Function(LocationPointService)? onLocationFetched,
  }) {
    _isLoading = true;

    notifyListeners();

    final unsubscriber = view.getLocations(
      limit: limit,
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
        _hasFetchedPreviewLocations = true;
      },
      onEmptyEnd: () {
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
