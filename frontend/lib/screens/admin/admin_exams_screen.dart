import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

class AdminExamsScreen extends StatefulWidget {
  const AdminExamsScreen({super.key});

  @override
  State<AdminExamsScreen> createState() => _AdminExamsScreenState();
}

class _AdminExamsScreenState extends State<AdminExamsScreen> {
  List<dynamic> _subjectsList = [];
  List<dynamic> _seriesList = [];
  bool _loadingMeta = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadExams();
      _loadMeta();
    });
  }

  Future<void> _loadMeta() async {
    setState(() => _loadingMeta = true);
    try {
      final auth = context.read<AuthProvider>();
      final subjRes = await auth.api.get('/admin/subjects');
      final seriesRes = await auth.api.get('/school/series');
      setState(() {
        _subjectsList = subjRes['data'] ?? [];
        _seriesList = seriesRes['data'] ?? [];
      });
    } catch (_) {}
    setState(() => _loadingMeta = false);
  }

  void _showFormDialog([Map<String, dynamic>? exam]) {
    final isEdit = exam != null;
    final titleCtrl = TextEditingController(text: exam?['title'] ?? '');
    final descCtrl = TextEditingController(text: exam?['description'] ?? '');
    final yearCtrl = TextEditingController(text: exam?['year']?.toString() ?? '');
    final serieCtrl = TextEditingController(text: exam?['serie'] ?? '');

    String selectedType = exam?['type'] ?? 'bac';
    String epreuvePdfUrl = exam?['file_url'] ?? exam?['fileUrl'] ?? '';
    String corrigePdfUrl = exam?['corrige_pdf_url'] ?? exam?['corrigePdfUrl'] ?? '';
    String? pickedEpreuveFileName;
    String? pickedCorrigeFileName;
    bool isPremium = exam?['is_premium'] ?? exam?['isPremium'] ?? true;

    String? selectedSubjectId = exam?['subject_id'] ?? exam?['subjectId'];
    if (selectedSubjectId != null && !_subjectsList.any((s) => s['id'] == selectedSubjectId)) {
      selectedSubjectId = null;
    }
    if (selectedSubjectId == null && _subjectsList.isNotEmpty) {
      selectedSubjectId = _subjectsList.first['id'];
    }

    String? selectedSeriesId = exam?['series_id'] ?? exam?['seriesId'];
    if (selectedSeriesId != null && !_seriesList.any((s) => s['id'] == selectedSeriesId)) {
      selectedSeriesId = null;
    }
    if (selectedSeriesId == null && _seriesList.isNotEmpty) {
      selectedSeriesId = _seriesList.first['id'];
    }

    final adminProv = context.read<AdminProvider>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> pickAndUpload({required bool isEpreuve}) async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf'],
                withData: true,
              );
              if (result == null || result.files.isEmpty) return;
              final file = result.files.first;

              final url = await adminProv.uploadFile(file: file, fileType: 'exam');
              if (url != null) {
                setDialogState(() {
                  if (isEpreuve) {
                    epreuvePdfUrl = url;
                    pickedEpreuveFileName = file.name;
                  } else {
                    corrigePdfUrl = url;
                    pickedCorrigeFileName = file.name;
                  }
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                isEdit ? 'Modifier l\'annale' : 'Ajouter une annale',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Titre (ex: BAC 2023 – Mathématiques D)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Description (optionnel)'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Type d'examen
                    const Text('Type d\'examen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: ['bac', 'bepc', 'bet', 'blanc'].map((t) {
                        return ChoiceChip(
                          label: Text(t.toUpperCase()),
                          selected: selectedType == t,
                          onSelected: (_) => setDialogState(() => selectedType = t),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Année + Série courte
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: yearCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Année (ex: 2023)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: serieCtrl,
                            decoration: const InputDecoration(labelText: 'Série (ex: D, A4, G)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Matière
                    if (_subjectsList.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        value: selectedSubjectId,
                        decoration: const InputDecoration(labelText: 'Matière'),
                        items: _subjectsList.map<DropdownMenuItem<String>>((s) {
                          return DropdownMenuItem<String>(
                            value: s['id'],
                            child: Text(s['name'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (val) => setDialogState(() => selectedSubjectId = val),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Série scolaire
                    if (_seriesList.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        value: selectedSeriesId,
                        decoration: const InputDecoration(labelText: 'Filière / Série scolaire'),
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

                    // Barre de progression upload
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
                              'Upload… ${(prov.uploadProgress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),

                    // Upload épreuve
                    const Text('📄 Épreuve (PDF)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () => pickAndUpload(isEpreuve: true),
                      icon: const Icon(Icons.upload_file_rounded, color: Color(0xFF2563EB)),
                      label: Text(
                        pickedEpreuveFileName != null
                            ? '✅ ${pickedEpreuveFileName!}'
                            : (epreuvePdfUrl.isNotEmpty ? '✅ Fichier chargé' : 'Choisir le PDF épreuve'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Upload corrigé
                    const Text('✏️ Corrigé (PDF)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () => pickAndUpload(isEpreuve: false),
                      icon: const Icon(Icons.upload_file_rounded, color: Colors.green),
                      label: Text(
                        pickedCorrigeFileName != null
                            ? '✅ ${pickedCorrigeFileName!}'
                            : (corrigePdfUrl.isNotEmpty ? '✅ Corrigé chargé' : 'Choisir le PDF corrigé (optionnel)'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 16),

                    CheckboxListTile(
                      title: const Text('Accès Premium Requis', style: TextStyle(fontSize: 14)),
                      value: isPremium,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setDialogState(() => isPremium = val ?? true),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final body = {
                      'title': titleCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'type': selectedType,
                      'year': int.tryParse(yearCtrl.text.trim()),
                      'serie': serieCtrl.text.trim().isNotEmpty ? serieCtrl.text.trim() : null,
                      'subjectId': selectedSubjectId,
                      'seriesId': selectedSeriesId,
                      'fileUrl': epreuvePdfUrl.isNotEmpty ? epreuvePdfUrl : null,
                      'corrigePdfUrl': corrigePdfUrl.isNotEmpty ? corrigePdfUrl : null,
                      'isPremium': isPremium,
                    };
                    if (isEdit) {
                      await adminProv.updateExam(exam['id'], body);
                    } else {
                      await adminProv.createExam(body);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
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

  void _deleteConfirm(String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette annale ?'),
        content: Text('Supprimer "$title" supprimera aussi les fichiers PDF du serveur.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<AdminProvider>().deleteExam(id);
              if (ctx.mounted) Navigator.pop(ctx);
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
    final exams = adminProv.exams;
    final loading = adminProv.loading || _loadingMeta;

    final typeColors = {
      'bac': const Color(0xFF2563EB),
      'bepc': const Color(0xFF7C3AED),
      'bet': const Color(0xFF059669),
      'blanc': const Color(0xFF0891B2),
    };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Annales & Examens Blancs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: loading && exams.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => adminProv.loadExams(),
              child: exams.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('Aucune annale pour l\'instant',
                              style: TextStyle(color: Colors.grey[500])),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () => _showFormDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter une annale'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: exams.length,
                      itemBuilder: (context, i) {
                        final e = exams[i];
                        final type = (e['type'] ?? 'bac').toString().toLowerCase();
                        final color = typeColors[type] ?? const Color(0xFF2563EB);
                        final hasCorrige = (e['corrige_pdf_url'] ?? '').toString().isNotEmpty;
                        final isPremium = e['is_premium'] == true || e['isPremium'] == true;

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: color.withOpacity(0.2), width: 1.5),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  type.toUpperCase(),
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
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
                                  '${e['subject_name'] ?? ''} • ${e['year'] ?? ''} ${e['serie'] ?? ''}',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        hasCorrige ? '✅ Avec corrigé' : '📄 Sans corrigé',
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF15803D)),
                                      ),
                                    ),
                                    if (isPremium) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Premium',
                                          style: TextStyle(fontSize: 10, color: Color(0xFFD97706)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
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
                                  onPressed: () => _deleteConfirm(e['id'], e['title'] ?? ''),
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
        label: const Text('Ajouter une annale'),
      ),
    );
  }
}
