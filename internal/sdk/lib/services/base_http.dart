import 'package:reclaim_flutter_sdk/utils/dio.dart';

final reclaimHttpBaseClient = buildDio()
  ..options.baseUrl = 'https://api.reclaimprotocol.org/api';
