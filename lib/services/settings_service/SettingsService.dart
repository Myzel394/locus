import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:locus/api/get-address.dart';
import 'package:locus/api/nostr-relays.dart';
import 'package:locus/constants/app.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/utils/cache.dart';
import 'package:locus/utils/device/index.dart';
import 'package:locus/utils/nostr/select-random-relays.dart';
import 'package:locus/utils/platform.dart';

import 'SettingsMapLocation.dart';
import 'enums.dart';
import 'utils.dart';

const STORAGE_KEY = "_app_settings";

const storage = FlutterSecureStorage();

class SettingsService extends ChangeNotifier {
  String localeName;
  bool automaticallyLookupAddresses;
  bool showHints;
  bool userHasSeenWelcomeScreen = false;
  bool requireBiometricAuthenticationOnStart = false;
  bool alwaysUseBatterySaveMode = false;
  bool useRealtimeUpdates = false;
  String serverOrigin;
  List<String> _relays;
  AndroidTheme androidTheme;
  SettingsLastMapLocation? lastMapLocation;
  String currentAppVersion;

  GeocoderProvider geocoderProvider;

  // null = system default
  Color? primaryColor;

  // Apple
  MapProvider mapProvider;

  final Set<String> _seenHelperSheets;

  DateTime? lastHeadlessRun;

  SettingsService({
    required this.automaticallyLookupAddresses,
    required this.primaryColor,
    required this.mapProvider,
    required this.showHints,
    required this.geocoderProvider,
    required this.androidTheme,
    required this.localeName,
    required this.userHasSeenWelcomeScreen,
    required this.requireBiometricAuthenticationOnStart,
    required this.alwaysUseBatterySaveMode,
    required this.serverOrigin,
    required this.currentAppVersion,
    required this.useRealtimeUpdates,
    this.lastHeadlessRun,
    this.lastMapLocation,
    Set<String>? seenHelperSheets,
    List<String>? relays,
  })  : _relays = relays ?? [],
        _seenHelperSheets = seenHelperSheets ?? {};

  static Future<SettingsService> createDefault() async {
    return SettingsService(
      automaticallyLookupAddresses: true,
      primaryColor: null,
      androidTheme:
          await fetchIsMIUI() ? AndroidTheme.miui : AndroidTheme.materialYou,
      mapProvider:
          isPlatformApple() ? MapProvider.apple : MapProvider.openStreetMap,
      showHints: true,
      geocoderProvider: isSystemGeocoderAvailable()
          ? GeocoderProvider.system
          : selectRandomProvider(),
      localeName: "en",
      userHasSeenWelcomeScreen: false,
      seenHelperSheets: {},
      requireBiometricAuthenticationOnStart: false,
      alwaysUseBatterySaveMode: false,
      lastHeadlessRun: null,
      serverOrigin: "https://locus.cfd",
      lastMapLocation: null,
      currentAppVersion: CURRENT_APP_VERSION,
      useRealtimeUpdates: true,
    );
  }

  static bool isSystemGeocoderAvailable() =>
      isPlatformApple() || (Platform.isAndroid && isGMSFlavor);

  static SettingsService fromJSON(final Map<String, dynamic> data) {
    return SettingsService(
      automaticallyLookupAddresses: data['automaticallyLoadLocation'],
      primaryColor:
          data['primaryColor'] != null ? Color(data['primaryColor']) : null,
      mapProvider: MapProvider.values[data['mapProvider']],
      relays: List<String>.from(data['relays'] ?? []),
      showHints: data['showHints'],
      geocoderProvider: GeocoderProvider.values[data['geocoderProvider']],
      androidTheme: AndroidTheme.values[data['androidTheme']],
      localeName: data['localeName'],
      userHasSeenWelcomeScreen: data['userHasSeenWelcomeScreen'],
      seenHelperSheets: Set<String>.from(data['seenHelperSheets'] ?? {}),
      requireBiometricAuthenticationOnStart:
          data['requireBiometricAuthenticationOnStart'],
      alwaysUseBatterySaveMode: data['alwaysUseBatterySaveMode'],
      lastHeadlessRun: data['lastHeadlessRun'] != null
          ? DateTime.parse(data['lastHeadlessRun'])
          : null,
      serverOrigin: data['serverOrigin'],
      lastMapLocation: data['lastMapLocation'] != null
          ? SettingsLastMapLocation.fromJSON(data['lastMapLocation'])
          : null,
      currentAppVersion: data['currentAppVersion'],
      useRealtimeUpdates: data['useRealtimeUpdates'],
    );
  }

  // Restores either from storage or creates a new default instance
  static Future<SettingsService> restore() async {
    final rawData = await storage.read(key: STORAGE_KEY);

    if (rawData == null || rawData.isEmpty) {
      return createDefault();
    }

    final defaultValues = (await createDefault()).toJSON();
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
      "androidTheme": androidTheme.index,
      "localeName": localeName,
      "userHasSeenWelcomeScreen": userHasSeenWelcomeScreen,
      "seenHelperSheets": _seenHelperSheets.toList(),
      "requireBiometricAuthenticationOnStart":
          requireBiometricAuthenticationOnStart,
      "alwaysUseBatterySaveMode": alwaysUseBatterySaveMode,
      "lastHeadlessRun": lastHeadlessRun?.toIso8601String(),
      "serverOrigin": serverOrigin,
      "lastMapLocation": lastMapLocation?.toJSON(),
      "currentAppVersion": currentAppVersion,
      "useRealtimeUpdates": useRealtimeUpdates,
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
      } catch (error) {
        FlutterLogs.logError(
          LOG_TAG,
          "SettingsService",
          "Failed to get address from $provider: $error",
        );
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

  Future<Iterable<String>> getDefaultRelaysOrRandom() async {
    if (_relays.isNotEmpty) {
      return _relays;
    }

    final relaysData = await withCache(getNostrRelays, "relays")();
    final availableRelays =
        List<String>.from(relaysData["relays"] as List<dynamic>);
    final relays = await selectRandomRelays(availableRelays);

    return relays;
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

  void setAndroidTheme(final AndroidTheme value) {
    androidTheme = value;
    notifyListeners();
  }

  AndroidTheme getAndroidTheme() => androidTheme;

  Future<void> setHasSeenWelcomeScreen() async {
    userHasSeenWelcomeScreen = true;
    notifyListeners();
    await save();
  }

  bool getRequireBiometricAuthenticationOnStart() =>
      requireBiometricAuthenticationOnStart;

  void setRequireBiometricAuthenticationOnStart(final bool value) {
    requireBiometricAuthenticationOnStart = value;
    notifyListeners();
  }

  bool getAlwaysUseBatterySaveMode() => alwaysUseBatterySaveMode;

  void setAlwaysUseBatterySaveMode(final bool value) {
    alwaysUseBatterySaveMode = value;
    notifyListeners();
  }

  bool getUseRealtimeUpdates() => useRealtimeUpdates;

  void setUseRealtimeUpdates(final bool value) {
    useRealtimeUpdates = value;
    notifyListeners();
  }

  Future<bool> hasBiometricsAvailable() {
    final auth = LocalAuthentication();

    return auth.canCheckBiometrics;
  }

  bool isMIUI() => androidTheme == AndroidTheme.miui;

  bool hasSeenHelperSheet(final HelperSheet sheet) =>
      _seenHelperSheets.contains(sheet.name);

  Future<void> markHelperSheetAsSeen(final HelperSheet sheet) async {
    _seenHelperSheets.add(sheet.name);
    notifyListeners();
    await save();
  }

  String getServerOrigin() => serverOrigin;

  String getServerHost() => serverOrigin.substring(8);

  void serverServerOrigin(final String value) {
    serverOrigin = value;
    notifyListeners();
  }

  SettingsLastMapLocation? getLastMapLocation() => lastMapLocation;

  void setLastMapLocation(final SettingsLastMapLocation? value) {
    lastMapLocation = value;
    notifyListeners();
  }
}
