import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../config/constants.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    final user = context.read<AuthProvider>().user;
    final seriesId = user?['seriesId'];
    await context.read<CourseProvider>().loadCourses(seriesId: seriesId);
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();
    final courses = courseProvider.courses;
    final loading = courseProvider.loading;
    final theme = Theme.of(context);

    final String serverUrl = AppConstants.apiBaseUrl.endsWith('/api')
        ? AppConstants.apiBaseUrl.substring(0, AppConstants.apiBaseUrl.length - 4)
        : AppConstants.apiBaseUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mes Cours'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: courses.length,
                itemBuilder: (_, i) {
                  final c = courses[i];
                  final isVideo = c['type'] == 'video';
                  final isPremium = c['isPremium'] == true || c['is_premium'] == true;
                  final thumbnailUrl = c['thumbnailUrl'] ?? c['thumbnail_url'];
                  
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.go('/courses/${c['id']}'),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Thumbnail / Icon banner
                            Container(
                              width: 110,
                              color: isVideo ? const Color(0xFFF3E8FF) : const Color(0xFFFEE2E2),
                              child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                                  ? Image.network(
                                      thumbnailUrl.startsWith('http') ? thumbnailUrl : '$serverUrl$thumbnailUrl',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Icon(
                                          isVideo ? Icons.play_circle_fill_rounded : Icons.picture_as_pdf_rounded,
                                          color: isVideo ? Colors.purple[700] : Colors.red[700],
                                          size: 32,
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Icon(
                                        isVideo ? Icons.play_circle_fill_rounded : Icons.picture_as_pdf_rounded,
                                        color: isVideo ? Colors.purple[700] : Colors.red[700],
                                        size: 32,
                                      ),
                                    ),
                            ),
                            
                            // Course details info
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c['title'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Color(0xFF1E293B),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          c['subjectName'] ?? c['subject_name'] ?? '',
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isVideo ? Colors.purple[50] : Colors.red[50],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            isVideo ? 'Vidéo' : 'Document PDF',
                                            style: TextStyle(
                                              color: isVideo ? Colors.purple[800] : Colors.red[800],
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (isPremium)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFF59E0B), width: 0.5),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.workspace_premium_rounded, color: Color(0xFFD97706), size: 10),
                                                SizedBox(width: 2),
                                                Text(
                                                  'PREMIUM',
                                                  style: TextStyle(
                                                    color: Color(0xFFB45309),
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
