import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

// ─── Design tokens (identiques au Dashboard) ─────────────────────────────────
const kBg = Color(0xFFF8FAFC);
const kSurface = Colors.white;
const kBorder = Color(0xFFE8EDF5);
const kTextPrimary = Color(0xFF0F172A);
const kTextSecondary = Color(0xFF64748B);
const kTextMuted = Color(0xFF94A3B8);

class AdminSubjectsScreen extends StatefulWidget {
  const AdminSubjectsScreen({super.key});

  @override
  State<AdminSubjectsScreen> createState() => _AdminSubjectsScreenState();
}

class _AdminSubjectsScreenState extends State<AdminSubjectsScreen> {
  String _searchQuery = '';

  final Map<String, IconData> _availableIcons = {
    'calculate_rounded': Icons.calculate_rounded,
    'menu_book_rounded': Icons.menu_book_rounded,
    'language_rounded': Icons.language_rounded,
    'science_rounded': Icons.science_rounded,
    'grass_rounded': Icons.grass_rounded,
    'psychology_rounded': Icons.psychology_rounded,
    'engineering_rounded': Icons.engineering_rounded,
    'architecture_rounded': Icons.architecture_rounded,
    'history_edu_rounded': Icons.history_edu_rounded,
    'public_rounded': Icons.public_rounded,
    'biotech_rounded': Icons.biotech_rounded,
    'computer_rounded': Icons.computer_rounded,
  };

  final List<String> _availableColors = [
    '#2563EB', // Blue
    '#10B981', // Emerald
    '#EF4444', // Red
    '#8B5CF6', // Violet
    '#EC4899', // Pink
    '#F59E0B', // Amber
    '#06B6D4', // Cyan
    '#F97316', // Orange
    '#6B7280', // Grey
    '#0EA5E9', // Sky
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadSubjects();
    });
  }

  Color _hex(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return const Color(0xFF2563EB);
    }
  }

  // ── Form Dialog ───────────────────────────────────────────────────────────

  void _showFormDialog([Map<String, dynamic>? subject]) {
    final isEdit = subject != null;
    final nameCtrl = TextEditingController(text: subject?['name'] ?? '');
    final descCtrl = TextEditingController(text: subject?['description'] ?? '');

    String selectedIconKey = subject?['icon'] ?? 'menu_book_rounded';
    if (!_availableIcons.containsKey(selectedIconKey)) selectedIconKey = 'menu_book_rounded';

    String selectedColor = subject?['color'] ?? '#2563EB';
    if (!_availableColors.contains(selectedColor)) selectedColor = _availableColors.first;

    showDialog(
      context: context,
      // Fond semi-opaque net pour masquer correctement le fond
      barrierColor: Colors.black.withOpacity(0.60),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final previewColor = _hex(selectedColor);
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 480,
                maxHeight: MediaQuery.of(ctx).size.height * 0.88,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Preview Header ─────────────────────────────────────
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [previewColor, previewColor.withOpacity(0.6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Icon(
                                _availableIcons[selectedIconKey] ?? Icons.menu_book_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            nameCtrl.text.isEmpty ? 'Nom de la matière' : nameCtrl.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),


                  // ── Form ───────────────────────────────────────────────
                  // Flexible + SingleChildScrollView gèrent le clavier virtuel
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        20,
                        24,
                        20 + MediaQuery.of(ctx).viewInsets.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,

                        children: [
                          TextField(
                            controller: nameCtrl,
                            onChanged: (_) => setS(() {}),
                            decoration: InputDecoration(
                              labelText: 'Nom de la matière',
                              hintText: 'ex: Mathématiques',
                              prefixIcon: const Icon(Icons.edit_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: descCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Description (facultatif)',
                              prefixIcon: const Icon(Icons.notes_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Color picker
                          const Text('Couleur', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kTextSecondary)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _availableColors.map((hex) {
                              final isSel = hex == selectedColor;
                              return GestureDetector(
                                onTap: () => setS(() => selectedColor = hex),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: isSel ? 38 : 34,
                                  height: isSel ? 38 : 34,
                                  decoration: BoxDecoration(
                                    color: _hex(hex),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSel ? Colors.white : Colors.transparent,
                                      width: 3,
                                    ),
                                    boxShadow: isSel
                                        ? [BoxShadow(color: _hex(hex).withOpacity(0.5), blurRadius: 8, spreadRadius: 1)]
                                        : [],
                                  ),
                                  child: isSel
                                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Icon picker
                          const Text('Icône', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kTextSecondary)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableIcons.entries.map((entry) {
                              final isSel = entry.key == selectedIconKey;
                              final selColor = _hex(selectedColor);
                              return GestureDetector(
                                onTap: () => setS(() => selectedIconKey = entry.key),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSel ? selColor : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSel ? selColor : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: isSel
                                        ? [BoxShadow(color: selColor.withOpacity(0.3), blurRadius: 8)]
                                        : [],
                                  ),
                                  child: Icon(
                                    entry.value,
                                    size: 22,
                                    color: isSel ? Colors.white : kTextSecondary,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          // Actions
                          Row(
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
                                    backgroundColor: _hex(selectedColor),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () async {
                                    if (nameCtrl.text.trim().isEmpty) return;
                                    final adminProv = context.read<AdminProvider>();
                                    if (isEdit) {
                                      await adminProv.updateSubject(
                                        subject['id'],
                                        nameCtrl.text.trim(),
                                        descCtrl.text.trim(),
                                        selectedIconKey,
                                        selectedColor,
                                      );
                                    } else {
                                      await adminProv.createSubject(
                                        nameCtrl.text.trim(),
                                        descCtrl.text.trim(),
                                        selectedIconKey,
                                        selectedColor,
                                      );
                                    }
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  },
                                  child: Text(isEdit ? 'Enregistrer' : 'Créer la matière'),
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
          );

        },
      ),
    );
  }

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
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Supprimer la matière ?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextPrimary)),
              const SizedBox(height: 8),
              Text(
                'Tous les cours et exercices liés à "$name" seront aussi supprimés. Cette action est irréversible.',
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
                        await context.read<AdminProvider>().deleteSubject(id);
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
    final loading = adminProv.loading;
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 900;

    final subjects = adminProv.subjects.where((s) {
      if (_searchQuery.isEmpty) return true;
      return (s['name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // ── Top Bar ────────────────────────────────────────────────────
          Container(
            color: kSurface,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      onPressed: () => context.go('/admin'),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Matières & Programmes',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kTextPrimary),
                        ),
                        Text(
                          'Configurer les couleurs, icônes et filières',
                          style: TextStyle(fontSize: 11, color: kTextSecondary),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // ── Search Bar (Web) ──────────────────────────────────
                    if (isWide)
                      Container(
                        width: 240,
                        height: 38,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Rechercher une matière…',
                            hintStyle: TextStyle(color: kTextMuted, fontSize: 13),
                            prefixIcon: Icon(Icons.search_rounded, size: 18, color: kTextMuted),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),

                    // ── Add Button ────────────────────────────────────────
                    FilledButton.icon(
                      onPressed: () => _showFormDialog(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(isWide ? 'Ajouter une matière' : 'Ajouter'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: kBorder),

          // ── Body ───────────────────────────────────────────────────────
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: loading && subjects.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: () => adminProv.loadSubjects(),
                        child: subjects.isEmpty
                            ? _buildEmptyState()
                            : GridView.builder(
                                padding: const EdgeInsets.all(24),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isWide ? 4 : (width > 600 ? 3 : 2),
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: 0.85,
                                ),
                                itemCount: subjects.length,
                                itemBuilder: (ctx, i) => _buildSubjectCard(subjects[i]),
                              ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> sub) {
    final hexColor = sub['color'] ?? '#2563EB';
    final color = _hex(hexColor);
    final iconName = sub['icon'] ?? 'menu_book_rounded';
    final icon = _availableIcons[iconName] ?? Icons.menu_book_rounded;
    final name = sub['name'] ?? '';
    final desc = sub['description'] ?? '';

    return Material(
      color: kSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _showFormDialog(sub),
        borderRadius: BorderRadius.circular(20),
        hoverColor: color.withOpacity(0.03),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Color Header ───────────────────────────────────────────
              Container(
                height: 90,
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
                    // Background decorative circles
                    Positioned(
                      right: -12,
                      top: -12,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 20,
                      bottom: -20,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: Colors.white, size: 28),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Content ────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: kTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc.isEmpty ? 'Aucune description' : desc,
                        style: TextStyle(
                          fontSize: 11,
                          color: desc.isEmpty ? kTextMuted : kTextSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),

                      // ── Actions row ───────────────────────────────────
                      Row(
                        children: [
                          // Color dot
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const Spacer(),

                          // PopupMenu Actions
                          PopupMenuButton<String>(
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.more_horiz_rounded, size: 16, color: kTextSecondary),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 8,
                            onSelected: (val) {
                              if (val == 'edit') _showFormDialog(sub);
                              if (val == 'delete') _deleteConfirm(sub['id'], name);
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 16, color: color),
                                    const SizedBox(width: 10),
                                    const Text('Modifier', style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                                    SizedBox(width: 10),
                                    Text('Supprimer', style: TextStyle(fontSize: 13, color: Color(0xFFEF4444))),
                                  ],
                                ),
                              ),
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
            child: const Icon(Icons.palette_outlined, size: 56, color: kTextMuted),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucune matière',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Commencez par créer vos premières matières.',
            style: TextStyle(color: kTextSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showFormDialog(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Créer une matière'),
          ),
        ],
      ),
    );
  }
}
