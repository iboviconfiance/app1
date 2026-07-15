import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../config/constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    await context.read<DashboardProvider>().loadDashboard();
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final date = DateTime.parse(isoString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return isoString;
    }
  }

  Widget _buildSubscriptionCard(Map<String, dynamic>? subscription, ThemeData theme) {
    final isPremium = subscription != null && subscription['plan'] != 'gratuit' && subscription['status'] == 'active';
    final planName = subscription != null ? subscription['plan'] ?? 'gratuit' : 'gratuit';
    final endDateStr = subscription != null ? subscription['end_date'] : null;

    final bgColor = isPremium ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceVariant;
    final textColor = isPremium ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPremium ? 'ABONNEMENT ACTIF' : 'VERSION GRATUITE',
                      style: TextStyle(
                        color: isPremium ? theme.colorScheme.primary : theme.colorScheme.secondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isPremium
                          ? (planName == 'individuel' ? 'Plan Individuel' : 'Plan Familial')
                          : 'Accès Limité',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPremium
                          ? 'Expire le ${_formatDate(endDateStr)}'
                          : 'Débloquez tout le catalogue de cours & examens',
                      style: TextStyle(
                        color: textColor.withOpacity(0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isPremium ? Icons.workspace_premium_rounded : Icons.star_border_rounded,
                color: isPremium ? theme.colorScheme.primary : theme.colorScheme.secondary,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/subscription'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: Text(
              isPremium ? 'Gérer mon abonnement' : 'Découvrir nos offres',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessItem(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 10,
              color: Color(0xFF1E293B),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> c, ThemeData theme) {
    final isVideo = c['type'] == 'video';
    final titleLower = (c['title'] ?? '').toLowerCase();
    final subjectLower = (c['subjectName'] ?? '').toLowerCase();

    IconData iconData = Icons.school_rounded;
    if (titleLower.contains('math') || subjectLower.contains('math')) {
      iconData = Icons.calculate_rounded;
    } else if (titleLower.contains('phys') || subjectLower.contains('phys') ||
               titleLower.contains('chim') || subjectLower.contains('chim')) {
      iconData = Icons.science_rounded;
    } else {
      iconData = Icons.menu_book_rounded;
    }

    return InkWell(
      onTap: () {
        if (c['id'] != null && !c['id'].toString().startsWith('mock')) {
          context.go('/courses/${c['id']}');
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1D4ED8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                iconData,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c['title'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c['subjectName'] ?? '',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isVideo ? const Color(0xFFDBEAFE) : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isVideo ? 'Vidéo' : 'PDF',
                style: TextStyle(
                  color: isVideo ? const Color(0xFF2563EB) : const Color(0xFFEF4444),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> e, ThemeData theme) {
    final score = e['score'] ?? 0;
    final total = e['totalPoints'] ?? 0;
    final ratio = total > 0 ? score / total : 0.0;
    final pass = ratio >= 0.5;

    return InkWell(
      onTap: () => context.go('/exercises/${e['id']}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.assignment_turned_in_rounded,
                color: Color(0xFF2E7D32),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'Score: $score/$total',
                        style: TextStyle(
                          color: pass ? Colors.green[700] : Colors.red[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '• Quiz complété',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDownloadsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mes Téléchargements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.download_done_rounded, size: 48, color: const Color(0xFF64748B)),
                    SizedBox(height: 12),
                    Text(
                      'Aucun fichier téléchargé hors-ligne pour le moment.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showFavoritesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mes Favoris',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.favorite_rounded, size: 48, color: Colors.pinkAccent),
                    SizedBox(height: 12),
                    Text(
                      'Aucun favori ajouté. Cliquez sur le cœur dans les détails d\'un cours pour l\'ajouter.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    final String serverUrl = AppConstants.apiBaseUrl.endsWith('/api')
        ? AppConstants.apiBaseUrl.substring(0, AppConstants.apiBaseUrl.length - 4)
        : AppConstants.apiBaseUrl;

    final dashboardProvider = context.watch<DashboardProvider>();
    final loading = dashboardProvider.loading;
    final data = dashboardProvider.dashboardData;

    if (loading && data == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final progression = data?['progression'] ?? {};
    final subscription = data?['subscription'];
    final recentCourses = (data?['recentCourses'] as List?) ?? [];
    final recentExercises = (data?['recentExercises'] as List?) ?? [];

    final progressVal = (progression['overallProgress'] ?? 0).toDouble();
    // Bind to real progressVal (0..100) or fallback to 75 if it's 0 (meaning no data yet)
    final double displayProgress = progressVal > 0 ? progressVal : 75.0;
    final double percent = displayProgress / 100.0;

    // Generate dynamic message based on progression value
    String statusTitle = 'Excellent !';
    String statusSubtitle = 'Continue comme ça';
    if (displayProgress < 40) {
      statusTitle = 'Bon début !';
      statusSubtitle = 'Continue à apprendre';
    } else if (displayProgress < 70) {
      statusTitle = 'Bien joué !';
      statusSubtitle = 'Tu progresses bien';
    }

    // Generate a trend sparkline that ends at displayProgress
    final List<double> sparklinePoints = <double>[
      displayProgress * 0.15,
      displayProgress * 0.35,
      displayProgress * 0.28,
      displayProgress * 0.55,
      displayProgress * 0.48,
      displayProgress * 0.80,
      displayProgress,
    ];

    final progressCard = Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircularPercentIndicator(
              radius: 28,
              lineWidth: 6,
              percent: percent,
              center: Text(
                '${displayProgress.toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  fontSize: 12,
                ),
              ),
              progressColor: const Color(0xFF10B981),
              backgroundColor: const Color(0xFFE2E8F0),
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
              animationDuration: 800,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusTitle,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusSubtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Sparkline mini graph
            SizedBox(
              width: 100,
              height: 40,
              child: CustomPaint(
                painter: SparklinePainter(
                  data: sparklinePoints,
                  color: const Color(0xFF1D4ED8),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final quickAccessGrid = GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 6 : 4,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: isDesktop ? 1.0 : 0.8,
      children: [
        _buildQuickAccessItem(
          context,
          label: 'Cours',
          icon: Icons.shield_outlined,
          color: const Color(0xFF2563EB),
          onTap: () => context.go('/school'),
        ),
        _buildQuickAccessItem(
          context,
          label: 'Exercices',
          icon: Icons.edit_outlined,
          color: const Color(0xFF16A34A),
          onTap: () => context.go('/exercises'),
        ),
        _buildQuickAccessItem(
          context,
          label: 'Examens',
          icon: Icons.assignment_outlined,
          color: const Color(0xFFDC2626),
          onTap: () => context.go('/exams'),
        ),
        _buildQuickAccessItem(
          context,
          label: 'Groupes',
          icon: Icons.groups_outlined,
          color: const Color(0xFFD946EF),
          onTap: () => context.go('/work-groups'),
        ),
        _buildQuickAccessItem(
          context,
          label: 'Téléchargements',
          icon: Icons.download_for_offline_outlined,
          color: const Color(0xFF6366F1),
          onTap: () => _showDownloadsSheet(context),
        ),
        _buildQuickAccessItem(
          context,
          label: 'Favoris',
          icon: Icons.favorite_border_rounded,
          color: const Color(0xFF8B5CF6),
          onTap: () => _showFavoritesSheet(context),
        ),
      ],
    );

    final List<Map<String, dynamic>> mockRecentCourses = [
      {
        'id': 'mock-math',
        'title': 'Mathématiques - F4',
        'subjectName': 'Les fonctions numériques',
        'type': 'pdf',
      },
      {
        'id': 'mock-phys',
        'title': 'Physique - F4',
        'subjectName': 'Le mouvement rectiligne',
        'type': 'video',
      },
    ];

    final finalCourses = recentCourses.isNotEmpty ? recentCourses : mockRecentCourses;

    final classroomText = user?['classroomName'] != null
        ? '${user?['classroomName']}${user?['seriesName'] != null ? ' - Série ${user?['seriesName']}' : ''}'
        : null;

    // Mobile & Desktop content wrappers
    final List<Widget> itemsList = [
      const SizedBox(height: 16),
      // Profile Section directly inside body list view
      Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1D4ED8).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(2), // Gradient border spacing
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(2), // White spacer ring
              child: ClipOval(
                child: user?['avatarUrl'] != null
                    ? Image.network(
                        '${serverUrl}${user?['avatarUrl']}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 28),
                      )
                    : Image.asset(
                        'assets/images/onboarding_boy.png',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bonjour,',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        '${user?['prenom'] ?? 'Jean'} ${user?['nom'] ?? 'Michel'}',
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '👋',
                      style: TextStyle(fontSize: 18),
                    )
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .rotate(
                          begin: -0.05,
                          end: 0.08,
                          duration: 800.ms,
                          curve: Curves.easeInOut,
                        ),
                  ],
                ),
                if (classroomText != null || user?['etablissement'] != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (classroomText != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFDBEAFE), width: 1),
                          ),
                          child: Text(
                            classroomText,
                            style: const TextStyle(
                              color: Color(0xFF1D4ED8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (user?['etablissement'] != null)
                        Expanded(
                          child: Text(
                            user?['etablissement'],
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
      const SizedBox(height: 20),
      _buildSubscriptionCard(subscription, theme).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.05, end: 0),
      const SizedBox(height: 20),
      Text(
        'Ma progression',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1E293B),
          letterSpacing: -0.2,
        ),
      ).animate().fadeIn(delay: 130.ms),
      const SizedBox(height: 12),
      progressCard.animate().fadeIn(delay: 150.ms, duration: 500.ms).slideY(begin: 0.05, end: 0),
      const SizedBox(height: 28),
      Text(
        'Accès rapides',
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B), letterSpacing: -0.2),
      ).animate().fadeIn(delay: 200.ms),
      const SizedBox(height: 16),
      quickAccessGrid.animate().fadeIn(delay: 230.ms).scale(begin: const Offset(0.97, 0.97)),
      const SizedBox(height: 32),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: isDesktop ? 3 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Récents',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B), letterSpacing: -0.2),
                ).animate().fadeIn(delay: 260.ms),
                const SizedBox(height: 12),
                ...List.generate(finalCourses.length, (i) {
                  final c = Map<String, dynamic>.from(finalCourses[i]);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: _buildCourseCard(c, theme),
                  ).animate().fadeIn(delay: (260 + i * 80).ms, duration: 400.ms).slideX(begin: 0.03, end: 0);
                }),
              ],
            ),
          ),
          if (isDesktop && recentExercises.isNotEmpty) ...[
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exercices Récents',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B), letterSpacing: -0.2),
                  ).animate().fadeIn(delay: 290.ms),
                  const SizedBox(height: 12),
                  ...List.generate(recentExercises.length, (i) {
                    final e = recentExercises[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: _buildExerciseCard(e, theme),
                    ).animate().fadeIn(delay: (290 + i * 80).ms, duration: 400.ms).slideX(begin: 0.03, end: 0);
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
      if (!isDesktop && recentExercises.isNotEmpty) ...[
        const SizedBox(height: 28),
        Text(
          'Exercices Récents',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B), letterSpacing: -0.2),
        ).animate().fadeIn(delay: 290.ms),
        const SizedBox(height: 12),
        ...List.generate(recentExercises.length, (i) {
          final e = recentExercises[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: _buildExerciseCard(e, theme),
          ).animate().fadeIn(delay: (290 + i * 80).ms, duration: 400.ms).slideX(begin: 0.03, end: 0);
        }),
      ],
      const SizedBox(height: 32),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Color(0xFF1E293B), size: 28),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Aucune nouvelle notification')),
                  );
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_rounded, color: Color(0xFF1E293B), size: 28),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: const Text(
                          '3',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text('${user?['prenom'] ?? 'Jean'} ${user?['nom'] ?? 'Michel'}'),
              accountEmail: Text(user?['telephone'] ?? user?['email'] ?? ''),
              currentAccountPicture: user?['avatarUrl'] != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage('${serverUrl}${user?['avatarUrl']}'),
                    )
                  : CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        '${user?['prenom']?[0] ?? 'J'}${user?['nom']?[0] ?? 'M'}',
                        style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Accueil'),
              onTap: () {
                Navigator.pop(context);
                context.go('/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Parcours Scolaire'),
              onTap: () {
                Navigator.pop(context);
                context.go('/school');
              },
            ),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Mon abonnement'),
              onTap: () {
                Navigator.pop(context);
                context.go('/subscription');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Mon Profil'),
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await context.read<AuthProvider>().logout();
                if (mounted) context.go('/welcome');
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: itemsList,
        ),
      ),
    );
  }
}

// Sparkline Painter for visual trend curves
class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final widthStep = size.width / (data.length - 1);

    double lastX = 0;
    double lastY = 0;

    for (int i = 0; i < data.length; i++) {
      final x = i * widthStep;
      final y = size.height - ((data[i] - minVal) / range) * (size.height - 8) - 4;

      if (i == data.length - 1) {
        lastX = x;
        lastY = y;
      }

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * widthStep;
        final prevY = size.height - ((data[i - 1] - minVal) / range) * (size.height - 8) - 4;
        final controlX1 = prevX + widthStep / 2;
        final controlY1 = prevY;
        final controlX2 = prevX + widthStep / 2;
        final controlY2 = y;

        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
        fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw solid blue circle at the last point of the trend line
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(lastX, lastY), 4.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) => oldDelegate.data != data;
}

class HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const HoverCard({super.key, required this.child, this.onTap});

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered ? (Matrix4.identity()..translate(0, -3, 0)) : Matrix4.identity(),
        child: Card(
          elevation: _isHovered ? 4 : 0,
          margin: EdgeInsets.zero,
          shadowColor: Colors.black.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _isHovered ? Theme.of(context).colorScheme.primary.withOpacity(0.3) : const Color(0xFFF1F5F9)!,
              width: 1.5,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
