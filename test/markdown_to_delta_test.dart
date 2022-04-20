import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/src/custom_quill_attributes.dart';
import 'package:markdown_quill/src/markdown_to_delta.dart';
import 'package:markdown_quill/src/utils.dart';

final _mdDocument = md.Document(
  encodeHtml: false,
  extensionSet: md.ExtensionSet.gitHubFlavored,
);

void mdToDeltaCheck(
  String markdown,
  List<Operation> ops, [
  MarkdownToDelta? converter,
]) {
  final result = (converter ?? MarkdownToDelta(markdownDocument: _mdDocument))
      .convert(markdown);
  expect(result.toList(), fromOps(ops));
}

List<Operation> fromOps(List<Operation> ops) {
  final delta = Delta();
  for (final op in ops) {
    delta.push(op);
  }
  return delta.toList();
}

Map<String, dynamic> attrsToJson(List<Attribute> attrs) {
  return <String, dynamic>{
    for (final attr in attrs) ...attr.toJson(),
  };
}

void main() {
  test('Empty String', () {
    mdToDeltaCheck(
      '',
      [],
    );
  });

  test('single line', () {
    mdToDeltaCheck(
      'Test',
      [
        Operation.insert('Test'),
        Operation.insert('\n'),
      ],
    );
  });

  test('Multi line', () {
    mdToDeltaCheck(
      'Test\nTest 2\n\nTest 3',
      [
        Operation.insert('Test Test 2\nTest 3\n'),
      ],
    );
  });

  test('lazy block quote', () {
    mdToDeltaCheck(
      '> Hello\n' '  this is a test\n' "And it's working  ",
      [
        Operation.insert('Hello'), // starting space removed
        Operation.insert('\n', Attribute.blockQuote.toJson()),
        Operation.insert('  this is a test'),
        Operation.insert('\n', Attribute.blockQuote.toJson()),
        Operation.insert("And it's working"), // ending space removed
        Operation.insert('\n', Attribute.blockQuote.toJson()),
      ],
    );
  });

  test('image between texts (same lines)', () {
    mdToDeltaCheck(
      '''
Hello
![](https://i.imgur.com/yjZ4ljc.jpg)
Goodbye
''',
      [
        Operation.insert('Hello '),
        Operation.insert(
            BlockEmbed.image('https://i.imgur.com/yjZ4ljc.jpg').toJson()),
        Operation.insert(' Goodbye'),
        Operation.insert('\n'),
      ],
    );
  });

  test('image between texts (different lines)', () {
    mdToDeltaCheck(
      '''
Hello

![](https://i.imgur.com/yjZ4ljc.jpg)

Goodbye
''',
      [
        Operation.insert('Hello\n'),
        Operation.insert(
            BlockEmbed.image('https://i.imgur.com/yjZ4ljc.jpg').toJson()),
        Operation.insert('\nGoodbye'),
        Operation.insert('\n'),
      ],
    );
  });

  test('escaped ` character', () {
    const md = r'''
*   [Going forward, the \`--dev\` flag passed into Substrate nodes will imply \`--tmp\` if a \`--base-path\` is not explicitly provided](https://github.com/paritytech/substrate/pull/9938), meaning all dev chains are now temporary chains by default. To persist a dev chain’s database, pass in the base-path parameter.
''';

    final link =
        LinkAttribute('https://github.com/paritytech/substrate/pull/9938');

    mdToDeltaCheck(
      md,
      [
        Operation.insert(
          'Going forward, the `--dev` flag passed into Substrate nodes will imply `--tmp` if a `--base-path` is not explicitly provided',
          link.toJson(),
        ),
        Operation.insert(
            ', meaning all dev chains are now temporary chains by default. To persist a dev chain’s database, pass in the base-path parameter.'),
        Operation.insert('\n', Attribute.ul.toJson()),
      ],
    );
  });

  test('3 lines', () {
    mdToDeltaCheck(
      '''
Hello

Tarek

Goodbye
''',
      [
        Operation.insert('Hello\n'),
        Operation.insert('Tarek\n'),
        Operation.insert('Goodbye\n'),
      ],
    );
  });

  test('exclusive blocks new line', () {
    mdToDeltaCheck(
      '''
> # Hello
# World''',
      [
        Operation.insert('Hello'),
        Operation.insert('\n', Attribute.blockQuote.toJson()),
        Operation.insert('World'),
        Operation.insert('\n', Attribute.h1.toJson()),
      ],
    );
  });

  test('code block with language', () {
    final styles = <Attribute>[
      Attribute.codeBlock,
      CodeBlockLanguageAttribute('java'),
    ];
    mdToDeltaCheck(
      '''
```java
public static void main() 
{
// comment
}
```
''',
      [
        Operation.insert('public static void main() '),
        Operation.insert('\n', attrsToJson(styles)),
        Operation.insert('{'),
        Operation.insert('\n', attrsToJson(styles)),
        Operation.insert('// comment'),
        Operation.insert('\n', attrsToJson(styles)),
        Operation.insert('}'),
        Operation.insert('\n', attrsToJson(styles)),
      ],
    );
  });

  group('friebetill/delta_markdown tests', () {
    test('Works on one line strings', () {
      mdToDeltaCheck(
        'Test\n',
        [
          Operation.insert('Test\n'),
        ],
      );
    });

    test('Works on one line with header 1', () {
      mdToDeltaCheck(
        '# Heading level 1\n',
        [
          Operation.insert('Heading level 1'),
          Operation.insert('\n', Attribute.h1.toJson()),
        ],
      );
    });

    // test('Works on one line with header 2', () {
    //   const markdown = '## Heading level 2\n';
    //   const expected =
    //       r'[{"insert":"Heading level 2"},{"insert":"\n","attributes":{"header":2}}]';
    //
    //   final result = markdownToDelta(markdown);
    //
    //   expect(result, expected);
    // });

    test('Works on one line with header 2', () {
      mdToDeltaCheck(
        '## Heading level 2\n',
        [
          Operation.insert('Heading level 2'),
          Operation.insert('\n', Attribute.h2.toJson()),
        ],
      );
    });

    // test('Works on one line with header 3', () {
    //   const markdown = '### Heading level 3\n';
    //   const expected =
    //       r'[{"insert":"Heading level 3"},{"insert":"\n","attributes":{"header":3}}]';
    //
    //   final result = markdownToDelta(markdown);
    //
    //   expect(result, expected);
    // });

    test('Works on one line with header 3', () {
      mdToDeltaCheck(
        '### Heading level 3\n',
        [
          Operation.insert('Heading level 3'),
          Operation.insert('\n', Attribute.h3.toJson()),
        ],
      );
    });

    // test('Works on one line italic string', () {
    //   const markdown = '_Test_\n';
    //   const expected =
    //       r'[{"insert":"Test","attributes":{"italic":true}},{"insert":"\n"}]';
    //
    //   final result = markdownToDelta(markdown);
    //
    //   expect(result, expected);
    // });

    test('Works on one line italic string', () {
      mdToDeltaCheck(
        '_Test_\n',
        [
          Operation.insert('Test', Attribute.italic.toJson()),
          Operation.insert('\n'),
        ],
      );
    });

    // test('Works on one line with block quote', () {
    //   const markdown = '> Test\n';
    //   const expected =
    //       r'[{"insert":"Test"},{"insert":"\n","attributes":{"blockquote":true}}]';
    //
    //   final result = markdownToDelta(markdown);
    //
    //   expect(result, expected);
    // });

    test('Works on one line with block quote', () {
      mdToDeltaCheck(
        '> Test\n',
        [
          Operation.insert('Test'),
          Operation.insert('\n', Attribute.blockQuote.toJson()),
        ],
      );
    });

    // test('Works on one line with code block', () {
    //   const markdown = '```\nTest\n```\n';
    //   const expected =
    //       '[{"insert":"Test"},{"insert":"\\n","attributes":{"code-block":true}}]';
    //
    //   final result = markdownToDelta(markdown);
    //
    //   expect(result, expected);
    // });

    test('Works on one line with code block', () {
      mdToDeltaCheck(
        '```\nTest\n```\n',
        [
          Operation.insert('Test'),
          Operation.insert('\n', Attribute.codeBlock.toJson()),
        ],
      );
    });

    // test('Works on one line with ordered list', () {
    //   const markdown = '1. Test\n';
    //   const expected =
    //       r'[{"insert":"Test"},{"insert":"\n","attributes":{"list":"ordered"}}]';
    //
    //   final result = markdownToDelta(markdown);
    //
    //   expect(result, expected);
    // });

    test('Works on one line with ordered list', () {
      mdToDeltaCheck(
        '1. Test',
        [
          Operation.insert('Test'),
          Operation.insert('\n', Attribute.ol.toJson()),
        ],
      );
    });

    test('Works on one line with ordered list', () {
      mdToDeltaCheck(
        '1. Test\n',
        [
          Operation.insert('Test'),
          Operation.insert('\n', Attribute.ol.toJson()),
        ],
      );
    });

    // test('Works on one line with unordered list', () {
    //   const markdown = '* Test\n';
    //   const expected =
    //       r'[{"insert":"Test"},{"insert":"\n","attributes":{"list":"bullet"}}]';
    //
    //   final result = markdownToDelta(markdown);
    //
    //   expect(result, expected);
    // });

    test('Works on one line with unordered list', () {
      mdToDeltaCheck(
        '* Test\n',
        [
          Operation.insert('Test'),
          Operation.insert('\n', Attribute.ul.toJson()),
        ],
      );
    });

    // test('Works with one inline bold attribute', () {
    //   const markdown = '**Foo** bar\n';
    //   const expected =
    //       r'[{"insert":"Foo","attributes":{"bold":true}},{"insert":" bar\n"}]';
    //
    //   final result = markdownToDelta(markdown);
    //
    //   expect(result, expected);
    // });

    test('Works with one inline bold attribute', () {
      mdToDeltaCheck(
        '**Foo** bar\n',
        [
          Operation.insert('Foo', Attribute.bold.toJson()),
          Operation.insert(' bar\n'),
        ],
      );
    });

    // test('Works on one text with multiple inline styles', () {
    //   const markdown = '_**Foo**_\n';
    //   const expected =
    //       r'[{"insert":"Foo","attributes":{"italic":true,"bold":true}},{"insert":"\n"}]';
    //
    //   final result = markdownToDelta(markdown);
    //
    //   expect(result, expected);
    // });

    test('Works on one text with multiple inline styles', () {
      mdToDeltaCheck(
        '_**Foo**_\n',
        [
          Operation.insert(
              'Foo', attrsToJson([Attribute.bold, Attribute.italic])),
          Operation.insert('\n'),
        ],
      );
    });

    // test('Works with one link', () {
    //   const markdown = '[FooBar](http://foo.bar)\n';
    //   const expected =
    //       r'[{"insert":"FooBar","attributes":{"link":"http://foo.bar"}},{"insert":"\n"}]';
    //
    //   final result = markdownToDelta(markdown);
    //
    //   expect(result, expected);
    // });

    test('Works with one link', () {
      mdToDeltaCheck(
        '[FooBar](http://foo.bar)\n',
        [
          Operation.insert('FooBar', LinkAttribute('http://foo.bar').toJson()),
          Operation.insert('\n'),
        ],
      );
    });

    // test('Works with one image', () {
    //   const markdown = '![](http://image.jpg)\n';
    //   const expected =
    //       r'[{"insert":{"image":"http://image.jpg"}},{"insert":"\n"}]';
    //
    //   final result = markdownToDelta(markdown);
    //
    //   expect(result, expected);
    // });

    test('Works with one image', () {
      mdToDeltaCheck(
        '![](http://image.jpg)',
        [
          Operation.insert(BlockEmbed.image('http://image.jpg').toJson()),
          Operation.insert('\n'),
        ],
      );
    });

    // test('Works not with inline code', () {
    //   // flutter_quill does not support inline code currently.
    //   const markdown = '`Foo` bar\n';
    //   const expected = r'[{"insert":"Foo bar\n"}]';
    //
    //   // This should be the expected output when flutter_quill supports code:
    //   // r'[{"insert":"Foo","attributes":{"code":true}},{"insert":" bar\n"}]';
    //
    //   final result = markdownToDelta(markdown);
    //
    //   expect(result, expected);
    // });

    test('Works not with inline code', () {
      mdToDeltaCheck(
        '`Foo` bar\n',
        [
          Operation.insert('Foo', Attribute.inlineCode.toJson()),
          Operation.insert(' bar'),
          Operation.insert('\n'),
        ],
      );
    });

    // test('Works with greater and smaller symbol in code', () {
    //   const markdown = '```\n<br />\n```';
    //   const expected =
    //       r'[{"insert":"<br />"},{"insert":"\n","attributes":{"code-block":true}}]';
    //
    //   final result = markdownToDelta(markdown);
    //
    //   expect(result, expected);
    // });

    test('Works with greater and smaller symbol in code', () {
      mdToDeltaCheck(
        '```\n<br />\n```',
        [
          Operation.insert('<br />'),
          Operation.insert('\n', Attribute.codeBlock.toJson()),
        ],
      );
    });

    // test('Works with &-symbol', () {
    //   const markdown = 'Foo & Bar\n';
    //   const expected = r'[{"insert":"Foo & Bar\n"}]';
    //
    //   final result = markdownToDelta(markdown);
    //
    //   expect(result, expected);
    // });

    test('Works with &-symbol', () {
      mdToDeltaCheck(
        '**Foo** ~~&~~ *Bar*\n',
        [
          Operation.insert('Foo', Attribute.bold.toJson()),
          Operation.insert(' '),
          Operation.insert('&', Attribute.strikeThrough.toJson()),
          Operation.insert(' '),
          Operation.insert('Bar', Attribute.italic.toJson()),
          Operation.insert('\n'),
        ],
      );
    });

    // test('Works with horizontal line', () {
    //   const markdown = 'Foo\n\n---\n\nBar\n';
    //   const expected = r'[{"insert":"Foo\n"},{"insert":{"divider":"hr"}},{"insert":"Bar\n"}]';
    //
    //   final result = markdownToDelta(markdown);
    //
    //   expect(result, expected);
    // });

    test('Works with horizontal line', () {
      // modified, we add new line after hr
      mdToDeltaCheck(
        'Foo\n\n---\n\nBar\n',
        [
          Operation.insert('Foo\n'),
          Operation.insert(horizontalRule.toJson()),
          Operation.insert('\nBar\n'),
        ],
      );
    });
  });

  group('gfm', () {
    group('2.2 Tabs', () {
      test('1', () {
        mdToDeltaCheck(
          '\tfoo\tbas\t\tbim',
          [
            Operation.insert('foo\tbas\t\tbim'),
            Operation.insert('\n', Attribute.codeBlock.toJson()),
          ],
        );
      });
      test('10', () {
        mdToDeltaCheck(
          '#\tFoo',
          [
            Operation.insert('Foo'),
            Operation.insert('\n', Attribute.h1.toJson()),
          ],
        );
      });
      test('11', () {
        mdToDeltaCheck(
          '*\t*\t*\t',
          [
            Operation.insert(horizontalRule.toJson()),
            Operation.insert('\n'),
          ],
        );
      });
    });
    group('4.1 Thematic breaks ', () {
      test('13 & 17', () {
        mdToDeltaCheck(
          '''
***
---
___

 ***
  ***
   ***''',
          [
            Operation.insert(horizontalRule.toJson()),
            Operation.insert('\n'),
            Operation.insert(horizontalRule.toJson()),
            Operation.insert('\n'),
            Operation.insert(horizontalRule.toJson()),
            Operation.insert('\n'),
            Operation.insert(horizontalRule.toJson()),
            Operation.insert('\n'),
            Operation.insert(horizontalRule.toJson()),
            Operation.insert('\n'),
            Operation.insert(horizontalRule.toJson()),
            Operation.insert('\n'),
          ],
        );
      });

      test('18', () {
        mdToDeltaCheck(
          '    ***',
          [
            Operation.insert('***'),
            Operation.insert('\n', Attribute.codeBlock.toJson()),
          ],
        );
      });

      test('19', () {
        mdToDeltaCheck(
          '''
Foo
    ***''',
          [
            Operation.insert('Foo ***'),
            Operation.insert('\n'),
          ],
        );
      });
      test('26', () {
        mdToDeltaCheck(
          '*-*',
          [
            Operation.insert('-', Attribute.italic.toJson()),
            Operation.insert('\n'),
          ],
        );
      });
      test('27', () {
        mdToDeltaCheck(
          '''
- foo
***
- bar''',
          [
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.ul.toJson()),
            Operation.insert(horizontalRule.toJson()),
            Operation.insert('\n'),
            Operation.insert('bar'),
            Operation.insert('\n', Attribute.ul.toJson()),
          ],
        );
      });
      test('30', () {
        mdToDeltaCheck(
          '''
* foo
* * *
* bar''',
          [
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.ul.toJson()),
            Operation.insert(horizontalRule.toJson()),
            Operation.insert('\n'),
            Operation.insert('bar'),
            Operation.insert('\n', Attribute.ul.toJson()),
          ],
        );
      });
    });
    group('4.2ATX headings ', () {
      final convertor = MarkdownToDelta(
        markdownDocument: _mdDocument,
        customElementToBlockAttribute: {
          'h4': (_) => [HeaderAttribute(level: 4)],
          'h5': (_) => [HeaderAttribute(level: 5)],
          'h6': (_) => [HeaderAttribute(level: 6)],
        },
      );
      test('32', () {
        mdToDeltaCheck(
          '''
# foo
## foo
### foo
#### foo
##### foo
###### foo''',
          [
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.h1.toJson()),
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.h2.toJson()),
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.h3.toJson()),
            Operation.insert('foo'),
            Operation.insert('\n', HeaderAttribute(level: 4).toJson()),
            Operation.insert('foo'),
            Operation.insert('\n', HeaderAttribute(level: 5).toJson()),
            Operation.insert('foo'),
            Operation.insert('\n', HeaderAttribute(level: 6).toJson()),
          ],
          convertor,
        );
      });
      test('33', () {
        mdToDeltaCheck(
          '''
####### foo''',
          [
            Operation.insert('####### foo'),
            Operation.insert('\n'),
          ],
          convertor,
        );
      });
      test('34', () {
        mdToDeltaCheck(
          '''
#5 bolt

#hashtag''',
          [
            Operation.insert('#5 bolt'),
            Operation.insert('\n'),
            Operation.insert('#hashtag'),
            Operation.insert('\n'),
          ],
          convertor,
        );
      });
      test('35', () {
        mdToDeltaCheck(
          r'''
\## foo''',
          [
            Operation.insert('## foo'),
            Operation.insert('\n'),
          ],
          convertor,
        );
      });
      test('36', () {
        mdToDeltaCheck(
          r'''
# foo *bar* \*baz\*''',
          [
            Operation.insert('foo '),
            Operation.insert('bar', Attribute.italic.toJson()),
            Operation.insert(' *baz*'),
            Operation.insert('\n', Attribute.h1.toJson()),
          ],
          convertor,
        );
      });
      test('37', () {
        mdToDeltaCheck(
          '''
#                  foo                     ''',
          [
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.h1.toJson()),
          ],
          convertor,
        );
      });
      test('38', () {
        mdToDeltaCheck(
          '''
 ### foo
  ## foo
   # foo
''',
          [
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.h3.toJson()),
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.h2.toJson()),
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.h1.toJson()),
          ],
          convertor,
        );
      });
      test('39', () {
        mdToDeltaCheck(
          '''
    # foo
''',
          [
            Operation.insert('# foo'),
            Operation.insert('\n', Attribute.codeBlock.toJson()),
          ],
          convertor,
        );
      });
      test('40', () {
        mdToDeltaCheck(
          '''
foo
    # bar
''',
          [
            Operation.insert('foo # bar'),
            Operation.insert('\n'),
          ],
          convertor,
        );
      });
      test('41', () {
        mdToDeltaCheck(
          '''
## foo ##
  ###   bar    ###
''',
          [
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.h2.toJson()),
            Operation.insert('bar'),
            Operation.insert('\n', Attribute.h3.toJson()),
          ],
          convertor,
        );
      });
      test('47', () {
        mdToDeltaCheck(
          '''
****
## foo
****''',
          [
            Operation.insert(horizontalRule.toJson()),
            Operation.insert('\n'),
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.h2.toJson()),
            Operation.insert(horizontalRule.toJson()),
            Operation.insert('\n'),
          ],
          convertor,
        );
      });
      test('47', () {
        mdToDeltaCheck(
          '''
****
## foo
****''',
          [
            Operation.insert(horizontalRule.toJson()),
            Operation.insert('\n'),
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.h2.toJson()),
            Operation.insert(horizontalRule.toJson()),
            Operation.insert('\n'),
          ],
          convertor,
        );
      });

      // have issue with markdown parser
      test('49', () {
        mdToDeltaCheck(
          '''
## 
#
### ###''',
          [
            Operation.insert('\n', Attribute.h2.toJson()),
            Operation.insert('\n', Attribute.h1.toJson()),
            Operation.insert('\n', Attribute.h3.toJson()),
          ],
          convertor,
        );
      }, skip: true);
    });
    group('4.3 Setext headings ', () {
      test('50', () {
        mdToDeltaCheck(
          '''
Foo *bar*
=========

Foo *bar*
---------''',
          [
            Operation.insert('Foo '),
            Operation.insert('bar', Attribute.italic.toJson()),
            Operation.insert('\n', Attribute.h1.toJson()),
            Operation.insert('Foo '),
            Operation.insert('bar', Attribute.italic.toJson()),
            Operation.insert('\n', Attribute.h2.toJson()),
          ],
        );
      });
      test('51', () {
        mdToDeltaCheck(
          '''
Foo *bar
baz*
====''',
          [
            Operation.insert('Foo '),
            Operation.insert('bar baz', Attribute.italic.toJson()),
            Operation.insert('\n', Attribute.h1.toJson()),
          ],
        );
      });
      // issue with markdown parser
      test('52', () {
        mdToDeltaCheck(
          '''
  Foo *bar
baz*\t
====''',
          [
            Operation.insert('Foo '),
            Operation.insert('bar baz', Attribute.italic.toJson()),
            Operation.insert('\n', Attribute.h1.toJson()),
          ],
        );
      }, skip: true);
      test('62', () {
        mdToDeltaCheck(
          '''
> Foo
---''',
          [
            Operation.insert('Foo'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
            Operation.insert(horizontalRule.toJson()),
            Operation.insert('\n'),
          ],
        );
      });
      test('69', () {
        mdToDeltaCheck(
          '''
- foo
-----''',
          [
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.ul.toJson()),
            Operation.insert(horizontalRule.toJson()),
            Operation.insert('\n'),
          ],
        );
      });

      // issue
      // https://github.com/dart-lang/markdown/pull/386
      test('72', () {
        mdToDeltaCheck(
          r'''
\> foo
------''',
          [
            Operation.insert('> foo'),
            Operation.insert('\n', Attribute.h2.toJson()),
          ],
        );
      }, skip: true);
    });

    group('4.7 Link reference definitions', () {
      test('161', () {
        mdToDeltaCheck(
          '''
[foo]: /url "title"

[foo]''',
          [
            Operation.insert('foo', LinkAttribute('/url').toJson()),
            Operation.insert('\n'),
          ],
        );
      });
      test('165', () {
        mdToDeltaCheck(
          '''
[foo]: /url '
title
line1
line2
'

[foo]''',
          [
            Operation.insert('foo', LinkAttribute('/url').toJson()),
            Operation.insert('\n'),
          ],
        );
      });
      test('166', () {
        mdToDeltaCheck(
          '''
[foo]: /url 'title

with blank line'

[foo]''',
          [
            Operation.insert("[foo]: /url 'title\n"),
            Operation.insert("with blank line'\n"),
            Operation.insert('[foo]'),
            Operation.insert('\n'),
          ],
        );
      }, skip: true);
    });

    group('4.8 Paragraphs', () {
      test('189', () {
        mdToDeltaCheck(
          '''
aaa

bbb''',
          [
            Operation.insert('aaa\n'),
            Operation.insert('bbb\n'),
          ],
        );
      });
      test('190', () {
        mdToDeltaCheck(
          '''
aaa
bbb

ccc
ddd''',
          [
            Operation.insert('aaa bbb\n'),
            Operation.insert('ccc ddd\n'),
          ],
        );
      });
      test('191', () {
        mdToDeltaCheck(
          '''
aaa


bbb''',
          [
            Operation.insert('aaa\n'),
            Operation.insert('bbb\n'),
          ],
        );
      });
      test('192', () {
        mdToDeltaCheck(
          '''
  aaa
 bbb''',
          [
            Operation.insert('aaa bbb\n'),
          ],
        );
      });
      test('193', () {
        mdToDeltaCheck(
          '''
aaa
             bbb
                                       ccc''',
          [
            Operation.insert('aaa bbb ccc\n'),
          ],
        );
      });
      test('194', () {
        mdToDeltaCheck(
          '''
   aaa
bbb''',
          [
            Operation.insert('aaa bbb\n'),
          ],
        );
      });
      test('195', () {
        mdToDeltaCheck(
          '''
    aaa
bbb''',
          [
            Operation.insert('aaa'),
            Operation.insert('\n', Attribute.codeBlock.toJson()),
            Operation.insert('bbb\n'),
          ],
        );
      });
      test('196', () {
        mdToDeltaCheck(
          '''
aaa     
bbb     ''',
          [
            Operation.insert('aaa\n'),
            Operation.insert('bbb\n'),
          ],
        );
      });
    });
    group('4.9 Blank lines ', () {
      test('197', () {
        mdToDeltaCheck(
          '''


  

aaa
  

# aaa

  

''',
          [
            Operation.insert('aaa\n'),
            Operation.insert('aaa'),
            Operation.insert('\n', Attribute.h1.toJson()),
          ],
        );
      });
    });
    group('5.1 Block quotes', () {
      // EXCLUSIVE BLOCKS
      test('206', () {
        mdToDeltaCheck(
          '''
> # Foo
> bar
> baz''',
          [
            Operation.insert('Foo'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
            Operation.insert('bar'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
            Operation.insert('baz'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
          ],
        );
      });

      test('207', () {
        mdToDeltaCheck(
          '''
># Foo
>bar
> baz''',
          [
            Operation.insert('Foo'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
            Operation.insert('bar'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
            Operation.insert('baz'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
          ],
        );
      });

      test('208', () {
        mdToDeltaCheck(
          '''
   > # Foo
   > bar
 > baz
''',
          [
            Operation.insert('Foo'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
            Operation.insert('bar'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
            Operation.insert('baz'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
          ],
        );
      });

      test('209', () {
        mdToDeltaCheck(
          '''
    > # Foo
    > bar
    > baz
''',
          [
            Operation.insert('> # Foo'),
            Operation.insert('\n', Attribute.codeBlock.toJson()),
            Operation.insert('> bar'),
            Operation.insert('\n', Attribute.codeBlock.toJson()),
            Operation.insert('> baz'),
            Operation.insert('\n', Attribute.codeBlock.toJson()),
          ],
        );
      });

      test('210', () {
        mdToDeltaCheck(
          '''
> # Foo
> bar
baz
''',
          [
            Operation.insert('Foo'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
            Operation.insert('bar'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
            Operation.insert('baz'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
          ],
        );
      });

      test('211', () {
        mdToDeltaCheck(
          '''
> bar
baz
> foo
''',
          [
            Operation.insert('bar'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
            Operation.insert('baz'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
          ],
        );
      });
      test('212', () {
        mdToDeltaCheck(
          '''
> foo
---
''',
          [
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
            Operation.insert(horizontalRule.toJson()),
            Operation.insert('\n'),
          ],
        );
      });
      test('213', () {
        mdToDeltaCheck(
          '''
> - foo
- bar
''',
          [
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
            Operation.insert('bar'),
            Operation.insert('\n', Attribute.ul.toJson()),
          ],
        );
      });
      test('214', () {
        mdToDeltaCheck(
          '''
>     foo
    bar
''',
          [
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
            Operation.insert('bar'),
            Operation.insert('\n', Attribute.codeBlock.toJson()),
          ],
        );
      });
      test('215', () {
        mdToDeltaCheck(
          '''
> ```
foo
```
''',
          [
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
          ],
        );
      }, skip: true);
      test('217', () {
        mdToDeltaCheck(
          '''
>
''',
          [
            Operation.insert('\n', Attribute.blockQuote.toJson()),
          ],
        );
      });
      test('218', () {
        mdToDeltaCheck(
          '''
>
>  
> 
''',
          [
            Operation.insert('\n', Attribute.blockQuote.toJson()),
          ],
        );
      });
      test('219', () {
        mdToDeltaCheck(
          '''
>
> foo
>  
''',
          [
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
          ],
        );
      });
      test('220', () {
        mdToDeltaCheck(
          '''
> foo

> bar
''',
          [
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
            Operation.insert('\n'),
            Operation.insert('bar'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
          ],
        );
      });
      test('223', () {
        mdToDeltaCheck(
          '''
foo
> bar
''',
          [
            Operation.insert('foo'),
            Operation.insert('\n'),
            Operation.insert('bar'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
          ],
        );
      });
      test('228', () {
        mdToDeltaCheck(
          '''
> > > foo
bar
''',
          [
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
            Operation.insert('bar'),
            Operation.insert('\n', Attribute.blockQuote.toJson()),
          ],
        );
      });
    });
    group('5.4 Lists', () {
      test('281', () {
        mdToDeltaCheck(
          '''
- foo
- bar
+ baz''',
          [
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.ul.toJson()),
            Operation.insert('bar'),
            Operation.insert('\n', Attribute.ul.toJson()),
            Operation.insert('baz'),
            Operation.insert('\n', Attribute.ul.toJson()),
          ],
        );
      });
      test('282', () {
        mdToDeltaCheck(
          '''
1. foo
2. bar
3) baz''',
          [
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.ol.toJson()),
            Operation.insert('bar'),
            Operation.insert('\n', Attribute.ol.toJson()),
            Operation.insert('baz'),
            Operation.insert('\n', Attribute.ol.toJson()),
          ],
        );
      });
      test('283', () {
        mdToDeltaCheck(
          '''
Foo
- bar
- baz''',
          [
            Operation.insert('Foo'),
            Operation.insert('\n'),
            Operation.insert('bar'),
            Operation.insert('\n', Attribute.ul.toJson()),
            Operation.insert('baz'),
            Operation.insert('\n', Attribute.ul.toJson()),
          ],
        );
      });
      // issue with parser
      test('284', () {
        mdToDeltaCheck(
          '''
The number of windows in my house is
14.  The number of doors is 6.''',
          [
            Operation.insert(
                'The number of windows in my house is 14.  The number of doors is 6.'),
            Operation.insert('\n'),
          ],
        );
      }, skip: true);
      test('286', () {
        mdToDeltaCheck(
          '''
- foo

- bar


- baz''',
          [
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.ul.toJson()),
            Operation.insert('bar'),
            Operation.insert('\n', Attribute.ul.toJson()),
            Operation.insert('baz'),
            Operation.insert('\n', Attribute.ul.toJson()),
          ],
        );
      });
      test('287', () {
        mdToDeltaCheck(
          '''
- foo
  - bar
    - baz''',
          [
            Operation.insert('foo'),
            Operation.insert('\n', Attribute.ul.toJson()),
            Operation.insert('bar'),
            Operation.insert(
                '\n', attrsToJson([Attribute.ul, IndentAttribute(level: 1)])),
            Operation.insert('baz'),
            Operation.insert(
                '\n', attrsToJson([Attribute.ul, IndentAttribute(level: 2)])),
          ],
        );
      });
      test('306', () {
        mdToDeltaCheck(
          '''
- a
  - b
  - c

- d
  - e
  - f''',
          [
            Operation.insert('a'),
            Operation.insert('\n', Attribute.ul.toJson()),
            Operation.insert('b'),
            Operation.insert(
              '\n',
              attrsToJson([Attribute.ul, IndentAttribute(level: 1)]),
            ),
            Operation.insert('c'),
            Operation.insert(
              '\n',
              attrsToJson([Attribute.ul, IndentAttribute(level: 1)]),
            ),
            Operation.insert('d'),
            Operation.insert('\n', Attribute.ul.toJson()),
            Operation.insert('e'),
            Operation.insert(
                '\n', attrsToJson([Attribute.ul, IndentAttribute(level: 1)])),
            Operation.insert('f'),
            Operation.insert(
                '\n', attrsToJson([Attribute.ul, IndentAttribute(level: 1)])),
          ],
        );
      });
    });
  });
}
