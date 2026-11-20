import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../logger/logger.dart';
import 'jamendo_config.dart';

/// Kind of failure, used by the UI to pick the right message.
enum JamendoErrorKind { offline, timeout, server, api, notConfigured, unknown }

class JamendoException implements Exception {
  final JamendoErrorKind kind;
  final String message;
  const JamendoException(this.kind, this.message);

  @override
  String toString() => 'JamendoException($kind): $message';
}

/// Raw API response: `headers` + `results`.
class JamendoResponse {
  final List<Map<String, dynamic>> results;
  final String? next;

  /// True when served from an expired cache entry because the network
  /// request failed (offline mode).
  final bool fromStaleCache;

  const JamendoResponse(this.results, {this.next, this.fromStaleCache = false});
}

/// Performs a GET and returns the decoded JSON body. Replaceable in tests.
typedef JamendoTransport = Future<Map<String, dynamic>> Function(Uri uri);

class JamendoApiClient {
  static final AppLogger _logger = AppLogger('JamendoApiClient');

  final String clientId;
  final String baseUrl;
  final JamendoTransport _transport;
  final int maxRetries;
  final Duration retryDelay;

  /// Jamendo intermittently answers a valid query with an empty "success"
  /// response (measured: roughly 1 in 4 calls, for any parameters). An empty
  /// result is therefore retried this many times before it is accepted.
  final int emptyResultRetries;

  JamendoApiClient({
    String? clientId,
    String? baseUrl,
    JamendoTransport? transport,
    this.maxRetries = 2,
    this.retryDelay = const Duration(milliseconds: 600),
    this.emptyResultRetries = 2,
  }) : clientId = clientId ?? JamendoConfig.clientId,
       baseUrl = baseUrl ?? JamendoConfig.baseUrl,
       _transport = transport ?? _dioTransport();

  static JamendoTransport _dioTransport() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: JamendoConfig.connectTimeout,
        receiveTimeout: JamendoConfig.receiveTimeout,
        responseType: ResponseType.json,
      ),
    );
    return (uri) async {
      final response = await dio.getUri<dynamic>(uri);
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      throw const JamendoException(JamendoErrorKind.server, 'Unexpected body');
    };
  }

  /// Builds the request URL.
  ///
  /// Multi-value parameters (e.g. `include`, `id`, `tags`) are joined with a
  /// space encoded as `%20`. Jamendo treats a literal `+` (which
  /// `Uri(queryParameters: ...)` would produce) as part of the value and
  /// returns no results.
  Uri buildUri(String endpoint, Map<String, Object?> params) {
    final query = <String>[
      'client_id=${Uri.encodeComponent(clientId)}',
      'format=json',
    ];
    params.forEach((key, value) {
      if (value == null) return;
      final String text;
      if (value is Iterable) {
        final parts = value.map((v) => v.toString()).where((v) => v.isNotEmpty);
        if (parts.isEmpty) return;
        text = parts.join(' ');
      } else {
        text = value.toString();
      }
      if (text.isEmpty) return;
      query.add('${Uri.encodeComponent(key)}=${Uri.encodeComponent(text)}');
    });
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final normalized = path.endsWith('/') ? path : '$path/';
    return Uri.parse('$baseUrl$normalized?${query.join('&')}');
  }

  Future<JamendoResponse> get(
    String endpoint, [
    Map<String, Object?> params = const {},
  ]) async {
    if (clientId.isEmpty) {
      throw const JamendoException(
        JamendoErrorKind.notConfigured,
        'JAMENDO_CLIENT_ID is not set (see JamendoConfig).',
      );
    }
    final uri = buildUri(endpoint, params);
    var attempt = 0;
    var emptyAttempts = 0;
    while (true) {
      try {
        final body = await _transport(uri);
        final response = parse(body);
        if (response.results.isEmpty && emptyAttempts < emptyResultRetries) {
          emptyAttempts++;
          await Future<void>.delayed(retryDelay * emptyAttempts);
          continue;
        }
        return response;
      } catch (e) {
        final error = mapError(e);
        final retryable =
            error.kind == JamendoErrorKind.timeout ||
            error.kind == JamendoErrorKind.server;
        if (!retryable || attempt >= maxRetries) {
          _logger.w('⚠️ $endpoint failed: ${error.message}');
          throw error;
        }
        attempt++;
        await Future<void>.delayed(retryDelay * attempt);
      }
    }
  }

  /// Validates the Jamendo envelope.
  static JamendoResponse parse(Map<String, dynamic> body) {
    final headers = body['headers'];
    if (headers is Map) {
      final status = headers['status']?.toString();
      if (status != null && status != 'success') {
        throw JamendoException(
          JamendoErrorKind.api,
          '${headers['code']}: ${headers['error_message']}',
        );
      }
    }
    final results = body['results'];
    final list = results is List
        ? results.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];
    final next = headers is Map ? headers['next']?.toString() : null;
    return JamendoResponse(list, next: (next?.isEmpty ?? true) ? null : next);
  }

  static JamendoException mapError(Object e) {
    if (e is JamendoException) return e;
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return JamendoException(JamendoErrorKind.timeout, e.message ?? 'Timeout');
        case DioExceptionType.connectionError:
          return JamendoException(JamendoErrorKind.offline, e.message ?? 'Offline');
        case DioExceptionType.badResponse:
          final code = e.response?.statusCode ?? 0;
          return JamendoException(
            code >= 500 ? JamendoErrorKind.server : JamendoErrorKind.api,
            'HTTP $code',
          );
        default:
          if (e.error is SocketException) {
            return JamendoException(JamendoErrorKind.offline, '${e.error}');
          }
          return JamendoException(JamendoErrorKind.unknown, e.message ?? '$e');
      }
    }
    if (e is SocketException) {
      return JamendoException(JamendoErrorKind.offline, e.message);
    }
    if (e is TimeoutException) {
      return const JamendoException(JamendoErrorKind.timeout, 'Timeout');
    }
    return JamendoException(JamendoErrorKind.unknown, '$e');
  }
}
