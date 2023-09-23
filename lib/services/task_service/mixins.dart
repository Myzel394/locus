import 'package:cryptography/cryptography.dart';

mixin LocationBase {
  late final SecretKey _encryptionPassword;
  late final List<String> relays;
  late final String nostrPublicKey;
}
