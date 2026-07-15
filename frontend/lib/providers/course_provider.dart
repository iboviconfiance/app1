import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../config/constants.dart';

class CourseProvider extends ChangeNotifier {
  final ApiService _api;
  List<dynamic> _courses = [];
  Map<String, dynamic>? _selectedCourse;
  bool _loading = false;
  bool _loadingDetail = false;
  String? _error;
  
  // Track offline cached status of courses
  Map<String, bool> _cachedStatus = {};

  CourseProvider(this._api);

  List<dynamic> get courses => _courses;
  Map<String, dynamic>? get selectedCourse => _selectedCourse;
  bool get loading => _loading;
  bool get loadingDetail => _loadingDetail;
  String? get error => _error;

  bool isCourseFileCached(String courseId, String type) {
    final ext = type == 'video' ? 'mp4' : 'pdf';
    return _cachedStatus[courseId] ?? false;
  }

  Future<void> checkCachedStatus(String courseId, String type) async {
    final ext = type == 'video' ? 'mp4' : 'pdf';
    final isCached = await CacheService.isFileCached(courseId, ext);
    if (_cachedStatus[courseId] != isCached) {
      _cachedStatus[courseId] = isCached;
      notifyListeners();
    }
  }

  Future<void> loadCourses({String? seriesId}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final path = seriesId != null ? '/courses?seriesId=$seriesId' : '/courses';
    
    try {
      await _api.getWithCache(
        path,
        onCacheHit: (cachedData) {
          final newCourses = cachedData['data'] as List;
          final isSame = const DeepCollectionEquality().equals(_courses, newCourses);
          if (!isSame) {
            _courses = newCourses;
            _loading = false;
            notifyListeners();
          }
        },
      );
      
      // Load from network
      final res = await _api.get(path);
      final newCourses = res['data'] as List;
      final isSame = const DeepCollectionEquality().equals(_courses, newCourses);
      _loading = false;
      if (!isSame) {
        _courses = newCourses;
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

  Future<void> loadCourseDetail(String courseId) async {
    _loadingDetail = true;
    _error = null;
    notifyListeners();

    final path = '/courses/$courseId';

    try {
      // Check cached status
      final cachedData = await CacheService.getCachedJson(path);
      if (cachedData != null) {
        final newDetail = cachedData['data'];
        final isSame = const DeepCollectionEquality().equals(_selectedCourse, newDetail);
        if (!isSame) {
          _selectedCourse = newDetail;
          _loadingDetail = false;
          notifyListeners();
        }
      }

      final res = await _api.get(path);
      final newDetail = res['data'];
      await CacheService.cacheJson(path, res);
      
      // Update history progress on backend
      await _api.post('/courses/$courseId/progress', {'progressPercent': 10, 'lastPosition': 0});
      
      final isSame = const DeepCollectionEquality().equals(_selectedCourse, newDetail);
      _loadingDetail = false;
      if (!isSame) {
        _selectedCourse = newDetail;
        notifyListeners();
      } else {
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      _loadingDetail = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String courseId, bool isCurrentlyFavorite) async {
    try {
      if (isCurrentlyFavorite) {
        await _api.delete('/courses/$courseId/favorite');
      } else {
        await _api.post('/courses/$courseId/favorite', {});
      }
      
      // Update local state if selectedCourse is active
      if (_selectedCourse != null && _selectedCourse!['id'] == courseId) {
        // Just reload details to keep state in sync
        loadCourseDetail(courseId);
      }
    } catch (_) {}
  }

  Future<void> downloadForOffline(String courseId, String fileUrl, String type) async {
    final ext = type == 'video' ? 'mp4' : 'pdf';
    _cachedStatus[courseId] = false;
    notifyListeners();

    try {
      // Simulate/Trigger download count increment
      final res = await _api.get('/courses/$courseId/download');
      final path = res['data']['fileUrl'] ?? fileUrl;
      
      final baseUrl = AppConstants.apiBaseUrl.endsWith('/api')
          ? AppConstants.apiBaseUrl.substring(0, AppConstants.apiBaseUrl.length - 4)
          : 'http://localhost:3000';
      final fullUrl = path.startsWith('http') ? path : '$baseUrl$path';
      
      final file = await CacheService.downloadAndCacheFile(courseId, fullUrl, ext);
      
      if (file != null) {
        _cachedStatus[courseId] = true;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> removeOfflineFile(String courseId, String type) async {
    final ext = type == 'video' ? 'mp4' : 'pdf';
    await CacheService.deleteCachedFile(courseId, ext);
    _cachedStatus[courseId] = false;
    notifyListeners();
  }
}
