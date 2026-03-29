import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/defect_status.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

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
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      );

      await _plugin.initialize(initSettings);
      await _requestPermissions();
      _isInitialized = true;
    } catch (_) {
      _isInitialized = true;
    }
  }

  Future<void> _requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    final macos = _plugin
        .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    await macos?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> showCriticalAlert(DefectStatus status) async {
    if (kIsWeb) {
      return;
    }

    if (!_isInitialized) {
      await initialize();
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'critical_alerts_channel',
        'Critical Alerts',
        channelDescription: 'Alerts for priority A or OPEN defects',
        importance: Importance.max,
        priority: Priority.high,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      );

      final title =
          status.priorityUpper == 'A' ? 'Priorite A detectee' : 'Defaut OPEN detecte';
      final body =
          '${status.defect} - Flash: ${status.flash} - Statut: ${status.statusUpper}';

      final id = status.timestamp.millisecondsSinceEpoch % 2147483647;
      await _plugin.show(id, title, body, details);
    } catch (_) {
      // Ignore local notification failures to keep monitoring flow stable.
    }
  }
}
