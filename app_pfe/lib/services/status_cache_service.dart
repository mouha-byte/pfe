import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/defect_status.dart';

class StatusCacheService {
  static const String _historyKey = 'cached_status_history';

  Future<void> saveHistory(List<DefectStatus> items) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = items
        .map((item) => jsonEncode(item.toJson()))
        .toList(growable: false);
    await prefs.setStringList(_historyKey, payload);
  }

  Future<List<DefectStatus>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = prefs.getStringList(_historyKey);
    if (payload == null || payload.isEmpty) {
      return <DefectStatus>[];
    }

    final result = <DefectStatus>[];
    for (final raw in payload) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          result.add(DefectStatus.fromJson(decoded));
        }
      } catch (_) {
        // Ignore malformed cached entries.
      }
    }
    return result;
  }
}
