import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _api;
  Map<String, dynamic>? _dashboardData;
  bool _loading = false;
  String? _error;

  DashboardProvider(this._api);

  Map<String, dynamic>? get dashboardData => _dashboardData;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadDashboard() async {
    _loading = true;
    _error = null;
    notifyListeners();

    const path = '/dashboard';

    try {
      // 1. Load cached dashboard data first (so user gets instant UI loading)
      await _api.getWithCache(
        path,
        onCacheHit: (cachedData) {
          final newData = cachedData['data'];
          final isSame = const DeepCollectionEquality().equals(_dashboardData, newData);
          if (!isSame) {
            _dashboardData = newData;
            _loading = false;
            notifyListeners();
          }
        },
      );

      // 2. Fetch fresh network data
      final res = await _api.get(path);
      final newData = res['data'];
      final isSame = const DeepCollectionEquality().equals(_dashboardData, newData);
      _loading = false;
      if (!isSame) {
        _dashboardData = newData;
        notifyListeners();
      } else {
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }
}
