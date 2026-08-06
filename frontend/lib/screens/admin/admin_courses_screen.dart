import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

class AdminCoursesScreen extends StatefulWidget {
  const AdminCoursesScreen({super.key});

  @override
  State<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends State<AdminCoursesScreen> {
  List<dynamic> _classrooms = [];
  List<dynamic> _seriesList = [];
  bool _loadingMetadata = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadCourses();
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

  void _showFormDialog([Map<String, dynamic>? course]) {
    final isEdit = course != null;
    final titleCtrl = TextEditingController(text: course?['title'] ?? '');
    final descCtrl = TextEditingController(text: course?['description'] ?? '');
    String selectedType = course?['type'] ?? 'pdf';

    // URL states (utilisés si pas d'upload)
    String fileUrl = course?['fileUrl'] ?? course?['file_url'] ?? '';
    String videoUrl = course?['videoUrl'] ?? course?['video_url'] ?? '';
    String thumbnailUrl = course?['thumbnailUrl'] ?? course?['thumbnail_url'] ?? '';

    // Nom des fichiers sélectionnés (affichage)
    String? pickedMainFileName;
    String? pickedThumbFileName;

    final adminProv = context.read<AdminProvider>();
    final subjects = adminProv.subjects;

    String? selectedSubjectId = course?['subjectId'] ?? course?['subject_id'];
    if (selectedSubjectId != null && !subjects.any((s) => s['id'] == selectedSubjectId)) {
      selectedSubjectId = null;
    }
    if (selectedSubjectId == null && subjects.isNotEmpty) {
      selectedSubjectId = subjects.first['id'];
    }

    String? selectedClassroomId = course?['classroomId'] ?? course?['classroom_id'];
    if (selectedClassroomId != null && !_classrooms.any((c) => c['id'] == selectedClassroomId)) {
      selectedClassroomId = null;
    }
    if (selectedClassroomId == null && _classrooms.isNotEmpty) {
      selectedClassroomId = _classrooms.first['id'];
    }

    String? selectedSeriesId = course?['seriesId'] ?? course?['series_id'];
    if (selectedSeriesId != null && !_seriesList.any((s) => s['id'] == selectedSeriesId)) {
      selectedSeriesId = null;
    }
    if (selectedSeriesId == null && _seriesList.isNotEmpty) {
      selectedSeriesId = _seriesList.first['id'];
    }

    bool isPremium = course?['isPremium'] ?? course?['is_premium'] ?? false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickAndUploadFile({required bool isMainFile}) async {
              final type = isMainFile
                  ? (selectedType == 'pdf' ? FileType.custom : FileType.video)
                  : FileType.image;
              final exts = isMainFile
                  ? (selectedType == 'pdf' ? ['pdf'] : ['mp4'])
                  : ['jpg', 'jpeg', 'png', 'webp'];

              final result = await FilePicker.platform.pickFiles(
                type: type,
                allowedExtensions: type == FileType.custom || type == FileType.image ? exts : null,
                withData: true,
              );
              if (result == null || result.files.isEmpty) return;
              final file = result.files.first;

              final uploadType = isMainFile
                  ? (selectedType == 'pdf' ? 'pdf' : 'video')
                  : 'image';
              final url = await adminProv.uploadFile(file: file, fileType: uploadType);
              if (url != null) {
                setDialogState(() {
                  if (isMainFile) {
                    if (selectedType == 'pdf') {
                      fileUrl = url;
                    } else {
                      videoUrl = url;
                    }
                    pickedMainFileName = file.name;
                  } else {
                    thumbnailUrl = url;
                    pickedThumbFileName = file.name;
                  }
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(isEdit ? 'Modifier le cours' : 'Ajouter un cours'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Titre du cours'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 16),

                    // Type selector
                    const Text('Type de cours', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'pdf',
                          groupValue: selectedType,
                          onChanged: (val) => setDialogState(() {
                            selectedType = val!;
                            pickedMainFileName = null;
                          }),
                        ),
                        const Text('Document PDF'),
                        const SizedBox(width: 16),
                        Radio<String>(
                          value: 'video',
                          groupValue: selectedType,
                          onChanged: (val) => setDialogState(() {
                            selectedType = val!;
                            pickedMainFileName = null;
                          }),
                        ),
                        const Text('Vidéo'),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Upload barre de progression
                    Consumer<AdminProvider>(
                      builder: (ctx, prov, _) {
                        if (!prov.isUploading) return const SizedBox.shrink();
                        return Column(
                          children: [
                            LinearProgressIndicator(
                              value: prov.uploadProgress,
                              backgroundColor: Colors.grey[200],
                              color: const Color(0xFF2563EB),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upload en cours… ${(prov.uploadProgress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),

                    // Bouton upload fichier principal
                    OutlinedButton.icon(
                      onPressed: () => pickAndUploadFile(isMainFile: true),
                      icon: Icon(selectedType == 'pdf'
                          ? Icons.picture_as_pdf_rounded
                          : Icons.video_file_rounded),
                      label: Text(
                        pickedMainFileName != null
                            ? '✅ ${pickedMainFileName!}'
                            : (selectedType == 'pdf' ? 'Choisir un PDF' : 'Choisir une vidéo MP4'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Bouton upload thumbnail
                    OutlinedButton.icon(
                      onPressed: () => pickAndUploadFile(isMainFile: false),
                      icon: const Icon(Icons.image_outlined),
                      label: Text(
                        pickedThumbFileName != null
                            ? '✅ ${pickedThumbFileName!}'
                            : 'Choisir une image de couverture',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dropdowns
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
                      'type': selectedType,
                      'fileUrl': selectedType == 'pdf' ? fileUrl : null,
                      'videoUrl': selectedType == 'video' ? videoUrl : null,
                      'thumbnailUrl': thumbnailUrl.isNotEmpty ? thumbnailUrl : null,
                      'subjectId': selectedSubjectId,
                      'classroomId': selectedClassroomId,
                      'seriesId': selectedSeriesId,
                      'isPremium': isPremium,
                    };
                    if (isEdit) {
                      await adminProv.updateCourse(course['id'], body);
                    } else {
                      await adminProv.createCourse(body);
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
        title: const Text('Supprimer le cours ?'),
        content: Text('Êtes-vous sûr de vouloir supprimer "$name" ?\nLe fichier sera définitivement supprimé du serveur.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<AdminProvider>().deleteCourse(id);
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
    final courses = adminProv.courses;
    final loading = adminProv.loading || _loadingMetadata;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Gestion des Cours'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: loading && courses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await adminProv.loadCourses();
                await _loadMetadata();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final c = courses[index];
                  final isVideo = c['type'] == 'video';
                  final isPremium = c['isPremium'] == true || c['is_premium'] == true;

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isVideo ? Colors.purple[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isVideo ? Icons.play_circle_fill_rounded : Icons.picture_as_pdf_rounded,
                          color: isVideo ? Colors.purple[700] : Colors.red[700],
                          size: 24,
                        ),
                      ),
                      title: Text(
                        c['title'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '${c['subject_name'] ?? c['subjectName'] ?? ''} • ${c['classroom_name'] ?? c['classroomName'] ?? ''}',
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
                            onPressed: () => _showFormDialog(c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                            onPressed: () => _deleteConfirm(c['id'], c['title']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un cours'),
      ),
    );
  }
}
