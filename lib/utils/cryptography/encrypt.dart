import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'classes.dart';
import 'constants.dart';

Future<String> encryptUsingAES(
  final String message,
  final SecretKey secretKey,
) async {
  final encrypted = await AES_ALGORITHM.encrypt(
    Uint8List.fromList(const Utf8Encoder().convert(message)),
    secretKey: secretKey,
  );

  final publicData = PublicStringData(
      cipherText: encrypted.cipherText, nonce: encrypted.nonce);

  return publicData.publicString;
}
