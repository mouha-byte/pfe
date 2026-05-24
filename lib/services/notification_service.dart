import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/defect_status.dart';

class NotificationService {
  static const String _channelKey = 'critical_alerts_channel';

  bool _isInitialized = false;

  /// awesome_notifications only supports Android and iOS. On Windows, web,
  /// macOS and Linux we silently no-op so the dashboard still runs.
  bool get _isSupported {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    if (!_isSupported) {
      _isInitialized = true;
      return;
    }

    try {
      await AwesomeNotifications().initialize(null, [
        NotificationChannel(
          channelKey: _channelKey,
          channelName: 'Alertes Defaut',
          channelDescription: 'Alertes lorsqu un defaut est detecte',
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
    if (!_isSupported) {
      return;
    }

    if (!_isInitialized) {
      await initialize();
    }

    try {
      const title = 'Defaut detecte';
      final body =
          '${status.displayError} - Porte: ${status.doorLabel} - Mode: ${status.displayMode}';

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
