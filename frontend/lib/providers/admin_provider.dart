import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/upload_service.dart';
import 'package:file_picker/file_picker.dart';

class AdminProvider extends ChangeNotifier {
  final ApiService _api;

  bool _loading = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _analytics;
  List<dynamic> _subjects = [];
  List<dynamic> _courses = [];
  List<dynamic> _exercises = [];
  List<dynamic> _exams = [];
  List<dynamic> _users = [];
  String? _error;
  String _searchQuery = '';

  AdminProvider(this._api);

  bool get loading => _loading;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  Map<String, dynamic>? get stats => _stats;
  Map<String, dynamic>? get analytics => _analytics;
  List<dynamic> get subjects => _subjects;
  List<dynamic> get courses => _courses;
  List<dynamic> get exercises => _exercises;
  List<dynamic> get exams => _exams;
  List<dynamic> get users => _users;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  void _clearError() => _error = null;

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UPLOAD DE FICHIERS
  // ──────────────────────────────────────────────────────────────────────────

  /// Upload un fichier vers le serveur.
  /// Retourne l'URL publique du fichier ou null en cas d'erreur.
  Future<String?> uploadFile({
    required PlatformFile file,
    required String fileType,
  }) async {
    final token = _api.token;
    if (token == null) return null;

    final uploadService = UploadService(baseUrl: _api.serverBaseUrl);

    _isUploading = true;
    _uploadProgress = 0.0;
    _clearError();
    notifyListeners();

    try {
      final result = await uploadService.uploadFile(
        file: file,
        fileType: fileType,
        token: token,
        onProgress: (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );
      return result.url;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isUploading = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }



  // ──────────────────────────────────────────────────────────────────────────
  // STATS
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> loadStats() async {
    _loading = true;
    _clearError();
    notifyListeners();
    try {
      final res = await _api.get('/admin/stats');
      _stats = res['data'];
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ANALYTICS PROFESSEUR
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> loadAnalytics({
    String? seriesId,
    String? classroomId,
    DateTime? dateFrom,
  }) async {
    _loading = true;
    _clearError();
    notifyListeners();
    try {
      final queryParams = <String, String>{};
      if (seriesId != null) queryParams['seriesId'] = seriesId;
      if (classroomId != null) queryParams['classroomId'] = classroomId;
      if (dateFrom != null) queryParams['dateFrom'] = dateFrom.toIso8601String();

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final endpoint = '/admin/analytics${queryString.isNotEmpty ? '?$queryString' : ''}';
      final res = await _api.get(endpoint);
      _analytics = res['data'];
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SUBJECTS CRUD
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> loadSubjects() async {
    _loading = true;
    _clearError();
    notifyListeners();
    try {
      final res = await _api.get('/admin/subjects');
      _subjects = res['data'] ?? [];
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> createSubject(
      String name, String description, String icon, String color) async {
    _loading = true;
    _clearError();
    notifyListeners();
    try {
      await _api.post('/admin/subjects', {
        'name': name,
        'description': description,
        'icon': icon,
        'color': color,
      });
      await loadSubjects();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateSubject(
      String id, String name, String description, String icon, String color) async {
    _loading = true;
    _clearError();
    notifyListeners();
    try {
      await _api.put('/admin/subjects/$id', {
        'name': name,
        'description': description,
        'icon': icon,
        'color': color,
      });
      await loadSubjects();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteSubject(String id) async {
    _loading = true;
    _clearError();
    notifyListeners();
    try {
      await _api.delete('/admin/subjects/$id');
      await loadSubjects();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // COURSES CRUD
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> loadCourses() async {
    _loading = true;
    _clearError();
    notifyListeners();
    try {
      final res = await _api.get('/admin/courses');
      _courses = res['data'] ?? [];
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> createCourse(Map<String, dynamic> data) async {
    _loading = true;
    _clearError();
    notifyListeners();
    try {
      await _api.post('/admin/courses', data);
      await loadCourses();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCourse(String id, Map<String, dynamic> data) async {
    _loading = true;
    _clearError();
    notifyListeners();
    try {
      await _api.put('/admin/courses/$id', data);
      await loadCourses();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCourse(String id) async {
    _loading = true;
    _clearError();
    notifyListeners();
    try {
      await _api.delete('/admin/courses/$id');
      await loadCourses();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // EXERCISES CRUD
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> loadExercises() async {
    _loading = true;
    _clearError();
    notifyListeners();
    try {
      final res = await _api.get('/admin/exercises');
      _exercises = res['data'] ?? [];
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> createExercise(Map<String, dynamic> data) async {
    _loading = true;
    _clearError();
    notifyListeners();
    try {
      await _api.post('/admin/exercises', data);
      await loadExercises();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateExercise(String id, Map<String, dynamic> data) async {
    _loading = true;
    _clearError();
    notifyListeners();
    try {
      await _api.put('/admin/exercises/$id', data);
      await loadExercises();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteExercise(String id) async {
    _loading = true;
    _clearError();
    notifyListeners();
    try {
      await _api.delete('/admin/exercises/$id');
      await loadExercises();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // EXERCISE QUESTIONS CRUD
  // ──────────────────────────────────────────────────────────────────────────

  Future<List<dynamic>> loadQuestions(String exerciseId) async {
    _loading = true;
    _clearError();
    notifyListeners();
    try {
      final res = await _api.get('/admin/exercises/$exerciseId/questions');
      return res['data'] ?? [];
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> createQuestion(
      String exerciseId, Map<String, dynamic> data) async {
    _loading = true;
    _clearError();
    notifyListeners();
    try {
      await _api.post('/admin/exercises/$exerciseId/questions', data);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateQuestion(
      String questionId, Map<String, dynamic> data) async {
    _loading = true;
    _clearError();
    notifyListeners();
    try {
      await _api.put('/admin/questions/$questionId', data);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteQuestion(String questionId) async {
    _loading = true;
    _clearError();
    notifyListeners();
    try {
      await _api.delete('/admin/questions/$questionId');
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // EXAMS / ANNALES CRUD
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> loadExams() async {
    _loading = true;
    _clearError();
    notifyListeners();
    try {
      final res = await _api.get('/admin/exams');
      _exams = res['data'] ?? [];
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> createExam(Map<String, dynamic> data) async {
    _loading = true;
    _clearError();
    notifyListeners();
    try {
      await _api.post('/admin/exams', data);
      await loadExams();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateExam(String id, Map<String, dynamic> data) async {
    _loading = true;
    _clearError();
    notifyListeners();
    try {
      await _api.put('/admin/exams/$id', data);
      await loadExams();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteExam(String id) async {
    _loading = true;
    _clearError();
    notifyListeners();
    try {
      await _api.delete('/admin/exams/$id');
      await loadExams();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // USERS MANAGEMENT
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> loadUsers() async {
    _loading = true;
    _clearError();
    notifyListeners();
    try {
      final res = await _api.get('/admin/users');
      _users = res['data'] ?? [];
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserRole(String id, String role) async {
    _loading = true;
    _clearError();
    notifyListeners();
    try {
      await _api.put('/admin/users/$id/role', {'role': role});
      await loadUsers();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }
}
