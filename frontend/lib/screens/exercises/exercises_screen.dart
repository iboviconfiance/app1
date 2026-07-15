import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  List<dynamic> _exercises = [];
  bool _loading = true;
  String? _filter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<AuthProvider>().user;
    var path = '/exercises';
    if (_filter != null) path += '?type=$_filter';
    else if (user?['seriesId'] != null) path += '?seriesId=${user!['seriesId']}';
    final res = await context.read<AuthProvider>().api.get(path);
    setState(() { _exercises = res['data'] as List; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercices'),
        actions: [
          PopupMenuButton<String?>(
            onSelected: (v) { setState(() { _filter = v; _loading = true; }); _load(); },
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('Tous')),
              const PopupMenuItem(value: 'qcm', child: Text('QCM')),
              const PopupMenuItem(value: 'quiz', child: Text('Quiz')),
              const PopupMenuItem(value: 'examen_blanc', child: Text('Examens blancs')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _exercises.length,
              itemBuilder: (_, i) {
                final e = _exercises[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.quiz),
                    title: Text(e['title'] ?? ''),
                    subtitle: Text('${e['type']} • ${e['subjectName'] ?? ''} • ${e['durationMinutes']} min'),
                    onTap: () => context.go('/exercises/${e['id']}'),
                  ),
                );
              },
            ),
    );
  }
}
