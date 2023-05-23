// This file contains everything related to cryptography.
// It contains high level functions that are used by the rest of the app.
// If you want to add anything cryptography related, add it here. Do not add it anywhere else.
// We want to make sure that all cryptography related code is in one place, so that we can easily review it.
//
// Some general notes:
// * We use AES CBC with 256 bits
// * We do not use a MAC - We rely on Nostr's signature for authentication (https://en.wikipedia.org/wiki/Message_authentication_code)
// * We share the initial vector publicly (https://security.stackexchange.com/a/254752/226496)
import "dart:convert";
import "dart:typed_data";

import "package:cryptography/cryptography.dart";

final AES_ALGORITHM = AesCbc.with256bits(
  macAlgorithm: MacAlgorithm.empty,
);

Future<String> encryptUsingAES(
  final String message,
  final SecretKey secretKey,
) async {
  final encrypted = await AES_ALGORITHM.encrypt(
    Uint8List.fromList(const Utf8Encoder().convert(message)),
    secretKey: secretKey,
  );

  final publicData = PublicStringData(cipherText: encrypted.cipherText, nonce: encrypted.nonce);

  return publicData.publicString;
}

Future<String> decryptUsingAES(
  final String cipherText,
  final SecretKey secretKey,
) async {
  final publicData = PublicStringData.fromPublicString(cipherText);
  final decrypted = await AES_ALGORITHM.decrypt(
    SecretBox(
      List<int>.from(publicData.cipherText),
      mac: Mac.empty,
      nonce: publicData.nonce,
    ),
    secretKey: secretKey,
  );

  return const Utf8Decoder().convert(decrypted);
}

Future<SecretKey> generateSecretKey() async {
  final secretKey = await AES_ALGORITHM.newSecretKey();

  return secretKey;
}

class PublicStringData {
  final List<int> cipherText;
  final List<int> nonce;

  const PublicStringData({
    required this.cipherText,
    required this.nonce,
  });

  String get publicString => jsonEncode([nonce, cipherText]);

  factory PublicStringData.fromPublicString(final String publicString) {
    final parsed = jsonDecode(publicString);

    return PublicStringData(
      nonce: List<int>.from(parsed[0]),
      cipherText: List<int>.from(parsed[1]),
    );
  }
}
