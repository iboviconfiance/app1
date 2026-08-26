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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Padding réduit sur petits écrans pour éviter le chevauchement
        final cardPadding = constraints.maxWidth < 140 ? 10.0 : 14.0;
        return Container(
          padding: EdgeInsets.all(cardPadding),
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  // Trend badge — protégé contre l'overflow
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.trending_up_rounded, size: 11, color: Color(0xFF16A34A)),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              sub,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: kTextPrimary,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: kTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
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
      // Ombre légère pour harmoniser avec les stat cards
      shadowColor: color.withOpacity(0.10),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: color.withOpacity(0.03),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              // Texte occupe l'espace disponible
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: kTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Badge protégé contre l'overflow
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 72),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_ios_rounded, color: kTextMuted, size: 12),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    const SizedBox(width: 12),
                    // Titre dans Expanded pour éviter l'overflow du badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            width < 360 ? 'Admin' : 'Console d\'Administration',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: kTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Gestion de la plateforme KLAS+',
                            style: const TextStyle(fontSize: 11, color: kTextSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Admin badge — masqué sur très petits écrans
                    if (width >= 340)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: width < 400 ? 8 : 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield_rounded, color: Colors.white, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              width < 400 ? 'Admin' : 'Console Admin',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

                      // ── Stats Grid : conserve les données pendant le rechargement ──
                      if (stats != null)
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: isWide ? 5 : (width > 600 ? 3 : 2),
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: isWide ? 1.0 : (width < 360 ? 0.9 : 1.0),
                              children: [
                                _buildStatCard(
                                  label: 'Élèves inscrits',
                                  value: '${stats!['total_users'] ?? 0}',
                                  sub: 'Actifs',
                                  icon: Icons.people_rounded,
                                  color: const Color(0xFF2563EB),
                                  delay: 0,
                                ),
                                _buildStatCard(
                                  label: 'Abonnés Premium',
                                  value: '${stats['active_subscriptions'] ?? 0}',
                                  sub: 'Payants',
                                  icon: Icons.workspace_premium_rounded,
                                  color: const Color(0xFFF59E0B),
                                  delay: 60,
                                ),
                                _buildStatCard(
                                  label: 'Cours publiés',
                                  value: '${stats['total_courses'] ?? 0}',
                                  sub: 'En ligne',
                                  icon: Icons.menu_book_rounded,
                                  color: const Color(0xFF10B981),
                                  delay: 120,
                                ),
                                _buildStatCard(
                                  label: 'Exercices / QCM',
                                  value: '${stats['total_exercises'] ?? 0}',
                                  sub: 'Disponibles',
                                  icon: Icons.quiz_rounded,
                                  color: const Color(0xFF8B5CF6),
                                  delay: 180,
                                ),
                                _buildStatCard(
                                  label: 'Annales BAC',
                                  value: '${stats['total_exams'] ?? 0}',
                                  sub: 'Annales',
                                  icon: Icons.history_edu_rounded,
                                  color: const Color(0xFFEF4444),
                                  delay: 240,
                                ),
                              ],
                            ),
                            // Spinner en overlay — pas de layout shift
                            if (loading)
                              const Positioned(
                                top: 8,
                                right: 8,
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                          ],
                        )
                      else if (loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        ),

                      const SizedBox(height: 36),

                      // ── Section : Gestion des contenus ─────────────────
                      _buildSectionHeader('Gestion des contenus', 'Créer, éditer et organiser'),
                      const SizedBox(height: 16),

                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isWide ? 2 : 1,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        // Ratio dynamique selon la largeur
                        childAspectRatio: isWide
                            ? 4.0
                            : (width < 360 ? 3.5 : (width < 420 ? 4.0 : 4.5)),
                        children: [
                          _buildMenuTile(
                            title: 'Matières & Programmes',
                            subtitle: 'Icônes, couleurs et filières.',
                            icon: Icons.palette_rounded,
                            color: const Color(0xFF06B6D4),
                            badge: 'Matières',
                            onTap: () => context.go('/admin/subjects'),
                            delay: 300,
                          ),
                          _buildMenuTile(
                            title: 'Cours PDF & Vidéos',
                            subtitle: 'Chapitres, PDF et vidéos.',
                            icon: Icons.library_books_rounded,
                            color: const Color(0xFF10B981),
                            badge: 'Contenus',
                            onTap: () => context.go('/admin/courses'),
                            delay: 340,
                          ),
                          _buildMenuTile(
                            title: 'Exercices & QCM',
                            subtitle: 'Quiz interactifs et barèmes.',
                            icon: Icons.quiz_rounded,
                            color: const Color(0xFF8B5CF6),
                            badge: 'Quiz',
                            onTap: () => context.go('/admin/exercises'),
                            delay: 380,
                          ),
                          _buildMenuTile(
                            title: 'Annales BAC / BEPC',
                            subtitle: 'Sujets officiels et corrigés.',
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
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: isWide
                            ? 4.0
                            : (width < 360 ? 3.5 : (width < 420 ? 4.0 : 4.5)),
                        children: [
                          _buildMenuTile(
                            title: 'Gestion des Utilisateurs',
                            subtitle: 'Comptes et rôles enseignants.',
                            icon: Icons.manage_accounts_rounded,
                            color: const Color(0xFF3B82F6),
                            badge: 'Rôles',
                            onTap: () => context.go('/admin/users'),
                            delay: 460,
                          ),
                          _buildMenuTile(
                            title: 'Analytics Professeur',
                            subtitle: 'Notions qui bloquent les élèves.',
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
