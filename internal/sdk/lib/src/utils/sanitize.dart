Map<K, V>? ensureMap<K, V>(dynamic data) {
  if (data is Map) {
    if (data is Map<K, V>) {
      return data;
    }
    return <K, V>{
      for (final entry in data.entries.where((e) => e.key is K && e.value is V)) (entry.key as K): entry.value as V,
    };
  }
  return null;
}

const _redacted = '[REDACTED]';

final _combinedSensitivePattern = RegExp(
  r'set-cookie\s*[:=]\s*[^\n;,]+|'
  r'(?<!set-)cookie\s*[:=]\s*[^\n]+|'
  r'authorization\s*[:=]\s*[^\n\r,}]+|'
  r'bearer\s+\S+|'
  r'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]+|'
  r'-----BEGIN[^-]*PRIVATE[^-]*KEY-----[\s\S]*?-----END[^-]*PRIVATE[^-]*KEY-----|'
  r'(?:secret|password|passwd|pwd|token|api[_-]?key|private[_-]?key|access[_-]?key|client[_-]?secret)\s*[:=]\s*\S+|'
  r'proof\s*[:=]\s*\S+|'
  r'proofString\s*[:=]\s*\S+|'
  r'(?:request|response)[Bb]ody\s*[:=]\s*\S+|'
  r'payload\s*[:=]\s*\S+|'
  r'body\s*[:=]\s*\S+|'
  // URL query params carrying PII — value runs until next `&`, whitespace, or
  // structural punctuation. Catches URL-encoded forms (e.g. `email=foo%40bar.com`)
  // that the plain-email pattern below would miss.
  r'(?:email|mail|phone|phone[_-]?number|mobile(?:[_-]?number)?|msisdn|first[_-]?name|last[_-]?name|full[_-]?name|dob|date[_-]?of[_-]?birth|birth[_-]?date|aadhaar|aadhar|aadhaar[_-]?number|pan|pan[_-]?number|ssn|passport(?:[_-]?number)?|account(?:[_-]?number)?|bank[_-]?account|ifsc|iban|card[_-]?number|cvv)\s*=\s*[^&\s,;}"\x27]+|'
  r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  caseSensitive: false,
);

/// Sanitize a log message by redacting sensitive information.
///
/// Redacts: cookies, authorization headers, bearer tokens, JWTs,
/// private keys, secrets/passwords/tokens, proof data, proofString,
/// requestBody/responseBody, payload, body, and emails.
String sanitizeLogMessage(String message) {
  try {
    return message.replaceAllMapped(_combinedSensitivePattern, (match) {
      final m = match[0]!;

      // Fast path for Keys separated by colon or equals
      int colonIdx = m.indexOf(':');
      int eqIdx = m.indexOf('=');
      int sepIdx = -1;

      if (colonIdx != -1 && eqIdx != -1) {
        sepIdx = colonIdx < eqIdx ? colonIdx : eqIdx;
      } else if (colonIdx != -1) {
        sepIdx = colonIdx;
      } else {
        sepIdx = eqIdx;
      }

      if (sepIdx != -1) {
        int prefixEnd = sepIdx + 1;
        while (prefixEnd < m.length && (m.codeUnitAt(prefixEnd) == 32 || m.codeUnitAt(prefixEnd) == 9)) {
          prefixEnd++; // Preserve whitespaces naturally
        }
        return '${m.substring(0, prefixEnd)}$_redacted';
      }

      // Fast path for bearer auth spaces
      if (m.toLowerCase().startsWith('bearer')) {
        int prefixEnd = 6;
        while (prefixEnd < m.length && (m.codeUnitAt(prefixEnd) == 32 || m.codeUnitAt(prefixEnd) == 9)) {
          prefixEnd++;
        }
        return '${m.substring(0, prefixEnd)}$_redacted';
      }

      // Valueless redacts (e.g. JWT, PEM, Email fallback)
      return _redacted;
    });
  } catch (_) {
    return message;
  }
}
