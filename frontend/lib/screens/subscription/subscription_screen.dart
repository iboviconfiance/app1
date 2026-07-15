import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  List<dynamic> _plans = [];
  String _method = 'airtel_money'; // airtel_money, mtn_mobile_money
  final _phoneCtrl = TextEditingController();
  bool _loading = true;
  bool _submitting = false;

  // Selected billing config
  int _activePlanTab = 0; // 0: Individuel, 1: Familial
  String _selectedDuration = '1 Mois'; // 1 Semaine, 1 Mois, 3 Mois, 1 An

  @override
  void initState() {
    super.initState();
    _load();
    final user = context.read<AuthProvider>().user;
    _phoneCtrl.text = user?['telephone'] ?? '';
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await context.read<AuthProvider>().api.get('/subscriptions/plans');
      setState(() {
        _plans = res['data'] as List;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _subscribe(String planId) async {
    setState(() => _submitting = true);
    try {
      final res = await context.read<AuthProvider>().api.post('/subscriptions/subscribe', {
        'plan': planId,
        'method': _method,
        'phoneNumber': _phoneCtrl.text.trim(),
      });
      
      // Update local user authentication/subscription details if provider has it
      await context.read<AuthProvider>().refreshProfile();

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
                SizedBox(width: 12),
                Text('Paiement Réussi', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              res['data']?['message'] ?? 'Votre abonnement a été activé avec succès. Merci pour votre confiance !',
              style: const TextStyle(height: 1.4),
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back
                },
                child: const Text('Accéder aux cours'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  int _getPrice() {
    if (_activePlanTab == 0) {
      // Individuel
      switch (_selectedDuration) {
        case '1 Semaine':
          return 1500;
        case '1 Mois':
          return 5000;
        case '3 Mois':
          return 12000;
        case '1 An':
          return 45000;
        default:
          return 5000;
      }
    } else {
      // Familial
      switch (_selectedDuration) {
        case '1 Semaine':
          return 3500;
        case '1 Mois':
          return 12000;
        case '3 Mois':
          return 30000;
        case '1 An':
          return 100000;
        default:
          return 12000;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().user;
    
    // Check if user has an active premium subscription right now
    // Wait, let's pull subscription active info from provider/user
    final activeSubscription = user?['subscription'] ?? user?['activeSubscription'];
    final hasPremium = activeSubscription != null && activeSubscription['plan'] != 'gratuit' && activeSubscription['status'] == 'active';
    final planName = activeSubscription != null ? activeSubscription['plan'] ?? 'gratuit' : 'gratuit';

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final currentPrice = _getPrice();
    final planIdToSend = _activePlanTab == 0 ? 'individuel' : 'familial';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Forfaits KLAS+'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Card showing current status (Écran 12)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: hasPremium ? const Color(0xFF10B981) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: hasPremium ? Colors.transparent : const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.workspace_premium_rounded,
                            color: hasPremium ? Colors.white : const Color(0xFFF59E0B),
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasPremium ? 'Abonnement Actif' : 'Aucun Abonnement Actif',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: hasPremium ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hasPremium 
                                    ? 'Vous profitez actuellement de l\'offre ${planName.toUpperCase()}'
                                    : 'Abonnez-vous pour débloquer l\'accès complet',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: hasPremium ? Colors.white.withOpacity(0.9) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 24),

                    // Plan Tabs selector (Écran 12)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: Row(
                        children: [
                          _buildPlanTab(0, 'Individuel'),
                          _buildPlanTab(1, 'Familial (jusqu\'à 5)'),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 24),

                    // Duration selector list with radio tiles (Écran 12)
                    Text(
                      'Choisissez la durée',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 12),
                    Column(
                      children: ['1 Semaine', '1 Mois', '3 Mois', '1 An'].map((duration) {
                        final isSelected = _selectedDuration == duration;
                        int price = 0;
                        if (_activePlanTab == 0) {
                          price = duration == '1 Semaine' ? 1500 : (duration == '1 Mois' ? 5000 : (duration == '3 Mois' ? 12000 : 45000));
                        } else {
                          price = duration == '1 Semaine' ? 3500 : (duration == '1 Mois' ? 12000 : (duration == '3 Mois' ? 30000 : 100000));
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: isSelected ? theme.colorScheme.primary.withOpacity(0.04) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? theme.colorScheme.primary : const Color(0xFFE2E8F0),
                                width: isSelected ? 2.0 : 1.5,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedDuration = duration;
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                child: Row(
                                  children: [
                                    Radio<String>(
                                      value: duration,
                                      groupValue: _selectedDuration,
                                      activeColor: theme.colorScheme.primary,
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(() => _selectedDuration = v);
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        duration,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$price FCFA',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isSelected ? theme.colorScheme.primary : const Color(0xFF334155),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 24),

                    // Payment method block selector (Écran 12)
                    Text(
                      'Mode de Paiement Mobile Money',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ).animate().fadeIn(delay: 250.ms),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildPaymentMethodBlock(
                          method: 'airtel_money',
                          label: 'Airtel Money',
                          logoColor: const Color(0xFFE11D48), // Airtel Red
                          borderColor: const Color(0xFFE11D48),
                        ),
                        const SizedBox(width: 16),
                        _buildPaymentMethodBlock(
                          method: 'mtn_mobile_money',
                          label: 'MTN Mobile Money',
                          logoColor: const Color(0xFFEAB308), // MTN Yellow
                          borderColor: const Color(0xFFCA8A04),
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 24),

                    // Payment Phone Number field (Écran 12)
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de téléphone de facturation',
                        prefixIcon: Icon(Icons.phone_iphone_rounded),
                        hintText: '+242 06 123 4567',
                      ),
                    ).animate().fadeIn(delay: 350.ms),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // Checkout paying footer button (Écran 12)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: FilledButton(
                onPressed: _submitting ? null : () => _subscribe(planIdToSend),
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text('Payer $currentPrice FCFA'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanTab(int idx, String label) {
    final isSelected = _activePlanTab == idx;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activePlanTab = idx;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isSelected ? theme.colorScheme.primary : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodBlock({
    required String method,
    required String label,
    required Color logoColor,
    required Color borderColor,
  }) {
    final isSelected = _method == method;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? logoColor.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? borderColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: logoColor.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              _method = method;
            });
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: logoColor.withOpacity(0.1),
                  child: Text(
                    label[0],
                    style: TextStyle(color: logoColor, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isSelected ? logoColor : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  method == 'airtel_money' ? 'Congo Airtel' : 'Congo MTN',
                  style: TextStyle(color: const Color(0xFF64748B), fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
