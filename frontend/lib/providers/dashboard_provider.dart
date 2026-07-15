import 'package:flutter/foundation.dart';
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
          _dashboardData = cachedData['data'];
          _loading = false;
          notifyListeners();
        },
      );

      // 2. Fetch fresh network data
      final res = await _api.get(path);
      _dashboardData = res['data'];
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }
}
