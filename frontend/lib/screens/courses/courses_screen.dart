import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Cours')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: courses.length,
                itemBuilder: (_, i) {
                  final c = courses[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(c['type'] == 'video' ? Icons.play_arrow : Icons.picture_as_pdf),
                      ),
                      title: Text(c['title'] ?? ''),
                      subtitle: Text('${c['subjectName'] ?? ''} • ${c['type']}'),
                      trailing: c['isPremium'] == true ? const Chip(label: Text('Premium')) : null,
                      onTap: () => context.go('/courses/${c['id']}'),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
