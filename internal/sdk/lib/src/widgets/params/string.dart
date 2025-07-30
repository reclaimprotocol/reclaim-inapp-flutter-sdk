import 'dart:convert';
import 'package:intl/intl.dart' show Intl;

import '../../logging/logging.dart';

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

String? formatJsonValueAsHumanizedSummary(String value) {
  final log = logging.child('formatJsonValueAsHumanizedSummary');
  try {
    final input = value.trim();
    if (input.length >= 2 && input.startsWith('"') && input.endsWith('"')) {
      return formatJsonValueAsHumanizedSummary(input.substring(1, input.length - 1));
    }
    if (['nan', 'null', 'undefined'].contains(input.toString().trim().toLowerCase())) {
      return 'Not available';
    }
    if (['inf', '-inf', 'infinity', '-infinity'].contains(input.toString().trim().toLowerCase())) {
      return 'Infinite';
    }

    final data = json.decode(input);

    if (data is Map || data is List) {
      if (data is List && data.length == 1) {
        final first = data.first;
        if (first is String) {
          return formatJsonValueAsHumanizedSummary(first);
        }
        try {
          final value = formatJsonValueAsHumanizedSummary(json.encode(first));
          if (value != null) return value;
        } on FormatException catch (_) {
          // continue
        }
      }
      final count = () {
        if (data is Map) return data.keys.length;
        if (data is List) return data.length;
        return 0;
      }();
      return Intl.plural(count, zero: 'No items', one: '1 item', other: '$count items');
    }
    if (data is bool) {
      return Intl.select(data, {true: 'Yes', false: 'No'});
    }
    if (data is num) {
      if (data.isInfinite) return 'Infinite';
      if (data.isNaN) return 'Not available';
      return Intl.plural(data, zero: '0', one: '1', other: data.toString());
    }

    return data.toString();
  } on FormatException catch (_) {
    return null;
  } catch (e, s) {
    log.severe('Failed to format JSON value as humanized summary', e, s);
  }
  return null;
}

bool _isFormattedAsCollection(final String value) {
  final words = value.split(' ');
  if (words.length != 2) return false;
  return ['item', 'items'].any((e) => e == words.last);
}

bool isValueCollection(final String input) {
  final value = formatJsonValueAsHumanizedSummary(input);
  if (value == null) return false;
  return _isFormattedAsCollection(value) && !_isFormattedAsCollection(input);
}

String formatParamsValue(final String input, {final bool humanize = true}) {
  if (humanize) {
    final humanizedSummary = formatJsonValueAsHumanizedSummary(input);
    if (humanizedSummary != null) {
      return humanizedSummary;
    }
  }

  String text = input;
  text = text.trim();
  if (text.length > 2 && text.startsWith('"') && text.endsWith('"')) {
    text = text.substring(1, text.length - 1).trim();
  }

  if (text.isEmpty) return 'Empty';

  return text;
}
