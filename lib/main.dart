import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/dashboard_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/status_api_service.dart';
import 'services/status_cache_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final nativeFirebase = await _initFirebase();
  runApp(MonitoringApp(nativeFirebase: nativeFirebase));
}

/// Initialises the native Firebase SDK. On Android/iOS the platform config
/// (`google-services.json` / `GoogleService-Info.plist`) is picked up
/// automatically. On Windows/web/Linux there is no native config here, so this
/// fails gracefully and the app falls back to the Realtime Database REST API.
Future<bool> _initFirebase() async {
  try {
    await Firebase.initializeApp();
    return true;
  } catch (_) {
    return false;
  }
}

class MonitoringApp extends StatelessWidget {
  const MonitoringApp({super.key, required this.nativeFirebase});

  final bool nativeFirebase;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DashboardProvider>(
          create: (_) => DashboardProvider(
            apiService: StatusApiService(nativeAvailable: nativeFirebase),
            cacheService: StatusCacheService(),
            notificationService: NotificationService(),
          )..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'Salsabil Monitoring',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF005B96),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF3F6FB),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF14324A),
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
