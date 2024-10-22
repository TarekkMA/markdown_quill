import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

void main() {
  test('softLineBreak + link', () {
    // given
    const input = '''
A text
[a link](https://flutter.dev)
''';

    // when
    final delta = MarkdownToDelta(
      markdownDocument: md.Document(
        encodeHtml: false,
      ),
      softLineBreak: true,
    ).convert(input);

    // then
    expect(delta.operations, [
      Operation.insert('A text\n'),
      Operation.insert('a link', {'link': 'https://flutter.dev'}),
      Operation.insert('\n'),
    ]);
  });

  test('softLineBreak + link (an extra line at the end)', () {
    // given
    const input = '''
A text
[a link](https://flutter.dev)
test!
''';

    // when
    final delta = MarkdownToDelta(
      markdownDocument: md.Document(
        encodeHtml: false,
      ),
      softLineBreak: true,
    ).convert(input);

    // then
    expect(delta.operations, [
      Operation.insert('A text\n'),
      Operation.insert('a link', {'link': 'https://flutter.dev'}),
      Operation.insert('\ntest!\n'),
    ]);
  });
}
