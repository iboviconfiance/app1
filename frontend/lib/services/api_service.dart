import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'cache_service.dart';

class ApiService {
  String? _token;

  void setToken(String? token) => _token = token;

  /// Token JWT courant (peut être null si non connecté)
  String? get token => _token;

  /// Base URL du serveur (sans le suffixe /api) pour les uploads multipart
  String get serverBaseUrl {
    final api = AppConstants.apiBaseUrl; // ex: '/api' ou 'http://localhost:3000/api'
    if (api.startsWith('http')) {
      // Enlève le suffixe '/api' pour obtenir l'origine
      return api.endsWith('/api') ? api.substring(0, api.length - 4) : api;
    }
    // En mode Docker/Nginx, l'URL est relative → on utilise l'origine de la page
    return ''; // URL vide = même origine (Flutter Web)
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(Uri.parse('${AppConstants.apiBaseUrl}$path'), headers: _headers);
    return _handle(res);
  }

  Future<Map<String, dynamic>> getWithCache(String path, {String? customCacheKey, Function(Map<String, dynamic>)? onCacheHit}) async {
    final cacheKey = customCacheKey ?? path;
    
    // Check cache with 2 hours TTL for instant load
    final cachedData = await CacheService.getCachedJson(cacheKey, maxAge: const Duration(hours: 2));
    if (cachedData != null && onCacheHit != null) {
      onCacheHit(cachedData);
    }

    try {
      final res = await http.get(Uri.parse('${AppConstants.apiBaseUrl}$path'), headers: _headers);
      final data = _handle(res);
      await CacheService.cacheJson(cacheKey, data);
      return data;
    } catch (e) {
      // On network failure, try to fall back to the stale cache (ignoring TTL)
      final staleData = cachedData ?? await CacheService.getCachedJson(cacheKey);
      if (staleData != null) {
        if (cachedData == null && onCacheHit != null) {
          onCacheHit(staleData);
        }
        return staleData;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('${AppConstants.apiBaseUrl}$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final res = await http.delete(Uri.parse('${AppConstants.apiBaseUrl}$path'), headers: _headers);
    return _handle(res);
  }

  Map<String, dynamic> _handle(http.Response res) {
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(data['message'] ?? 'Erreur serveur');
    }
    return data;
  }
}
