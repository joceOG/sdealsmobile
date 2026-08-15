import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../design_system/design_system.dart';

/// Aide & Support — email réel + FAQ (contenu vitrine).
/// Pas de tickets / chat / WhatsApp support / « mes demandes » (inexistants).
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  static const double _hPad = 20;
  static const String _supportEmail = 'contact@soutralideals.com';

  /// FAQ marketing (soutrali-deals) — questions utiles à l’app, pas le reste.
  static const _faqs = <({String q, String a})>[
    (
      q: 'C’est quoi exactement Soutrali Deals ?',
      a:
          'Soutrali Deals est un écosystème digital ivoirien qui connecte talents locaux (freelances, artisans) et commerçants avec des clients. Métiers, Freelance et Vente & Achat au même endroit.',
    ),
    (
      q: 'Comment devenir prestataire ?',
      a:
          'Créez votre compte, complétez votre profil professionnel, puis activez le mode prestataire depuis Profil. Notre équipe peut valider votre profil ensuite.',
    ),
    (
      q: 'L’inscription est-elle payante ?',
      a:
          'L’inscription de base est gratuite. Des options premium peuvent exister pour plus de visibilité, mais vous pouvez commencer sans rien payer.',
    ),
    (
      q: 'Comment fonctionnent les paiements ?',
      a:
          'Soutrali Deals s’appuie sur les moyens locaux (Mobile Money, cartes) via SoutraPay. Consultez Portefeuille et Tarification dans Profil pour le détail.',
    ),
    (
      q: 'Puis-je vendre des produits ?',
      a:
          'Oui. L’univers Vente & Achat permet de créer une vitrine et de proposer vos produits à la communauté.',
    ),
    (
      q: 'Comment suivre une commande ?',
      a:
          'Profil → Mes commandes. Vous y voyez le statut de chaque demande.',
    ),
    (
      q: 'Comment gérer mes notifications ?',
      a:
          'Profil → Paramètres → Préférences de notifications, ou Profil → Notifications.',
    ),
    (
      q: 'J’ai un problème technique, qui contacter ?',
      a:
          'Écrivez-nous à contact@soutralideals.com. Décrivez le problème et, si possible, le modèle de téléphone et la version de l’app (À propos).',
    ),
  ];

  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<({String q, String a})> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _faqs;
    return _faqs
        .where((f) => f.q.toLowerCase().contains(q) || f.a.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _openMail({String? subject}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': subject ?? 'Aide Soutrali Deals',
      },
    );
    try {
      final ok = await launchUrl(uri);
      if (!ok && mounted) {
        await Clipboard.setData(const ClipboardData(text: _supportEmail));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email copié dans le presse-papiers')),
        );
      }
    } catch (_) {
      await Clipboard.setData(const ClipboardData(text: _supportEmail));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email copié dans le presse-papiers')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Scaffold(
      backgroundColor: SDColors.neutral50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, _hPad, 0),
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, color: SDColors.neutral900),
                tooltip: 'Retour',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(_hPad, 4, _hPad, 8),
              child: Text(
                'Aide & Support',
                style: SDTypography.displayMedium.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 12),
              child: Text(
                'Une question ? Consultez la FAQ ou écrivez-nous.',
                style: SDTypography.bodyMedium.copyWith(
                  color: SDColors.neutral600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _hPad),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Rechercher une question',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: SDColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: SDColors.neutral200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: SDColors.neutral200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: SDColors.primary600),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 28),
                children: [
                  _card(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _actionTile(
                          icon: Icons.mail_outline,
                          title: 'Nous contacter',
                          subtitle: 'Email · $_supportEmail',
                          onTap: () => _openMail(),
                        ),
                        const Divider(height: 1, color: SDColors.neutral200),
                        _actionTile(
                          icon: Icons.copy_outlined,
                          title: 'Copier l’email',
                          subtitle: 'Utile si votre messagerie ne s’ouvre pas',
                          onTap: () async {
                            await Clipboard.setData(
                              const ClipboardData(text: _supportEmail),
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Email copié'),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, color: SDColors.neutral200),
                        _actionTile(
                          icon: Icons.report_problem_outlined,
                          title: 'Signaler un problème',
                          subtitle: 'Ouvre un email prérempli',
                          onTap: () => _openMail(
                            subject: 'Signalement — Soutrali Deals app',
                          ),
                          showChevron: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Questions fréquentes',
                    style: SDTypography.titleMedium.copyWith(
                      color: SDColors.neutral900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Aucune question ne correspond. Contactez-nous par email.',
                        style: SDTypography.bodyMedium.copyWith(
                          color: SDColors.neutral500,
                        ),
                      ),
                    )
                  else
                    _card(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < items.length; i++) ...[
                            if (i > 0)
                              const Divider(
                                height: 1,
                                color: SDColors.neutral200,
                              ),
                            _FaqTile(
                              question: items[i].q,
                              answer: items[i].a,
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: SDColors.primary600.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: SDColors.primary700,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vous ne trouvez pas la réponse ?',
                                style: SDTypography.bodyLarge.copyWith(
                                  color: SDColors.neutral900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Écrivez à notre équipe support.',
                                style: SDTypography.bodyMedium.copyWith(
                                  color: SDColors.neutral600,
                                ),
                              ),
                              TextButton(
                                onPressed: () => _openMail(),
                                style: TextButton.styleFrom(
                                  foregroundColor: SDColors.primary700,
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text('Nous contacter →'),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _card({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: child,
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showChevron = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: SDColors.primary600, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SDTypography.bodyLarge.copyWith(
                      color: SDColors.neutral900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: SDTypography.bodySmall.copyWith(
                      color: SDColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              const Icon(
                Icons.chevron_right,
                color: SDColors.neutral400,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        iconColor: SDColors.neutral500,
        collapsedIconColor: SDColors.neutral500,
        title: Text(
          question,
          style: SDTypography.bodyLarge.copyWith(
            color: SDColors.neutral900,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: SDTypography.bodyMedium.copyWith(
                color: SDColors.neutral600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
