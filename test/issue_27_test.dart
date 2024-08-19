import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

final _mdDocument = md.Document(
  encodeHtml: false,
  extensionSet: md.ExtensionSet.gitHubFlavored,
);

final _mdToDelta = MarkdownToDelta(
  markdownDocument: _mdDocument,
);

final _deltaToMd = DeltaToMarkdown();

/// https://github.com/TarekkMA/markdown_quill/issues/27
void main() {
  test('list A', () {
    _verify('''
1. One
2. Two
3. Three

''');
  });

  test('list B', () {
    _verify('''
1. One
2. Two
    1. Two One
    2. Two Two
3. Three

''');
  });

  test('list C', () {
    _verify('''
1. One
2. Two
    - Two One
    - Two Two
3. Three

''');
  });
}

void _verify(String input) {
  final delta = _mdToDelta.convert(input);
  final document = Document.fromDelta(delta);
  final reMarkdown = _deltaToMd.convert(document.toDelta());

  expect(reMarkdown, input);
}
