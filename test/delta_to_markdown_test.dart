import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:quill_markdown/src/delta_to_markdown.dart';
import 'package:quill_markdown/src/markdown_to_delta.dart';

import 'markdown_to_delta_test.dart';

final _mdDocument = md.Document(
  encodeHtml: false,
  extensionSet: md.ExtensionSet.gitHubFlavored,
);

final mdToDelta = MarkdownToDelta(markdownDocument: _mdDocument);

List<md.Node> parseMarkdown(String markdown) {
  return _mdDocument.parseLines(const LineSplitter().convert(markdown));
}

/// checks the if rendered html of both inputs are equal
void expectEqualMarkdown(String actual, String match) {
  final actualNodes = parseMarkdown(actual);
  final matchNodes = parseMarkdown(match);
  final actualHtml = md.HtmlRenderer().render(actualNodes);
  final matchHtml = md.HtmlRenderer().render(matchNodes);

  expect(actualHtml, matchHtml);
}

void deltaToMdCheck(Delta delta, String expected) {
  final actual = DeltaToMarkdown().convert(delta);
  expectEqualMarkdown(actual, expected);
}

void deltaOpsToMdCheck(List<Operation> ops, String expected) {
  final delta = Delta();
  for (final op in ops) {
    delta.push(op);
  }
  deltaToMdCheck(delta, expected);
}

/// convert input markdown to delta and then back
/// to markdown, then compare the input with the
/// conversion output.
void mdToDeltaToMdCheck(String expected) {
  final delta = mdToDelta.convert(expected);
  deltaToMdCheck(delta, expected);
}

void main() {
  test('test 1', () {
    mdToDeltaToMdCheck(
      '''
1. Hello
   1. This is okay
  
* Test
* Test 2
  * Test 3
    ''',
    );
  });

  test('horizontal line 1', () {
    final ops = [
      Operation.insert('Foo\n'),
      Operation.insert(BlockEmbed.horizontalRule.toJson()),
      Operation.insert('\nBar\n'),
    ];
    const expected = 'Foo\n\n---\n\nBar\n';

    deltaOpsToMdCheck(ops, expected);
  });

  test('nested styles', () {
    final link = LinkAttribute('http://nested.styles');
    final bold = Attribute.bold;
    final italic = Attribute.italic;
    final striked = Attribute.strikeThrough;

    final ops = [
      Operation.insert('Ok '),
      Operation.insert(
        '321',
        attrsToJson([link]),
      ),
      Operation.insert(
        'Hello ',
        attrsToJson([link, bold]),
      ),
      Operation.insert(
        'World',
        attrsToJson([link, bold, italic, striked]),
      ),
      Operation.insert(
        ' Egypt',
        attrsToJson([link, bold, italic]),
      ),
      Operation.insert(
        ' !123',
        attrsToJson([link]),
      ),
      Operation.insert(' Done'),
      Operation.insert('\n'),
    ];
    const expected =
        'Ok [321**Hello _~~World~~ Egypt_** !123](http://nested.styles) Done';

    deltaOpsToMdCheck(ops, expected);
  });

  group('friebetill/delta_markdown tests', () {
    // test('Works on one line strings', () {
    //   const delta = '[{"insert":"Test\\n"}]';
    //   const expected = 'Test\n';
    //
    //   final result = deltaToMarkdown(delta);
    //
    //   expect(result, expected);
    // });

    test('Works on one line strings', () {
      final ops = [Operation.insert('Test\n')];
      const expected = 'Test\n';

      deltaOpsToMdCheck(ops, expected);
    });

    // test('Works on one line with header 1', () {
    //   const delta =
    //       r'[{"insert":"Heading level 1"},{"insert":"\n","attributes":{"header":1}}]';
    //   const expected = '# Heading level 1\n';
    //
    //   final result = deltaToMarkdown(delta);
    //
    //   expect(result, expected);
    // });

    test('Works on one line with header 1', () {
      final ops = [
        Operation.insert('Heading level 1'),
        Operation.insert('\n', Attribute.h1.toJson()),
      ];
      const expected = '# Heading level 1\n';

      deltaOpsToMdCheck(ops, expected);
    });

    // test('Works on one line with header 2', () {
    //   const delta =
    //       r'[{"insert":"Heading level 2"},{"insert":"\n","attributes":{"header":2}}]';
    //   const expected = '## Heading level 2\n';
    //
    //   final result = deltaToMarkdown(delta);
    //
    //   expect(result, expected);
    // });

    test('Works on one line with header 2', () {
      final ops = [
        Operation.insert('Heading level 2'),
        Operation.insert('\n', Attribute.h2.toJson()),
      ];
      const expected = '## Heading level 2\n';

      deltaOpsToMdCheck(ops, expected);
    });

    // test('Works on one line with header 3', () {
    //   const delta =
    //       r'[{"insert":"Heading level 3"},{"insert":"\n","attributes":{"header":3}}]';
    //   const expected = '### Heading level 3\n';
    //
    //   final result = deltaToMarkdown(delta);
    //
    //   expect(result, expected);
    // });

    test('Works on one line with header 3', () {
      final ops = [
        Operation.insert('Heading level 3'),
        Operation.insert('\n', Attribute.h3.toJson()),
      ];
      const expected = '### Heading level 3\n';

      deltaOpsToMdCheck(ops, expected);
    });

    // test('Works on one line italic string', () {
    //   const delta =
    //       r'[{"insert":"Test","attributes":{"italic":true}},{"insert":"\n"}]';
    //   const expected = '_Test_\n';
    //
    //   final result = deltaToMarkdown(delta);
    //
    //   expect(result, expected);
    // });

    test('Works on one line italic string', () {
      final ops = [
        Operation.insert('Test', Attribute.italic.toJson()),
        Operation.insert('\n'),
      ];
      const expected = '_Test_\n';

      deltaOpsToMdCheck(ops, expected);
    });

    // test('Works on one text with multiple inline styles', () {
    //   const delta =
    //       r'[{"attributes":{"italic":true,"bold":true},"insert":"Foo"},{"insert":"\n"}]';
    //   const expected = '_**Foo**_\n';
    //
    //   final result = deltaToMarkdown(delta);
    //
    //   expect(result, expected);
    // });

    test('Works on one text with multiple inline styles', () {
      final ops = [
        Operation.insert(
            'Foo',
            attrsToJson([
              Attribute.italic,
              Attribute.bold,
            ])),
        Operation.insert('\n'),
      ];
      // const expected = '_**Foo**_\n';
      const expected = '**_Foo_**\n';

      deltaOpsToMdCheck(ops, expected);
    });

    // test('Works on one line with block quote', () {
    //   const delta =
    //       r'[{"insert":"Test"},{"insert":"\n","attributes":{"blockquote":true}}]';
    //   const expected = '> Test\n';
    //
    //   final result = deltaToMarkdown(delta);
    //
    //   expect(result, expected);
    // });

    test('Works on one line with block quote', () {
      final ops = [
        Operation.insert('Test'),
        Operation.insert('\n', Attribute.blockQuote.toJson()),
      ];
      const expected = '> Test\n';

      deltaOpsToMdCheck(ops, expected);
    });

    // test('Works on one line with code block', () {
    //   const delta =
    //       r'[{"insert":"Test"},{"insert":"\n","attributes":{"code-block":true}}]';
    //   const expected = '```\nTest\n```\n';
    //
    //   final result = deltaToMarkdown(delta);
    //
    //   expect(result, expected);
    // });

    test('Works on one line with code block', () {
      final ops = [
        Operation.insert('Test'),
        Operation.insert('\n', Attribute.codeBlock.toJson()),
      ];
      const expected = '```\nTest\n```\n';

      deltaOpsToMdCheck(ops, expected);
    });

    // test('Works on one line with ordered list', () {
    //   const delta =
    //       r'[{"insert":"Test"},{"insert":"\n","attributes":{"list":"ordered"}}]';
    //   const expected = '1. Test\n';
    //
    //   final result = deltaToMarkdown(delta);
    //
    //   expect(result, expected);
    // });

    test('Works on one line with ordered list', () {
      final ops = [
        Operation.insert('Test'),
        Operation.insert('\n', Attribute.ol.toJson()),
      ];
      const expected = '1. Test\n';

      deltaOpsToMdCheck(ops, expected);
    });

    // test('Works with horizontal line', () {
    //   const delta = r'[{"insert":"Foo\n"},{"insert":{"divider":"hr"}},{"insert":"Bar\n"}]';
    //   const expected = 'Foo\n\n---\n\nBar\n';
    //
    //   final result = deltaToMarkdown(delta);
    //
    //   expect(result, expected);
    // });

    test('Works with horizontal line', () {
      final ops = [
        Operation.insert('Foo\n'),
        Operation.insert(BlockEmbed.horizontalRule.toJson()),
        Operation.insert('Bar\n'),
      ];
      const expected = 'Foo\n\n---\n\nBar\n';

      deltaOpsToMdCheck(ops, expected);
    });

    // test('Works on one line with unordered list', () {
    //   const delta =
    //       r'[{"insert":"Test"},{"insert":"\n","attributes":{"list":"bullet"}}]';
    //   const expected = '* Test\n';
    //
    //   final result = deltaToMarkdown(delta);
    //
    //   expect(result, expected);
    // });

    test('Works on one line with unordered list', () {
      final ops = [
        Operation.insert('Test'),
        Operation.insert('\n', Attribute.ul.toJson()),
      ];
      const expected = '* Test\n';

      deltaOpsToMdCheck(ops, expected);
    });

    // test('Works with one inline bold attribute', () {
    //   const delta =
    //       r'[{"insert":"Foo","attributes":{"bold":true}},{"insert":" bar\n"}]';
    //   const expected = '**Foo** bar\n';
    //
    //   final result = deltaToMarkdown(delta);
    //
    //   expect(result, expected);
    // });

    test('Works with one inline bold attribute', () {
      final ops = [
        Operation.insert('Foo', Attribute.bold.toJson()),
        Operation.insert(' bar\n'),
      ];
      const expected = '**Foo** bar\n';

      deltaOpsToMdCheck(ops, expected);
    });

    // test('Works with one link', () {
    //   const delta =
    //       r'[{"insert":"FooBar","attributes":{"link":"http://foo.bar"}},{"insert":"\n"}]';
    //   const expected = '[FooBar](http://foo.bar)\n';
    //
    //   final result = deltaToMarkdown(delta);
    //
    //   expect(result, expected);
    // });

    test('Works with one link', () {
      final ops = [
        Operation.insert('FooBar', LinkAttribute('http://foo.bar').toJson()),
        Operation.insert('\n'),
      ];
      const expected = '[FooBar](http://foo.bar)\n';

      deltaOpsToMdCheck(ops, expected);
    });

    // test('Works with one image', () {
    //   const delta = r'[{"insert":{"image":"http://image.jpg"}},{"insert":"\n"}]';
    //   const expected = '![](http://image.jpg)\n';
    //
    //   final result = deltaToMarkdown(delta);
    //
    //   expect(result, expected);
    // });

    test('Works with one image', () {
      final ops = [
        Operation.insert(BlockEmbed.image('http://image.jpg')),
        Operation.insert('\n'),
      ];
      const expected = '![](http://image.jpg)\n';

      deltaOpsToMdCheck(ops, expected);
    });
  });
}
