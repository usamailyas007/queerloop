import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../cache/cache_manager.dart';
import '../config/app_config.dart';
import 'api_exception.dart';

class ApiClient {
  /// Toggle HTTP API logging. Kept false per user request to only show socket logs.
  static const bool enableApiLogging = false;

  ApiClient({String? baseUrl, Dio? dio})
      : _dio = dio ?? Dio() {
    final String url = baseUrl ?? AppConfig.baseUrl;
    assert(
      url.isNotEmpty,
      'BASE_URL is empty. Run with --dart-define-from-file=env/staging.json',
    );

    _dio.options
      ..baseUrl = url
      ..connectTimeout = const Duration(minutes: 2)
      ..receiveTimeout = const Duration(minutes: 2)
      // `sendTimeout` on the web adapter throws for body-less requests
      // ("cannot be used without a request body to send on Web"), so keep it
      // off the web build — bodyless GET/DELETE are the common case there.
      ..sendTimeout = kIsWeb ? null : const Duration(minutes: 2)
      ..headers = <String, String>{'Accept': 'application/json'};

    // A second, interceptor-free client used only for the token-refresh call.
    // Making that request through `_dio` would re-enter the 401 interceptor
    // that triggered it (and can deadlock), so it gets its own plain Dio.
    _bareDio = Dio()
      ..options.baseUrl = url
      ..options.connectTimeout = const Duration(seconds: 15)
      ..options.receiveTimeout = const Duration(seconds: 20)
      ..options.sendTimeout = kIsWeb ? null : const Duration(seconds: 20)
      ..options.headers = <String, String>{'Accept': 'application/json'};

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          if (isPublicEndpoint(options.path)) {
            options.headers.remove('Authorization');
          } else {
            final String? token = authToken;
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          final String path = options.path.toLowerCase();
          final bool isTargetApi = enableApiLogging ||
              path.contains('/restrict') ||
              path.contains('/conversations/share') ||
              path.contains('/share') ||
              path.contains('/messages') ||
              path.contains('/block');

          if (isTargetApi) {
            debugPrint('┌──────────────────────────────────────────────────────────');
            debugPrint('🌐 [API Request] ${options.method} ${options.uri}');
            debugPrint('🔑 Headers: Authorization: ${options.headers['Authorization'] != null ? "Bearer ..." : "None"}');
            if (options.data != null) {
              debugPrint('📦 Payload:\n${_prettyJson(options.data)}');
            } else {
              debugPrint('📦 Payload: null (no body)');
            }
            debugPrint('└──────────────────────────────────────────────────────────');
          }
          handler.next(options);
        },
        onResponse: (Response<dynamic> response, ResponseInterceptorHandler handler) {
          final String path =
              response.requestOptions.path.toLowerCase();
          final bool isTargetApi = enableApiLogging ||
              path.contains('/restrict') ||
              path.contains('/conversations/share') ||
              path.contains('/share') ||
              path.contains('/messages') ||
              path.contains('/block');

          if (isTargetApi) {
            debugPrint('┌──────────────────────────────────────────────────────────');
            debugPrint('✅ [API Response] ${response.requestOptions.method} ${response.requestOptions.path} [Status ${response.statusCode}]');
            debugPrint('📥 Response Body:\n${_prettyJson(response.data)}');
            debugPrint('└──────────────────────────────────────────────────────────');
          }
          handler.next(response);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          final String path =
              error.requestOptions.path.toLowerCase();
          final bool isTargetApi = enableApiLogging ||
              path.contains('/restrict') ||
              path.contains('/conversations/share') ||
              path.contains('/share') ||
              path.contains('/messages') ||
              path.contains('/block');

          if (isTargetApi) {
            debugPrint('┌──────────────────────────────────────────────────────────');
            debugPrint('❌ [API Error] ${error.requestOptions.method} ${error.requestOptions.path} [Status ${error.response?.statusCode}]');
            debugPrint('⚠️ Error Response Body:\n${_prettyJson(error.response?.data)}');
            debugPrint('└──────────────────────────────────────────────────────────');
          }

          final RequestOptions req = error.requestOptions;
          final int? statusCode = error.response?.statusCode;
          final bool isAuthPath = isPublicEndpoint(req.path) ||
              req.path.contains('/auth/refresh');

          if (statusCode == 401 && !isAuthPath) {
            final int retryCount = req.extra['retry_count'] as int? ?? 0;
            if (retryCount >= 1) {
              return handler.next(error);
            }

            // 1. Check if token was already refreshed by another concurrent request
            final String currentHeader =
                req.headers['Authorization'] as String? ?? '';
            final String currentBearer =
                (authToken != null && authToken!.isNotEmpty)
                    ? 'Bearer $authToken'
                    : '';

            if (currentBearer.isNotEmpty &&
                currentHeader.isNotEmpty &&
                currentHeader != currentBearer) {
              debugPrint(
                  '🔄 [ApiClient] Token was already refreshed by another request. Retrying ${req.method} ${req.path} with current token...');
              try {
                req.extra['retry_count'] = 1;
                final Options options = Options(
                  method: req.method,
                  headers: Map<String, dynamic>.from(req.headers)
                    ..['Authorization'] = currentBearer,
                  responseType: req.responseType,
                  contentType: req.contentType,
                  validateStatus: req.validateStatus,
                  receiveTimeout: req.receiveTimeout,
                  sendTimeout: req.sendTimeout,
                  extra: req.extra,
                );

                final dynamic retryData = req.data is FormData
                    ? (req.data as FormData).clone()
                    : req.data;
                final Response<dynamic> retryResponse =
                    await _dio.request<dynamic>(
                  req.path,
                  data: retryData,
                  queryParameters: req.queryParameters,
                  options: options,
                );

                return handler.resolve(retryResponse);
              } catch (_) {
                // If retry with existing token still fails, fall through to refresh
              }
            }

            // 2. Perform token refresh
            if (onTokenRefresh != null) {
              try {
                final String? newToken = await _refreshTokenLock();
                if (newToken != null && newToken.isNotEmpty) {
                  authToken = newToken;
                  debugPrint(
                      '🔄 [ApiClient] Retrying original request ${req.method} ${req.path} with refreshed token...');
                  req.extra['retry_count'] = 1;
                  final Options options = Options(
                    method: req.method,
                    headers: Map<String, dynamic>.from(req.headers)
                      ..['Authorization'] = 'Bearer $newToken',
                    responseType: req.responseType,
                    contentType: req.contentType,
                    validateStatus: req.validateStatus,
                    receiveTimeout: req.receiveTimeout,
                    sendTimeout: req.sendTimeout,
                    extra: req.extra,
                  );

                  final dynamic retryData = req.data is FormData
                      ? (req.data as FormData).clone()
                      : req.data;
                  final Response<dynamic> retryResponse =
                      await _dio.request<dynamic>(
                    req.path,
                    data: retryData,
                    queryParameters: req.queryParameters,
                    options: options,
                  );

                  return handler.resolve(retryResponse);
                }
              } catch (retryError) {
                debugPrint('❌ [ApiClient] Retry request failed: $retryError');
                if (retryError is DioException) {
                  return handler.next(retryError);
                }
              }
            }
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

  String get baseUrl => _dio.options.baseUrl;
  final Dio _dio;
  late final Dio _bareDio;

  String? authToken;

  void Function()? onUnauthorized;
  Future<String?> Function()? onTokenRefresh;

  Future<String?>? _activeRefreshFuture;

  Future<String?> _refreshTokenLock() {
    if (_activeRefreshFuture != null) {
      debugPrint('⏳ [ApiClient] Refresh already in flight, awaiting existing future...');
      return _activeRefreshFuture!;
    }

    _activeRefreshFuture = () async {
      try {
        final String? token = await onTokenRefresh?.call();
        if (token != null && token.isNotEmpty) {
          authToken = token;
        }
        return token;
      } finally {
        _activeRefreshFuture = null;
      }
    }();

    return _activeRefreshFuture!;
  }

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

  Future<dynamic> post(String path, {Object? body, Duration? timeout}) =>
      _send(() => _dio.post<dynamic>(
            path,
            data: body,
            options: timeout != null
                ? Options(sendTimeout: timeout, receiveTimeout: timeout)
                : null,
          ));

  /// POST with no auth header and no interceptors — used only for `/auth/refresh`
  /// so it can run safely from inside the 401 interceptor (admin token refresh).
  Future<dynamic> postNoAuth(String path, {Object? body}) =>
      _send(() => _bareDio.post<dynamic>(path, data: body));

  Future<dynamic> patch(String path, {Object? body, Duration? timeout}) =>
      _send(() => _dio.patch<dynamic>(
            path,
            data: body,
            options: timeout != null
                ? Options(sendTimeout: timeout, receiveTimeout: timeout)
                : null,
          ));

  Future<dynamic> put(String path, {Object? body, Duration? timeout}) =>
      _send(() => _dio.put<dynamic>(
            path,
            data: body,
            options: timeout != null
                ? Options(sendTimeout: timeout, receiveTimeout: timeout)
                : null,
          ));

  Future<dynamic> delete(String path, {Object? body, Duration? timeout}) =>
      _send(() => _dio.delete<dynamic>(
            path,
            data: body,
            options: timeout != null
                ? Options(sendTimeout: timeout, receiveTimeout: timeout)
                : null,
          ));

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

  /// Returns true for endpoints that never require or accept Authorization headers.
  static bool isPublicEndpoint(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/verify-email') ||
        path.contains('/auth/password-reset') ||
        path.contains('/auth/cancel-deletion') ||
        path.contains('/users/username-available');
  }
}

