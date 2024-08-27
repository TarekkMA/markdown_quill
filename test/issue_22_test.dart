import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

import 'utils/custom_blockquote_syntax.dart';
import 'utils/keep_empty_line_block_syntax.dart';

/// https://github.com/TarekkMA/markdown_quill/issues/22
void main() {
  /// in this approach we prevent second line being merged into quote block
  /// by supplying [CustomBlockquoteSyntax]
  test(
    'quotes disappearing/merging',
    () {
      // given
      const inputMarkdown = '''
> This is a quote
This is another line

''';

      final mdDocument = md.Document(
        encodeHtml: false,
        blockSyntaxes: [
          const KeepEmptyLineBlockSyntax(),
          const CustomBlockquoteSyntax(acceptParagraphContinuation: false)
        ],
        extensionSet: md.ExtensionSet.gitHubFlavored,
      );

      final mdToDelta = MarkdownToDelta(
        markdownDocument: mdDocument,
      );

      final deltaToMd = DeltaToMarkdown(
        visitLineHandleNewLine: (style, out) => out.writeln(),
      );

      // when
      final delta = mdToDelta.convert(inputMarkdown);

      final document = Document.fromDelta(delta);
      final reMarkdown = deltaToMd.convert(document.toDelta());

      // then
      expect(reMarkdown, inputMarkdown);
    },
  );
}
