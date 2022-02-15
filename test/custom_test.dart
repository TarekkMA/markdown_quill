import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

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

    expect(
        delta.toList(),
        fromOps([
          Operation.insert(EmbeddableTable(md).toJson()),
          Operation.insert('\n'),
        ]));

    final mdBackAgain = deltaToMd.convert(delta);

    expect(mdBackAgain.trim(), md);
  });

  test('table in middle of text', () {
    const md = '''
We are extremely excited to finally announce our crowdloan details!

TL;DR:

|  |  |
|--|--|
| Crowdloan Cap | 100,000 KSM |
| Total Token Supply | 100,000,000 SUB |
| Crowdloan Reward Allocation | 16,500,000 SUB (16.5%) |
| Base Rewards | 15,000,000 SUB (15%) |
| Maximum Referral Rewards | 1,500,000 SUB (1.5%) |
| Minimum Tokens Per KSM | 150 SUB (.00015%) |
| Referral Bonus | 7.5 SUB per KSM to both referrer and referee |
| Initial Unlock | 20% |

# The Breakdown
Having watched and taken notes on other crowdloans, we have decided to keep it simple. **Perfect communication and transparency is our #1 goal.**
''';
    mdToDeltaToMdCheck(md, mdToDelta, deltaToMd, _mdDocument);
  });

  test('code block with language', () {
    mdToDeltaToMdCheck('''
```dart
dart code
```
```java
java code
```
```
not specified
```''');
  });
}
