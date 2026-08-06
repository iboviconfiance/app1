import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AdminProvider extends ChangeNotifier {
  final ApiService _api;

  bool _loading = false;
  Map<String, dynamic>? _stats;
  List<dynamic> _subjects = [];
  List<dynamic> _courses = [];
  List<dynamic> _exercises = [];
  List<dynamic> _users = [];
  String? _error;

  AdminProvider(this._api);

  bool get loading => _loading;
  Map<String, dynamic>? get stats => _stats;
  List<dynamic> get subjects => _subjects;
  List<dynamic> get courses => _courses;
  List<dynamic> get exercises => _exercises;
  List<dynamic> get users => _users;
  String? get error => _error;

  void _clearError() {
    _error = null;
  }

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

  // --- SUBJECTS CRUD ---
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

  Future<void> createSubject(String name, String description, String icon, String color) async {
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

  Future<void> updateSubject(String id, String name, String description, String icon, String color) async {
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

  // --- COURSES CRUD ---
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

  // --- EXERCISES CRUD ---
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

  // --- EXERCISE QUESTIONS CRUD ---
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

  Future<void> createQuestion(String exerciseId, Map<String, dynamic> data) async {
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

  Future<void> updateQuestion(String questionId, Map<String, dynamic> data) async {
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

  // --- USERS MANAGEMENT ---
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
