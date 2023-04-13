import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

Future<File> createTempFile(final Uint8List data, {String? extension, String? name}) async {
  final tempDir = await getTemporaryDirectory();

  final stem = name ?? uuid.v4();
  final fileName = extension != null ? '$stem.$extension' : stem;

  final path = '${tempDir.path}/$fileName';
  final file = await File(path).create();
  await file.writeAsBytes(data);

  return file;
}
