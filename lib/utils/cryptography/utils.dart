import 'package:cryptography/cryptography.dart';

import 'constants.dart';

Future<SecretKey> generateSecretKey() async {
  final secretKey = await AES_ALGORITHM.newSecretKey();

  return secretKey;
}
