// The only error type ApiClient throws.

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.kind,
    this.code,
    this.retryAfterSeconds,
    this.data,
  });

  final String message;
  final int? statusCode;
  final ApiErrorKind? kind;
  final String? code;
  final int? retryAfterSeconds;
  final dynamic data;

  bool get isUnauthorized => statusCode == 401;
  bool get isOffline => kind == ApiErrorKind.network;

  @override
  String toString() => 'ApiException($statusCode, code: $code): $message';
}

enum ApiErrorKind { network, timeout, server, client, cancelled, unknown }
