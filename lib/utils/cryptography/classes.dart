import 'dart:convert';

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
