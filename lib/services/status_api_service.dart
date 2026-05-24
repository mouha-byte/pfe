import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
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

/// Reads the Firebase **Realtime Database** (never Firestore) from the
/// `/portes` node, where each child `PORTE-XX` holds `door`/`error`/`mode`.
///
/// Two data paths share one parser:
///  * Native SDK (`firebase_database`) when Firebase initialised successfully
///    (mobile uses your `google-services.json`) -> true realtime via `onValue`.
///  * REST endpoint (`/portes.json`) as a fallback on platforms where the
///    native SDK has no config (e.g. Windows desktop / web).
class StatusApiService {
  StatusApiService({
    http.Client? client,
    String? databaseUrl,
    bool nativeAvailable = false,
  }) : _client = client ?? http.Client(),
       _useNative = nativeAvailable,
       databaseUrl =
           (databaseUrl ??
                   const String.fromEnvironment(
                     'FIREBASE_DB_URL',
                     defaultValue:
                         'https://projet-pfe-5a26a-default-rtdb.firebaseio.com',
                   ))
               .replaceAll(RegExp(r'/$'), '');

  final http.Client _client;
  final String databaseUrl;

  /// Whether the native Realtime Database SDK is usable. Flipped to `false`
  /// permanently the first time a native call fails, so we fall back to REST.
  bool _useNative;

  bool get isNative => _useNative;

  /// Node holding the 20 doors, each as a `PORTE-XX` child.
  static const String _node = 'portes';

  /// Shown in the UI (offline banner).
  String get baseUrl => databaseUrl;

  /// Realtime push stream of all doors. Returns `null` when the native SDK is
  /// unavailable; the provider then falls back to periodic REST polling.
  Stream<List<DefectStatus>>? watch() {
    if (!_useNative) {
      return null;
    }
    try {
      return FirebaseDatabase.instance
          .ref(_node)
          .onValue
          .map((event) => _parse(event.snapshot.value, DateTime.now()));
    } catch (_) {
      _useNative = false;
      return null;
    }
  }

  /// One-shot read of all doors (used for pull-to-refresh and REST polling).
  Future<List<DefectStatus>> fetchPortes() async {
    if (_useNative) {
      try {
        final snapshot = await FirebaseDatabase.instance
            .ref(_node)
            .get()
            .timeout(const Duration(seconds: 8));
        return _parse(snapshot.value, DateTime.now());
      } catch (_) {
        // Native path failed -> drop to REST for the rest of the session.
        _useNative = false;
      }
    }
    return _fetchRest();
  }

  Future<List<DefectStatus>> _fetchRest() async {
    final uri = Uri.parse('$databaseUrl/$_node.json');
    late final http.Response response;

    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 8));
    } on TimeoutException catch (error) {
      throw StatusApiException(
        message: 'Delai depasse (8 s) en interrogeant Firebase',
        uri: uri,
        innerError: error,
      );
    } on http.ClientException catch (error) {
      throw StatusApiException(
        message: 'Erreur reseau HTTP vers Firebase',
        uri: uri,
        innerError: error,
      );
    } catch (error) {
      throw StatusApiException(
        message: 'Erreur de transport inattendue',
        uri: uri,
        innerError: error,
      );
    }

    if (response.statusCode != 200) {
      throw StatusApiException(
        message: 'Statut HTTP inattendu depuis Firebase',
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
        message: 'Reponse Firebase non JSON',
        uri: uri,
        responseBody: response.body,
        innerError: error,
      );
    }

    return _parse(decoded, DateTime.now());
  }

  /// Parses the raw `/portes` value (native SDK or REST) into a door list.
  List<DefectStatus> _parse(Object? value, DateTime now) {
    if (value == null) {
      return const <DefectStatus>[];
    }

    if (value is! Map) {
      throw StatusApiException(
        message: 'Format inattendu pour le noeud "$_node"',
        uri: Uri.parse('$databaseUrl/$_node.json'),
      );
    }

    final portes = <DefectStatus>[];
    _stringKeyed(value).forEach((port, dynamic child) {
      if (child is Map) {
        portes.add(
          DefectStatus.fromJson(_stringKeyed(child), port: port, timestamp: now),
        );
      }
    });

    portes.sort((a, b) => a.port.compareTo(b.port));
    return portes;
  }

  Map<String, dynamic> _stringKeyed(Map<dynamic, dynamic> value) {
    return value.map<String, dynamic>(
      (key, dynamic v) => MapEntry(key.toString(), v),
    );
  }

  void dispose() {
    _client.close();
  }
}
