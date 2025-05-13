
import 'package:dio/dio.dart';
import 'package:reclaim_flutter_sdk/utils/source/source.dart';

class ApiClientInsertionInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    options.headers['reclaim-api-client'] = await getClientSource();
    super.onRequest(options, handler);
  }
}