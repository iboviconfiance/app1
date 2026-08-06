import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

class TeacherAnalyticsScreen extends StatefulWidget {
  const TeacherAnalyticsScreen({super.key});

  @override
  State<TeacherAnalyticsScreen> createState() => _TeacherAnalyticsScreenState();
}

class _TeacherAnalyticsScreenState extends State<TeacherAnalyticsScreen> {
  List<dynamic> _seriesList = [];
  String? _selectedSeriesId;
  String _selectedPeriod = '30'; // jours
  bool _loadingMeta = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMeta();
      _loadAnalytics();
    });
  }

  Future<void> _loadMeta() async {
    setState(() => _loadingMeta = true);
    try {
      final auth = context.read<AuthProvider>();
      final seriesRes = await auth.api.get('/school/series');
      setState(() => _seriesList = seriesRes['data'] ?? []);
    } catch (_) {}
    setState(() => _loadingMeta = false);
  }

  Future<void> _loadAnalytics() async {
    final adminProv = context.read<AdminProvider>();
    DateTime? dateFrom;
    if (_selectedPeriod != 'all') {
      dateFrom = DateTime.now().subtract(Duration(days: int.parse(_selectedPeriod)));
    }
    await adminProv.loadAnalytics(
      seriesId: _selectedSeriesId,
      dateFrom: dateFrom,
    );
  }

  Color _getScoreColor(double score) {
    if (score < 40) return const Color(0xFFEF4444);
    if (score < 60) return const Color(0xFFF97316);
    if (score < 75) return const Color(0xFFEAB308);
    return const Color(0xFF22C55E);
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final analytics = adminProv.analytics;
    final loading = adminProv.loading || _loadingMeta;

    final List subjectPerformance = analytics?['subjectPerformance'] as List? ?? [];
    final List weakExercises = analytics?['weakExercises'] as List? ?? [];
    final Map<String, dynamic> globalStats = 
        analytics?['globalStats'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Analytics Professeur',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: loading && analytics == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Filtres ─────────────────────────────────────────────
                    _buildFilters(),
                    const SizedBox(height: 20),

                    // ── Stats globales ───────────────────────────────────────
                    if (globalStats.isNotEmpty) _buildGlobalStats(globalStats),
                    const SizedBox(height: 20),

                    // ── Graphique barres par matière ─────────────────────────
                    if (subjectPerformance.isNotEmpty) ...[
                      _buildSectionTitle(
                        '📊 Score moyen par matière',
                        subtitle: 'Classé du plus faible au plus fort',
                      ),
                      const SizedBox(height: 12),
                      _buildBarChart(subjectPerformance),
                      const SizedBox(height: 24),
                    ],

                    // ── Notions à renforcer ──────────────────────────────────
                    if (weakExercises.isNotEmpty) ...[
                      _buildSectionTitle(
                        '🚨 Notions à renforcer',
                        subtitle: 'Exercices avec score moyen < 50%',
                        isAlert: true,
                      ),
                      const SizedBox(height: 12),
                      ...weakExercises.map((ex) => _buildWeakExerciseCard(ex)),
                      const SizedBox(height: 16),
                    ],

                    // ── Aucune donnée ────────────────────────────────────────
                    if (analytics != null &&
                        subjectPerformance.isEmpty &&
                        weakExercises.isEmpty)
                      _buildEmptyState(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filtres', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSeriesId,
                  decoration: const InputDecoration(
                    labelText: 'Filière',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('Toutes')),
                    ..._seriesList.map<DropdownMenuItem<String>>((s) =>
                        DropdownMenuItem<String>(
                          value: s['id'],
                          child: Text(s['name'] ?? ''),
                        )),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedSeriesId = val);
                    _loadAnalytics();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Période',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '7', child: Text('7 jours')),
                    DropdownMenuItem(value: '30', child: Text('1 mois')),
                    DropdownMenuItem(value: '90', child: Text('Trimestre')),
                    DropdownMenuItem(value: 'all', child: Text('Tout')),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedPeriod = val ?? '30');
                    _loadAnalytics();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalStats(Map<String, dynamic> stats) {
    final avg = (stats['globalAvgPercent'] as num?)?.toDouble() ?? 0.0;
    final submissions = (stats['totalSubmissions'] as num?)?.toInt() ?? 0;
    final students = (stats['activeStudents'] as num?)?.toInt() ?? 0;

    return Row(
      children: [
        _buildStatCard('Élèves actifs', students.toString(), Icons.people_rounded, const Color(0xFF2563EB)),
        const SizedBox(width: 12),
        _buildStatCard('Soumissions', submissions.toString(), Icons.assignment_turned_in_rounded, const Color(0xFF7C3AED)),
        const SizedBox(width: 12),
        _buildStatCard('Moy. globale', '${avg.toStringAsFixed(1)}%', Icons.trending_up_rounded, _getScoreColor(avg)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle, bool isAlert = false}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              ],
            ],
          ),
        ),
        if (isAlert)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '⚠️ À surveiller',
              style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildBarChart(List subjects) {
    const maxBars = 8;
    final displaySubjects = subjects.take(maxBars).toList();
    final maxY = 100.0;

    return Container(
      height: 260,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF1E293B),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final s = displaySubjects[group.x.toInt()];
                return BarTooltipItem(
                  '${s['subjectName']}\n${rod.toY.toStringAsFixed(1)}%',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}%',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= displaySubjects.length) return const SizedBox();
                  final name = displaySubjects[idx]['subjectName'] as String? ?? '';
                  final short = name.length > 6 ? name.substring(0, 6) : name;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(short, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(
            show: true,
            horizontalInterval: 25,
            drawVerticalLine: false,
          ),
          barGroups: List.generate(displaySubjects.length, (i) {
            final s = displaySubjects[i];
            final score = (s['avgScorePercent'] as num?)?.toDouble() ?? 0.0;
            final color = _getScoreColor(score);
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: score,
                  width: 20,
                  color: color,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: color.withOpacity(0.07),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildWeakExerciseCard(dynamic ex) {
    final score = (ex['avgScorePercent'] as num?)?.toInt() ?? 0;
    final subjectColor = _parseColor(ex['subjectColor'] as String?);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFEE2E2), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Row(
        children: [
          // Score circle
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$score%',
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ex['exerciseTitle'] ?? 'Sans titre',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: subjectColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ex['subjectName'] ?? '',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.group_outlined, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      '${ex['totalSubmissions'] ?? 0} soumissions',
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Barre alerte
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.bar_chart_rounded, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Pas encore de données',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Les analytics s\'alimenteront dès que\ndes élèves commenceront les exercices.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String? hex) {
    try {
      if (hex == null || hex.isEmpty) return const Color(0xFF2563EB);
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF2563EB);
    }
  }
}
