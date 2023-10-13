import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';

import "./constants.dart";
import '../location_point_service.dart';

class LocationHistory extends ChangeNotifier {
  late final List<Position> locations;

  LocationHistory(final List<Position>? locations,)
      : locations = locations ?? [];

  // Locations used for the user preview. Only shows the locations in the last
  // hour
  List<Position> get previewLocations {
    final minDate = DateTime.now().subtract(const Duration(hours: 1));

    return locations
        .where((location) =>
    location.timestamp != null && location.timestamp!.isAfter(minDate))
        .sorted((a, b) => a.timestamp!.compareTo(b.timestamp!))
        .toList();
  }

  factory LocationHistory.fromJSON(final Map<String, dynamic> data) =>
      LocationHistory(
        data["locations"] != null
            ? List<Position>.from(
          data["locations"].map(
                (location) =>
                Position.fromMap(location as Map<String, dynamic>),
          ),
        )
            : null,
      );

  static Future<LocationHistory> restore() async {
    final data = await storage.read(key: KEY);

    if (data == null) {
      return LocationHistory(null);
    }

    return LocationHistory.fromJSON(jsonDecode(data) as Map<String, dynamic>);
  }

  // To avoid too many crumbled locations, we only save locations that are at
  // least one minute apart
  bool _canAdd(final Position position) {
    return position.timestamp != null;
  }

  void add(final Position position) {
    final lastLocation = locations.lastOrNull;

    if (lastLocation != null &&
        lastLocation.timestamp!.difference(position.timestamp!).abs() <=
            const Duration(minutes: 1)) {
      // Replace oldest one with new one
      locations.removeLast();
    }

    locations.add(position);

    final strippedLocations = locations.take(60).toList();

    locations.clear();
    locations.addAll(strippedLocations);

    notifyListeners();
  }

  void clear() {
    locations.clear();
    notifyListeners();
  }

  Map<String, dynamic> toJSON() =>
      {
        "locations": locations.map((location) => location.toJson()).toList(),
      };

  Future<void> save() async {
    await storage.write(
      key: KEY,
      value: jsonEncode(toJSON()),
    );
  }
}
