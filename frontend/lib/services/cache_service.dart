import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class CacheService {
  static const String _jsonPrefix = 'cache_json_';

  // 1. JSON Cache (cache-first, network-fallback)
  static Future<void> cacheJson(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_jsonPrefix$key', jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> getCachedJson(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('$_jsonPrefix$key');
    if (jsonStr != null) {
      try {
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // 2. Local File Cache (PDF / Video download for offline use)
  static Future<String?> getCachedFilePath(String courseId, String fileExtension) async {
    if (kIsWeb) return null;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/course_$courseId.$fileExtension');
      if (await file.exists()) {
        return file.path;
      }
    } catch (_) {}
    return null;
  }

  static Future<File?> downloadAndCacheFile(String courseId, String fileUrl, String fileExtension) async {
    if (kIsWeb) return null;
    try {
      final response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/course_$courseId.$fileExtension');
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> isFileCached(String courseId, String fileExtension) async {
    if (kIsWeb) return false;
    final path = await getCachedFilePath(courseId, fileExtension);
    return path != null;
  }

  static Future<void> deleteCachedFile(String courseId, String fileExtension) async {
    if (kIsWeb) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/course_$courseId.$fileExtension');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
