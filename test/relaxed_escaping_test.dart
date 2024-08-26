import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

void main() {
  test('default escaping', () {
    _checkEscaping(
      input: '''
Not all characters **should** be escaped.

1. This neither.

''',
      output: r'''
Not all characters **should** be escaped\.

1. This neither\.

''',
      relaxed: false,
    );
  });

  test('relaxed escaping', () {
    const input = '''
Not all characters **should** be escaped.

1. This neither.

''';
    _checkEscaping(
      input: input,
      output: input, // no escape characters should be added
      relaxed: true,
    );
  });
}

void _checkEscaping({
  required String input,
  required String output,
  required bool relaxed,
}) {
  final mdDocument = md.Document(
    encodeHtml: false,
    extensionSet: md.ExtensionSet.gitHubFlavored,
  );

  final mdToDelta = MarkdownToDelta(
    markdownDocument: mdDocument,
  );

  final deltaToMd = relaxed
      ? DeltaToMarkdown(
          customContentHandler: DeltaToMarkdown.escapeSpecialCharactersRelaxed)
      : DeltaToMarkdown();

  final delta = mdToDelta.convert(input);
  final document = Document.fromDelta(delta);
  final reMarkdown = deltaToMd.convert(document.toDelta());

  expect(reMarkdown, output);
}
