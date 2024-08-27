// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:markdown/markdown.dart';
import 'package:markdown/src/charcode.dart';
import 'package:markdown/src/patterns.dart';
import 'package:markdown/src/util.dart';

/// this is a copy-paste from blockquote_syntax (added acceptParagraphContinuation flag)
/// Parses email-style blockquotes: `> quote`.
class CustomBlockquoteSyntax extends BlockSyntax {
  @override
  RegExp get pattern => blockquotePattern;

  const CustomBlockquoteSyntax({
    required this.acceptParagraphContinuation,
  });

  // if true, paragraph procedeing blockquote gets merged into the quote (unless it's empty)
  final bool acceptParagraphContinuation;

  /// Whether this blockquote ends with a lazy continuation line.
  // The definition of lazy continuation lines:
  // https://spec.commonmark.org/0.30/#lazy-continuation-line
  static var _lazyContinuation = false;
  @override
  List<Line> parseChildLines(BlockParser parser) {
    // Grab all of the lines that form the blockquote, stripping off the ">".
    final childLines = <Line>[];
    _lazyContinuation = false;

    while (!parser.isDone) {
      final currentLine = parser.current;
      final match = pattern.firstMatch(parser.current.content);
      if (match != null) {
        // A block quote marker consists of a `>` together with an optional
        // following space of indentation, see
        // https://spec.commonmark.org/0.30/#block-quote-marker.
        final markerStart = match.match.indexOf('>');
        int markerEnd;
        if (currentLine.content.length > 1) {
          var hasSpace = false;
          // Check if there is a following space if the marker is not at the end
          // of this line.
          if (markerStart < currentLine.content.length - 1) {
            final nextChar = currentLine.content.codeUnitAt(markerStart + 1);
            hasSpace = nextChar == $tab || nextChar == $space;
          }
          markerEnd = markerStart + (hasSpace ? 2 : 1);
        } else {
          markerEnd = markerStart + 1;
        }
        childLines.add(Line(currentLine.content.substring(markerEnd)));
        parser.advance();
        _lazyContinuation = false;
        continue;
      }

      final lastLine = childLines.last;

      // A paragraph continuation is OK. This is content that cannot be parsed
      // as any other syntax except Paragraph, and it doesn't match the bar in
      // a Setext header.
      // Because indented code blocks cannot interrupt paragraphs, a line
      // matched CodeBlockSyntax is also paragraph continuation text.
      final otherMatched =
          parser.blockSyntaxes.firstWhere((s) => s.canParse(parser));
      if ((acceptParagraphContinuation &&
              otherMatched is ParagraphSyntax &&
              !lastLine.isBlankLine &&
              !codeFencePattern.hasMatch(lastLine.content)) ||
          (otherMatched is CodeBlockSyntax &&
              !indentPattern.hasMatch(lastLine.content))) {
        childLines.add(parser.current);
        _lazyContinuation = true;
        parser.advance();
      } else {
        break;
      }
    }

    return childLines;
  }

  @override
  Node parse(BlockParser parser) {
    final childLines = parseChildLines(parser);

    // Recursively parse the contents of the blockquote.
    final children = BlockParser(childLines, parser.document).parseLines(
      // The setext heading underline cannot be a lazy continuation line in a
      // block quote.
      // https://spec.commonmark.org/0.30/#example-93
      disabledSetextHeading: _lazyContinuation,
      parentSyntax: this,
    );

    return Element('blockquote', children);
  }
}
