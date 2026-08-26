import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import 'admin_page_layout.dart';

class AdminExamsScreen extends StatefulWidget {
  const AdminExamsScreen({super.key});

  @override
  State<AdminExamsScreen> createState() => _AdminExamsScreenState();
}

class _AdminExamsScreenState extends State<AdminExamsScreen> {
  List<dynamic> _subjectsList = [];
  List<dynamic> _seriesList = [];
  bool _loadingMeta = false;

  final Map<String, Color> _typeColors = {
    'bac': const Color(0xFF2563EB),
    'bepc': const Color(0xFF7C3AED),
    'bet': const Color(0xFF059669),
    'blanc': const Color(0xFF0891B2),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().setSearchQuery('');
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
    selectedSubjectId ??= _subjectsList.isNotEmpty ? _subjectsList.first['id'] : null;

    String? selectedSeriesId = exam?['series_id'] ?? exam?['seriesId'];
    if (selectedSeriesId != null && !_seriesList.any((s) => s['id'] == selectedSeriesId)) {
      selectedSeriesId = null;
    }
    selectedSeriesId ??= _seriesList.isNotEmpty ? _seriesList.first['id'] : null;

    final adminProv = context.read<AdminProvider>();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setS) {
          Future<void> pickAndUpload({required bool isEpreuve}) async {
            final result = await FilePicker.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf'],
              withData: true,
            );
            if (result == null || result.files.isEmpty) return;
            final file = result.files.first;

            final url = await adminProv.uploadFile(file: file, fileType: 'exam');
            if (url != null) {
              setS(() {
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

          final activeColor = _typeColors[selectedType] ?? kBlue;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 520,
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                    decoration: BoxDecoration(
                      color: activeColor.withOpacity(0.08),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: activeColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.history_edu_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit ? 'Modifier l\'annale' : 'Nouvelle annale',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color: kTextPrimary,
                              ),
                            ),
                            Text(
                              'Examen Officiel / Blanc (${selectedType.toUpperCase()})',
                              style: const TextStyle(color: kTextSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: kTextSecondary),
                        ),
                      ],
                    ),
                  ),

                  // ── Scrollable content ──────────────────────────────────────────────
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        24,
                        24,
                        24 + MediaQuery.of(ctx).viewInsets.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _field(titleCtrl, 'Titre (ex: BAC 2023 - Mathématiques)', Icons.title_rounded),
                          const SizedBox(height: 12),
                          _field(descCtrl, 'Description (optionnel)', Icons.notes_rounded, maxLines: 2),
                          const SizedBox(height: 16),

                          // Type de session d'examen (BAC, BEPC, etc.)
                          const Text('Type d\'examen',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kTextSecondary)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['bac', 'bepc', 'bet', 'blanc'].map((t) {
                              final isSel = selectedType == t;
                              final c = _typeColors[t] ?? kBlue;
                              return ChoiceChip(
                                label: Text(t.toUpperCase(),
                                    style: TextStyle(
                                        color: isSel ? Colors.white : kTextSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                                selected: isSel,
                                selectedColor: c,
                                checkmarkColor: Colors.white,
                                backgroundColor: const Color(0xFFF1F5F9),
                                onSelected: (_) => setS(() => selectedType = t),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // Année + Série courte
                          Row(
                            children: [
                              Expanded(
                                child: _field(yearCtrl, 'Année (ex: 2024)', Icons.calendar_today_rounded,
                                    keyboardType: TextInputType.number),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _field(serieCtrl, 'Série (ex: D, A4)', Icons.class_outlined),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Upload progress (Shared with AdminProvider)
                          Consumer<AdminProvider>(
                            builder: (_, prov, __) {
                              if (!prov.isUploading) return const SizedBox.shrink();
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      const SizedBox(width: 4),
                                      const Text('Téléchargement sur le serveur…',
                                          style: TextStyle(fontSize: 12, color: kTextSecondary)),
                                      const Spacer(),
                                      Text(
                                        '${(prov.uploadProgress * 100).toStringAsFixed(0)}%',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kBlue),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: prov.uploadProgress,
                                      backgroundColor: const Color(0xFFE2E8F0),
                                      color: kBlue,
                                      minHeight: 6,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],
                              );
                            },
                          ),

                          // Document Épreuve PDF
                          const Text('📄 Document Épreuve (PDF)',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kTextSecondary)),
                          const SizedBox(height: 8),
                          _uploadButton(
                            label: pickedEpreuveFileName != null
                                ? pickedEpreuveFileName!
                                : (epreuvePdfUrl.isNotEmpty ? '✅ Épreuve déjà chargée' : 'Sélectionner l\'épreuve PDF'),
                            icon: Icons.picture_as_pdf_rounded,
                            color: activeColor,
                            hasFile: pickedEpreuveFileName != null || epreuvePdfUrl.isNotEmpty,
                            onTap: () => pickAndUpload(isEpreuve: true),
                          ),
                          const SizedBox(height: 14),

                          // Document Corrigé PDF
                          const Text('✏️ Corrigé (PDF optionnel)',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kTextSecondary)),
                          const SizedBox(height: 8),
                          _uploadButton(
                            label: pickedCorrigeFileName != null
                                ? pickedCorrigeFileName!
                                : (corrigePdfUrl.isNotEmpty ? '✅ Corrigé déjà chargé' : 'Sélectionner le corrigé PDF'),
                            icon: Icons.assignment_turned_in_outlined,
                            color: const Color(0xFF10B981),
                            hasFile: pickedCorrigeFileName != null || corrigePdfUrl.isNotEmpty,
                            onTap: () => pickAndUpload(isEpreuve: false),
                          ),
                          const SizedBox(height: 20),

                          // Dropdowns
                          if (_subjectsList.isNotEmpty) ...[
                            _dropdown<String>(
                              label: 'Matière',
                              value: selectedSubjectId,
                              items: _subjectsList,
                              labelKey: 'name',
                              onChanged: (v) => setS(() => selectedSubjectId = v),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (_seriesList.isNotEmpty) ...[
                            _dropdown<String>(
                              label: 'Série scolaire associée',
                              value: selectedSeriesId,
                              items: _seriesList,
                              labelKey: 'name',
                              onChanged: (v) => setS(() => selectedSeriesId = v),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Premium Toggle
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPremium ? const Color(0xFFFEF3C7) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isPremium ? const Color(0xFFFBBF24) : kBorder,
                              ),
                            ),
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Accès Premium requis',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              subtitle: Text(
                                isPremium ? 'Réservé aux abonnés payants' : 'Gratuit pour tous',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isPremium ? const Color(0xFFD97706) : kTextMuted,
                                ),
                              ),
                              value: isPremium,
                              activeColor: const Color(0xFFF59E0B),
                              onChanged: (v) => setS(() => isPremium = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Actions ────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                    decoration: const BoxDecoration(
                      color: kSurface,
                      border: Border(top: BorderSide(color: kBorder)),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: activeColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
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
                            child: Text(isEdit ? 'Enregistrer' : 'Créer l\'annale'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _deleteConfirm(String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Supprimer cette annale ?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextPrimary)),
              const SizedBox(height: 8),
              Text(
                'L\'épreuve "$title" et ses corrigés associés seront définitivement supprimés.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: kTextSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        await context.read<AdminProvider>().deleteExam(id);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Supprimer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final exams = adminProv.exams;
    final loading = adminProv.loading || _loadingMeta;
    final width = MediaQuery.of(context).size.width;

    final query = adminProv.searchQuery;
    final filtered = exams.where((e) {
      if (query.isEmpty) return true;
      final t = (e['title'] ?? '').toString().toLowerCase();
      final sub = (e['subject_name'] ?? '').toString().toLowerCase();
      final q = query.toLowerCase();
      return t.contains(q) || sub.contains(q);
    }).toList();

    return AdminPageLayout(
      title: 'Annales & Examens Blancs',
      subtitle: 'Gérer les sujets d\'examens officiels et corrigés',
      searchHint: 'Rechercher un sujet…',
      actionLabel: 'Ajouter une annale',
      onAction: () => _showFormDialog(),
      onBack: () => context.go('/admin'),
      onSearch: (q) => adminProv.setSearchQuery(q),
      child: loading && filtered.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => adminProv.loadExams(),
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: adminGridColumns(width),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: adminCardAspectRatio(width),
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => _buildExamCard(filtered[i]),
                    ),
            ),
    );
  }

  Widget _buildExamCard(Map<String, dynamic> e) {
    final type = (e['type'] ?? 'bac').toString().toLowerCase();
    final color = _typeColors[type] ?? kBlue;
    final hasCorrige = (e['corrige_pdf_url'] ?? e['corrigePdfUrl'] ?? '').toString().isNotEmpty;
    final isPremium = e['is_premium'] == true || e['isPremium'] == true;

    return Material(
      color: kSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _showFormDialog(e),
        borderRadius: BorderRadius.circular(20),
        hoverColor: color.withOpacity(0.02),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ─────────────────────────────────────────────
              Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.65)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      top: -10,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Icon
                    Positioned(
                      left: 14,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    // Type Tag
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          adminBadge(type.toUpperCase(), Colors.white),
                          if (isPremium) ...[
                            const SizedBox(height: 4),
                            adminPremiumBadge(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Content ─────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e['title'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kTextPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${e['subject_name'] ?? ''} • ${e['year'] ?? ''} ${e['serie'] ?? ''}',
                        style: const TextStyle(fontSize: 10, color: kTextMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Corrigé tag indicator
                          adminBadge(
                            hasCorrige ? 'Avec corrigé' : 'Sans corrigé',
                            hasCorrige ? const Color(0xFF10B981) : const Color(0xFF64748B),
                          ),
                          // Actions menu — zone de clic agrandie
                          PopupMenuButton<String>(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.more_horiz_rounded, size: 16, color: kTextSecondary),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 8,
                            onSelected: (val) {
                              if (val == 'edit') _showFormDialog(e);
                              if (val == 'delete') _deleteConfirm(e['id'], e['title'] ?? '');
                            },
                            itemBuilder: (_) => [
                              adminMenuItem('edit', 'Modifier', Icons.edit_outlined, kBlue),
                              const PopupMenuDivider(),
                              adminMenuItem('delete', 'Supprimer', Icons.delete_outline_rounded, const Color(0xFFEF4444)),
                            ],
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
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.assignment_outlined, size: 56, color: kTextMuted),
          ),
          const SizedBox(height: 20),
          const Text('Aucune annale', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextPrimary)),
          const SizedBox(height: 8),
          const Text('Téléversez vos premiers examens officiels ou blancs.',
              style: TextStyle(color: kTextSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showFormDialog(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ajouter une annale'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _uploadButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool hasFile,
    required VoidCallback onTap,
  }) {
    return Material(
      color: hasFile ? color.withOpacity(0.05) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasFile ? color.withOpacity(0.4) : kBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(hasFile ? Icons.check_circle_rounded : Icons.upload_rounded, color: hasFile ? color : kTextMuted, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: hasFile ? color : kTextSecondary,
                    fontWeight: hasFile ? FontWeight.w500 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: kTextMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<dynamic> items,
    required String labelKey,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 14, color: kTextPrimary),
      items: items.map<DropdownMenuItem<T>>((item) {
        return DropdownMenuItem<T>(
          value: item['id'] as T,
          child: Text(item[labelKey]?.toString() ?? ''),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
