import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:locus/utils/cryptography/encrypt.dart';

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
}