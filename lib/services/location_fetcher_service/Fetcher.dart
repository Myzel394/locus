import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:locus/services/location_fetcher_service/Locations.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/view_service/index.dart';
import 'package:locus/utils/nostr_fetcher/NostrSocket.dart';
import 'package:nostr/nostr.dart';

class Fetcher extends ChangeNotifier {
  final TaskView view;
  final Locations _locations = Locations();

  final List<NostrSocket> _sockets = [];

  bool _isMounted = true;
  bool _isLoading = false;
  bool _hasFetchedPreviewLocations = false;
  bool _hasFetchedAllLocations = false;

  UnmodifiableSetView<LocationPointService> get locations =>
      _locations.locations;

  List<LocationPointService> get sortedLocations => _locations.sortedLocations;

  bool get isLoading => _isLoading;

  bool get hasFetchedPreviewLocations => _hasFetchedPreviewLocations;

  bool get hasFetchedAllLocations => _hasFetchedAllLocations;

  Fetcher(this.view);

  Future<void> _getLocations(
    final Request request,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      for (final relay in view.relays) {
        try {
          final socket = NostrSocket(
            relay: relay,
            decryptMessage: view.decryptFromNostrMessage,
          );
          socket.stream.listen((location) {
            _locations.add(location);
          });
          await socket.connect();
          socket.addData(request.serialize());

          _sockets.add(socket);
        } on SocketException catch (error) {
          continue;
        }
      }

      await Future.wait(_sockets.map((socket) => socket.onComplete));
    } catch (error) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPreviewLocations() async {
    await _getLocations(
      NostrSocket.createNostrRequestDataFromTask(
        view,
        from: DateTime.now().subtract(const Duration(hours: 24)),
      ),
    );

    _hasFetchedPreviewLocations = true;
  }

  Future<void> fetchMoreLocations([
    int limit = 50,
  ]) async {
    final previousAmount = _locations.locations.length;
    final earliestLocation = _locations.sortedLocations.first;

    await _getLocations(
      NostrSocket.createNostrRequestDataFromTask(
        view,
        limit: limit,
        until: earliestLocation.createdAt,
      ),
    );

    final afterAmount = _locations.locations.length;

    // If amount is same, this means that no more locations are available.
    if (afterAmount == previousAmount) {
      _hasFetchedAllLocations = true;
    }
  }

  Future<void> fetchAllLocations() async {
    await _getLocations(
      NostrSocket.createNostrRequestDataFromTask(
        view,
      ),
    );

    _hasFetchedAllLocations = true;
  }

  @override
  void dispose() {
    _isMounted = false;

    for (final socket in _sockets) {
      socket.closeConnection();
    }

    super.dispose();
  }
}
