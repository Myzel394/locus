import 'package:cryptography/cryptography.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:nostr/nostr.dart';

class LocationPointDecrypter {
  final SecretKey _password;

  const LocationPointDecrypter(this._password);

  Future<LocationPointService> decryptFromNostrMessage(
    final Message message,
  ) async {
    return LocationPointService.fromEncrypted(
      message.message.content,
      _password,
    );
  }
}
