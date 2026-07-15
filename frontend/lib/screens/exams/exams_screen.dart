import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  List<dynamic> _exams = [];
  bool _loading = true;

  // Selected filter (null means all)
  String? _selectedType;

  // Active category resource link
  String _selectedCategory = 'Anciens sujets';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await context.read<AuthProvider>().api.get('/exams');
      setState(() {
        _exams = res['data'] as List;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'bepc':
        return 'BEPC';
      case 'bac_general':
        return 'BAC Général';
      case 'bac_technique':
        return 'BAC Technique';
      case 'bet':
        return 'BET';
      default:
        return type.toUpperCase();
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'bepc':
        return const Color(0xFF2563EB); // Blue
      case 'bac_general':
        return const Color(0xFF059669); // Emerald
      case 'bac_technique':
        return const Color(0xFFD97706); // Orange
      case 'bet':
        return const Color(0xFF7C3AED); // Violet
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'bepc':
        return Icons.menu_book_rounded;
      case 'bac_general':
        return Icons.school_rounded;
      case 'bac_technique':
        return Icons.construction_rounded;
      case 'bet':
        return Icons.engineering_rounded;
      default:
        return Icons.assignment;
    }
  }

  Future<void> _openExam(Map<String, dynamic> exam) async {
    final fileUrl = exam['fileUrl'];
    if (fileUrl != null) {
      try {
        final uri = Uri.parse('http://localhost:3000$fileUrl');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Impossible d\'ouvrir le fichier de l\'examen')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $e')),
          );
        }
      }
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(exam['title'] ?? 'Examen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type : ${_typeLabel(exam['type'])}'),
              const SizedBox(height: 6),
              Text('Année : ${exam['year'] ?? 'N/A'}'),
              const SizedBox(height: 6),
              Text('Durée : ${exam['durationMinutes'] ?? 0} minutes'),
              const SizedBox(height: 12),
              const Text('Ce sujet d\'examen sera bientôt disponible au téléchargement.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Apply filters based on selectedType
    final filteredExams = _exams.where((e) {
      if (_selectedType != null && e['type'] != _selectedType) return false;
      return true;
    }).toList();

    final categories = ['Anciens sujets', 'Corrigés', 'Examens blancs', 'Conseils & Méthodes'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Examens d\'État'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top filter badges grid (Écran 11)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Diplômes & Certificats',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.9,
                        children: ['bepc', 'bac_general', 'bac_technique', 'bet'].map((type) {
                          final isSelected = _selectedType == type;
                          final color = _typeColor(type);
                          final icon = _typeIcon(type);

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected ? color : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)!,
                                width: 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedType = null; // Clear filter
                                  } else {
                                    _selectedType = type;
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    icon,
                                    color: isSelected ? Colors.white : color,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _typeLabel(type),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: isSelected ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                // Horizontal links category buttons (Écran 11)
                Container(
                  height: 54,
                  color: Colors.white,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSel = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSel,
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: const Color(0xFFF8FAFC),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isSel ? Colors.white : const Color(0xFF475569),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(color: isSel ? Colors.transparent : const Color(0xFFE2E8F0)!),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Exam list
                Expanded(
                  child: filteredExams.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.folder_open_rounded, size: 48, color: const Color(0xFF64748B)),
                              const SizedBox(height: 12),
                              Text(
                                'Aucun examen disponible pour cette sélection.',
                                style: TextStyle(color: const Color(0xFF475569), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredExams.length,
                          itemBuilder: (context, index) {
                            final e = filteredExams[index];
                            final color = _typeColor(e['type'] ?? '');
                            final isPremium = e['isPremium'] == true;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Card(
                                elevation: 0,
                                margin: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: const Color(0xFFF1F5F9)!, width: 1.5),
                                ),
                                child: InkWell(
                                  onTap: () => _openExam(e),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(Icons.description_rounded, color: color),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                e['title'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${_typeLabel(e['type'])} • Année ${e['year'] ?? ''} • ${e['durationMinutes']} min',
                                                style: TextStyle(
                                                  color: const Color(0xFF64748B),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Premium gold lock or launch icon
                                        if (isPremium)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.amber[50],
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.amber[100]!),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.lock_rounded, color: Colors.amber[800], size: 12),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'PREMIUM',
                                                  style: TextStyle(
                                                    color: Colors.amber[800],
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 9,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: const Color(0xFFCBD5E1),
                                            size: 16,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: (index * 60).ms).slideY(begin: 0.05, end: 0);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
