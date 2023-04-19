import 'dart:convert';
import 'dart:math';

final random = Random.secure();

createCryptoRandomString([final int length = 32]) {
  var values = List<int>.generate(length, (i) => random.nextInt(256));

  return base64Url.encode(values);
}
