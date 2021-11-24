import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'delta_to_markdown_test.dart';

Future<void> main() async {
  final dir = Directory('./test/md_files');
  final files = (await dir.list().toList()).whereType<File>().toList();

  for (final file in files) {
    final fileName = file.uri.pathSegments.last;
    test(fileName, () async {
      final markdown = await file.readAsString();
      mdToDeltaToMdCheck(markdown);
    });
  }
}
