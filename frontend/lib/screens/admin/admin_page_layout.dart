import 'dart:async';
import 'package:flutter/material.dart';

// ─── Design tokens partagés ──────────────────────────────────────────────────
const kBg = Color(0xFFF8FAFC);
const kSurface = Colors.white;
const kBorder = Color(0xFFE8EDF5);
const kTextPrimary = Color(0xFF0F172A);
const kTextSecondary = Color(0xFF64748B);
const kTextMuted = Color(0xFF94A3B8);
const kBlue = Color(0xFF2563EB);

// ─── AdminPageLayout ─────────────────────────────────────────────────────────
/// Layout de base pour toutes les pages admin.
/// Gère : TopBar, SearchBar avec debounce 300ms, conteneur centré 1100px.

class AdminPageLayout extends StatefulWidget {
  final String title;
  final String subtitle;
  final String searchHint;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback onBack;
  final void Function(String query) onSearch;
  final Widget child;
  final List<Widget>? extraActions;

  const AdminPageLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.searchHint,
    required this.actionLabel,
    required this.onAction,
    required this.onBack,
    required this.onSearch,
    required this.child,
    this.extraActions,
  });

  @override
  State<AdminPageLayout> createState() => _AdminPageLayoutState();
}

class _AdminPageLayoutState extends State<AdminPageLayout> {
  Timer? _debounce;

  void _onSearchChanged(String value) {
    // ── Debounce 300ms (Point de vigilance 1) ────────────────────────────────
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // ── TopBar ─────────────────────────────────────────────────────────
          Container(
            color: kSurface,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: Row(
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      onPressed: widget.onBack,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: kTextPrimary,
                            ),
                          ),
                          Text(
                            widget.subtitle,
                            style: const TextStyle(
                                fontSize: 11, color: kTextSecondary),
                          ),
                        ],
                      ),
                    ),

                    // SearchBar — uniquement sur écrans larges (debounced)
                    if (isWide) ...[
                      Container(
                        width: 220,
                        height: 38,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          onChanged: _onSearchChanged,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: widget.searchHint,
                            hintStyle:
                                const TextStyle(color: kTextMuted, fontSize: 13),
                            prefixIcon: const Icon(Icons.search_rounded,
                                size: 18, color: kTextMuted),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],

                    // Extra actions slot
                    if (widget.extraActions != null) ...widget.extraActions!,

                    // Primary action button
                    FilledButton.icon(
                      onPressed: widget.onAction,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(isWide ? widget.actionLabel : 'Ajouter'),
                      style: FilledButton.styleFrom(
                        backgroundColor: kBlue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: kBorder),

          // ── Content ────────────────────────────────────────────────────────
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Calcule le nombre de colonnes selon la largeur d'écran.
int adminGridColumns(double width) {
  if (width > 1000) return 3;
  if (width > 640) return 2;
  return 1;
}

/// Calcule le childAspectRatio de façon dynamique (Point de vigilance 2).
/// Évite l'écrasement du contenu sur les cartes au redimensionnement Web.
double adminCardAspectRatio(double width, {int columns = -1}) {
  final cols = columns > 0 ? columns : adminGridColumns(width);
  // Largeur estimée d'une carte = (width - marges) / cols
  final cardWidth = (width.clamp(320.0, 1100.0) - 48 - (cols - 1) * 14) / cols;
  // Hauteur cible = 210px fixe → ratio = width / height
  return cardWidth / 210;
}

// ─── Badge helpers ────────────────────────────────────────────────────────────

Widget adminBadge(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.bold, color: color),
    ),
  );
}

Widget adminTypeBadge(String type) {
  final isPdf = type == 'pdf';
  return adminBadge(
    isPdf ? 'PDF' : 'VIDÉO',
    isPdf ? const Color(0xFFEF4444) : const Color(0xFF7C3AED),
  );
}

Widget adminPremiumBadge() =>
    adminBadge('Premium', const Color(0xFFD97706));

// ─── PopupMenu action tile ────────────────────────────────────────────────────

PopupMenuItem<String> adminMenuItem(
    String value, String label, IconData icon, Color color) {
  return PopupMenuItem<String>(
    value: value,
    child: Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, color: color)),
      ],
    ),
  );
}
