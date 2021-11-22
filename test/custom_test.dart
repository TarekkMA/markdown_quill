import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:quill_markdown/quill_markdown.dart';
import 'package:quill_markdown/src/embeddable_table_syntax.dart';

import 'delta_to_markdown_test.dart';
import 'markdown_to_delta_test.dart';

final _mdDocument = md.Document(
  encodeHtml: false,
  extensionSet: md.ExtensionSet.gitHubFlavored,
  blockSyntaxes: [const EmbeddableTableSyntax()],
);

final mdToDelta = MarkdownToDelta(
  markdownDocument: _mdDocument,
  customElementToEmbeddable: {
    EmbeddableTable.tableType: EmbeddableTable.fromMdSyntax,
  },
);

final deltaToMd = DeltaToMarkdown(
  customEmbedHandlers: {
    EmbeddableTable.tableType: EmbeddableTable.toMdSyntax,
  },
);

void main() {
  test('table', () {
    const md = '''
| Syntax      | Description |
| ----------- | ----------- |
| Header      | **T**itle   |
| ~Paragraph~ | _Text_      |''';

    final delta = mdToDelta.convert(md);

    expect(delta.toList(), fromOps([
      Operation.insert(EmbeddableTable(md).toJson()),
      Operation.insert('\n'),
    ]));

    final mdBackAgain = deltaToMd.convert(delta);

    expect(mdBackAgain.trim(), md);
  });
}
