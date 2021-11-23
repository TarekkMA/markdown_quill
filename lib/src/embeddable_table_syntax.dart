import 'package:charcode/charcode.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:markdown/markdown.dart';

/// Parses tables.
class EmbeddableTableSyntax extends BlockSyntax {
  static const _base = TableSyntax();

  @override
  bool canEndBlock(BlockParser parser) => false;

  @override
  RegExp get pattern => _base.pattern;

  const EmbeddableTableSyntax();

  @override
  bool canParse(BlockParser parser) => _base.canParse(parser);

  /// Parses a table into its three parts:
  ///
  /// * a head row of head cells (`<th>` cells)
  /// * a divider of hyphens and pipes (not rendered)
  /// * many body rows of body cells (`<td>` cells)
  @override
  Node? parse(BlockParser parser) {
    final columnCount = _columnCount(parser.next!);
    final headCells = _columnCount(parser.current);
    final valBuf = StringBuffer('${parser.current}\n${parser.next!}');
    parser.advance();
    if (columnCount != headCells) {
      return null;
    }

    // advance header and divider of hyphens.
    parser.advance();

    while (!parser.isDone && !BlockSyntax.isAtBlockEnd(parser)) {
      valBuf.write('\n${parser.current}');
      parser.advance();
    }

    return Element.empty(EmbeddableTable.tableType)
      ..attributes['data'] = valBuf.toString();
  }

  int _columnCount(String line) {
    var startIndex = _walkPastOpeningPipe(line);

    var endIndex = line.length - 1;
    while (endIndex > 0) {
      var ch = line.codeUnitAt(endIndex);
      if (ch == $pipe) {
        endIndex--;
        break;
      }
      if (ch != $space && ch != $tab) {
        break;
      }
      endIndex--;
    }

    return line.substring(startIndex, endIndex + 1).split('|').length;
  }

  int _walkPastWhitespace(String line, int index) {
    while (index < line.length) {
      var ch = line.codeUnitAt(index);
      if (ch != $space && ch != $tab) {
        break;
      }
      index++;
    }
    return index;
  }

  int _walkPastOpeningPipe(String line) {
    var index = 0;
    while (index < line.length) {
      var ch = line.codeUnitAt(index);
      if (ch == $pipe) {
        index++;
        index = _walkPastWhitespace(line, index);
      }
      if (ch != $space && ch != $tab) {
        // No leading pipe.
        break;
      }
      index++;
    }
    return index;
  }
}

class EmbeddableTable extends BlockEmbed {
  static const tableType = 'x-embed-table';

  EmbeddableTable(String data) : super(tableType, data);

  static EmbeddableTable fromMdSyntax(Map<String, String> attributes) =>
      EmbeddableTable(attributes['data']!);

  static void toMdSyntax(Embed embed, StringSink out) {
    out
      ..writeln(embed.value.data)
      ..writeln();
  }
}
