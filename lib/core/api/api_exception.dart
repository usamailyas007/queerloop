// The only error type ApiClient throws.

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.kind});

  final String message;
  final int? statusCode;
  final ApiErrorKind? kind;

  bool get isUnauthorized => statusCode == 401;
  bool get isOffline => kind == ApiErrorKind.network;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

enum ApiErrorKind { network, timeout, server, client, cancelled, unknown }
