String formatParamsLabel(final String input) {
  String text = input;
  text = text.trim();
  if (text.toUpperCase() == text) {
    text = text.toLowerCase();
  }
  text = text.replaceAll(RegExp(r'\s+'), '_');
  List<String> words = text.split(RegExp(r'(?=[A-Z])|_'));
  text = words
      .map((word) {
        if (word.isEmpty) return '';
        return '${word[0].toUpperCase()}${word.toLowerCase().substring(1)}';
      })
      .join(' ');
  return text;
}

String formatParamsValue(final String input) {
  String text = input;
  text = text.trim();
  if (text.length > 2 && text.startsWith('"') && text.endsWith('"')) {
    text = text.substring(1, text.length - 1).trim();
  }
  return text;
}
