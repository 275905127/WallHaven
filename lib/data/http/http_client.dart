import 'package:dio/dio.dart';

class HttpClient {
  final Dio dio;

  HttpClient({
    Dio? dio,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 20),
  }) : dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: connectTimeout,
                receiveTimeout: receiveTimeout,
              ),
            );
}
