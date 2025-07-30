import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';

class SizedNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double width;
  final double height;

  const SizedNetworkImage({super.key, required this.imageUrl, this.width = 30, this.height = 30});

  @override
  State<SizedNetworkImage> createState() => _SizedNetworkImageState();
}

class _SizedNetworkImageState extends State<SizedNetworkImage> {
  late Future<Uint8List> _imageData;

  @override
  void initState() {
    super.initState();
    _imageData = _fetchImageData(widget.imageUrl);
  }

  Future<Uint8List> _fetchImageData(String url) async {
    try {
      final dio = Dio();
      dio.httpClientAdapter = NativeAdapter(
        createCupertinoConfiguration: () {
          return URLSessionConfiguration.ephemeralSessionConfiguration();
        },
        createCronetEngine: () {
          return CronetEngine.build(cacheMode: CacheMode.disk, enableBrotli: true, enableHttp2: true, enableQuic: true);
        },
      );
      final response = await dio.get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
      return Uint8List.fromList(response.data!);
    } catch (e) {
      // Return a white color image
      return Uint8List.fromList(List.filled(1, 255));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _imageData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(strokeWidth: 3);
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return SizedBox(width: widget.width, height: widget.height, child: Image.memory(snapshot.data!));
        }
      },
    );
  }
}
