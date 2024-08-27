import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

import 'utils/custom_list_syntax.dart';
import 'utils/keep_empty_line_block_syntax.dart';

void main() {
  test(
    'ordered/unordered list merging',
    () {
      // given
      const inputMarkdown = '''
1. This is ordered list
This is a simple line
- This is unordered list
''';

      final mdDocument = md.Document(
        encodeHtml: false,
        blockSyntaxes: const [
          CustomOrderedListSyntax(acceptParagraphContinuation: false),
          CustomUnorderedListSyntax(acceptParagraphContinuation: false),
          KeepEmptyLineBlockSyntax(),
        ],
        extensionSet: md.ExtensionSet.gitHubFlavored,
      );

      final mdToDelta = MarkdownToDelta(
        markdownDocument: mdDocument,
      );

      final deltaToMd = DeltaToMarkdown(
          visitLineHandleNewLine: (style, out) => out.writeln());

      // when
      final delta = mdToDelta.convert(inputMarkdown);

      final document = Document.fromDelta(delta);
      final reMarkdown = deltaToMd.convert(document.toDelta());

      // then
      expect(reMarkdown, inputMarkdown);
    },
  );
}
