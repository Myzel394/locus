class SettingsLastMapLocation {
  final double latitude;
  final double longitude;
  final double accuracy;

  const SettingsLastMapLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });

  factory SettingsLastMapLocation.fromJSON(final Map<String, dynamic> data) =>
      SettingsLastMapLocation(
        latitude: data['latitude'] as double,
        longitude: data['longitude'] as double,
        accuracy: data['accuracy'] as double,
      );

  Map<String, dynamic> toJSON() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
      };
}
