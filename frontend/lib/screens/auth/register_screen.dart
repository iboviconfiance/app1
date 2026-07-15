import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController(text: 'Jean Michel');
  final _phoneCtrl = TextEditingController(text: '+242 06 123 4567');
  final _emailCtrl = TextEditingController(text: 'jean.michel@gmail.com');
  final _passCtrl = TextEditingController(text: 'password123');
  final _confirmPassCtrl = TextEditingController(text: 'password123');
  final _etabCtrl = TextEditingController(text: 'Lycée Technique de Kinshasa');
  
  List<dynamic> _allClassrooms = [];
  List<dynamic> _filteredClassrooms = [];
  List<dynamic> _series = [];
  
  String? _selectedLevel;
  String? _classroomId;
  String? _seriesId;
  String? _error;
  bool _obscureText = true;
  bool _obscureConfirmText = true;

  @override
  void initState() {
    super.initState();
    _loadSchool();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _etabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSchool() async {
    try {
      final api = context.read<AuthProvider>().api;
      final res = await api.get('/school/classrooms');
      setState(() {
        _allClassrooms = res['data'] as List;
        // Default select technical level to match mockup
        _selectedLevel = 'lycee_technique';
        _filterClassrooms('lycee_technique');
      });
    } catch (_) {}
  }

  void _filterClassrooms(String level) {
    setState(() {
      _filteredClassrooms = _allClassrooms.where((c) => c['level'] == level).toList();
      _classroomId = null;
      _series = [];
      _seriesId = null;
    });
  }

  Future<void> _loadSeries(String classroomId) async {
    final api = context.read<AuthProvider>().api;
    final res = await api.get('/school/series?classroomId=$classroomId');
    setState(() {
      _series = res['data'] as List;
      _seriesId = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    try {
      // Split full name for API compatibility
      final parts = _fullNameCtrl.text.trim().split(' ');
      final nom = parts.isNotEmpty ? parts.first : '';
      final prenom = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      
      final cleanPhone = _phoneCtrl.text.trim().replaceAll(' ', '');

      await context.read<AuthProvider>().register({
        'nom': nom,
        'prenom': prenom,
        'telephone': cleanPhone,
        'email': _emailCtrl.text.trim(),
        'password': _passCtrl.text,
        'etablissement': _etabCtrl.text.trim(),
        if (_classroomId != null) 'classroomId': _classroomId,
        if (_seriesId != null) 'seriesId': _seriesId,
      });
      if (mounted) context.go('/dashboard');
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    final registerForm = Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Logo
                Center(
                  child: Image.asset(
                    'assets/images/logo_badge.png',
                    height: 56,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Inscription',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Créez votre compte KLAS+',
                  style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[100]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: Colors.red[700], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w500, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ).animate().shake(duration: 400.ms),
                TextFormField(
                  controller: _fullNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    hintText: 'Jean Michel',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Veuillez saisir votre nom complet' : null,
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    hintText: '+242 06 123 4567',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? 'Veuillez saisir votre téléphone' : null,
                ).animate().fadeIn(delay: 130.ms).slideY(begin: 0.05, end: 0),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'jean.michel@gmail.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Veuillez saisir votre adresse email';
                    }
                    if (!v.contains('@') || !v.contains('.')) {
                      return 'Veuillez saisir une adresse email valide';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 160.ms).slideY(begin: 0.05, end: 0),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: const Color(0xFF94A3B8),
                      ),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                    ),
                  ),
                  obscureText: _obscureText,
                  validator: (v) => v == null || v.length < 6 ? 'Le mot de passe doit faire au moins 6 caractères' : null,
                ).animate().fadeIn(delay: 190.ms).slideY(begin: 0.05, end: 0),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPassCtrl,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: const Color(0xFF94A3B8),
                      ),
                      onPressed: () => setState(() => _obscureConfirmText = !_obscureConfirmText),
                    ),
                  ),
                  obscureText: _obscureConfirmText,
                  validator: (v) => v != _passCtrl.text ? 'Les mots de passe ne correspondent pas' : null,
                ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.05, end: 0),
                const SizedBox(height: 16),

                // Niveau Selection
                DropdownButtonFormField<String>(
                  value: _selectedLevel,
                  decoration: const InputDecoration(labelText: 'Niveau'),
                  items: const [
                    DropdownMenuItem(value: 'college', child: Text('Collège')),
                    DropdownMenuItem(value: 'lycee_general', child: Text('Lycée Général')),
                    DropdownMenuItem(value: 'lycee_technique', child: Text('Lycée Technique')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedLevel = v);
                      _filterClassrooms(v);
                    }
                  },
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 16),

                // Classe Selection
                DropdownButtonFormField<String>(
                  value: _classroomId,
                  decoration: const InputDecoration(labelText: 'Classe'),
                  items: _filteredClassrooms.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['id'] as String,
                      child: Text(c['name'] as String),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _classroomId = v);
                      _loadSeries(v);
                    }
                  },
                ).animate().fadeIn(delay: 280.ms),
                const SizedBox(height: 16),

                // Série Selection
                DropdownButtonFormField<String>(
                  value: _seriesId,
                  decoration: const InputDecoration(labelText: 'Série'),
                  items: _series.map((s) {
                    return DropdownMenuItem<String>(
                      value: s['id'] as String,
                      child: Text(s['name'] as String),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _seriesId = v),
                ).animate().fadeIn(delay: 310.ms),
                const SizedBox(height: 16),

                // Établissement Selection
                TextFormField(
                  controller: _etabCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Établissement',
                    hintText: 'Nom de votre école',
                  ),
                ).animate().fadeIn(delay: 340.ms).slideY(begin: 0.05, end: 0),
                const SizedBox(height: 32),

                FilledButton(
                  onPressed: auth.loading ? null : _submit,
                  child: auth.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('S\'inscrire'),
                ).animate().fadeIn(delay: 370.ms).scale(begin: const Offset(0.97, 0.97)),
                const SizedBox(height: 24),

                // Social buttons divider
                Row(
                  children: [
                    Expanded(child: Divider(color: const Color(0xFFE2E8F0))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ou continuer avec',
                        style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 13),
                      ),
                    ),
                    Expanded(child: Divider(color: const Color(0xFFE2E8F0))),
                  ],
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 20),

                // Google & Facebook Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Text(
                          'G',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        label: const Text('Google'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
                        label: const Text('Facebook'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 430.ms).slideY(begin: 0.05, end: 0),
                const SizedBox(height: 32),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Déjà un compte ?',
                      style: TextStyle(color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Se connecter'),
                    ),
                  ],
                ).animate().fadeIn(delay: 460.ms),
              ],
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/login'),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: isDesktop
          ? Center(
              child: Card(
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.1),
                margin: const EdgeInsets.all(32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: registerForm,
                ),
              ),
            )
          : SafeArea(child: registerForm),
    );
  }
}
