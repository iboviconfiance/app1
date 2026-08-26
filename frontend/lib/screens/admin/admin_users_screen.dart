import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
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

  void _showRoleDialog(Map<String, dynamic> user) {
    String selectedRole = user['role'] ?? 'student';
    final adminProv = context.read<AdminProvider>();
    final currentUserId = context.read<AuthProvider>().user?['id'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isSelf = user['id'] == currentUserId;
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Modifier le rôle de ${user['prenom']} ${user['nom']}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isSelf) ...[
                    const Card(
                      color: Color(0xFFFEE2E2),
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text(
                          'Attention : Vous modifiez votre propre rôle. Si vous vous retirez le rôle d\'administrateur, vous perdrez l\'accès à cette console.',
                          style: TextStyle(color: Color(0xFF991B1B), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Rôle'),
                    items: const [
                      DropdownMenuItem(value: 'student', child: Text('Élève (student)')),
                      DropdownMenuItem(value: 'teacher', child: Text('Enseignant (teacher)')),
                      DropdownMenuItem(value: 'admin', child: Text('Administrateur (admin)')),
                    ],
                    onChanged: (val) => setDialogState(() => selectedRole = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () async {
                    await adminProv.updateUserRole(user['id'], selectedRole);
                    // If changed self, refresh session profile
                    if (isSelf) {
                      await context.read<AuthProvider>().refreshProfile();
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

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFFEF4444); // Red
      case 'teacher':
        return const Color(0xFF3B82F6); // Blue
      case 'student':
      default:
        return const Color(0xFF10B981); // Green
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'teacher':
        return 'Enseignant';
      case 'student':
      default:
        return 'Élève';
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final users = adminProv.users;
    final loading = adminProv.loading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Gestion des Utilisateurs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: loading && users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => adminProv.loadUsers(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final u = users[index];
                  final role = u['role'] ?? 'student';
                  final color = _roleColor(role);
                  final className = u['classroom_name'] ?? u['classroomName'];
                  final seriesName = u['series_name'] ?? u['seriesName'];

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person, color: color, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Flexible évite que le badge de rôle soit poussé hors de l'écran
                                    Flexible(
                                      child: Text(
                                        '${u['prenom'] ?? ''} ${u['nom'] ?? ''}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _roleLabel(role),
                                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 4),
                                Text(
                                  'Tél: ${u['telephone'] ?? ''} • Inscrit le ${_formatDate(u['created_at'] ?? u['createdAt'])}',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                ),
                                if (u['etablissement'] != null && u['etablissement'].isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Étab: ${u['etablissement']}',
                                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                  ),
                                ],
                                if (className != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Classe: $className${seriesName != null ? ' - Série $seriesName' : ''}',
                                    style: const TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.manage_accounts_rounded, color: Colors.blue),
                            onPressed: () => _showRoleDialog(u),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
