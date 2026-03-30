import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/defect_status.dart';
import '../services/notification_service.dart';
import '../services/status_api_service.dart';
import '../services/status_cache_service.dart';

class DashboardProvider extends ChangeNotifier {
  static const List<String> _monitoredPorts = <String>[
    'PORT-01',
    'PORT-02',
    'PORT-03',
    'PORT-04',
    'PORT-05',
    'PORT-06',
    'PORT-07',
    'PORT-08',
    'PORT-09',
    'PORT-10',
    'PORT-11',
    'PORT-12',
  ];

  DashboardProvider({
    required StatusApiService apiService,
    required StatusCacheService cacheService,
    required NotificationService notificationService,
    this.refreshInterval = const Duration(seconds: 2),
    this.historyLimit = 20,
  }) : _apiService = apiService,
       _cacheService = cacheService,
       _notificationService = notificationService;

  final StatusApiService _apiService;
  final StatusCacheService _cacheService;
  final NotificationService _notificationService;
  final Duration refreshInterval;
  final int historyLimit;

  final List<DefectStatus> _history = <DefectStatus>[];
  final Map<String, DefectStatus> _latestByPort = <String, DefectStatus>{};

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  String? _debugCause;
  DateTime? _lastUpdatedAt;
  String? _lastNotifiedKey;
  Timer? _timer;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get debugCause => _debugCause;
  String get apiBaseUrl => _apiService.baseUrl;
  DateTime? get lastUpdatedAt => _lastUpdatedAt;
  UnmodifiableListView<String> get monitoredPorts =>
      UnmodifiableListView<String>(_monitoredPorts);
  DefectStatus? get latest => _history.isEmpty ? null : _history.first;
  UnmodifiableListView<DefectStatus> get latestByPort {
    final latestItems = _latestByPort.values.toList(growable: false)
      ..sort((a, b) => a.port.compareTo(b.port));
    return UnmodifiableListView<DefectStatus>(latestItems);
  }

  UnmodifiableListView<DefectStatus> get history =>
      UnmodifiableListView<DefectStatus>(_history);

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;

    await _notificationService.initialize();
    await _loadCachedHistory();

    unawaited(refresh());

    _timer = Timer.periodic(refreshInterval, (_) {
      unawaited(refresh(isAutomatic: true));
    });
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
      final status = await _apiService.fetchStatus();
      _insertStatus(status);
      _lastUpdatedAt = DateTime.now();
      _errorMessage = null;
      _debugCause = null;

      await _cacheService.saveHistory(_history);
      await _notifyIfCritical(status);
    } catch (error) {
      _errorMessage =
          'Connexion au serveur indisponible. Donnees en cache affichees.';
      _debugCause = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCachedHistory() async {
    final cached = await _cacheService.loadHistory();
    if (cached.isEmpty) {
      return;
    }

    _history
      ..clear()
      ..addAll(cached);
    _rebuildLatestByPort();
    _lastUpdatedAt = DateTime.now();
    notifyListeners();
  }

  void _insertStatus(DefectStatus status) {
    _latestByPort[status.port] = status;

    if (_history.isNotEmpty && _history.first.uniqueKey == status.uniqueKey) {
      _history[0] = status;
      return;
    }

    _history.insert(0, status);
    if (_history.length > historyLimit) {
      _history.removeRange(historyLimit, _history.length);
    }
  }

  void _rebuildLatestByPort() {
    _latestByPort.clear();
    for (final item in _history) {
      _latestByPort.putIfAbsent(item.port, () => item);
    }
  }

  Future<void> _notifyIfCritical(DefectStatus status) async {
    if (!status.isCritical) {
      return;
    }

    if (_lastNotifiedKey == status.uniqueKey) {
      return;
    }

    _lastNotifiedKey = status.uniqueKey;
    await _notificationService.showCriticalAlert(status);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _apiService.dispose();
    super.dispose();
  }
}
