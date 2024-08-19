import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

final _mdDocument = md.Document(
  encodeHtml: false,
  blockSyntaxes: [const KeepEmptyLineBlockSyntax()],
  extensionSet: md.ExtensionSet.gitHubFlavored,
);

final _mdToDelta = MarkdownToDelta(
  markdownDocument: _mdDocument,
);

final _deltaToMd = DeltaToMarkdown(
  visitLineHandleNewLine: (style, out) => out.writeln(),
);

void main() {
  test('!', () {
    _verify('\\!\n');
  });

  test('1NL', () {
    _verify('''
First line

Third line
''');
  });

  test('1NL+ENL', () {
    _verify('''
First line

Third line

''');
  });

  test('2NL', () {
    _verify('''
First line


Third line
''');
  });

  test('2NL+ENL', () {
    _verify('''
First line


Third line

''');
  });
}

void _verify(String input) {
  final delta = _mdToDelta.convert(input);
  final document = Document.fromDelta(delta);
  final reMarkdown = _deltaToMd.convert(document.toDelta());

  expect(reMarkdown, input);
}

class KeepEmptyLineBlockSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^(?:[ \t]*)$');

  const KeepEmptyLineBlockSyntax();

  @override
  md.Node? parse(md.BlockParser parser) {
    parser.advance();

    return md.Element.text('p', '');
  }
}
