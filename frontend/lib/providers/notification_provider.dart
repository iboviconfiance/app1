import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Modèle local représentant une notification de l'utilisateur.
class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'course' | 'exercise' | 'subscription' | 'general'
  final String? actionRoute; // Route GoRouter cible (ex: '/school')
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.actionRoute,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String? ?? 'general',
      actionRoute: json['actionRoute'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      actionRoute: actionRoute,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

/// Provider gérant la liste des notifications de l'utilisateur.
/// Appelle GET /api/notifications et POST /api/notifications/read-all.
class NotificationProvider extends ChangeNotifier {
  final ApiService _api;

  List<AppNotification> _notifications = [];
  bool _loading = false;
  String? _error;

  NotificationProvider(this._api);

  List<AppNotification> get notifications => _notifications;
  bool get loading => _loading;
  String? get error => _error;

  /// Nombre de notifications non lues.
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Charge les notifications depuis l'API backend.
  Future<void> loadNotifications() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/notifications');
      final list = res['data'] as List<dynamic>? ?? [];
      _notifications = list
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Marque toutes les notifications comme lues (appel API + état local).
  Future<void> markAllAsRead() async {
    try {
      await _api.post('/notifications/read-all', {});
      _notifications =
          _notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Marque une notification individuelle comme lue (appel API + état local).
  Future<void> markAsRead(String notificationId) async {
    try {
      await _api.post('/notifications/$notificationId/read', {});
      _notifications = _notifications.map((n) {
        return n.id == notificationId ? n.copyWith(isRead: true) : n;
      }).toList();
      notifyListeners();
    } catch (_) {}
  }
}
