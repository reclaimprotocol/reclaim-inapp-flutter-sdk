import 'dart:async';
import 'dart:convert';

import '../constants.dart';
import '../logging/logging.dart';
import '../overrides/overrides.dart';
import '../services/base_http.dart';
import '../utils/http/http.dart';
import 'reclaim_app_theme.dart';

class AppInfo extends ReclaimOverride<AppInfo> {
  final String appName;
  final String appImage;
  final bool isRecurring;
  final ReclaimAppThemeInfo? theme;

  const AppInfo({required this.appName, required this.appImage, required this.isRecurring, this.theme});

  factory AppInfo.fromJson(Map<String, dynamic> json) {
    return AppInfo(
      appName: json['name']?.toString() ?? '',
      appImage: json['appImageUrl']?.toString() ?? '',
      isRecurring: json['isRecurring'] == true || json['isRecurring']?.toString().toLowerCase() == 'true',
      theme: json['themeInfo'] != null ? ReclaimAppThemeInfo.fromJson(json['themeInfo']) : null,
    );
  }

  static final _cachedAppInfo = <String, Completer<AppInfo>>{};

  static Future<AppInfo> fromAppId(String appId) async {
    final appInfo = ReclaimOverrides.appInfo;
    if (appInfo != null) {
      return appInfo;
    }
    final logger = logging.child('AppInfo.fromAppId');
    try {
      if (_cachedAppInfo.containsKey(appId)) {
        return _cachedAppInfo[appId]!.future;
      }
      final completer = Completer<AppInfo>();
      _cachedAppInfo[appId] = completer;
      final client = reclaimHttpBaseClient;
      final response = await client.get(Uri.parse('${ReclaimUrls.SDK_API_BASE_URL}/api/applications/info/$appId'));
      if (!response.isSuccess) {
        throw Exception('Failed to fetch app info: ${response.statusCode} - ${response.body}');
      }
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['application'] == null) {
        throw Exception('Application data is null');
      }
      final appInfo = AppInfo.fromJson(data['application']);
      completer.complete(appInfo);
      return appInfo;
    } catch (error, stackTrace) {
      logger.severe('Error fetching app name', error, stackTrace);
      final fallbackAppInfo = const AppInfo(appName: '', appImage: '', isRecurring: false);
      if (_cachedAppInfo.containsKey(appId)) {
        final completer = _cachedAppInfo.remove(appId);
        if (completer != null && !completer.isCompleted) {
          completer.complete(fallbackAppInfo);
        }
      }
      return fallbackAppInfo;
    }
  }

  @override
  AppInfo copyWith({String? appName, String? appImage, bool? isRecurring, ReclaimAppThemeInfo? theme}) {
    return AppInfo(
      appName: appName ?? this.appName,
      appImage: appImage ?? this.appImage,
      isRecurring: isRecurring ?? this.isRecurring,
      theme: theme ?? this.theme,
    );
  }
}
