import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/defect_status.dart';

class StatusApiException implements Exception {
  const StatusApiException({
    required this.message,
    required this.uri,
    this.statusCode,
    this.responseBody,
    this.innerError,
  });

  final String message;
  final Uri uri;
  final int? statusCode;
  final String? responseBody;
  final Object? innerError;

  @override
  String toString() {
    final parts = <String>[
      message,
      'url=$uri',
      if (statusCode != null) 'status=$statusCode',
      if (responseBody != null && responseBody!.isNotEmpty)
        'body=${_shorten(responseBody!)}',
      if (innerError != null) 'error=$innerError',
    ];
    return 'StatusApiException(${parts.join(' | ')})';
  }

  static String _shorten(String value) {
    const maxLength = 220;
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength)}...';
  }
}

class StatusApiService {
  StatusApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = (baseUrl ??
                const String.fromEnvironment(
                  'API_BASE_URL',
                  defaultValue: 'http://192.168.1.21:5000/',
                ))
            .replaceAll(RegExp(r'/$'), '');

  final http.Client _client;
  final String baseUrl;

  Future<DefectStatus> fetchStatus() async {
    final uri = Uri.parse('$baseUrl/status');
    late final http.Response response;

    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 6));
    } on TimeoutException catch (error) {
      throw StatusApiException(
        message: 'Request timeout after 6 seconds',
        uri: uri,
        innerError: error,
      );
    } on http.ClientException catch (error) {
      throw StatusApiException(
        message: 'HTTP client transport error',
        uri: uri,
        innerError: error,
      );
    } catch (error) {
      throw StatusApiException(
        message: 'Unexpected transport error',
        uri: uri,
        innerError: error,
      );
    }

    if (response.statusCode != 200) {
      throw StatusApiException(
        message: 'Unexpected HTTP status from backend',
        uri: uri,
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw StatusApiException(
        message: 'Response is not valid JSON',
        uri: uri,
        responseBody: response.body,
        innerError: error,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw StatusApiException(
        message: 'Invalid JSON payload type (expected object)',
        uri: uri,
        responseBody: response.body,
      );
    }

    try {
      return DefectStatus.fromJson(decoded);
    } catch (error) {
      throw StatusApiException(
        message: 'JSON format is incompatible with DefectStatus model',
        uri: uri,
        responseBody: response.body,
        innerError: error,
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
