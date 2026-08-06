import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/admin_provider.dart';

// ─── Design tokens ───────────────────────────────────────────────────────────
const kBg = Color(0xFFF8FAFC);
const kSurface = Colors.white;
const kBorder = Color(0xFFE8EDF5);
const kTextPrimary = Color(0xFF0F172A);
const kTextSecondary = Color(0xFF64748B);
const kTextMuted = Color(0xFF94A3B8);

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadStats();
    });
  }

  // ── Stat Card ─────────────────────────────────────────────────────────────

  Widget _buildStatCard({
    required String label,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
    required int delay,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 20,
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
              // Icon badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              // Trend badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up_rounded, size: 12, color: Color(0xFF16A34A)),
                    const SizedBox(width: 3),
                    Text(
                      sub,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: kTextPrimary,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: kTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms).slideY(begin: 0.15, end: 0);
  }

  // ── Menu Tile ─────────────────────────────────────────────────────────────

  Widget _buildMenuTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String badge,
    required VoidCallback onTap,
    required int delay,
  }) {
    return Material(
      color: kSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: color.withOpacity(0.03),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios_rounded, color: kTextMuted, size: 14),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms).slideX(begin: 0.05, end: 0);
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final stats = adminProv.stats;
    final loading = adminProv.loading;
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 900;

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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      onPressed: () => context.go('/profile'),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Console d\'Administration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: kTextPrimary,
                          ),
                        ),
                        Text(
                          'Gestion de la plateforme KLAS+',
                          style: TextStyle(fontSize: 12, color: kTextSecondary),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Admin badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text('Admin', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
                child: RefreshIndicator(
                  onRefresh: () => adminProv.loadStats(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                    children: [

                      // ── Section : Aperçu global ─────────────────────────
                      _buildSectionHeader('Aperçu global', 'Données en temps réel'),
                      const SizedBox(height: 16),

                      if (loading && stats == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: isWide ? 5 : (width > 600 ? 3 : 2),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: isWide ? 1.1 : 1.2,
                          children: [
                            _buildStatCard(
                              label: 'Élèves inscrits',
                              value: '${stats?['total_users'] ?? 0}',
                              sub: 'Actifs',
                              icon: Icons.people_rounded,
                              color: const Color(0xFF2563EB),
                              delay: 0,
                            ),
                            _buildStatCard(
                              label: 'Abonnés Premium',
                              value: '${stats?['active_subscriptions'] ?? 0}',
                              sub: 'Payants',
                              icon: Icons.workspace_premium_rounded,
                              color: const Color(0xFFF59E0B),
                              delay: 60,
                            ),
                            _buildStatCard(
                              label: 'Cours publiés',
                              value: '${stats?['total_courses'] ?? 0}',
                              sub: 'En ligne',
                              icon: Icons.menu_book_rounded,
                              color: const Color(0xFF10B981),
                              delay: 120,
                            ),
                            _buildStatCard(
                              label: 'Exercices / QCM',
                              value: '${stats?['total_exercises'] ?? 0}',
                              sub: 'Disponibles',
                              icon: Icons.quiz_rounded,
                              color: const Color(0xFF8B5CF6),
                              delay: 180,
                            ),
                            _buildStatCard(
                              label: 'Annales BAC',
                              value: '${stats?['total_exams'] ?? 0}',
                              sub: 'Annales',
                              icon: Icons.history_edu_rounded,
                              color: const Color(0xFFEF4444),
                              delay: 240,
                            ),
                          ],
                        ),

                      const SizedBox(height: 36),

                      // ── Section : Gestion des contenus ─────────────────
                      _buildSectionHeader('Gestion des contenus', 'Créer, éditer et organiser'),
                      const SizedBox(height: 16),

                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isWide ? 2 : 1,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: isWide ? 3.8 : 4.5,
                        children: [
                          _buildMenuTile(
                            title: 'Matières & Programmes',
                            subtitle: 'Configurer les icônes, couleurs et filières.',
                            icon: Icons.palette_rounded,
                            color: const Color(0xFF06B6D4),
                            badge: 'Matières',
                            onTap: () => context.go('/admin/subjects'),
                            delay: 300,
                          ),
                          _buildMenuTile(
                            title: 'Cours PDF & Vidéos',
                            subtitle: 'Téléverser des chapitres, PDF et vidéos de cours.',
                            icon: Icons.library_books_rounded,
                            color: const Color(0xFF10B981),
                            badge: 'Contenus',
                            onTap: () => context.go('/admin/courses'),
                            delay: 340,
                          ),
                          _buildMenuTile(
                            title: 'Exercices & QCM',
                            subtitle: 'Créer des quiz interactifs et définir les barèmes.',
                            icon: Icons.quiz_rounded,
                            color: const Color(0xFF8B5CF6),
                            badge: 'Quiz',
                            onTap: () => context.go('/admin/exercises'),
                            delay: 380,
                          ),
                          _buildMenuTile(
                            title: 'Annales BAC / BEPC',
                            subtitle: 'Téléverser les sujets officiels et leurs corrigés.',
                            icon: Icons.history_edu_rounded,
                            color: const Color(0xFFEF4444),
                            badge: 'Examens',
                            onTap: () => context.go('/admin/exams'),
                            delay: 420,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Section : Administration ────────────────────────
                      _buildSectionHeader('Administration', 'Équipe & Analytics'),
                      const SizedBox(height: 16),

                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isWide ? 2 : 1,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: isWide ? 3.8 : 4.5,
                        children: [
                          _buildMenuTile(
                            title: 'Gestion des Utilisateurs',
                            subtitle: 'Consulter les comptes et promouvoir les enseignants.',
                            icon: Icons.manage_accounts_rounded,
                            color: const Color(0xFF3B82F6),
                            badge: 'Rôles',
                            onTap: () => context.go('/admin/users'),
                            delay: 460,
                          ),
                          _buildMenuTile(
                            title: 'Analytics Professeur',
                            subtitle: 'Voir les notions qui bloquent le plus les élèves.',
                            icon: Icons.bar_chart_rounded,
                            color: const Color(0xFFF97316),
                            badge: 'Insights',
                            onTap: () => context.go('/admin/analytics'),
                            delay: 500,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String sub) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
              ),
            ),
            Text(sub, style: const TextStyle(fontSize: 12, color: kTextMuted)),
          ],
        ),
      ],
    );
  }
}
