/// State of a single door ("porte") read from the Firebase Realtime Database
/// under `/portes/PORTE-XX`.
class DefectStatus {
  const DefectStatus({
    required this.port,
    required this.door,
    required this.error,
    required this.mode,
    required this.timestamp,
  });

  /// Door identifier, e.g. "PORTE-01".
  final String port;

  /// Door state. `0` = fermee, `1` (or any non-zero) = ouverte.
  final int door;

  /// Raw fault message coming from the device (e.g. "Communication FIP").
  /// An empty/`OK`/`Aucun` value means there is no active fault.
  final String error;

  /// Communication mode reported by the device (e.g. "WiFi").
  final String mode;

  /// Local timestamp of when this snapshot was read. The Realtime Database
  /// does not store a timestamp, so it is synthesised on read.
  final DateTime timestamp;

  /// Values that are considered "no fault".
  static const Set<String> _healthyErrors = <String>{
    '',
    'OK',
    'RAS',
    'NONE',
    'NORMAL',
    'AUCUN',
    'AUCUN DEFAUT',
    'AUCUN DÉFAUT',
    'PAS DE DEFAUT',
    'PAS DE DÉFAUT',
  };

  bool get isDoorOpen => door != 0;
  String get doorLabel => isDoorOpen ? 'Ouverte' : 'Fermee';

  /// `true` when the `error` field holds a real fault message.
  bool get hasFault => !_healthyErrors.contains(error.trim().toUpperCase());

  /// A fault is critical for alerting/notification purposes.
  bool get isCritical => hasFault;

  String get statusLabel => hasFault ? 'DEFAUT' : 'NORMAL';

  /// Human friendly error text for display.
  String get displayError => hasFault ? error.trim() : 'Aucun defaut';

  String get displayMode => mode.trim().isEmpty ? '--' : mode.trim();

  /// Stable identity used for de-duplication and notification throttling.
  String get uniqueKey => '$port|$door|${error.trim()}|${mode.trim()}';

  factory DefectStatus.fromJson(
    Map<String, dynamic> json, {
    String? port,
    DateTime? timestamp,
  }) {
    return DefectStatus(
      port: port ?? (json['port'] ?? '').toString(),
      door: _toInt(json['door']),
      error: (json['error'] ?? '').toString(),
      mode: (json['mode'] ?? '').toString(),
      timestamp: timestamp ?? _parseTimestamp(json['timestamp']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is bool) {
      return value ? 1 : 0;
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? 0;
    }
    return 0;
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'port': port,
      'door': door,
      'error': error,
      'mode': mode,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
