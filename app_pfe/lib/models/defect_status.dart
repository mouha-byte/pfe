class DefectStatus {
  const DefectStatus({
    required this.flash,
    required this.defect,
    required this.priority,
    required this.status,
    required this.timestamp,
  });

  final int flash;
  final String defect;
  final String priority;
  final String status;
  final DateTime timestamp;

  String get priorityUpper => priority.toUpperCase();
  String get statusUpper => status.toUpperCase();

  bool get isCritical => priorityUpper == 'A' || statusUpper == 'OPEN';

  String get uniqueKey =>
      '${timestamp.toIso8601String()}|$defect|$priorityUpper|$statusUpper|$flash';

  factory DefectStatus.fromJson(Map<String, dynamic> json) {
    return DefectStatus(
      flash: _toInt(json['flash']),
      defect: (json['defect'] ?? 'Inconnu').toString(),
      priority: (json['priority'] ?? 'B').toString(),
      status: (json['status'] ?? 'OPEN').toString(),
      timestamp: _parseTimestamp(json['timestamp']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
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
      'flash': flash,
      'defect': defect,
      'priority': priority,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
