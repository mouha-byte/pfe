import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/defect_status.dart';
import '../services/notification_service.dart';
import '../services/status_api_service.dart';
import '../services/status_cache_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({
    required StatusApiService apiService,
    required StatusCacheService cacheService,
    required NotificationService notificationService,
    this.refreshInterval = const Duration(seconds: 2),
    this.porteCount = 12,
  }) : _apiService = apiService,
       _cacheService = cacheService,
       _notificationService = notificationService,
       _monitoredPorts = List<String>.generate(
         porteCount,
         (i) => 'PORTE-${(i + 1).toString().padLeft(2, '0')}',
         growable: false,
       );

  final StatusApiService _apiService;
  final StatusCacheService _cacheService;
  final NotificationService _notificationService;
  final Duration refreshInterval;
  final int porteCount;
  final List<String> _monitoredPorts;

  final Map<String, DefectStatus> _latestByPort = <String, DefectStatus>{};

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  String? _debugCause;
  DateTime? _lastUpdatedAt;
  Set<String> _notifiedKeys = <String>{};
  Timer? _timer;
  StreamSubscription<List<DefectStatus>>? _subscription;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get debugCause => _debugCause;
  String get apiBaseUrl => _apiService.baseUrl;

  /// `true` when live updates come from the native Realtime Database stream.
  bool get isRealtime => _apiService.isNative;

  DateTime? get lastUpdatedAt => _lastUpdatedAt;

  UnmodifiableListView<String> get monitoredPorts =>
      UnmodifiableListView<String>(_monitoredPorts);

  /// Latest known state of each door, sorted by port id.
  UnmodifiableListView<DefectStatus> get latestByPort {
    final items = _latestByPort.values.toList(growable: false)
      ..sort((a, b) => a.port.compareTo(b.port));
    return UnmodifiableListView<DefectStatus>(items);
  }

  int get activeCount => _latestByPort.length;
  int get faultCount =>
      _latestByPort.values.where((item) => item.hasFault).length;
  int get openDoorCount =>
      _latestByPort.values.where((item) => item.isDoorOpen).length;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;

    await _notificationService.initialize();
    await _loadCachedPortes();

    final stream = _apiService.watch();
    if (stream != null) {
      // Native Realtime Database: push-based, no polling needed.
      _subscription = stream.listen(
        _onPortes,
        onError: (Object error) {
          _errorMessage =
              'Connexion a Firebase indisponible. Donnees en cache affichees.';
          _debugCause = error.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } else {
      // REST fallback: poll periodically.
      unawaited(refresh());
      _timer = Timer.periodic(refreshInterval, (_) {
        unawaited(refresh(isAutomatic: true));
      });
    }
  }

  Future<void> refresh({bool isAutomatic = false}) async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    if (!isAutomatic) {
      _errorMessage = null;
    }
    _debugCause = null;
    notifyListeners();

    try {
      final portes = await _apiService.fetchPortes();
      _applyPortes(portes);
      _lastUpdatedAt = DateTime.now();
      _errorMessage = null;
      _debugCause = null;

      await _cacheService.savePortes(portes);
      await _notifyNewFaults(portes);
    } catch (error) {
      _errorMessage =
          'Connexion a Firebase indisponible. Donnees en cache affichees.';
      _debugCause = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onPortes(List<DefectStatus> portes) {
    _applyPortes(portes);
    _lastUpdatedAt = DateTime.now();
    _errorMessage = null;
    _debugCause = null;
    _isLoading = false;
    unawaited(_cacheService.savePortes(portes));
    unawaited(_notifyNewFaults(portes));
    notifyListeners();
  }

  Future<void> _loadCachedPortes() async {
    final cached = await _cacheService.loadPortes();
    if (cached.isEmpty) {
      return;
    }

    _applyPortes(cached);
    _lastUpdatedAt = DateTime.now();
    notifyListeners();
  }

  void _applyPortes(List<DefectStatus> portes) {
    _latestByPort
      ..clear()
      ..addEntries(portes.map((item) => MapEntry(item.port, item)));
  }

  Future<void> _notifyNewFaults(List<DefectStatus> portes) async {
    final currentFaultKeys = <String>{};
    for (final porte in portes) {
      if (!porte.hasFault) {
        continue;
      }
      currentFaultKeys.add(porte.uniqueKey);
      if (!_notifiedKeys.contains(porte.uniqueKey)) {
        await _notificationService.showCriticalAlert(porte);
      }
    }
    _notifiedKeys = currentFaultKeys;
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_subscription?.cancel());
    _apiService.dispose();
    super.dispose();
  }
}
