import 'package:material_ui/material_ui.dart';

final _markup = RegExp(
  r'\*\*(.+?)\*\*|\[(.+?)\]\((https?://[^)\s]+)\)',
  dotAll: true,
);

String plainMessage(String value) {
  return value
      .replaceAllMapped(_markup, (match) {
        return match.group(1) ?? match.group(2) ?? '';
      })
      .replaceAll('**', '')
      .replaceAll('`', '');
}

class MessageText extends StatelessWidget {
  const MessageText({super.key, required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(style: style, children: _spans(text, style)),
    );
  }
}

List<InlineSpan> _spans(String text, TextStyle style) {
  final spans = <InlineSpan>[];
  var index = 0;
  for (final match in _markup.allMatches(text)) {
    if (match.start > index) {
      spans.add(TextSpan(text: text.substring(index, match.start)));
    }
    final bold = match.group(1);
    if (bold != null) {
      spans.add(TextSpan(text: bold, style: style.copyWith(fontWeight: FontWeight.w700)));
    } else {
      spans.add(
        TextSpan(
          text: match.group(2),
          style: style.copyWith(
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
          ),
        ),
      );
    }
    index = match.end;
  }
  if (index < text.length) {
    spans.add(TextSpan(text: text.substring(index)));
  }
  if (spans.isEmpty) {
    spans.add(TextSpan(text: text));
  }
  return spans;
}
