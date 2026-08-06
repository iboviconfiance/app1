import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

class AdminExercisesScreen extends StatefulWidget {
  const AdminExercisesScreen({super.key});

  @override
  State<AdminExercisesScreen> createState() => _AdminExercisesScreenState();
}

class _AdminExercisesScreenState extends State<AdminExercisesScreen> {
  List<dynamic> _classrooms = [];
  List<dynamic> _seriesList = [];
  bool _loadingMetadata = false;
  Map<String, dynamic>? _selectedExerciseForQuestions;
  List<dynamic> _questions = [];
  bool _loadingQuestions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadExercises();
      context.read<AdminProvider>().loadSubjects();
      _loadMetadata();
    });
  }

  Future<void> _loadMetadata() async {
    setState(() => _loadingMetadata = true);
    try {
      final auth = context.read<AuthProvider>();
      final classRes = await auth.api.get('/school/classrooms');
      final seriesRes = await auth.api.get('/school/series');
      setState(() {
        _classrooms = classRes['data'] ?? [];
        _seriesList = seriesRes['data'] ?? [];
      });
    } catch (_) {}
    setState(() => _loadingMetadata = false);
  }

  Future<void> _loadQuestions(Map<String, dynamic> exercise) async {
    setState(() {
      _selectedExerciseForQuestions = exercise;
      _loadingQuestions = true;
    });
    try {
      final qList = await context.read<AdminProvider>().loadQuestions(exercise['id']);
      setState(() {
        _questions = qList;
      });
    } catch (_) {}
    setState(() => _loadingQuestions = false);
  }

  void _showFormDialog([Map<String, dynamic>? exercise]) {
    final isEdit = exercise != null;
    final titleCtrl = TextEditingController(text: exercise?['title'] ?? '');
    final descCtrl = TextEditingController(text: exercise?['description'] ?? '');
    final durationCtrl = TextEditingController(text: '${exercise?['durationMinutes'] ?? exercise?['duration_minutes'] ?? 30}');
    final pointsCtrl = TextEditingController(text: '${exercise?['totalPoints'] ?? exercise?['total_points'] ?? 20}');

    final adminProv = context.read<AdminProvider>();
    final subjects = adminProv.subjects;

    String? selectedSubjectId = exercise?['subjectId'] ?? exercise?['subject_id'];
    if (selectedSubjectId != null && !subjects.any((s) => s['id'] == selectedSubjectId)) {
      selectedSubjectId = null;
    }
    if (selectedSubjectId == null && subjects.isNotEmpty) {
      selectedSubjectId = subjects.first['id'];
    }

    String? selectedClassroomId = exercise?['classroomId'] ?? exercise?['classroom_id'];
    if (selectedClassroomId != null && !_classrooms.any((c) => c['id'] == selectedClassroomId)) {
      selectedClassroomId = null;
    }
    if (selectedClassroomId == null && _classrooms.isNotEmpty) {
      selectedClassroomId = _classrooms.first['id'];
    }

    String? selectedSeriesId = exercise?['seriesId'] ?? exercise?['series_id'];
    if (selectedSeriesId != null && !_seriesList.any((s) => s['id'] == selectedSeriesId)) {
      selectedSeriesId = null;
    }
    if (selectedSeriesId == null && _seriesList.isNotEmpty) {
      selectedSeriesId = _seriesList.first['id'];
    }

    bool isPremium = exercise?['isPremium'] ?? exercise?['is_premium'] ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(isEdit ? 'Modifier l\'exercice' : 'Ajouter un exercice'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Titre de l\'exercice (QCM)')),
                    const SizedBox(height: 12),
                    TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: durationCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Durée (minutes)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: pointsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Points totaux'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (subjects.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        value: selectedSubjectId,
                        decoration: const InputDecoration(labelText: 'Matière'),
                        items: subjects.map<DropdownMenuItem<String>>((s) {
                          return DropdownMenuItem<String>(
                            value: s['id'],
                            child: Text(s['name'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (val) => setDialogState(() => selectedSubjectId = val),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (_classrooms.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        value: selectedClassroomId,
                        decoration: const InputDecoration(labelText: 'Classe scolaire'),
                        items: _classrooms.map<DropdownMenuItem<String>>((c) {
                          return DropdownMenuItem<String>(
                            value: c['id'],
                            child: Text('${c['name']} (${c['level']})'),
                          );
                        }).toList(),
                        onChanged: (val) => setDialogState(() => selectedClassroomId = val),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (_seriesList.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        value: selectedSeriesId,
                        decoration: const InputDecoration(labelText: 'Série / Filière'),
                        items: _seriesList.map<DropdownMenuItem<String>>((s) {
                          return DropdownMenuItem<String>(
                            value: s['id'],
                            child: Text(s['name'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (val) => setDialogState(() => selectedSeriesId = val),
                      ),
                      const SizedBox(height: 16),
                    ],

                    CheckboxListTile(
                      title: const Text('Accès Premium Requis', style: TextStyle(fontSize: 14)),
                      value: isPremium,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setDialogState(() => isPremium = val ?? false),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    
                    final body = {
                      'title': titleCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'type': 'qcm',
                      'durationMinutes': int.tryParse(durationCtrl.text) ?? 30,
                      'totalPoints': int.tryParse(pointsCtrl.text) ?? 20,
                      'subjectId': selectedSubjectId,
                      'classroomId': selectedClassroomId,
                      'seriesId': selectedSeriesId,
                      'isPremium': isPremium,
                    };
                    
                    if (isEdit) {
                      await adminProv.updateExercise(exercise['id'], body);
                      if (_selectedExerciseForQuestions?['id'] == exercise['id']) {
                        setState(() {
                          _selectedExerciseForQuestions = {
                            ..._selectedExerciseForQuestions!,
                            ...body,
                          };
                        });
                      }
                    } else {
                      await adminProv.createExercise(body);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteConfirm(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'exercice ?'),
        content: Text('Êtes-vous sûr de vouloir supprimer l\'exercice "$name" ? Toutes les questions liées seront également supprimées.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<AdminProvider>().deleteExercise(id);
              if (_selectedExerciseForQuestions?['id'] == id) {
                setState(() {
                  _selectedExerciseForQuestions = null;
                  _questions = [];
                });
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // --- QUESTIONS EDIT DIALOG ---
  void _showQuestionFormDialog([Map<String, dynamic>? question]) {
    final isEdit = question != null;
    final textCtrl = TextEditingController(text: question?['questionText'] ?? question?['question_text'] ?? '');
    final explCtrl = TextEditingController(text: question?['explanation'] ?? '');
    final pointsCtrl = TextEditingController(text: '${question?['points'] ?? 4}');
    
    // Parse options
    List<dynamic> options = [];
    if (question != null) {
      options = List.from(question['options'] ?? []);
    }
    // Ensure we have at least 4 options
    while (options.length < 4) {
      options.add('');
    }

    final List<TextEditingController> optionCtrls = options.map((opt) => TextEditingController(text: opt.toString())).toList();
    int correctAnswer = question?['correctAnswer'] ?? question?['correct_answer'] ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(isEdit ? 'Modifier la question' : 'Ajouter une question'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: textCtrl,
                      decoration: const InputDecoration(labelText: 'Énoncé de la question'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pointsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Points attribués'),
                    ),
                    const SizedBox(height: 16),
                    
                    const Text('Options de réponse (Cochez la bonne réponse)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    ...List.generate(4, (i) {
                      return Row(
                        children: [
                          Radio<int>(
                            value: i,
                            groupValue: correctAnswer,
                            onChanged: (val) => setDialogState(() => correctAnswer = val!),
                          ),
                          Expanded(
                            child: TextField(
                              controller: optionCtrls[i],
                              decoration: InputDecoration(labelText: 'Option ${i + 1}'),
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 16),
                    TextField(
                      controller: explCtrl,
                      decoration: const InputDecoration(labelText: 'Explication pédagogique (facultatif)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (textCtrl.text.trim().isEmpty) return;
                    
                    final parsedOptions = optionCtrls.map((c) => c.text.trim()).toList();
                    if (parsedOptions.any((opt) => opt.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Veuillez remplir toutes les options de réponse')),
                      );
                      return;
                    }

                    final adminProv = context.read<AdminProvider>();
                    final exerciseId = _selectedExerciseForQuestions!['id'];

                    final body = {
                      'questionText': textCtrl.text.trim(),
                      'options': parsedOptions,
                      'correctAnswer': correctAnswer,
                      'points': int.tryParse(pointsCtrl.text) ?? 4,
                      'explanation': explCtrl.text.trim(),
                      'orderIndex': isEdit ? (question['orderIndex'] ?? question['order_index'] ?? 1) : (_questions.length + 1),
                    };

                    if (isEdit) {
                      await adminProv.updateQuestion(question['id'], body);
                    } else {
                      await adminProv.createQuestion(exerciseId, body);
                    }
                    
                    // Reload questions list
                    await _loadQuestions(_selectedExerciseForQuestions!);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteQuestionConfirm(String questionId, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la question ?'),
        content: Text('Êtes-vous sûr de vouloir supprimer la question : "$text" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<AdminProvider>().deleteQuestion(questionId);
              await _loadQuestions(_selectedExerciseForQuestions!);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final exercises = adminProv.exercises;
    final loading = adminProv.loading || _loadingMetadata;

    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    Widget exercisesListView = ListView.builder(
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final e = exercises[index];
        final isSelected = _selectedExerciseForQuestions?['id'] == e['id'];
        final isPremium = e['isPremium'] == true || e['is_premium'] == true;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isSelected ? theme.colorScheme.primary : const Color(0xFFF1F5F9), width: isSelected ? 2.0 : 1.5),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.quiz_rounded, color: Color(0xFF059669), size: 24),
            ),
            title: Text(
              e['title'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${e['subject_name'] ?? e['subjectName'] ?? ''} • ${e['classroom_name'] ?? e['classroomName'] ?? ''} • ${e['durationMinutes'] ?? e['duration_minutes'] ?? 30} min',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
                if (isPremium) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Premium',
                      style: TextStyle(color: Color(0xFFD97706), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () => _showFormDialog(e),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  onPressed: () => _deleteConfirm(e['id'], e['title']),
                ),
              ],
            ),
            onTap: () => _loadQuestions(e),
          ),
        );
      },
    );

    Widget questionsView = _selectedExerciseForQuestions == null
        ? const Center(
            child: Text(
              'Sélectionnez un QCM pour gérer ses questions.',
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Questions de : ${_selectedExerciseForQuestions!['title']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.green),
                      onPressed: () => _showQuestionFormDialog(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
              Expanded(
                child: _loadingQuestions
                    ? const Center(child: CircularProgressIndicator())
                    : _questions.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text(
                                'Aucune question dans ce QCM. Cliquez sur le bouton + pour en ajouter.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF94A3B8)),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _questions.length,
                            itemBuilder: (context, index) {
                              final q = _questions[index];
                              final text = q['questionText'] ?? q['question_text'] ?? '';
                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Q${index + 1} : $text',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              GestureDetector(
                                                child: const Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
                                                onTap: () => _showQuestionFormDialog(q),
                                              ),
                                              const SizedBox(width: 12),
                                              GestureDetector(
                                                child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                                                onTap: () => _deleteQuestionConfirm(q['id'], text),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      ...(q['options'] as List? ?? []).asMap().entries.map((entry) {
                                        final optIndex = entry.key;
                                        final optText = entry.value;
                                        final isCorrect = optIndex == (q['correctAnswer'] ?? q['correct_answer']);

                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 6.0),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isCorrect ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                                                color: isCorrect ? Colors.green : Colors.grey,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  optText.toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isCorrect ? Colors.green[800] : const Color(0xFF475569),
                                                    fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Gestion des Exercices & QCM'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (_selectedExerciseForQuestions != null && !isDesktop) {
              setState(() {
                _selectedExerciseForQuestions = null;
                _questions = [];
              });
            } else {
              context.go('/admin');
            }
          },
        ),
      ),
      body: isDesktop
          ? Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: loading && exercises.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : exercisesListView,
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                Expanded(
                  flex: 4,
                  child: questionsView,
                ),
              ],
            )
          : (_selectedExerciseForQuestions != null ? questionsView : Padding(
              padding: const EdgeInsets.all(16.0),
              child: loading && exercises.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : exercisesListView,
            )),
      floatingActionButton: _selectedExerciseForQuestions != null && !isDesktop
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showFormDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Créer un QCM'),
            ),
    );
  }
}
