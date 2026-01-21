import 'package:dio/dio.dart';

import '../../l10n/provider.dart';
import '../../services/source/source.dart';

class ApiClientInsertionInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    options.headers['reclaim-api-client'] = await getClientSource();
    final localeString = ReclaimLocalizationProvider.lastKnownLocale?.toString();
    if (localeString != null) {
      options.headers['reclaim-locale'] = localeString;
    }
    super.onRequest(options, handler);
  }
}
