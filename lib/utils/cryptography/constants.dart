import 'package:cryptography/cryptography.dart';

final AES_ALGORITHM = AesCbc.with256bits(
  macAlgorithm: MacAlgorithm.empty,
);
