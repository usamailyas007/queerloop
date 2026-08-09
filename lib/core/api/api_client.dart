// Single HTTP entry point for the app; the only file that touches Dio.

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({String? baseUrl, Dio? dio})
      : _dio = dio ?? Dio() {
    final String url = baseUrl ?? AppConfig.baseUrl;
    assert(
      url.isNotEmpty,
      'BASE_URL is empty. Run with --dart-define-from-file=env/staging.json',
    );

    _dio.options
      ..baseUrl = url
      ..connectTimeout = const Duration(seconds: 15)
      ..receiveTimeout = const Duration(seconds: 20)
      ..sendTimeout = const Duration(seconds: 20)
      ..headers = <String, String>{'Accept': 'application/json'};

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          final String? token = authToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) {
          if (error.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;

  String? authToken;

  void Function()? onUnauthorized;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
  }) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? body}) =>
      _send(() => _dio.post<dynamic>(path, data: body));

  Future<dynamic> put(String path, {Object? body}) =>
      _send(() => _dio.put<dynamic>(path, data: body));

  Future<dynamic> delete(String path, {Object? body}) =>
      _send(() => _dio.delete<dynamic>(path, data: body));

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final Response<dynamic> response = await request();
      return response.data;
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  ApiException _toApiException(DioException error) {
    final int? status = error.response?.statusCode;

    final ApiErrorKind kind = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        ApiErrorKind.timeout,
      DioExceptionType.connectionError => ApiErrorKind.network,
      DioExceptionType.cancel => ApiErrorKind.cancelled,
      DioExceptionType.badResponse when status != null && status >= 500 =>
        ApiErrorKind.server,
      DioExceptionType.badResponse => ApiErrorKind.client,
      _ => ApiErrorKind.unknown,
    };

    return ApiException(
      _messageFor(kind, error.response?.data),
      statusCode: status,
      kind: kind,
    );
  }

  String _messageFor(ApiErrorKind kind, dynamic body) {
    if (body is Map && body['message'] is String) {
      return body['message'] as String;
    }

    return switch (kind) {
      ApiErrorKind.network => 'No internet connection.',
      ApiErrorKind.timeout => 'The server took too long to respond.',
      ApiErrorKind.server => 'Something went wrong on our end.',
      ApiErrorKind.client => 'That request could not be completed.',
      ApiErrorKind.cancelled => 'Request cancelled.',
      ApiErrorKind.unknown => 'Something went wrong.',
    };
  }
}
