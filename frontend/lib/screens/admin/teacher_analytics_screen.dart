import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import 'admin_page_layout.dart';

class TeacherAnalyticsScreen extends StatefulWidget {
  const TeacherAnalyticsScreen({super.key});

  @override
  State<TeacherAnalyticsScreen> createState() => _TeacherAnalyticsScreenState();
}

class _TeacherAnalyticsScreenState extends State<TeacherAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _seriesList = [];
  String? _selectedSeriesId;
  String _selectedPeriod = '30';
  bool _loadingMeta = false;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMeta();
      _loadAnalytics();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    setState(() => _loadingMeta = true);
    try {
      final api = context.read<AuthProvider>().api;
      final r = await api.get('/school/series');
      setState(() => _seriesList = r['data'] ?? []);
    } catch (_) {}
    setState(() => _loadingMeta = false);
  }

  Future<void> _loadAnalytics() async {
    _animCtrl.reset();
    DateTime? dateFrom;
    if (_selectedPeriod != 'all') {
      dateFrom = DateTime.now().subtract(Duration(days: int.parse(_selectedPeriod)));
    }
    await context.read<AdminProvider>().loadAnalytics(
      seriesId: _selectedSeriesId,
      dateFrom: dateFrom,
    );
    _animCtrl.forward();
  }

  Color _scoreColor(double score) {
    if (score < 40) return const Color(0xFFEF4444);
    if (score < 60) return const Color(0xFFF97316);
    if (score < 75) return const Color(0xFFEAB308);
    return const Color(0xFF22C55E);
  }

  Color _parseHex(String? hex) {
    try {
      if (hex == null || hex.isEmpty) return const Color(0xFF2563EB);
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return const Color(0xFF2563EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final analytics = adminProv.analytics;
    final loading = adminProv.loading || _loadingMeta;
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 800;

    final List subjectPerf = analytics?['subjectPerformance'] as List? ?? [];
    final List weakEx = analytics?['weakExercises'] as List? ?? [];
    final Map<String, dynamic> global =
        analytics?['globalStats'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // ── Top Bar ──────────────────────────────────────────────────────
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Analytics Professeur',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: kTextPrimary)),
                          Text('Performance des élèves par matière',
                              style: TextStyle(fontSize: 11, color: kTextSecondary)),
                        ],
                      ),
                    ),
                    // Refresh button
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        icon: AnimatedRotation(
                          turns: loading ? 1 : 0,
                          duration: const Duration(milliseconds: 600),
                          child: const Icon(Icons.refresh_rounded, size: 20),
                        ),
                        onPressed: _loadAnalytics,
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ),
                    // Export badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF97316), Color(0xFFEF4444)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bar_chart_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text('Insights',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: kBorder),

          // ── Body ─────────────────────────────────────────────────────────
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: loading && analytics == null
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadAnalytics,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ── Filters ─────────────────────────────────
                              _buildFilters(isWide),
                              const SizedBox(height: 24),

                              // ── Global Stats ─────────────────────────────
                              if (global.isNotEmpty) ...[
                                _buildGlobalStats(global),
                                const SizedBox(height: 28),
                              ],

                              // ── Subject BarChart ─────────────────────────
                              if (subjectPerf.isNotEmpty) ...[
                                _buildSectionHeader(
                                  '📊 Score moyen par matière',
                                  'Classé du plus faible au plus fort',
                                  isWide,
                                ),
                                const SizedBox(height: 14),
                                _buildBarChart(subjectPerf),
                                const SizedBox(height: 28),
                              ],

                              // ── Weak exercises ───────────────────────────
                              if (weakEx.isNotEmpty) ...[
                                _buildSectionHeader(
                                  '🚨 Notions à renforcer',
                                  'Exercices avec score moyen < 50%',
                                  isWide,
                                  isAlert: true,
                                ),
                                const SizedBox(height: 14),
                                ...weakEx.map((ex) => _buildWeakCard(ex)),
                              ],

                              // ── Empty ────────────────────────────────────
                              if (analytics != null &&
                                  subjectPerf.isEmpty &&
                                  weakEx.isEmpty)
                                _buildEmptyState(),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filters ────────────────────────────────────────────────────────────────

  Widget _buildFilters(bool isWide) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: kTextSecondary),
              SizedBox(width: 8),
              Text('Filtres',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: kTextPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Series filter
              Expanded(
                child: _filterDropdown<String>(
                  label: 'Filière',
                  value: _selectedSeriesId,
                  icon: Icons.school_rounded,
                  items: [
                    const DropdownMenuItem<String>(
                        value: null, child: Text('Toutes les filières')),
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
              // Period filter
              Expanded(
                child: _filterDropdown<String>(
                  label: 'Période',
                  value: _selectedPeriod,
                  icon: Icons.calendar_today_rounded,
                  items: const [
                    DropdownMenuItem(value: '7', child: Text('7 derniers jours')),
                    DropdownMenuItem(value: '30', child: Text('30 derniers jours')),
                    DropdownMenuItem(value: '90', child: Text('Trimestre (90 j)')),
                    DropdownMenuItem(value: 'all', child: Text('Depuis le début')),
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

  Widget _filterDropdown<T>({
    required String label,
    required T? value,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 16, color: kTextSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(fontSize: 13, color: kTextPrimary),
      items: items,
      onChanged: onChanged,
    );
  }

  // ── Global Stats ───────────────────────────────────────────────────────────

  Widget _buildGlobalStats(Map<String, dynamic> stats) {
    final avg = (stats['globalAvgPercent'] as num?)?.toDouble() ?? 0.0;
    final submissions = (stats['totalSubmissions'] as num?)?.toInt() ?? 0;
    final students = (stats['activeStudents'] as num?)?.toInt() ?? 0;

    return Row(
      children: [
        _kpiCard('Élèves actifs', students.toString(),
            Icons.people_rounded, const Color(0xFF2563EB), '+ce mois', 0),
        const SizedBox(width: 12),
        _kpiCard('Soumissions', submissions.toString(),
            Icons.assignment_turned_in_rounded, const Color(0xFF7C3AED), 'Total', 60),
        const SizedBox(width: 12),
        _kpiCard('Moy. globale', '${avg.toStringAsFixed(1)}%',
            Icons.trending_up_rounded, _scoreColor(avg), _scoreLabel(avg), 120),
      ],
    );
  }

  String _scoreLabel(double score) {
    if (score < 40) return '⚠️ Critique';
    if (score < 60) return '📉 Faible';
    if (score < 75) return '📊 Moyen';
    return '✅ Bon';
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color,
      String sub, int delayMs) {
    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 400 + delayMs),
        curve: Curves.easeOut,
        builder: (ctx, anim, _) {
          return Opacity(
            opacity: anim,
            child: Transform.translate(
              offset: Offset(0, 16 * (1 - anim)),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kBorder),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.07),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: color, size: 18),
                        ),
                        Text(sub,
                            style: TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(label,
                        style: const TextStyle(
                            fontSize: 11, color: kTextSecondary)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Section Header ─────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, String sub, bool isWide,
      {bool isAlert = false}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary)),
              Text(sub,
                  style: const TextStyle(fontSize: 11, color: kTextMuted)),
            ],
          ),
        ),
        if (isAlert)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 13, color: Color(0xFFEF4444)),
                SizedBox(width: 5),
                Text('À surveiller',
                    style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
      ],
    );
  }

  // ── Bar Chart ──────────────────────────────────────────────────────────────

  Widget _buildBarChart(List subjects) {
    // Sort weakest first (ascending)
    final sorted = [...subjects]..sort((a, b) {
        final aScore = (a['avgScorePercent'] as num?)?.toDouble() ?? 0;
        final bScore = (b['avgScorePercent'] as num?)?.toDouble() ?? 0;
        return aScore.compareTo(bScore);
      });
    final display = sorted.take(8).toList();

    return Container(
      height: 280,
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12)
        ],
      ),
      child: AnimatedBuilder(
        animation: _animCtrl,
        builder: (ctx, _) {
          return BarChart(
            BarChartData(
              maxY: 100,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF1E293B),
                  tooltipRoundedRadius: 10,
                  getTooltipItem: (group, _, rod, __) {
                    final s = display[group.x];
                    return BarTooltipItem(
                      '${s['subjectName']}\n${rod.toY.toStringAsFixed(1)}%',
                      const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 25,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toInt()}%',
                      style: const TextStyle(fontSize: 10, color: kTextMuted),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx >= display.length) return const SizedBox();
                      final name = (display[idx]['subjectName'] as String?) ?? '';
                      final short = name.length > 7 ? '${name.substring(0, 6)}.' : name;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(short,
                            style: const TextStyle(
                                fontSize: 9, color: kTextSecondary)),
                      );
                    },
                  ),
                ),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                horizontalInterval: 25,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: kBorder, strokeWidth: 1),
              ),
              barGroups: List.generate(display.length, (i) {
                final score =
                    (display[i]['avgScorePercent'] as num?)?.toDouble() ?? 0;
                final color = _scoreColor(score);
                // Animate bars growing from 0
                final animated = score * _animCtrl.value;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: animated,
                      width: 22,
                      color: color,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(7)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: 100,
                        color: color.withOpacity(0.06),
                      ),
                    ),
                  ],
                );
              }),
            ),
          );
        },
      ),
    );
  }

  // ── Weak Exercise Card ─────────────────────────────────────────────────────

  Widget _buildWeakCard(dynamic ex) {
    final score = (ex['avgScorePercent'] as num?)?.toInt() ?? 0;
    final subColor = _parseHex(ex['subjectColor'] as String?);
    final total = ex['totalSubmissions'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEE2E2), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          // Score circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score%',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const Text('moy.',
                    style: TextStyle(
                        fontSize: 8,
                        color: Color(0xFFFCA5A5),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ex['exerciseTitle'] ?? 'Sans titre',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: kTextPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                          color: subColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(ex['subjectName'] ?? '',
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 12)),
                    const SizedBox(width: 12),
                    Icon(Icons.people_outline_rounded,
                        size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text('$total soumissions',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[400])),
                  ],
                ),
              ],
            ),
          ),
          // Progress mini bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFFBBF24), size: 18),
              const SizedBox(height: 6),
              SizedBox(
                width: 60,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: const Color(0xFFFECACA),
                    color: const Color(0xFFEF4444),
                    minHeight: 5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.bar_chart_outlined, size: 56, color: kTextMuted),
            ),
            const SizedBox(height: 20),
            const Text('Pas encore de données',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary)),
            const SizedBox(height: 8),
            const Text(
              'Les analytics s\'alimenteront dès que\ndes élèves commencent les exercices.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
