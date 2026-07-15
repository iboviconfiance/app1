import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';

class ExerciseQuizScreen extends StatefulWidget {
  final String id;
  const ExerciseQuizScreen({super.key, required this.id});

  @override
  State<ExerciseQuizScreen> createState() => _ExerciseQuizScreenState();
}

class _ExerciseQuizScreenState extends State<ExerciseQuizScreen> {
  Map<String, dynamic>? _exercise;
  final Map<String, int> _answers = {};
  Map<String, dynamic>? _result;
  bool _loading = true;

  // Quiz progression state
  int _currentIndex = 0;
  int _secondsElapsed = 0;
  Timer? _timer;
  bool _showCorrections = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await context.read<AuthProvider>().api.get('/exercises/${widget.id}');
      setState(() {
        _exercise = res['data'];
        _loading = false;
        _startTimer();
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsElapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final mins = (totalSeconds % 3600) ~/ 60;
    final secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    _timer?.cancel();
    setState(() => _loading = true);
    try {
      final res = await context.read<AuthProvider>().api.post(
        '/exercises/${widget.id}/submit',
        {'answers': _answers},
      );
      setState(() {
        _result = res['data'];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _restartQuiz() {
    setState(() {
      _result = null;
      _answers.clear();
      _currentIndex = 0;
      _showCorrections = false;
      _loading = true;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_result != null) {
      return _buildResultScreen(theme);
    }

    final questions = (_exercise!['questions'] as List?) ?? [];
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_exercise!['title'] ?? '')),
        body: const Center(child: Text('Aucune question dans cet exercice.')),
      );
    }

    final currentQuestion = questions[_currentIndex];
    final qId = currentQuestion['id'] as String;
    final options = currentQuestion['options'] as List? ?? [];
    final selectedOptionIndex = _answers[qId];

    final optionLetters = ['A', 'B', 'C', 'D'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_exercise!['title'] ?? 'Entraînement'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 20, color: const Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  _formatTime(_secondsElapsed),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Question progress bar indicator
            LinearProgressIndicator(
              value: (_currentIndex + 1) / questions.length,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              minHeight: 5,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Question index label
                    Text(
                      'Question ${_currentIndex + 1} sur ${questions.length}',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Question text Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: const Color(0xFFF1F5F9)!, width: 1.5),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          currentQuestion['questionText'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
                    const SizedBox(height: 24),
                    // Option items
                    ...List.generate(options.length, (idx) {
                      final isSelected = selectedOptionIndex == idx;
                      final letter = idx < optionLetters.length ? optionLetters[idx] : '?';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isSelected ? theme.colorScheme.primary.withOpacity(0.06) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? theme.colorScheme.primary : const Color(0xFFE2E8F0) ?? const Color(0xFFE2E8F0),
                              width: isSelected ? 2.0 : 1.5,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _answers[qId] = idx;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Row(
                                children: [
                                  // Letter bubble badge
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: isSelected ? theme.colorScheme.primary : const Color(0xFFF8FAFC),
                                    child: Text(
                                      letter,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : const Color(0xFF475569),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      options[idx].toString(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? theme.colorScheme.primary : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  // Selected trailing icon check
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 22,
                                    )
                                  else
                                    Icon(
                                      Icons.circle_outlined,
                                      color: const Color(0xFFCBD5E1),
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: (idx * 60).ms);
                    }),
                  ],
                ),
              ),
            ),
            // Bottom navigation row
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  if (_currentIndex > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentIndex--;
                          });
                        },
                        child: const Text('Précédent'),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: selectedOptionIndex == null
                          ? null
                          : () {
                              if (_currentIndex < questions.length - 1) {
                                setState(() {
                                  _currentIndex++;
                                });
                              } else {
                                _submit();
                              }
                            },
                      child: Text(
                        _currentIndex < questions.length - 1 ? 'Question suivante' : 'Soumettre le Quiz',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- STEP 10: Trophy result and congratulations view ---
  Widget _buildResultScreen(ThemeData theme) {
    final score = _result!['score'] ?? 0;
    final total = _result!['totalPoints'] ?? 0;
    final percentage = _result!['percentage'] ?? 0;
    final isPass = percentage >= 60;
    final corrections = _result!['corrections'] as List? ?? [];

    final incorrectCount = total - score;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Résultats'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Falling Confettis Animation Row using only native flutter_animate
          if (isPass)
            for (int i = 0; i < 20; i++)
              Positioned(
                left: (i * 24.0) % 350 + 16,
                top: -30,
                child: Icon(
                  Icons.star_rounded,
                  color: [Colors.amber, Colors.amberAccent, Colors.yellow, Colors.orangeAccent][i % 4],
                  size: 10 + (i % 3) * 6.0,
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .slideY(
                      begin: 0,
                      end: 700,
                      duration: Duration(milliseconds: 1600 + i * 180),
                      curve: Curves.easeIn,
                    )
                    .rotate(
                      begin: 0,
                      end: 2,
                      duration: Duration(milliseconds: 1600 + i * 180),
                    ),
              ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        // Golden Trophy cup logo
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.emoji_events_rounded,
                              size: 90,
                              color: isPass ? Colors.amber[700] : const Color(0xFF94A3B8),
                            ),
                          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          isPass ? 'Félicitations !' : 'Continuez vos efforts !',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isPass
                              ? 'Vous avez brillamment complété l\'exercice.'
                              : 'Entraînez-vous encore pour améliorer votre note.',
                          style: TextStyle(color: const Color(0xFF64748B), fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Score metrics box
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildResultMetric(
                                    context,
                                    label: 'Note',
                                    value: '$score/$total',
                                    color: isPass ? Colors.green[700]! : Colors.red[700]!,
                                  ),
                                  _buildResultMetric(
                                    context,
                                    label: 'Précision',
                                    value: '$percentage%',
                                    color: isPass ? Colors.green[700]! : Colors.red[700]!,
                                  ),
                                ],
                              ),
                              const Divider(height: 32, thickness: 1, color: Color(0xFFE2E8F0)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildResultMetric(
                                    context,
                                    label: 'Bonnes rép.',
                                    value: '$score',
                                    color: Colors.green[600]!,
                                  ),
                                  _buildResultMetric(
                                    context,
                                    label: 'Erreurs',
                                    value: '$incorrectCount',
                                    color: Colors.red[600]!,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0),
                        const SizedBox(height: 24),

                        // Expandable / Toggleable Corrections Section (Écran 10)
                        if (corrections.isNotEmpty) ...[
                          Card(
                            elevation: 0,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: const Color(0xFFF1F5F9)!, width: 1.5),
                            ),
                            child: Theme(
                              data: theme.copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                leading: Icon(Icons.playlist_add_check_rounded, color: theme.colorScheme.primary),
                                title: const Text(
                                  'Voir les corrections',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                ),
                                childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                onExpansionChanged: (expanded) {
                                  setState(() {
                                    _showCorrections = expanded;
                                  });
                                },
                                children: corrections.map((corr) {
                                  final isCorrect = corr['isCorrect'] == true;
                                  return Card(
                                    elevation: 0,
                                    color: isCorrect ? Colors.green[50] : Colors.red[50],
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                                color: isCorrect ? Colors.green[700] : Colors.red[700],
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  corr['questionText'] ?? '',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (corr['explanation'] != null && corr['explanation'].toString().isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 28),
                                              child: Text(
                                                'Explication : ${corr['explanation']}',
                                                style: TextStyle(
                                                  color: isCorrect ? Colors.green[800] : Colors.red[800],
                                                  fontSize: 12.5,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ).animate().fadeIn(delay: 300.ms),
                        ],
                      ],
                    ),
                  ),
                ),
                // Footer buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton(
                        onPressed: _restartQuiz,
                        child: const Text('Recommencer le Quiz'),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => context.go('/dashboard'),
                        child: const Text('Retour à l\'accueil'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultMetric(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
