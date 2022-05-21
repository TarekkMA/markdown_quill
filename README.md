# Markdown Quill


![build workflow](https://github.com/TarekkMA/markdown_quill/actions/workflows/build.yml/badge.svg)
[![codecov](https://codecov.io/gh/TarekkMA/markdown_quill/branch/master/graph/badge.svg?token=A08O1D2EBY)](https://codecov.io/gh/TarekkMA/markdown_quill)
[![pub package](https://img.shields.io/pub/v/markdown_quill.svg)](https://pub.dartlang.org/packages/markdown_quill)

## :heart_eyes_cat: Contributions are always welcomed :heart:

Provides converters to convert from markdown to quill (Delta) format and vice versa.


## Usage

### Simple

```dart
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

// Configure the markdown parser
final mdDocument = md.Document(encodeHtml: false);

final mdToDelta = MarkdownToDelta(markdownDocument: mdDocument);

final deltaToMd = DeltaToMarkdown();

const markdown = '''
# Test
Hello
> Testing

This is an `inline code`

and this is 
``
code block
``
''';

final delta = mdToDelta.convert(markdown);

final markdownAgain = deltaToMd.convert(delta);
```

### Customized

```dart
import 'package:flutter_quill/flutter_quill.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

// Configure the markdown parser
final mdDocument = md.Document(
  encodeHtml: false,
  extensionSet: md.ExtensionSet.gitHubFlavored,

  // you can add custom syntax.
  blockSyntaxes: [const EmbeddableTableSyntax()],
);

final mdToDelta = MarkdownToDelta(
  markdownDocument: mdDocument,

  // you can add custom attributes based on tags
  customElementToBlockAttribute: {
    'h4': (element) => [HeaderAttribute(level: 4)],
  },
  // custom embed
  customElementToEmbeddable: {
    EmbeddableTable.tableType: EmbeddableTable.fromMdSyntax,
  },
);

final deltaToMd = DeltaToMarkdown(
    customEmbedHandlers: {
      EmbeddableTable.tableType: EmbeddableTable.toMdSyntax,
    },
);



const markdown = '''
Hi, this is a test of markdown_quill.

| Syntax      | Description | Test Text     |
| :---        |    :----:   |          ---: |
| Header      | Title       | Here's this   |
| Paragraph   | Text        | And more      |

# H1
ok
# H2
# H3
done
# H4
''';


final delta = mdToDelta.convert(markdown);

final markdownAgain = deltaToMd.convert(delta);
```


## Limitation

### Image

Currently this convertor doesn't support image alts, only image src will be retained

### Block attributes exclusivity

flutter_quill block attributes have restrictions on how they can be combined.

These block attributes are exclusive and cannot be combined:

- Header
- List
- Code Block
- Block Quote

if the input markdown is:

```markdown
> # Foo
> bar
> baz
```

it will be treated as

```markdown
> Foo
> bar
> baz
```

## TODO

- Improve the output of `DeltaToMarkdown`