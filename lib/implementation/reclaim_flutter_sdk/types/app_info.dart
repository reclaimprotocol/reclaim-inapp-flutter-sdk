import '../logging/logging.dart';
import '../overrides/overrides.dart';
import '../utils/dio.dart';

class AppInfo
    extends ReclaimOverride<
        AppInfo> {
  final String
      appName;
  final String
      appImage;
  final bool
      isRecurring;

  const AppInfo(
      {required this.appName,
      required this.appImage,
      required this.isRecurring});

  factory AppInfo.fromJson(
      Map<String, dynamic>
          json) {
    return AppInfo(
      appName:
          json['application']['name'].toString(),
      appImage:
          json['application']['appImageUrl']?.toString() ?? '',
      isRecurring:
          json['application']['isRecurring'] == true || json['application']['isRecurring']?.toString().toLowerCase() == 'true',
    );
  }

  static final _cachedAppInfo =
      <String,
          AppInfo>{};

  static Future<AppInfo>
      fromAppId(String appId) async {
    final appInfo =
        ReclaimOverrides.appInfo;
    if (appInfo !=
        null) {
      return appInfo;
    }
    final logger =
        logging.child('AppInfo.fromAppId');
    try {
      if (_cachedAppInfo.containsKey(appId)) {
        return _cachedAppInfo[appId]!;
      }
      final dio =
          buildDio();
      final response =
          await dio.get<Map<String, dynamic>>('https://api.reclaimprotocol.org/api/applications/info/$appId');
      final Map<String, dynamic>
          data =
          response.data!;
      final appInfo =
          AppInfo.fromJson(data);
      _cachedAppInfo[appId] =
          appInfo;
      return appInfo;
    } catch (error, stackTrace) {
      logger.severe(
          'Error fetching app name',
          error,
          stackTrace);
      return AppInfo(
          appName: '',
          appImage: '',
          isRecurring: false);
    }
  }

  @override
  AppInfo
      copyWith({
    String?
        appName,
    String?
        appImage,
    bool?
        isRecurring,
  }) {
    return AppInfo(
      appName:
          appName ?? this.appName,
      appImage:
          appImage ?? this.appImage,
      isRecurring:
          isRecurring ?? this.isRecurring,
    );
  }
}
