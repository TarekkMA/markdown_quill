import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/models/documents/nodes/block.dart';
import 'package:flutter_quill/models/documents/nodes/container.dart';
import 'package:flutter_quill/models/documents/nodes/line.dart';
import 'package:flutter_quill/models/documents/nodes/node.dart';
import 'package:flutter_quill/models/documents/style.dart';

/// Convertor from [Delta] to quill Markdown string.
class DeltaToMarkdown extends Converter<Delta, String> {
  @override
  String convert(Delta input) {
    final quillDocument = Document.fromDelta(input);
    final root = _Root.fromQuill(quillDocument.root);

    final outBuffer = _NodeVisitorImpl().visitRoot(root);

    return outBuffer.toString();
  }
}

class _AttributeHandler {
  _AttributeHandler({
    this.beforeContent,
    this.afterContent,
  });

  final void Function(
    Attribute<Object?> attribute,
    Map<String, Attribute<Object?>> attributes,
    StringSink output,
  )? beforeContent;
  final void Function(
    Attribute<Object?> attribute,
    Map<String, Attribute<Object?>> attributes,
    StringSink output,
  )? afterContent;
}

extension on Object? {
  T? asNullable<T>() {
    final self = this;
    return self == null ? null : self as T;
  }
}

class _NodeVisitorImpl implements _NodeVisitor<StringSink> {
  final Map<String, _AttributeHandler> _blockAttrsHandlers = {
    Attribute.codeBlock.key: _AttributeHandler(
      beforeContent: (attribute, attributes, output) => output.writeln('```'),
      afterContent: (attribute, attributes, output) => output.writeln('```'),
    ),
  };

  final Map<String, _AttributeHandler> _lineAttrsHandlers = {
    Attribute.header.key: _AttributeHandler(
      beforeContent: (attribute, attributes, output) {
        output
          ..write('#' * (attribute.value.asNullable<int>() ?? 1))
          ..write(' ');
      },
    ),
    Attribute.blockQuote.key: _AttributeHandler(
      beforeContent: (attribute, attributes, output) => output.write('> '),
    ),
    Attribute.list.key: _AttributeHandler(
      beforeContent: (attribute, attributes, output) {
        final indentLevel =
            attributes[Attribute.indent.key]?.value.asNullable<int>() ?? 0;
        final isNumbered = attribute.value == 'ordered';
        output
          ..write((isNumbered ? '   ' : '  ') * indentLevel)
          ..write('${isNumbered ? '1.' : '-'} ');
      },
    ),
  };

  final Map<String, _AttributeHandler> _textAttrsHandlers = {
    Attribute.italic.key: _AttributeHandler(
      beforeContent: (attribute, attributes, output) => output.write('*'),
      afterContent: (attribute, attributes, output) => output.write('*'),
    ),
    Attribute.bold.key: _AttributeHandler(
      beforeContent: (attribute, attributes, output) => output.write('**'),
      afterContent: (attribute, attributes, output) => output.write('**'),
    ),
    Attribute.strikeThrough.key: _AttributeHandler(
      beforeContent: (attribute, attributes, output) => output.write('~~'),
      afterContent: (attribute, attributes, output) => output.write('~~'),
    ),
    Attribute.inlineCode.key: _AttributeHandler(
      beforeContent: (attribute, attributes, output) => output.write('`'),
      afterContent: (attribute, attributes, output) => output.write('`'),
    ),
    Attribute.link.key: _AttributeHandler(
      beforeContent: (attribute, attributes, output) => output.write('['),
      afterContent: (attribute, attributes, output) =>
          output.write('](${attribute.value.asNullable<String>() ?? ''})'),
    ),
  };

  @override
  StringSink visitRoot(_Root root, [StringSink? output]) {
    final out = output ??= StringBuffer();
    for (final container in root.children) {
      container.accept(this, out);
    }
    return out;
  }

  @override
  StringSink visitBlock(_Block block, [StringSink? output]) {
    final out = output ??= StringBuffer();
    final style = block.style;
    _handleAttribute(_blockAttrsHandlers, style, output, () {
      for (final line in block.children) {
        line.accept(this, out);
      }
    });
    return out;
  }

  @override
  StringSink visitLine(_Line line, [StringSink? output]) {
    final out = output ??= StringBuffer();
    final style = line.style;
    _handleAttribute(_lineAttrsHandlers, style, output, () {
      for (final leaf in line.children) {
        leaf.accept(this, out);
      }
    });
    if (style.isInline) {
      out.writeln();
    }
    out.writeln();
    return out;
  }

  @override
  StringSink visitText(_Text text, [StringSink? output]) {
    final out = output ??= StringBuffer();
    final style = text.style;
    _handleAttribute(_textAttrsHandlers, style, output, () {
      out.write(text.value);
    });
    return out;
  }

  @override
  StringSink visitEmbed(_Embed embed, [StringSink? output]) {
    final out = output ??= StringBuffer();

    final type = embed.value.type;
    final dynamic data = embed.value.data;

    if (type == BlockEmbed.imageType) {
      out.write('![]($data)');
    } else if (type == BlockEmbed.horizontalRuleType) {
      // adds new line after it
      // make --- separated so it doesn't get rendered as header
      out.writeln('- - -');
    }

    return out;
  }

  void _handleAttribute(
    Map<String, _AttributeHandler> handlers,
    Style style,
    StringSink output,
    VoidCallback contentHandler,
  ) {
    final handlersToUse = style.attributes.entries
        .where((entry) => handlers.containsKey(entry.key))
        .map((entry) => MapEntry(entry.key, handlers[entry.key]!));
    final attrs = style.attributes;
    for (final handlerEntry in handlersToUse) {
      handlerEntry.value.beforeContent?.call(
        attrs[handlerEntry.key]!,
        attrs,
        output,
      );
    }
    contentHandler();
    for (final handlerEntry in handlersToUse) {
      handlerEntry.value.afterContent?.call(
        attrs[handlerEntry.key]!,
        attrs,
        output,
      );
    }
  }
}

//// AST with visitor

@optionalTypeArgs
abstract class _NodeVisitor<T> {
  const _NodeVisitor._();

  T visitRoot(_Root root, [T? context]);

  T visitBlock(_Block block, [T? context]);

  T visitLine(_Line line, [T? context]);

  T visitText(_Text text, [T? context]);

  T visitEmbed(_Embed embed, [T? context]);
}

abstract class _Node {
  R accept<R>(_NodeVisitor<R> visitor, [R? context]);
}

class _Root extends _Node {
  _Root(this.children, this.style);

  factory _Root.fromQuill(Root root) {
    return _Root(
      root.children.cast<Container>().map(_Container.fromQuill).toList(),
      root.style,
    );
  }

  final List<_Container> children;
  final Style style;

  @override
  R accept<R>(_NodeVisitor<R> visitor, [R? context]) {
    return visitor.visitRoot(this, context);
  }
}

abstract class _Container<T> extends _Node {
  _Container(this.children, this.style);

  static _Container fromQuill(Container container) {
    if (container is Line) return _Line.fromQuill(container);
    if (container is Block) return _Block.fromQuill(container);
    throw Exception('Unknown type ${container.runtimeType}');
  }

  final List<T> children;
  final Style style;
}

class _Block extends _Container<_Line> {
  _Block(List<_Line> lines, Style style) : super(lines, style);

  factory _Block.fromQuill(Block block) {
    return _Block(
      block.children.cast<Line>().map((line) => _Line.fromQuill(line)).toList(),
      block.style,
    );
  }

  @override
  R accept<R>(_NodeVisitor<R> visitor, [R? context]) {
    return visitor.visitBlock(this, context);
  }
}

class _Line extends _Container<_Leaf> {
  _Line(List<_Leaf> leafs, Style style) : super(leafs, style);

  factory _Line.fromQuill(Line line) {
    return _Line(
      line.children.cast<Leaf>().map(_Leaf.fromQuill).toList(),
      line.style,
    );
  }

  @override
  R accept<R>(_NodeVisitor<R> visitor, [R? context]) {
    return visitor.visitLine(this, context);
  }
}

abstract class _Leaf<T> extends _Node {
  _Leaf(this.value, this.style);

  static _Leaf fromQuill(Leaf leaf) {
    if (leaf is Text) return _Text.fromQuill(leaf);
    if (leaf is Embed) return _Embed.fromQuill(leaf);
    throw Exception('Unknown type ${leaf.runtimeType}');
  }

  final T value;
  final Style style;
}

class _Text extends _Leaf<String> {
  _Text(String value, Style style) : super(value, style);

  factory _Text.fromQuill(Text text) => _Text(text.value, text.style);

  @override
  R accept<R>(_NodeVisitor<R> visitor, [R? context]) {
    return visitor.visitText(this, context);
  }
}

class _Embed extends _Leaf<Embeddable> {
  _Embed(Embeddable value, Style style) : super(value, style);

  factory _Embed.fromQuill(Embed embed) => _Embed(embed.value, embed.style);

  @override
  R accept<R>(_NodeVisitor<R> visitor, [R? context]) {
    return visitor.visitEmbed(this, context);
  }
}
