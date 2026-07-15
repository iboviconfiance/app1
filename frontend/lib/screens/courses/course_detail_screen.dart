import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../services/cache_service.dart';

class CourseDetailScreen extends StatefulWidget {
  final String id;
  const CourseDetailScreen({super.key, required this.id});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    final courseProvider = context.read<CourseProvider>();
    final authProvider = context.read<AuthProvider>();
    
    await courseProvider.loadCourseDetail(widget.id);
    
    try {
      final favoritesRes = await authProvider.api.get('/courses/favorites');
      final favorites = favoritesRes['data'] as List;
      setState(() {
        _isFavorite = favorites.any((fav) => fav['id'] == widget.id);
      });
    } catch (_) {}

    final course = courseProvider.selectedCourse;
    if (course != null) {
      await courseProvider.checkCachedStatus(widget.id, course['type'] ?? 'pdf');
    }
  }

  Future<void> _toggleFavorite() async {
    final courseProvider = context.read<CourseProvider>();
    await courseProvider.toggleFavorite(widget.id, _isFavorite);
    setState(() => _isFavorite = !_isFavorite);
  }

  Future<void> _downloadOrPlayOffline(Map<String, dynamic> course) async {
    final type = course['type'] ?? 'pdf';
    final ext = type == 'video' ? 'mp4' : 'pdf';
    final courseProvider = context.read<CourseProvider>();
    final isCached = courseProvider.isCourseFileCached(widget.id, type);

    if (isCached) {
      final path = await CacheService.getCachedFilePath(widget.id, ext);
      if (path != null) {
        final uri = Uri.file(path);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ouverture locale : $path')),
            );
          }
        }
      }
    } else {
      final fileUrl = course['fileUrl'] ?? '';
      await courseProvider.downloadForOffline(widget.id, fileUrl, type);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cours disponible hors-ligne !')),
        );
      }
    }
  }

  Future<void> _removeOffline(String type) async {
    final courseProvider = context.read<CourseProvider>();
    await courseProvider.removeOfflineFile(widget.id, type);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fichier supprimé du cache local')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();
    final loading = courseProvider.loadingDetail;
    final c = courseProvider.selectedCourse;

    if (loading || c == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final type = c['type'] ?? 'pdf';
    final isCached = courseProvider.isCourseFileCached(widget.id, type);

    return Scaffold(
      appBar: AppBar(
        title: Text(c['title'] ?? ''),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.red : null),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(c['description'] ?? '', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            if (type == 'video')
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Icon(Icons.play_circle_fill, size: 64)),
                ),
              ),
            const SizedBox(height: 16),
            if (isCached)
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text('Disponible hors-ligne', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _removeOffline(type),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Retirer', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            const Spacer(),
            if (type == 'pdf')
              FilledButton.icon(
                onPressed: () => _downloadOrPlayOffline(c),
                icon: Icon(isCached ? Icons.chrome_reader_mode : Icons.download),
                label: Text(isCached ? 'Lire le PDF local' : 'Télécharger PDF'),
              ),
            if (type == 'video')
              FilledButton.icon(
                onPressed: () => _downloadOrPlayOffline(c),
                icon: Icon(isCached ? Icons.play_arrow : Icons.download),
                label: Text(isCached ? 'Lire la vidéo locale' : 'Télécharger la vidéo'),
              ),
          ],
        ),
      ),
    );
  }
}
