import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/defect_status.dart';

class NotificationService {
  static const String _channelKey = 'critical_alerts_channel';

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    try {
      await AwesomeNotifications().initialize(null, [
        NotificationChannel(
          channelKey: _channelKey,
          channelName: 'Critical Alerts',
          channelDescription: 'Alerts for priority A or OPEN defects',
          importance: NotificationImportance.Max,
          defaultColor: const Color(0xFF1D466A),
          ledColor: Colors.white,
          playSound: true,
          enableVibration: true,
          channelShowBadge: true,
        ),
      ], debug: false);
      await _requestPermissions();
      _isInitialized = true;
    } catch (_) {
      _isInitialized = true;
    }
  }

  Future<void> _requestPermissions() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  Future<void> showCriticalAlert(DefectStatus status) async {
    if (kIsWeb) {
      return;
    }

    if (!_isInitialized) {
      await initialize();
    }

    try {
      final title = status.priorityUpper == 'A'
          ? 'Priorite A detectee'
          : 'Defaut OPEN detecte';
      final body =
          '${status.defect} - Flash: ${status.flash} - Statut: ${status.statusUpper}';

      final id = status.timestamp.millisecondsSinceEpoch % 2147483647;
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: _channelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
        ),
      );
    } catch (_) {
      // Ignore local notification failures to keep monitoring flow stable.
    }
  }
}
