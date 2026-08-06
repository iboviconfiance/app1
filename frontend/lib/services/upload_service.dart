import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class UploadResult {
  final String url;
  final String filename;
  final int size;

  const UploadResult({
    required this.url,
    required this.filename,
    required this.size,
  });
}

/// Service d'upload de fichiers vers l'API KLAS+.
///
/// Gère automatiquement la différence Flutter Web (bytes) vs Mobile (path)
/// et expose une callback de progression pour afficher une ProgressBar.
class UploadService {
  final String baseUrl;

  UploadService({required this.baseUrl});

  /// Upload un fichier et renvoie son URL publique sur le serveur.
  ///
  /// [file]       : PlatformFile issu de file_picker
  /// [fileType]   : 'pdf' | 'video' | 'image' | 'exam'
  /// [token]      : JWT de l'utilisateur connecté
  /// [onProgress] : callback 0.0 → 1.0 pendant la transmission
  Future<UploadResult> uploadFile({
    required PlatformFile file,
    required String fileType,
    required String token,
    void Function(double progress)? onProgress,
  }) async {
    final uri = Uri.parse('$baseUrl/api/admin/upload?fileType=$fileType');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    // ── Piège 1 corrigé : Web utilise fromBytes, Mobile utilise fromPath ─────
    http.MultipartFile multipartFile;

    if (kIsWeb) {
      // Sur Flutter Web, file.path est null (accès au chemin système interdit).
      // On utilise les octets lus en mémoire par file_picker.
      if (file.bytes == null) {
        throw Exception('Impossible de lire le fichier : bytes null (Web).');
      }
      multipartFile = http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
      );
    } else {
      // Sur mobile ou desktop, on utilise le chemin d'accès local.
      if (file.path == null) {
        throw Exception('Chemin du fichier introuvable (Mobile).');
      }
      multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path!,
        filename: file.name,
      );
    }

    request.files.add(multipartFile);

    // ── Envoi et suivi de progression ─────────────────────────────────────────
    final stream = await request.send();

    int bytesReceived = 0;
    final totalBytes = stream.contentLength ?? 0;
    final responseBytes = <int>[];
    final completer = Completer<http.Response>();

    stream.stream.listen(
      (chunk) {
        responseBytes.addAll(chunk);
        bytesReceived += chunk.length;
        if (onProgress != null && totalBytes > 0) {
          onProgress((bytesReceived / totalBytes).clamp(0.0, 1.0));
        }
      },
      onDone: () {
        if (onProgress != null) onProgress(1.0);
        completer.complete(
          http.Response.bytes(
            responseBytes,
            stream.statusCode,
            headers: stream.headers,
            request: stream.request,
          ),
        );
      },
      onError: (Object err) => completer.completeError(err),
    );

    final response = await completer.future;

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;
      return UploadResult(
        url: data['url'] as String,
        filename: data['filename'] as String,
        size: (data['size'] as num).toInt(),
      );
    } else {
      Map<String, dynamic> json = {};
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}
      throw Exception(
        json['message'] ?? 'Erreur upload (HTTP ${response.statusCode})',
      );
    }
  }
}
