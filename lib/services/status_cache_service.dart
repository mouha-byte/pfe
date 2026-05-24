import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/defect_status.dart';

/// Caches the last known door states so the dashboard still shows data while
/// Firebase is unreachable. SharedPreferences works on mobile and Windows.
class StatusCacheService {
  static const String _portesKey = 'cached_portes';

  Future<void> savePortes(List<DefectStatus> portes) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = portes
        .map((item) => jsonEncode(item.toJson()))
        .toList(growable: false);
    await prefs.setStringList(_portesKey, payload);
  }

  Future<List<DefectStatus>> loadPortes() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = prefs.getStringList(_portesKey) ?? const <String>[];

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
