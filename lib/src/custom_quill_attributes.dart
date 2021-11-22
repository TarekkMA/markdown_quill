import 'package:flutter_quill/flutter_quill.dart';

/// Custom attribute to save the language of codeblock
class CodeBlockLanguageAttribute extends Attribute<String?> {
  static const attrKey = 'x-md-codeblock-lang';

  CodeBlockLanguageAttribute(String? value)
      : super(attrKey, AttributeScope.IGNORE, value);
}