import 'package:markdown/markdown.dart' as md;

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
