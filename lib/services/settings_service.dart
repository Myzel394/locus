import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/get-address.dart';
import '../utils/device.dart';
import '../utils/platform.dart';

const STORAGE_KEY = "_app_settings";

const storage = FlutterSecureStorage();

enum MapProvider {
  openStreetMap,
  apple,
}

enum GeocoderProvider {
  system,
  geocodeMapsCo,
  nominatim,
}

// Selects a random provider from the list of available providers, not including
// the system provider.
GeocoderProvider selectRandomProvider() {
  final providers = GeocoderProvider.values
      .where((element) => element != GeocoderProvider.system)
      .toList();

  return providers[Random().nextInt(providers.length)];
}

class SettingsService extends ChangeNotifier {
  bool automaticallyLookupAddresses;
  bool showHints;
  List<String> _relays;

  GeocoderProvider geocoderProvider;

  // null = system default
  // transparent = MIUI Blue
  Color? primaryColor;

  // Apple
  MapProvider mapProvider;

  SettingsService({
    required this.automaticallyLookupAddresses,
    required this.primaryColor,
    required this.mapProvider,
    required this.showHints,
    required this.geocoderProvider,
    List<String>? relays,
  }) : _relays = relays ?? [];

  static SettingsService createDefault() {
    return SettingsService(
      automaticallyLookupAddresses: true,
      primaryColor: isMIUI() ? Colors.transparent : null,
      mapProvider:
          isPlatformApple() ? MapProvider.apple : MapProvider.openStreetMap,
      showHints: true,
      geocoderProvider: isSystemGeocoderAvailable()
          ? GeocoderProvider.system
          : selectRandomProvider(),
    );
  }

  static bool isSystemGeocoderAvailable() => false;

  static SettingsService fromJSON(final Map<String, dynamic> data) {
    return SettingsService(
      automaticallyLookupAddresses: data['automaticallyLoadLocation'],
      primaryColor:
          data['primaryColor'] != null ? Color(data['primaryColor']) : null,
      mapProvider: MapProvider.values[data['mapProvider']],
      relays: List<String>.from(data['relays'] ?? []),
      showHints: data['showHints'],
      geocoderProvider: GeocoderProvider.values[data['geocoderProvider']],
    );
  }

  // Restores either from storage or creates a new default instance
  static Future<SettingsService> restore() async {
    final rawData = await storage.read(key: STORAGE_KEY);

    if (rawData == null || rawData.isEmpty) {
      return createDefault();
    }

    final defaultValues = createDefault().toJSON();
    final data = Map<String, dynamic>.from(jsonDecode(rawData));
    // Merge data with default values, replace null values with default values
    final mergedData = HashMap<String, dynamic>.from(defaultValues)
      ..addAll(data..removeWhere((key, value) => value == null));

    final settings = fromJSON(mergedData);

    return settings;
  }

  Map<String, dynamic> toJSON() {
    return {
      'automaticallyLoadLocation': automaticallyLookupAddresses,
      'primaryColor': primaryColor?.value,
      'mapProvider': mapProvider.index,
      "relays": _relays,
      "showHints": showHints,
      "geocoderProvider": geocoderProvider.index,
    };
  }

  Future<String> getAddress(
    final double latitude,
    final double longitude,
  ) async {
    final providers = [
      getGeocoderProvider(),
      ...GeocoderProvider.values
          .where((element) => element != getGeocoderProvider())
    ];
    // If the user does not want to use the system provider,
    // we will not use it, even if it is the only one
    // available (for better privacy)
    if (!isSystemGeocoderAvailable() ||
        getGeocoderProvider() != GeocoderProvider.system) {
      providers.remove(GeocoderProvider.system);
    }

    for (final provider in providers) {
      try {
        switch (provider) {
          case GeocoderProvider.system:
            return await getAddressSystem(latitude, longitude);
          case GeocoderProvider.geocodeMapsCo:
            return await getAddressGeocodeMapsCo(latitude, longitude);
          case GeocoderProvider.nominatim:
            return await getAddressNominatim(latitude, longitude);
        }
      } catch (e) {
        print("Failed to get address from $provider: $e");
      }
    }

    throw Exception("Failed to get address from any provider");
  }

  Future<void> save() => storage.write(
        key: STORAGE_KEY,
        value: jsonEncode(toJSON()),
      );

  bool getAutomaticallyLookupAddresses() {
    return automaticallyLookupAddresses;
  }

  void setAutomaticallyLookupAddresses(final bool value) {
    automaticallyLookupAddresses = value;
    notifyListeners();
  }

  Color getPrimaryColor(final BuildContext context) {
    if (primaryColor != null) {
      return primaryColor!;
    }

    // Return system default
    if (isCupertino(context)) {
      return CupertinoTheme.of(context).primaryColor;
    } else {
      return Theme.of(context).primaryColor;
    }
  }

  void setPrimaryColor(final Color? value) {
    primaryColor = value;
    notifyListeners();
  }

  MapProvider getMapProvider() {
    return mapProvider;
  }

  void setMapProvider(final MapProvider value) {
    if (value == MapProvider.apple && !isPlatformApple()) {
      throw Exception("Apple Maps are not supported on this platform");
    }

    mapProvider = value;
    notifyListeners();
  }

  UnmodifiableListView<String> getRelays() {
    return UnmodifiableListView(_relays);
  }

  void setRelays(final List<String> value) {
    _relays = value;
    notifyListeners();
  }

  bool getShowHints() => showHints;

  void setShowHints(final bool value) {
    showHints = value;
    notifyListeners();
  }

  GeocoderProvider getGeocoderProvider() => geocoderProvider;

  void setGeocoderProvider(final GeocoderProvider value) {
    geocoderProvider = value;

    notifyListeners();
  }
}
