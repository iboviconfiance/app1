import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class AdminSubjectsScreen extends StatefulWidget {
  const AdminSubjectsScreen({super.key});

  @override
  State<AdminSubjectsScreen> createState() => _AdminSubjectsScreenState();
}

class _AdminSubjectsScreenState extends State<AdminSubjectsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadSubjects();
    });
  }

  // Predefined icons list
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
  };

  // Predefined colors list
  final List<String> _availableColors = [
    '#2563EB', // Blue
    '#10B981', // Emerald
    '#EF4444', // Red
    '#8B5CF6', // Violet
    '#EC4899', // Pink
    '#F59E0B', // Amber
    '#06B6D4', // Cyan
    '#6B7280', // Grey
  ];

  Color _parseHexColor(String hexString) {
    try {
      final cleanHex = hexString.replaceAll('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return const Color(0xFF2563EB);
    }
  }

  void _showFormDialog([Map<String, dynamic>? subject]) {
    final isEdit = subject != null;
    final nameCtrl = TextEditingController(text: subject?['name'] ?? '');
    final descCtrl = TextEditingController(text: subject?['description'] ?? '');
    
    String selectedIconKey = subject?['icon'] ?? 'menu_book_rounded';
    if (!_availableIcons.containsKey(selectedIconKey)) {
      selectedIconKey = 'menu_book_rounded';
    }
    
    String selectedColor = subject?['color'] ?? '#2563EB';
    if (!_availableColors.contains(selectedColor)) {
      selectedColor = _availableColors.first;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(isEdit ? 'Modifier la matière' : 'Ajouter une matière'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nom de la matière (ex: Mathématiques)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Description (facultatif)'),
                    ),
                    const SizedBox(height: 20),
                    
                    // Icon Picker
                    const Text('Icône associée', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _availableIcons.entries.map((entry) {
                          final isSel = entry.key == selectedIconKey;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Icon(entry.value, size: 20, color: isSel ? Colors.white : Colors.black87),
                              selected: isSel,
                              selectedColor: _parseHexColor(selectedColor),
                              onSelected: (_) {
                                setDialogState(() => selectedIconKey = entry.key);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Color Picker
                    const Text('Couleur associée', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableColors.map((hex) {
                        final isSel = hex == selectedColor;
                        final color = _parseHexColor(hex);
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() => selectedColor = hex);
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel ? Colors.black : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: isSel
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      }).toList(),
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
        title: const Text('Supprimer la matière ?'),
        content: Text('Êtes-vous sûr de vouloir supprimer la matière "$name" ? Tous les cours et QCMs liés seront également supprimés.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<AdminProvider>().deleteSubject(id);
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
    final subjects = adminProv.subjects;
    final loading = adminProv.loading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Gestion des Matières'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: loading && subjects.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => adminProv.loadSubjects(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final sub = subjects[index];
                  final hexColor = sub['color'] ?? '#2563EB';
                  final color = _parseHexColor(hexColor);
                  final iconName = sub['icon'] ?? 'menu_book_rounded';
                  final icon = _availableIcons[iconName] ?? Icons.menu_book_rounded;

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
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      title: Text(
                        sub['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: sub['description'] != null && sub['description'].isNotEmpty
                          ? Text(
                              sub['description'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            )
                          : const Text('Aucune description', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                            onPressed: () => _showFormDialog(sub),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                            onPressed: () => _deleteConfirm(sub['id'], sub['name']),
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
        label: const Text('Ajouter une matière'),
      ),
    );
  }
}
