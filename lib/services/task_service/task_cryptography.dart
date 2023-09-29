import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/utils/cryptography/encrypt.dart';
import 'package:locus/utils/nostr_fetcher/LocationPointDecrypter.dart';
import 'package:nostr/nostr.dart';

import 'task.dart';

class TaskCryptography {
  final Task task;
  final SecretKey _encryptionPassword;

  TaskCryptography(this.task, this._encryptionPassword);

  Future<String> generateViewKeyContent() async =>
      jsonEncode({
        "encryptionPassword": await _encryptionPassword.extractBytes(),
        "nostrPublicKey": task.nostrPublicKey,
        "relays": task.relays,
      });

  Future<String> encrypt(final String message) =>
      encryptUsingAES(message, _encryptionPassword);

  Future<LocationPointService> decryptFromNostrMessage(final Message message) =>
      LocationPointDecrypter(
        _encryptionPassword,
      ).decryptFromNostrMessage(message);
}