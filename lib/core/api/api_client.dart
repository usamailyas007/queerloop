import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../cache/cache_manager.dart';
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
      // `sendTimeout` on the web adapter throws for body-less requests
      // ("cannot be used without a request body to send on Web"), so keep it
      // off the web build — bodyless GET/DELETE are the common case there.
      ..sendTimeout = kIsWeb ? null : const Duration(seconds: 20)
      ..headers = <String, String>{'Accept': 'application/json'};

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          final String? token = authToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          debugPrint('┌──────────────────────────────────────────────────────────');
          debugPrint('🌐 [API Request] ${options.method} ${options.uri}');
          if (options.data != null) {
            debugPrint('📦 Payload:\n${_prettyJson(options.data)}');
          }
          debugPrint('└──────────────────────────────────────────────────────────');
          handler.next(options);
        },
        onResponse: (Response<dynamic> response, ResponseInterceptorHandler handler) {
          debugPrint('┌──────────────────────────────────────────────────────────');
          debugPrint('✅ [API Response] ${response.requestOptions.method} ${response.requestOptions.path} [Status ${response.statusCode}]');
          debugPrint('📥 Response Body:\n${_prettyJson(response.data)}');
          debugPrint('└──────────────────────────────────────────────────────────');
          handler.next(response);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) {
          debugPrint('┌──────────────────────────────────────────────────────────');
          debugPrint('❌ [API Error] ${error.requestOptions.method} ${error.requestOptions.path} [Status ${error.response?.statusCode}]');
          debugPrint('⚠️ Error Response Body:\n${_prettyJson(error.response?.data)}');
          debugPrint('└──────────────────────────────────────────────────────────');
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/login')) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  static String _prettyJson(dynamic data) {
    if (data == null) return 'null';
    try {
      if (data is Map || data is List) {
        return const JsonEncoder.withIndent('  ').convert(data);
      }
      return data.toString();
    } catch (_) {
      return data.toString();
    }
  }

  final Dio _dio;

  String? authToken;

  void Function()? onUnauthorized;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool useCache = true,
    Duration? cacheTtl,
  }) async {
    final String cacheKey = _toCacheKey(path, query);

    try {
      final dynamic data = await _send(
        () => _dio.get<dynamic>(path, queryParameters: query),
      );
      if (useCache && data != null) {
        CacheManager.instance.put(cacheKey, data, ttl: cacheTtl);
      }
      return data;
    } on ApiException catch (e) {
      if (useCache &&
          (e.kind == ApiErrorKind.network || e.kind == ApiErrorKind.timeout)) {
        final dynamic cached = CacheManager.instance.get(cacheKey);
        if (cached != null) {
          debugPrint('📦 [Cache Hit: Offline Fallback] $cacheKey');
          return cached;
        }
      }
      rethrow;
    }
  }

  Future<dynamic> post(String path, {Object? body}) =>
      _send(() => _dio.post<dynamic>(path, data: body));

  Future<dynamic> patch(String path, {Object? body}) =>
      _send(() => _dio.patch<dynamic>(path, data: body));

  Future<dynamic> put(String path, {Object? body}) =>
      _send(() => _dio.put<dynamic>(path, data: body));

  Future<dynamic> delete(String path, {Object? body}) =>
      _send(() => _dio.delete<dynamic>(path, data: body));

  String _toCacheKey(String path, Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) {
      return path;
    }
    final String queryStr =
        query.entries.map((MapEntry<String, dynamic> e) => '${e.key}=${e.value}').join('&');
    return '$path?$queryStr';
  }

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

    final dynamic body = error.response?.data;
    String? code;
    int? retryAfterSeconds;
    if (body is Map) {
      if (body['code'] is String) {
        code = body['code'] as String;
      }
      if (body['retryAfterSeconds'] is num) {
        retryAfterSeconds = (body['retryAfterSeconds'] as num).toInt();
      }
    }

    return ApiException(
      _messageFor(kind, body),
      statusCode: status,
      kind: kind,
      code: code,
      retryAfterSeconds: retryAfterSeconds,
      data: body,
    );
  }

  String _messageFor(ApiErrorKind kind, dynamic body) {
    if (body is Map) {
      if (body['message'] is String && (body['message'] as String).isNotEmpty) {
        return body['message'] as String;
      }
      if (body['message'] is List && (body['message'] as List).isNotEmpty) {
        return (body['message'] as List).first.toString();
      }
      if (body['error'] is String && (body['error'] as String).isNotEmpty) {
        return body['error'] as String;
      }
      if (body['detail'] is String && (body['detail'] as String).isNotEmpty) {
        return body['detail'] as String;
      }
    }

    return switch (kind) {
      ApiErrorKind.network => 'No internet connection.',
      ApiErrorKind.timeout => 'The server took too long to respond.',
      ApiErrorKind.server => 'Something went wrong on our end.',
      ApiErrorKind.client => 'Invalid credentials or request.',
      ApiErrorKind.cancelled => 'Request cancelled.',
      ApiErrorKind.unknown => 'Something went wrong.',
    };
  }
}
