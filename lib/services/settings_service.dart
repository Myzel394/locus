import 'dart:collection';
import 'dart:convert';

import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/platform.dart';

const STORAGE_KEY = "_app_settings";

const storage = FlutterSecureStorage();

enum MapProvider {
  openStreetMap,
  apple,
}

class SettingsService extends ChangeNotifier {
  bool automaticallyLookupAddresses;
  bool showHints;
  List<String> _relays;

  // null = system default
  Color? primaryColor;

  // Apple
  MapProvider mapProvider;

  SettingsService({
    required this.automaticallyLookupAddresses,
    required this.primaryColor,
    required this.mapProvider,
    required this.showHints,
    List<String>? relays,
  }) : _relays = relays ?? [];

  static SettingsService createDefault() {
    return SettingsService(
      automaticallyLookupAddresses: true,
      primaryColor: null,
      mapProvider:
          isPlatformApple() ? MapProvider.apple : MapProvider.openStreetMap,
      showHints: true,
    );
  }

  static SettingsService fromJSON(final Map<String, dynamic> data) {
    return SettingsService(
      automaticallyLookupAddresses: data['automaticallyLoadLocation'],
      primaryColor:
          data['primaryColor'] != null ? Color(data['primaryColor']) : null,
      mapProvider: MapProvider.values[data['mapProvider']],
      relays: List<String>.from(data['relays'] ?? []),
      showHints: data['showHints'],
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
    final mergedData = HashMap<String, dynamic>.from(defaultValues)
      ..addAll(data);

    return fromJSON(mergedData);
  }

  Map<String, dynamic> toJSON() {
    return {
      'automaticallyLoadLocation': automaticallyLookupAddresses,
      'primaryColor': primaryColor?.value,
      'mapProvider': mapProvider.index,
      "relays": _relays,
      "showHints": showHints,
    };
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
}
