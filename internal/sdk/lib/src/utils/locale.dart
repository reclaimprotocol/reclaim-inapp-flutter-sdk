import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

Locale? parseLocaleName(String? localeName) {
  if (localeName == null || localeName.isEmpty) return null;
  String name = localeName;
  try {
    name = Intl.canonicalizedLocale(name.toString());
  } catch (e, s) {
    debugPrint('[WARNING] $e');
    debugPrintStack(stackTrace: s);
  }
  final parts = name.split('_');
  if (parts.isEmpty) return null;
  final first = parts.firstOrNull;
  if (first == null || first.isEmpty) return null;
  final second = parts.length > 1 ? parts[1] : null;
  return Locale(first, second);
}
