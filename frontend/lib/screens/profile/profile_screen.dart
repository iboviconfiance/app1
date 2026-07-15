import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../config/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _etabCtrl = TextEditingController();

  String? _avatarBase64;
  Uint8List? _avatarBytes;
  bool _saving = false;
  Map<String, dynamic>? _appConfig;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final res = await context.read<AuthProvider>().api.get('/config');
      if (mounted) {
        setState(() {
          _appConfig = res['data'];
        });
      }
    } catch (_) {}
  }

  void _loadUser() {
    final user = context.read<AuthProvider>().user;
    _nomCtrl.text = user?['nom'] ?? '';
    _prenomCtrl.text = user?['prenom'] ?? '';
    _etabCtrl.text = user?['etablissement'] ?? '';
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _avatarBytes = result.files.single.bytes;
          _avatarBase64 = base64Encode(_avatarBytes!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de sélection d\'image: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final body = {
        'nom': _nomCtrl.text.trim(),
        'prenom': _prenomCtrl.text.trim(),
        'etablissement': _etabCtrl.text.trim(),
      };

      if (_avatarBase64 != null) {
        body['avatar'] = _avatarBase64!;
      }

      final res = await context.read<AuthProvider>().api.put('/users/profile', body);

      if (res['success'] == true) {
        await context.read<AuthProvider>().refreshProfile();
        setState(() {
          _avatarBase64 = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil mis à jour avec succès')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Erreur lors de la mise à jour')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  void _showUpdateEmailSheet(BuildContext parentContext) {
    final user = parentContext.read<AuthProvider>().user;
    final newValueCtrl = TextEditingController(text: user?['email'] ?? '');
    final passwordCtrl = TextEditingController();
    final codeCtrl = TextEditingController();

    int step = 1;
    bool loading = false;
    String? errorMsg;

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (step == 1) ...[
                      const Text(
                        'Modifier l\'adresse e-mail',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Saisissez votre nouvelle adresse e-mail. Un code de validation vous sera envoyé pour confirmer le changement.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: newValueCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Nouvelle adresse e-mail',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Mot de passe actuel',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Confirmer l\'adresse e-mail',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Entrez le code à 6 chiffres envoyé à ${newValueCtrl.text}.',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: codeCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                        decoration: const InputDecoration(
                          counterText: "",
                          hintText: "000000",
                          hintStyle: TextStyle(color: Color(0xFFCBD5E1), letterSpacing: 8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'Pour la démo, saisissez le code : 123456',
                          style: TextStyle(fontSize: 12, color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    if (errorMsg != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        errorMsg!,
                        style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: loading
                          ? null
                          : () async {
                              if (step == 1) {
                                if (newValueCtrl.text.trim().isEmpty || passwordCtrl.text.isEmpty) {
                                  setModalState(() {
                                    errorMsg = 'Veuillez remplir tous les champs.';
                                  });
                                  return;
                                }
                                setModalState(() {
                                  loading = true;
                                  errorMsg = null;
                                });
                                await Future.delayed(const Duration(milliseconds: 800));
                                setModalState(() {
                                  step = 2;
                                  loading = false;
                                });
                              } else {
                                if (codeCtrl.text.trim() != '123456') {
                                  setModalState(() {
                                    errorMsg = 'Code de confirmation incorrect. Saisissez 123456.';
                                  });
                                  return;
                                }
                                setModalState(() {
                                  loading = true;
                                  errorMsg = null;
                                });
                                try {
                                  final res = await parentContext.read<AuthProvider>().api.put('/users/profile', {
                                    'email': newValueCtrl.text.trim(),
                                    'currentPassword': passwordCtrl.text,
                                  });
                                  if (res['success'] == true) {
                                    await parentContext.read<AuthProvider>().refreshProfile();
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(parentContext).showSnackBar(
                                        const SnackBar(content: Text('Adresse e-mail mise à jour avec succès')),
                                      );
                                    }
                                  } else {
                                    setModalState(() {
                                      errorMsg = res['message'] ?? 'Erreur lors de la mise à jour';
                                      step = 1;
                                      loading = false;
                                    });
                                  }
                                } catch (e) {
                                  String errMsg = e.toString();
                                  if (errMsg.contains('401')) {
                                    errMsg = 'Mot de passe actuel incorrect.';
                                  } else if (errMsg.contains('400')) {
                                    errMsg = 'Format e-mail invalide ou adresse déjà utilisée.';
                                  }
                                  setModalState(() {
                                    errorMsg = errMsg;
                                    step = 1;
                                    loading = false;
                                  });
                                }
                              }
                            },
                      child: loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(step == 1 ? 'Continuer' : 'Confirmer la modification'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showUpdatePhoneSheet(BuildContext parentContext) {
    final user = parentContext.read<AuthProvider>().user;
    final newValueCtrl = TextEditingController(text: user?['telephone'] ?? '');
    final passwordCtrl = TextEditingController();
    final codeCtrl = TextEditingController();

    int step = 1;
    bool loading = false;
    String? errorMsg;

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (step == 1) ...[
                      const Text(
                        'Modifier le numéro de téléphone',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Saisissez votre nouveau numéro de téléphone. Un code de validation vous sera envoyé pour confirmer le changement.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: newValueCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Nouveau numéro de téléphone',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Mot de passe actuel',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Confirmer le numéro de téléphone',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Entrez le code à 6 chiffres envoyé au ${newValueCtrl.text}.',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: codeCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                        decoration: const InputDecoration(
                          counterText: "",
                          hintText: "000000",
                          hintStyle: TextStyle(color: Color(0xFFCBD5E1), letterSpacing: 8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'Pour la démo, saisissez le code : 123456',
                          style: TextStyle(fontSize: 12, color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    if (errorMsg != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        errorMsg!,
                        style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: loading
                          ? null
                          : () async {
                              if (step == 1) {
                                if (newValueCtrl.text.trim().isEmpty || passwordCtrl.text.isEmpty) {
                                  setModalState(() {
                                    errorMsg = 'Veuillez remplir tous les champs.';
                                  });
                                  return;
                                }
                                setModalState(() {
                                  loading = true;
                                  errorMsg = null;
                                });
                                await Future.delayed(const Duration(milliseconds: 800));
                                setModalState(() {
                                  step = 2;
                                  loading = false;
                                });
                              } else {
                                if (codeCtrl.text.trim() != '123456') {
                                  setModalState(() {
                                    errorMsg = 'Code de confirmation incorrect. Saisissez 123456.';
                                  });
                                  return;
                                }
                                setModalState(() {
                                  loading = true;
                                  errorMsg = null;
                                });
                                try {
                                  final res = await parentContext.read<AuthProvider>().api.put('/users/profile', {
                                    'telephone': newValueCtrl.text.trim(),
                                    'currentPassword': passwordCtrl.text,
                                  });
                                  if (res['success'] == true) {
                                    await parentContext.read<AuthProvider>().refreshProfile();
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(parentContext).showSnackBar(
                                        const SnackBar(content: Text('Numéro de téléphone mis à jour avec succès')),
                                      );
                                    }
                                  } else {
                                    setModalState(() {
                                      errorMsg = res['message'] ?? 'Erreur lors de la mise à jour';
                                      step = 1;
                                      loading = false;
                                    });
                                  }
                                } catch (e) {
                                  String errMsg = e.toString();
                                  if (errMsg.contains('401')) {
                                    errMsg = 'Mot de passe actuel incorrect.';
                                  } else if (errMsg.contains('400')) {
                                    errMsg = 'Numéro de téléphone déjà utilisé.';
                                  }
                                  setModalState(() {
                                    errorMsg = errMsg;
                                    step = 1;
                                    loading = false;
                                  });
                                }
                              }
                            },
                      child: loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(step == 1 ? 'Continuer' : 'Confirmer la modification'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showUpdatePasswordSheet(BuildContext parentContext) {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();

    bool loading = false;
    String? errorMsg;

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Modifier le mot de passe',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Veuillez saisir votre mot de passe actuel puis votre nouveau mot de passe.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: currentPasswordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe actuel',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPasswordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Nouveau mot de passe',
                        prefixIcon: Icon(Icons.lock_reset),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirmer le nouveau mot de passe',
                        prefixIcon: Icon(Icons.lock_clock_outlined),
                      ),
                    ),
                    if (errorMsg != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        errorMsg!,
                        style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: loading
                          ? null
                          : () async {
                              if (currentPasswordCtrl.text.isEmpty ||
                                  newPasswordCtrl.text.isEmpty ||
                                  confirmPasswordCtrl.text.isEmpty) {
                                setModalState(() {
                                  errorMsg = 'Veuillez remplir tous les champs.';
                                });
                                return;
                              }

                              if (newPasswordCtrl.text != confirmPasswordCtrl.text) {
                                setModalState(() {
                                  errorMsg = 'Les nouveaux mots de passe ne correspondent pas.';
                                });
                                return;
                              }

                              if (newPasswordCtrl.text.length < 6) {
                                setModalState(() {
                                  errorMsg = 'Le nouveau mot de passe doit comporter au moins 6 caractères.';
                                });
                                return;
                              }

                              setModalState(() {
                                loading = true;
                                errorMsg = null;
                              });

                              try {
                                final res = await parentContext.read<AuthProvider>().api.put('/users/profile', {
                                  'currentPassword': currentPasswordCtrl.text,
                                  'newPassword': newPasswordCtrl.text,
                                });

                                if (res['success'] == true) {
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(parentContext).showSnackBar(
                                      const SnackBar(content: Text('Mot de passe mis à jour avec succès')),
                                    );
                                  }
                                } else {
                                  setModalState(() {
                                    errorMsg = res['message'] ?? 'Erreur lors de la mise à jour';
                                    loading = false;
                                  });
                                }
                              } catch (e) {
                                String errMsg = e.toString();
                                if (errMsg.contains('401')) {
                                  errMsg = 'Mot de passe actuel incorrect.';
                                }
                                setModalState(() {
                                  errorMsg = errMsg;
                                  loading = false;
                                });
                              }
                            },
                      child: loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Confirmer la modification'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final theme = Theme.of(context);

    final String serverUrl = AppConstants.apiBaseUrl.endsWith('/api')
        ? AppConstants.apiBaseUrl.substring(0, AppConstants.apiBaseUrl.length - 4)
        : AppConstants.apiBaseUrl;

    final sub = user?['subscription'];
    final isPremium = sub != null && (sub['plan'] == 'individuel' || sub['plan'] == 'familial') && sub['status'] == 'active';

    final stats = user?['stats'] ?? {};
    final int completedCourses = stats['completedCourses'] ?? 0;
    final int totalExercises = stats['totalExercises'] ?? 0;
    final int avgScore = stats['avgScore'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon Profil')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          Center(
            child: Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _avatarBytes != null
                        ? Image.memory(_avatarBytes!, fit: BoxFit.cover)
                        : (user?['avatarUrl'] != null
                            ? Image.network(
                                '${serverUrl}${user?['avatarUrl']}',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 48),
                              )
                            : Image.asset(
                                'assets/images/onboarding_boy.png',
                                fit: BoxFit.cover,
                              )),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                Text(
                  '${user?['prenom'] ?? ''} ${user?['nom'] ?? ''}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPremium ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isPremium ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPremium ? Icons.workspace_premium : Icons.person_outline,
                        size: 14,
                        color: isPremium ? const Color(0xFFD97706) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPremium ? 'Membre PREMIUM' : 'Compte Gratuit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPremium ? const Color(0xFFB45309) : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          TextField(controller: _nomCtrl, decoration: const InputDecoration(labelText: 'Nom')),
          const SizedBox(height: 16),
          TextField(controller: _prenomCtrl, decoration: const InputDecoration(labelText: 'Prénom')),
          const SizedBox(height: 16),
          TextField(controller: _etabCtrl, decoration: const InputDecoration(labelText: 'Établissement')),
          if (user?['classroomName'] != null) ...[
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Classe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(user!['classroomName']),
            ),
          ],
          if (user?['seriesName'] != null) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Série', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(user!['seriesName']),
            ),
          ],

          const SizedBox(height: 24),
          const Text(
            'Statistiques de révision',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.menu_book,
                  value: '$completedCourses',
                  label: 'Cours terminés',
                  color: const Color(0xFF3B82F6),
                  bgColor: const Color(0xFFEFF6FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.assignment_turned_in_outlined,
                  value: '$totalExercises',
                  label: 'Quiz tentés',
                  color: const Color(0xFF10B981),
                  bgColor: const Color(0xFFECFDF5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.stars_rounded,
                  value: '$avgScore%',
                  label: 'Score moyen',
                  color: const Color(0xFFF59E0B),
                  bgColor: const Color(0xFFFEF3C7),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Text(
            'Informations de sécurité',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone_outlined, color: Color(0xFF1D4ED8), size: 20),
                  ),
                  title: const Text('Numéro de téléphone', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  subtitle: Text(
                    user?['telephone'] ?? 'Non renseigné',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                  onTap: () => _showUpdatePhoneSheet(context),
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFE2E8F0)),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.email_outlined, color: Color(0xFF1D4ED8), size: 20),
                  ),
                  title: const Text('Adresse e-mail', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  subtitle: Text(
                    user?['email'] ?? 'Non renseignée',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                  onTap: () => _showUpdateEmailSheet(context),
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFE2E8F0)),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline, color: Color(0xFF1D4ED8), size: 20),
                  ),
                  title: const Text('Mot de passe', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  subtitle: const Text(
                    '••••••••',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                  onTap: () => _showUpdatePasswordSheet(context),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Enregistrer'),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.groups),
            title: const Text('Groupes de travail'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.go('/work-groups'),
          ),
          ListTile(
            leading: const Icon(Icons.card_membership),
            title: const Text('Abonnement'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.go('/subscription'),
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Hiérarchie scolaire'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.go('/school'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Besoin d\'aide ou d\'assistance ?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.green),
                  title: const Text('Assistance WhatsApp'),
                  subtitle: Text(_appConfig?['supportPhoneNumber'] ?? '+242 06 000 0000'),
                  onTap: () async {
                    final num = _appConfig?['supportPhoneNumber'] ?? '+242060000000';
                    final cleanNum = num.replaceAll(' ', '').replaceAll('+', '');
                    final uri = Uri.parse('https://wa.me/$cleanNum');
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFE2E8F0)),
                ListTile(
                  leading: const Icon(Icons.mail_outline_rounded, color: Colors.blue),
                  title: const Text('Support par Email'),
                  subtitle: Text(_appConfig?['supportEmail'] ?? 'support@klasplus.cg'),
                  onTap: () async {
                    final email = _appConfig?['supportEmail'] ?? 'support@klasplus.cg';
                    final uri = Uri.parse('mailto:$email?subject=Assistance KLAS%2B');
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          OutlinedButton(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/welcome');
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}
