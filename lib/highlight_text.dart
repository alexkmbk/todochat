import 'package:flutter/material.dart';

extension UtilExtensions on String {
  List<String> multiSplit(Iterable<String> delimeters) => delimeters.isEmpty
      ? [this]
      : split(RegExp(delimeters.map(RegExp.escape).join('|')));
}

List<String> getHighlightedWords(String? str, [ignoreCase = true]) {
  List<String> res = [];

  if (str == null) {
    return res;
  }
  List<String> words = str.split(' ');

  for (var word in words) {
    if (ignoreCase) {
      word = word.toLowerCase();
    }
    if (!res.contains(word)) res.add(word);
  }
  return res;
}

class HighlightText extends StatelessWidget {
  final String text;
  final List<String> words;
  final TextStyle? textStyle;
  final TextStyle? highlightStyle;
  final Color? highlightColor;
  final bool ignoreCase;
  final int? maxLines;
  final TextSpan? leading;

  HighlightText({
    Key? key,
    required this.text,
    required this.words,
    this.textStyle,
    this.highlightColor,
    TextStyle? highlightStyle,
    this.ignoreCase = true,
    this.maxLines,
    this.leading,
  })  : assert(
          highlightColor == null || highlightStyle == null,
          'highlightColor and highlightStyle cannot be provided at same time.',
        ),
        highlightStyle = highlightStyle ??
            textStyle?.copyWith(color: highlightColor) ??
            TextStyle(color: highlightColor),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return Text(text, style: textStyle);
    }
    List<TextSpan> spans = [];
    if (leading != null) {
      spans.add(leading!);
    }

    var textWords = text.multiSplit([' ', '.', ',', '?', ':']);

    for (var word in textWords) {
      var wordToSearch = ignoreCase ? word.toLowerCase() : word;
      if (wordToSearch.isEmpty) {
        spans.add(_normalSpan(' '));
      } else if (words.contains(wordToSearch)) {
        spans.add(_highlightSpan('$word '));
      } else {
        spans.add(_normalSpan('$word '));
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      overflow: TextOverflow.ellipsis,
      maxLines: maxLines,
    );
  }

  TextSpan _highlightSpan(String content) {
    return TextSpan(text: content, style: highlightStyle);
  }

  TextSpan _normalSpan(String content) {
    return TextSpan(text: content, style: textStyle);
  }
}
