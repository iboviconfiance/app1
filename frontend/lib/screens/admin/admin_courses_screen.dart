import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import 'admin_page_layout.dart';

class AdminCoursesScreen extends StatefulWidget {
  const AdminCoursesScreen({super.key});

  @override
  State<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends State<AdminCoursesScreen> {
  List<dynamic> _classrooms = [];
  List<dynamic> _seriesList = [];
  bool _loadingMeta = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadCourses();
      context.read<AdminProvider>().loadSubjects();
      _loadMeta();
    });
  }

  Future<void> _loadMeta() async {
    setState(() => _loadingMeta = true);
    try {
      final api = context.read<AuthProvider>().api;
      final cr = await api.get('/school/classrooms');
      final sr = await api.get('/school/series');
      setState(() {
        _classrooms = cr['data'] ?? [];
        _seriesList = sr['data'] ?? [];
      });
    } catch (_) {}
    setState(() => _loadingMeta = false);
  }

  // ── Form Dialog ────────────────────────────────────────────────────────────

  void _showFormDialog([Map<String, dynamic>? course]) {
    final isEdit = course != null;
    final titleCtrl = TextEditingController(text: course?['title'] ?? '');
    final descCtrl = TextEditingController(text: course?['description'] ?? '');
    String selectedType = course?['type'] ?? 'pdf';

    String fileUrl = course?['fileUrl'] ?? course?['file_url'] ?? '';
    String videoUrl = course?['videoUrl'] ?? course?['video_url'] ?? '';
    String thumbnailUrl = course?['thumbnailUrl'] ?? course?['thumbnail_url'] ?? '';
    String? pickedMainFileName;
    String? pickedThumbFileName;

    final adminProv = context.read<AdminProvider>();
    final subjects = adminProv.subjects;

    String? selectedSubjectId = course?['subjectId'] ?? course?['subject_id'];
    if (selectedSubjectId != null && !subjects.any((s) => s['id'] == selectedSubjectId)) {
      selectedSubjectId = null;
    }
    selectedSubjectId ??= subjects.isNotEmpty ? subjects.first['id'] : null;

    String? selectedClassroomId = course?['classroomId'] ?? course?['classroom_id'];
    if (selectedClassroomId != null && !_classrooms.any((c) => c['id'] == selectedClassroomId)) {
      selectedClassroomId = null;
    }
    selectedClassroomId ??= _classrooms.isNotEmpty ? _classrooms.first['id'] : null;

    String? selectedSeriesId = course?['seriesId'] ?? course?['series_id'];
    if (selectedSeriesId != null && !_seriesList.any((s) => s['id'] == selectedSeriesId)) {
      selectedSeriesId = null;
    }
    selectedSeriesId ??= _seriesList.isNotEmpty ? _seriesList.first['id'] : null;

    bool isPremium = course?['isPremium'] ?? course?['is_premium'] ?? false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setS) {
          Future<void> pickAndUpload({required bool isMainFile}) async {
            final isPdf = selectedType == 'pdf';
            final result = await FilePicker.platform.pickFiles(
              type: isMainFile
                  ? (isPdf ? FileType.custom : FileType.video)
                  : FileType.image,
              allowedExtensions: isMainFile
                  ? (isPdf ? ['pdf'] : null)
                  : ['jpg', 'jpeg', 'png', 'webp'],
              withData: true,
            );
            if (result == null || result.files.isEmpty) return;
            final file = result.files.first;
            final uploadType = isMainFile ? (isPdf ? 'pdf' : 'video') : 'image';
            final url = await adminProv.uploadFile(file: file, fileType: uploadType);
            if (url != null) {
              setS(() {
                if (isMainFile) {
                  if (isPdf) { fileUrl = url; } else { videoUrl = url; }
                  pickedMainFileName = file.name;
                } else {
                  thumbnailUrl = url;
                  pickedThumbFileName = file.name;
                }
              });
            }
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                    decoration: BoxDecoration(
                      color: selectedType == 'pdf'
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFF5F3FF),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: selectedType == 'pdf'
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF7C3AED),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            selectedType == 'pdf'
                                ? Icons.picture_as_pdf_rounded
                                : Icons.play_circle_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit ? 'Modifier le cours' : 'Nouveau cours',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color: kTextPrimary,
                              ),
                            ),
                            Text(
                              selectedType == 'pdf' ? 'Document PDF' : 'Vidéo MP4',
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

                  // ── Scrollable content ─────────────────────────────────
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Titre
                          _field(titleCtrl, 'Titre du cours', Icons.title_rounded),
                          const SizedBox(height: 12),
                          _field(descCtrl, 'Description (optionnel)', Icons.notes_rounded, maxLines: 2),
                          const SizedBox(height: 16),

                          // Type toggle
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                _typeTab('pdf', 'PDF', Icons.picture_as_pdf_rounded,
                                    const Color(0xFFEF4444), selectedType, (v) => setS(() => selectedType = v)),
                                _typeTab('video', 'Vidéo', Icons.play_circle_rounded,
                                    const Color(0xFF7C3AED), selectedType, (v) => setS(() => selectedType = v)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Upload progress
                          Consumer<AdminProvider>(
                            builder: (_, prov, __) {
                              if (!prov.isUploading) return const SizedBox.shrink();
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      const SizedBox(width: 4),
                                      const Text('Upload en cours…',
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

                          // Upload principal
                          _uploadButton(
                            label: pickedMainFileName != null
                                ? pickedMainFileName!
                                : (selectedType == 'pdf'
                                    ? (fileUrl.isNotEmpty ? '✅ PDF déjà chargé' : 'Choisir le PDF')
                                    : (videoUrl.isNotEmpty ? '✅ Vidéo déjà chargée' : 'Choisir la vidéo MP4')),
                            icon: selectedType == 'pdf'
                                ? Icons.picture_as_pdf_rounded
                                : Icons.video_file_rounded,
                            color: selectedType == 'pdf'
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF7C3AED),
                            hasFile: pickedMainFileName != null ||
                                fileUrl.isNotEmpty ||
                                videoUrl.isNotEmpty,
                            onTap: () => pickAndUpload(isMainFile: true),
                          ),
                          const SizedBox(height: 10),

                          // Upload thumbnail
                          _uploadButton(
                            label: pickedThumbFileName != null
                                ? pickedThumbFileName!
                                : (thumbnailUrl.isNotEmpty
                                    ? '✅ Miniature chargée'
                                    : 'Choisir la miniature (optionnel)'),
                            icon: Icons.image_outlined,
                            color: const Color(0xFF0EA5E9),
                            hasFile: pickedThumbFileName != null || thumbnailUrl.isNotEmpty,
                            onTap: () => pickAndUpload(isMainFile: false),
                          ),
                          const SizedBox(height: 20),

                          // Dropdowns
                          if (subjects.isNotEmpty) ...[
                            _dropdown<String>(
                              label: 'Matière',
                              value: selectedSubjectId,
                              items: subjects,
                              labelKey: 'name',
                              onChanged: (v) => setS(() => selectedSubjectId = v),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (_seriesList.isNotEmpty) ...[
                            _dropdown<String>(
                              label: 'Série / Filière',
                              value: selectedSeriesId,
                              items: _seriesList,
                              labelKey: 'name',
                              onChanged: (v) => setS(() => selectedSeriesId = v),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (_classrooms.isNotEmpty) ...[
                            _dropdown<String>(
                              label: 'Classe',
                              value: selectedClassroomId,
                              items: _classrooms,
                              labelKey: 'name',
                              onChanged: (v) => setS(() => selectedClassroomId = v),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Premium toggle
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPremium
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isPremium
                                    ? const Color(0xFFFBBF24)
                                    : kBorder,
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
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: kBlue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
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
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            child: Text(isEdit ? 'Enregistrer' : 'Créer le cours'),
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

  // ── Delete dialog ──────────────────────────────────────────────────────────

  void _deleteConfirm(String id, String name) {
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
                    borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.delete_forever_rounded,
                    color: Color(0xFFEF4444), size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Supprimer ce cours ?',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary)),
              const SizedBox(height: 8),
              Text(
                '"$name" et son fichier seront définitivement supprimés du serveur.',
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
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        await context.read<AdminProvider>().deleteCourse(id);
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final loading = adminProv.loading || _loadingMeta;
    final width = MediaQuery.of(context).size.width;

    final courses = adminProv.courses.where((c) {
      if (_searchQuery.isEmpty) return true;
      final title = (c['title'] ?? '').toString().toLowerCase();
      final subject = (c['subject_name'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return title.contains(q) || subject.contains(q);
    }).toList();

    return AdminPageLayout(
      title: 'Cours PDF & Vidéos',
      subtitle: 'Gérer les contenus de cours de la plateforme',
      searchHint: 'Rechercher un cours…',
      actionLabel: 'Nouveau cours',
      onAction: () => _showFormDialog(),
      onBack: () => context.go('/admin'),
      onSearch: (q) => setState(() => _searchQuery = q),
      child: loading && courses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await adminProv.loadCourses();
                await _loadMeta();
              },
              child: courses.isEmpty
                  ? _emptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      // ── Point de vigilance 2 : ratio dynamique ────────
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: adminGridColumns(width),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: adminCardAspectRatio(width),
                      ),
                      itemCount: courses.length,
                      itemBuilder: (ctx, i) => _buildCourseCard(courses[i]),
                    ),
            ),
    );
  }

  // ── Course Card ────────────────────────────────────────────────────────────

  Widget _buildCourseCard(Map<String, dynamic> c) {
    final isVideo = c['type'] == 'video';
    final isPremium = c['isPremium'] == true || c['is_premium'] == true;
    final subjectName = c['subject_name'] ?? c['subjectName'] ?? '';
    final seriesName = c['series_name'] ?? c['seriesName'] ?? '';
    final cardColor = isVideo ? const Color(0xFF7C3AED) : const Color(0xFFEF4444);
    final hasThumb = (c['thumbnail_url'] ?? c['thumbnailUrl'] ?? '').toString().isNotEmpty;

    return Material(
      color: kSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _showFormDialog(c),
        borderRadius: BorderRadius.circular(20),
        hoverColor: cardColor.withOpacity(0.02),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: cardColor.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Card Header ─────────────────────────────────────────────
              Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cardColor, cardColor.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  image: hasThumb
                      ? DecorationImage(
                          image: NetworkImage(c['thumbnail_url'] ?? c['thumbnailUrl']),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            cardColor.withOpacity(0.5),
                            BlendMode.overlay,
                          ),
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    // Decorative circle
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
                    // Type icon
                    Positioned(
                      left: 14,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isVideo ? Icons.play_circle_rounded : Icons.picture_as_pdf_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    // Badges top-right
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          adminTypeBadge(c['type'] ?? 'pdf'),
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

              // ── Content ─────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c['title'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: kTextPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (subjectName.isNotEmpty || seriesName.isNotEmpty)
                        Text(
                          [subjectName, seriesName].where((s) => s.isNotEmpty).join(' • '),
                          style: const TextStyle(fontSize: 10, color: kTextMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const Spacer(),
                      // Actions row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Dot indicator
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: cardColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          // PopupMenu
                          PopupMenuButton<String>(
                            icon: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Icon(Icons.more_horiz_rounded,
                                  size: 15, color: kTextSecondary),
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 8,
                            onSelected: (val) {
                              if (val == 'edit') _showFormDialog(c);
                              if (val == 'delete') _deleteConfirm(c['id'], c['title'] ?? '');
                            },
                            itemBuilder: (_) => [
                              adminMenuItem('edit', 'Modifier', Icons.edit_outlined, kBlue),
                              const PopupMenuDivider(),
                              adminMenuItem('delete', 'Supprimer',
                                  Icons.delete_outline_rounded, const Color(0xFFEF4444)),
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

  Widget _emptyState() {
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
            child: const Icon(Icons.library_books_outlined, size: 56, color: kTextMuted),
          ),
          const SizedBox(height: 20),
          const Text('Aucun cours',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextPrimary)),
          const SizedBox(height: 8),
          const Text('Commencez par ajouter votre premier cours.',
              style: TextStyle(color: kTextSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showFormDialog(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ajouter un cours'),
          ),
        ],
      ),
    );
  }

  // ── Small helpers ──────────────────────────────────────────────────────────

  Widget _field(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
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

  Widget _typeTab(String value, String label, IconData icon, Color color,
      String current, void Function(String) onChange) {
    final isSel = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChange(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? kSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSel
                ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 8)]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSel ? color : kTextMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                  color: isSel ? color : kTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
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
              Icon(hasFile ? Icons.check_circle_rounded : Icons.upload_rounded,
                  color: hasFile ? color : kTextMuted, size: 18),
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
