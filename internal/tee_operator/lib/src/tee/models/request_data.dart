import 'dart:convert';

/// Request data model for TEE protocol requests
/// JSON serializable class for better structure and type safety
class ReclaimRequestData {
  final String url;
  final String method;
  final Map<String, String>? publicHeaders;
  final Map<String, String>? privateHeaders;
  final String? cookieStr;
  final String? authorisationHeader; // TEE expects this separately with British spelling
  final String? body;
  final String? geoLocation;
  final List<ResponseMatch>? responseMatches;
  final List<ResponseRedaction>? responseRedactions;
  final String? context;
  final Map<String, dynamic>? publicParamValues; // Note: field name is 'paramValues' in JSON
  final Map<String, dynamic>? privateParamValues; // Note: field name is 'paramValues' in JSON

  const ReclaimRequestData({
    required this.url,
    required this.method,
    this.publicHeaders,
    this.privateHeaders,
    this.cookieStr,
    this.authorisationHeader,
    this.body,
    this.geoLocation,
    this.responseMatches,
    this.responseRedactions,
    this.context,
    this.publicParamValues,
    this.privateParamValues,
  });

  /// Create ReclaimRequestData directly from claim request format
  /// This eliminates error-prone manual conversions and matches the WebView flow exactly
  factory ReclaimRequestData.fromClaimRequest(Map<String, dynamic> claimRequest) {
    final params = claimRequest['params'] as Map<String, dynamic>?;
    final secretParams = claimRequest['secretParams'] as Map<String, dynamic>?;

    if (params == null) {
      throw ArgumentError('Invalid claim request format - missing params, $claimRequest');
    }

    // Extract URL and method (required fields)
    final url = params['url']?.toString();
    final method = params['method']?.toString() ?? 'GET';

    if (url == null || url.isEmpty) {
      throw ArgumentError('URL cannot be empty');
    }

    // Extract public headers from params.headers
    Map<String, String>? publicHeaders;
    if (params['headers'] != null) {
      try {
        publicHeaders = Map<String, String>.from(params['headers'] as Map);
      } catch (e) {
        throw ArgumentError('Invalid headers format in params: $e');
      }
    }

    // Extract private data from secretParams
    Map<String, String>? privateHeaders;
    String? cookieStr;
    String? authorisationHeader;

    if (secretParams != null) {
      // Extract private headers
      if (secretParams['headers'] != null) {
        try {
          final headers = Map<String, String>.from(secretParams['headers'] as Map);
          // Handle Authorization header separately (Go expects it as authorisationHeader)
          if (headers.containsKey('Authorization')) {
            authorisationHeader = headers['Authorization'];
            headers.remove('Authorization');
          }
          privateHeaders = headers.isNotEmpty ? headers : null;
        } catch (e) {
          throw ArgumentError('Invalid headers format in secretParams: $e');
        }
      }

      // Extract cookie string
      if (secretParams['cookieStr'] != null) {
        cookieStr = secretParams['cookieStr'].toString();
      }

      // Extract explicit authorisation header if not already extracted
      if (authorisationHeader == null && secretParams['authorisationHeader'] != null) {
        authorisationHeader = secretParams['authorisationHeader'].toString();
      }
    }

    // Extract other optional fields
    final body = params['body']?.toString();
    final geoLocation = params['geoLocation']?.toString();

    // Convert context (can be String, Map, or null)
    String? contextStr;
    final contextRaw = claimRequest['context'];
    if (contextRaw != null && contextRaw.toString().isNotEmpty) {
      if (contextRaw is String) {
        contextStr = contextRaw.isNotEmpty ? contextRaw : null;
      } else if (contextRaw is Map) {
        contextStr = json.encode(contextRaw);
      } else {
        contextStr = contextRaw.toString();
      }
    }

    // Extract paramValues (both public and private)
    Map<String, dynamic>? publicParamValues;
    Map<String, dynamic>? privateParamValues;

    if (params['paramValues'] != null) {
      publicParamValues = params['paramValues'] as Map<String, dynamic>;
    }

    if (secretParams?['paramValues'] != null) {
      privateParamValues = secretParams!['paramValues'] as Map<String, dynamic>;
    }

    // Convert response matches and redactions
    final responseMatches = _convertMatches(params['responseMatches']);
    final responseRedactions = _convertRedactions(params['responseRedactions'] ?? params['redactions']);

    return ReclaimRequestData(
      url: url,
      method: method,
      publicHeaders: publicHeaders,
      privateHeaders: privateHeaders,
      cookieStr: cookieStr,
      authorisationHeader: authorisationHeader,
      body: body?.isNotEmpty == true ? body : null,
      geoLocation: geoLocation?.isNotEmpty == true ? geoLocation : null,
      responseMatches: responseMatches,
      responseRedactions: responseRedactions,
      context: contextStr,
      publicParamValues: publicParamValues,
      privateParamValues: privateParamValues,
    );
  }

  /// Convert to provider JSON format expected by native library
  /// This exactly matches the native attestor flow structure
  Map<String, dynamic> toProviderJson() {
    return {
      'name': 'http',
      'params': {
        'url': url,
        'method': method,
        if (body != null && body!.isNotEmpty) 'body': body,
        if (geoLocation != null) 'geoLocation': geoLocation,
        if (publicHeaders != null && publicHeaders!.isNotEmpty) 'headers': publicHeaders,
        if (responseMatches != null) 'responseMatches': responseMatches!.map((m) => m.toJson()).toList(),
        if (responseRedactions != null) 'responseRedactions': responseRedactions!.map((r) => r.toJson()).toList(),
        // Convert paramValues to Map<String, String> for Go compatibility
        if (publicParamValues != null && publicParamValues!.isNotEmpty)
          'paramValues': publicParamValues!.map((key, value) => MapEntry(key, value.toString())),
      },
      'secretParams': {
        if (privateHeaders != null && privateHeaders!.isNotEmpty) 'headers': privateHeaders,
        if (cookieStr != null && cookieStr!.isNotEmpty) 'cookieStr': cookieStr,
        if (authorisationHeader != null && authorisationHeader!.isNotEmpty) 'authorisationHeader': authorisationHeader,
        // Convert privateParamValues to Map<String, String> for Go compatibility
        if (privateParamValues != null && privateParamValues!.isNotEmpty)
          'paramValues': privateParamValues!.map((key, value) => MapEntry(key, value.toString())),
      },
      if (context != null) 'context': context,
    };
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'method': method,
    if (publicHeaders != null) 'publicHeaders': publicHeaders,
    if (privateHeaders != null) 'privateHeaders': privateHeaders,
    if (cookieStr != null) 'cookieStr': cookieStr,
    if (authorisationHeader != null) 'authorisationHeader': authorisationHeader,
    if (body != null) 'body': body,
    if (geoLocation != null) 'geoLocation': geoLocation,
    if (responseMatches != null) 'responseMatches': responseMatches!.map((m) => m.toJson()).toList(),
    if (responseRedactions != null) 'responseRedactions': responseRedactions!.map((r) => r.toJson()).toList(),
    if (context != null) 'context': context,
    if (publicParamValues != null) 'publicParamValues': publicParamValues,
    if (privateParamValues != null) 'privateParamValues': privateParamValues,
  };

  factory ReclaimRequestData.fromJson(Map<String, dynamic> json) {
    return ReclaimRequestData(
      url: json['url'] as String,
      method: json['method'] as String,
      publicHeaders: json['publicHeaders'] != null ? Map<String, String>.from(json['publicHeaders'] as Map) : null,
      privateHeaders: json['privateHeaders'] != null ? Map<String, String>.from(json['privateHeaders'] as Map) : null,
      cookieStr: json['cookieStr'] as String?,
      authorisationHeader: json['authorisationHeader'] as String?,
      body: json['body'] as String?,
      geoLocation: json['geoLocation'] as String?,
      responseMatches: json['responseMatches'] != null
          ? (json['responseMatches'] as List).map((e) => ResponseMatch.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      responseRedactions: json['responseRedactions'] != null
          ? (json['responseRedactions'] as List)
                .map((e) => ResponseRedaction.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      context: json['context'] as String?,
      publicParamValues: json['publicParamValues'] as Map<String, dynamic>?,
      privateParamValues: json['privateParamValues'] as Map<String, dynamic>?,
    );
  }

  /// Convert dynamic redactions to typed ResponseRedaction objects
  /// Handles both 'responseRedactions' and 'redactions' field names
  static List<ResponseRedaction> _convertRedactions(dynamic redactions) {
    if (redactions == null) {
      return [];
    }

    final list = redactions as List;
    return list
        .map((r) {
          if (r is Map) {
            // Create ResponseRedaction with all available fields
            return ResponseRedaction(
              jsonPath: r['jsonPath']?.toString(),
              xPath: r['xPath']?.toString(),
              regex: r['regex']?.toString(),
              hash: r['hash']?.toString(), // Critical for OPRF!
            );
          }
          return null;
        })
        .where((r) => r != null)
        .cast<ResponseRedaction>()
        .toList();
  }

  /// Convert dynamic matches to typed ResponseMatch objects
  static List<ResponseMatch> _convertMatches(dynamic matches) {
    if (matches == null) {
      return [];
    }

    final list = matches as List;
    return list
        .map((m) {
          if (m is Map) {
            return ResponseMatch(value: m['value']?.toString() ?? '', type: m['type']?.toString() ?? 'contains');
          }
          return null;
        })
        .where((m) => m != null)
        .cast<ResponseMatch>()
        .toList();
  }
}

/// Response match configuration
class ResponseMatch {
  final String value;
  final String type;

  const ResponseMatch({required this.value, required this.type});

  Map<String, dynamic> toJson() => {'value': value, 'type': type};

  factory ResponseMatch.fromJson(Map<String, dynamic> json) {
    return ResponseMatch(value: json['value'] as String, type: json['type'] as String);
  }
}

/// Response redaction configuration
class ResponseRedaction {
  final String? jsonPath;
  final String? xPath;
  final String? regex;
  final String? hash;

  const ResponseRedaction({this.jsonPath, this.xPath, this.regex, this.hash});

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{};
    if (jsonPath != null) result['jsonPath'] = jsonPath;
    if (xPath != null) result['xPath'] = xPath;
    if (regex != null) result['regex'] = regex;
    if (hash != null) result['hash'] = hash;
    return result;
  }

  factory ResponseRedaction.fromJson(Map<String, dynamic> json) {
    return ResponseRedaction(
      jsonPath: json['jsonPath'] as String?,
      xPath: json['xPath'] as String?,
      regex: json['regex'] as String?,
      hash: json['hash'] as String?,
    );
  }
}
