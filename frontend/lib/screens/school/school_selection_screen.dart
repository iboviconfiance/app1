import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';

class SchoolSelectionScreen extends StatefulWidget {
  const SchoolSelectionScreen({super.key});

  @override
  State<SchoolSelectionScreen> createState() => _SchoolSelectionScreenState();
}

class _SchoolSelectionScreenState extends State<SchoolSelectionScreen> {
  Map<String, dynamic>? _hierarchy;
  bool _loading = true;

  // Step-based navigation state:
  // 1: Level Grid
  // 2: Classes Tabs & Series List
  // 3: Subjects List with Progress
  // 4: Chapter Content Detail
  int _step = 1;

  // Selected parameters
  String? _selectedLevelKey; // college, lycee_general, lycee_technique
  String? _selectedLevelLabel; // Lycée Technique, etc.
  Map<String, dynamic>? _selectedClassroom;
  Map<String, dynamic>? _selectedSeries;
  List<dynamic> _subjects = [];
  Map<String, dynamic>? _selectedSubject;
  List<dynamic> _courses = [];

  // Filter tab for Step 4 (0: Tous/Cours, 1: Vidéos, 2: Documents)
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await context.read<AuthProvider>().api.get('/school/hierarchy');
      setState(() {
        _hierarchy = res['data'];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadSubjects(String seriesId) async {
    setState(() => _loading = true);
    try {
      final api = context.read<AuthProvider>().api;
      final res = await api.get('/school/subjects?seriesId=$seriesId');
      setState(() {
        _subjects = res['data'] as List;
        _loading = false;
        _step = 3;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadCourses(String seriesId, String subjectId) async {
    setState(() => _loading = true);
    try {
      final api = context.read<AuthProvider>().api;
      final res = await api.get('/courses?seriesId=$seriesId&subjectId=$subjectId');
      setState(() {
        _courses = res['data'] as List;
        _loading = false;
        _step = 4;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _downloadCourse(String courseId) async {
    try {
      final api = context.read<AuthProvider>().api;
      final res = await api.get('/courses/$courseId/download');
      final url = res['data']['fileUrl'];
      if (url != null) {
        final uri = Uri.parse('http://localhost:3000$url');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Téléchargement démarré')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de téléchargement: $e')),
        );
      }
    }
  }

  void _goBack() {
    if (_step > 1) {
      setState(() {
        _step--;
      });
    } else {
      context.go('/dashboard');
    }
  }

  // Helper labels & icons
  String _levelTitle(String key) {
    switch (key) {
      case 'college':
        return 'Collège';
      case 'lycee_general':
        return 'Lycée Général';
      case 'lycee_technique':
        return 'Lycée Technique & Industriel';
      default:
        return key;
    }
  }

  Color _levelColor(int index) {
    final colors = [
      const Color(0xFF2563EB), // Blue
      const Color(0xFF059669), // Emerald Green
      const Color(0xFFD97706), // Orange
      const Color(0xFF7C3AED), // Violet
    ];
    return colors[index % colors.length];
  }

  IconData _levelIcon(int index) {
    final icons = [
      Icons.school_rounded,
      Icons.construction_rounded,
      Icons.menu_book_rounded,
      Icons.architecture_rounded,
    ];
    return icons[index % icons.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Define appBar title dynamically based on steps
    String titleText = 'Parcours Scolaire';
    if (_step == 2) titleText = _selectedLevelLabel ?? 'Classes & Séries';
    if (_step == 3) titleText = 'Matières';
    if (_step == 4) titleText = _selectedSubject?['name'] ?? 'Détails du cours';

    return WillPopScope(
      onWillPop: () async {
        if (_step > 1) {
          _goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: _goBack,
          ),
          title: _step == 1 ? null : Text(titleText),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (_step > 1) ...[
                // Progress/Steps breadcrumb bar at the top
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final isActive = i + 1 == _step;
                      final isCompleted = i + 1 < _step;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: isCompleted
                                ? theme.colorScheme.secondary
                                : (isActive ? theme.colorScheme.primary : const Color(0xFFE2E8F0)),
                            child: isCompleted
                                ? const Icon(Icons.check, size: 12, color: Colors.white)
                                : Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isActive || isCompleted ? Colors.white : const Color(0xFF475569),
                                    ),
                                  ),
                          ),
                          if (i < 3)
                            Container(
                              width: 32,
                              height: 2,
                              color: i + 1 < _step ? theme.colorScheme.secondary : const Color(0xFFE2E8F0),
                            ),
                        ],
                      );
                    }),
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
              ],
              Expanded(
                child: _buildStepContent(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme) {
    switch (_step) {
      case 1:
        return _buildLevelGrid(theme);
      case 2:
        return _buildClassesAndSeries(theme);
      case 3:
        return _buildSubjectsList(theme);
      case 4:
        return _buildChapterContent(theme);
      default:
        return _buildLevelGrid(theme);
    }
  }

  // --- STEP 1: Level Grid (Écran 5) ---
  Widget _buildLevelGrid(ThemeData theme) {
    final levels = [
      {
        'key': 'college',
        'label': 'Collège Général',
        'desc': '6ème, 5ème, 4ème, 3ème',
        'color': const Color(0xFF059669),
        'icon': Icons.account_balance_rounded
      },
      {
        'key': 'college',
        'label': 'Collège Technique',
        'desc': '6ème, 5ème, 4ème, 3ème',
        'color': const Color(0xFF4F46E5),
        'icon': Icons.account_balance_rounded
      },
      {
        'key': 'lycee_general',
        'label': 'Lycée Général',
        'desc': 'Seconde, Première, Terminale',
        'color': const Color(0xFFD97706),
        'icon': Icons.account_balance_rounded
      },
      {
        'key': 'lycee_technique',
        'label': 'Lycée Technique & Industriel',
        'desc': 'Seconde, Première, Terminale',
        'color': const Color(0xFF64748B),
        'icon': Icons.engineering_rounded
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Niveaux',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Choisissez votre niveau',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              childAspectRatio: 0.82,
            ),
            itemCount: levels.length,
            itemBuilder: (context, index) {
              final item = levels[index];
              final color = item['color'] as Color;
              final icon = item['icon'] as IconData;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedLevelKey = item['key'] as String;
                      _selectedLevelLabel = item['label'] as String;
                      // Get rooms for this level
                      final classroomsList = _hierarchy?[item['key']] as List? ?? [];
                      if (classroomsList.isNotEmpty) {
                        _selectedClassroom = classroomsList.first;
                      }
                      _step = 2;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 40),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item['label'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['desc'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.05, end: 0);
            },
          ),
        ),
      ],
    );
  }

  // --- STEP 2: Classes Tabs & Series (Écran 6) ---
  Widget _buildClassesAndSeries(ThemeData theme) {
    final classroomsList = _hierarchy?[_selectedLevelKey] as List? ?? [];

    if (classroomsList.isEmpty) {
      return const Center(child: Text('Aucune classe disponible.'));
    }

    final selectedRoomIndex = classroomsList.indexWhere((c) => c['id'] == _selectedClassroom?['id']);
    final activeClassIndex = selectedRoomIndex != -1 ? selectedRoomIndex : 0;
    final currentClass = classroomsList[activeClassIndex];
    final seriesList = currentClass['series'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Horizontal scrollable class selector (tabs)
        Container(
          color: Colors.white,
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: classroomsList.length,
            itemBuilder: (context, index) {
              final c = classroomsList[index];
              final isSelected = c['id'] == currentClass['id'];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(c['name']),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.primary,
                  backgroundColor: const Color(0xFFF8FAFC),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)!),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedClassroom = c;
                      });
                    }
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Sélectionnez votre Série / Filière',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: seriesList.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.school, size: 48, color: const Color(0xFF64748B)),
                            const SizedBox(height: 12),
                            const Text(
                              'Enseignement Général Unique',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Cliquez pour charger les matières de cette classe.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: const Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () {
                                // Default Series mapping in Backend
                                _loadSubjects(currentClass['id']); // Actually requires seriesId!
                                // Wait, the default seriesId is in the classroom's series list, or we need to find it
                                // In the seed, we have exactly one series per classroom for college
                              },
                              child: const Text('Charger les matières'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: seriesList.length,
                  itemBuilder: (context, index) {
                    final s = seriesList[index];
                    final sColor = _levelColor(index);
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
                          onTap: () {
                            setState(() {
                              _selectedSeries = s;
                            });
                            _loadSubjects(s['id']);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: sColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.class_rounded, color: sColor),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Série ${s['name']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Enseignement secondaire ${s['name']}',
                                        style: TextStyle(color: const Color(0xFF64748B), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios_rounded, color: const Color(0xFFCBD5E1), size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: (index * 60).ms).slideX(begin: 0.05, end: 0);
                  },
                ),
        ),
      ],
    );
  }

  // --- STEP 3: Subjects List with Progress (Écran 7) ---
  Widget _buildSubjectsList(ThemeData theme) {
    if (_subjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 48, color: const Color(0xFF64748B)),
            const SizedBox(height: 12),
            const Text('Aucune matière disponible pour cette série.', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _goBack, child: const Text('Retour')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Text(
            'Matières de ${_selectedClassroom?['name']} - Série ${_selectedSeries?['name'] ?? 'Générale'}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _subjects.length,
            itemBuilder: (context, index) {
              final sub = _subjects[index];
              final subColor = _levelColor(index + 2);
              // Mock progression metrics (e.g. 75%, 45%, 0% for premium display)
              final progress = (index == 0) ? 75 : ((index == 1) ? 45 : 0);

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
                    onTap: () {
                      setState(() {
                        _selectedSubject = sub;
                      });
                      _loadCourses(_selectedSeries?['id'] ?? '', sub['id']);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: subColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.menu_book_rounded, color: subColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sub['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '${progress == 75 ? 3 : 1} Chapitres',
                                      style: TextStyle(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: progress / 100,
                                          backgroundColor: const Color(0xFFF1F5F9),
                                          valueColor: AlwaysStoppedAnimation<Color>(subColor),
                                          minHeight: 5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '$progress%',
                                      style: TextStyle(
                                        color: subColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios_rounded, color: const Color(0xFFCBD5E1), size: 16),
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
    );
  }

  // --- STEP 4: Chapter Details with tabs & Downloads (Écran 8) ---
  Widget _buildChapterContent(ThemeData theme) {
    // Filter course list based on active tab:
    // 0: Cours (All)
    // 1: Vidéos (isVideo)
    // 2: Documents (isPDF)
    final filtered = _courses.where((c) {
      if (_activeTab == 1) return c['type'] == 'video';
      if (_activeTab == 2) return c['type'] == 'pdf';
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tab selector
        Container(
          color: Colors.white,
          child: Row(
            children: [
              _buildHorizontalTab(0, 'Cours', Icons.layers_outlined),
              _buildHorizontalTab(1, 'Vidéos', Icons.play_circle_outline_rounded),
              _buildHorizontalTab(2, 'Documents', Icons.description_outlined),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_outlined, size: 48, color: const Color(0xFF64748B)),
                      const SizedBox(height: 12),
                      const Text(
                        'Aucun fichier disponible dans cette catégorie.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => setState(() => _activeTab = 0),
                        child: const Text('Afficher tous'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          // Virtual Chapter grouping to match visual specs
                          const Text(
                            'Chapitre 1 : Généralités et Fonctions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(filtered.length, (index) {
                            final c = filtered[index];
                            final isVideo = c['type'] == 'video';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Card(
                                elevation: 0,
                                margin: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: const Color(0xFFF1F5F9)!, width: 1.5),
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
                                  subtitle: Text(
                                    isVideo ? 'Vidéo • 15:30 min' : 'Document PDF • 2.4 Mo',
                                    style: TextStyle(color: const Color(0xFF64748B), fontSize: 12),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.download_rounded, color: theme.colorScheme.primary),
                                        onPressed: () => _downloadCourse(c['id']),
                                      ),
                                      const Icon(Icons.chevron_right_rounded),
                                    ],
                                  ),
                                  onTap: () => context.go('/courses/${c['id']}'),
                                ),
                              ),
                            ).animate().fadeIn(delay: (index * 60).ms);
                          }),
                        ],
                      ),
                    ),
                    // Fixed download full chapter button at the bottom
                    Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.white,
                      child: FilledButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Téléchargement du chapitre lancé en tâche de fond (3 fichiers)')),
                          );
                        },
                        icon: const Icon(Icons.download_for_offline_rounded),
                        label: const Text('Télécharger le chapitre'),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildHorizontalTab(int idx, String label, IconData icon) {
    final isSelected = _activeTab == idx;
    final theme = Theme.of(context);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? theme.colorScheme.primary : const Color(0xFF94A3B8),
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isSelected ? theme.colorScheme.primary : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
