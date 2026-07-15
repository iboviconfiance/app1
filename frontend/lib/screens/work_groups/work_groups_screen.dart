import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class WorkGroupsScreen extends StatefulWidget {
  const WorkGroupsScreen({super.key});

  @override
  State<WorkGroupsScreen> createState() => _WorkGroupsScreenState();
}

class _WorkGroupsScreenState extends State<WorkGroupsScreen> {
  List<dynamic> _groups = [];
  bool _loading = true;
  final _nameCtrl = TextEditingController();
  final _inviteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await context.read<AuthProvider>().api.get('/work-groups');
    setState(() { _groups = res['data'] as List; _loading = false; });
  }

  Future<void> _create() async {
    await context.read<AuthProvider>().api.post('/work-groups', {
      'name': _nameCtrl.text.trim(),
      'description': 'Groupe de révision',
    });
    _nameCtrl.clear();
    if (mounted) Navigator.pop(context);
    _load();
  }

  Future<void> _join() async {
    await context.read<AuthProvider>().api.post('/work-groups/join', {
      'inviteCode': _inviteCtrl.text.trim(),
    });
    _inviteCtrl.clear();
    if (mounted) Navigator.pop(context);
    _load();
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Créer un groupe'),
        content: TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nom du groupe')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(onPressed: _create, child: const Text('Créer')),
        ],
      ),
    );
  }

  void _showJoinDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rejoindre un groupe'),
        content: TextField(controller: _inviteCtrl, decoration: const InputDecoration(labelText: 'Code d\'invitation')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(onPressed: _join, child: const Text('Rejoindre')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groupes de travail'),
        actions: [
          IconButton(icon: const Icon(Icons.group_add), onPressed: _showJoinDialog),
          IconButton(icon: const Icon(Icons.add), onPressed: _showCreateDialog),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? const Center(child: Text('Aucun groupe. Créez-en un ou rejoignez avec un code.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _groups.length,
                  itemBuilder: (_, i) {
                    final g = _groups[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.groups),
                        title: Text(g['name'] ?? ''),
                        subtitle: Text('${g['memberCount'] ?? 0} membres • Code: ${g['inviteCode'] ?? ''}'),
                      ),
                    );
                  },
                ),
    );
  }
}
