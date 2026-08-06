import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/admin_provider.dart';

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

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.15), width: 1.5),
      ),
      color: color.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
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
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminProv = context.watch<AdminProvider>();
    final stats = adminProv.stats;
    final loading = adminProv.loading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Console d\'Administration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/profile'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => adminProv.loadStats(),
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text(
              'Aperçu global',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            if (loading && stats == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _buildStatCard(
                    label: 'ÉLÈVES',
                    value: '${stats?['total_users'] ?? 0}',
                    icon: Icons.people_rounded,
                    color: const Color(0xFF3B82F6),
                    theme: theme,
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                  _buildStatCard(
                    label: 'ABONNÉS',
                    value: '${stats?['active_subscriptions'] ?? 0}',
                    icon: Icons.workspace_premium_rounded,
                    color: const Color(0xFFF59E0B),
                    theme: theme,
                  ).animate().fadeIn(delay: 50.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
                  _buildStatCard(
                    label: 'COURS',
                    value: '${stats?['total_courses'] ?? 0}',
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFF10B981),
                    theme: theme,
                  ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
                  _buildStatCard(
                    label: 'EXERCICES',
                    value: '${stats?['total_exercises'] ?? 0}',
                    icon: Icons.assignment_rounded,
                    color: const Color(0xFF8B5CF6),
                    theme: theme,
                  ).animate().fadeIn(delay: 155.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
                ],
              ),
            const SizedBox(height: 32),
            const Text(
              'Gestion des contenus',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            _buildMenuTile(
              title: 'Gestion des Matières',
              subtitle: 'Créer, éditer, et configurer les couleurs et icônes des matières.',
              icon: Icons.palette_outlined,
              color: const Color(0xFF06B6D4),
              onTap: () => context.go('/admin/subjects'),
              theme: theme,
            ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
            _buildMenuTile(
              title: 'Gestion des Cours (PDF & Vidéos)',
              subtitle: 'Ajouter des chapitres de cours, téléverser des PDF et des vidéos.',
              icon: Icons.library_books_rounded,
              color: const Color(0xFF10B981),
              onTap: () => context.go('/admin/courses'),
              theme: theme,
            ).animate().fadeIn(delay: 250.ms, duration: 300.ms),
            _buildMenuTile(
              title: 'Gestion des Exercices (QCM & Quiz)',
              subtitle: 'Créer des quiz interactifs, ajouter des questions et définir les barèmes.',
              icon: Icons.quiz_rounded,
              color: const Color(0xFF8B5CF6),
              onTap: () => context.go('/admin/exercises'),
              theme: theme,
            ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
            _buildMenuTile(
              title: 'Gestion des Utilisateurs',
              subtitle: 'Consulter les comptes élèves et promouvoir les enseignants / administrateurs.',
              icon: Icons.manage_accounts_rounded,
              color: const Color(0xFF3B82F6),
              onTap: () => context.go('/admin/users'),
              theme: theme,
            ).animate().fadeIn(delay: 350.ms, duration: 300.ms),
          ],
        ),
      ),
    );
  }
}
