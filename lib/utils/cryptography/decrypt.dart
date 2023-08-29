import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'constants.dart';
import 'classes.dart';

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
