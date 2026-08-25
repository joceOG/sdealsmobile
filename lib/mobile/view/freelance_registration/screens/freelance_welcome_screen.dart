import 'package:flutter/material.dart';
import 'package:sdealsmobile/mobile/view/freelance_registration/screens/freelance_form_screen.dart';

import '../../../../design_system/design_system.dart';

/// STAB-13D — Welcome Freelance.
/// Pattern visuel/structurel identique au Welcome Prestataire (référence UX).
class FreelanceWelcomeScreen extends StatelessWidget {
  const FreelanceWelcomeScreen({super.key});

  static const _heroAsset = 'assets/welcome/freelance.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHero(context)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Développez votre activité freelance avec Soutrali Deals',
                          style: SDTypography.displaySmall.copyWith(
                            color: SDColors.neutral900,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            fontSize: 26,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Créez votre profil freelance et permettez aux clients de découvrir vos compétences, votre expérience et vos réalisations.',
                          style: SDTypography.bodyMedium.copyWith(
                            color: SDColors.neutral600,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 28),
                        const _BenefitRow(
                          icon: Icons.work_outline_rounded,
                          title: 'Trouvez de nouvelles missions',
                          description:
                              'Votre profil peut être découvert par des clients à la recherche de compétences comme les vôtres.',
                        ),
                        const SizedBox(height: 18),
                        const _BenefitRow(
                          icon: Icons.workspace_premium_outlined,
                          title: 'Mettez en avant votre expertise',
                          description:
                              'Ajoutez vos compétences, votre expérience, vos réalisations et vos domaines de spécialité.',
                        ),
                        const SizedBox(height: 18),
                        const _BenefitRow(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Gérez vos échanges simplement',
                          description:
                              'Retrouvez vos prises de contact, discussions et demandes depuis votre espace freelance.',
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Pour créer votre profil, préparez :',
                          style: SDTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: SDColors.neutral900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const _PrepItem(label: 'Votre métier ou spécialité'),
                        const _PrepItem(label: 'Vos compétences principales'),
                        const _PrepItem(label: 'Une photo de profil'),
                        const _PrepItem(
                            label: 'Vos réalisations ou portfolio'),
                        const _PrepItem(
                            label: 'Vos informations professionnelles'),
                        const _PrepItem(
                          label:
                              'Vos tarifs ou votre mode de facturation, si applicable',
                          isLast: true,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: SDColors.primary50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: SDColors.primary100),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: SDColors.primary700,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Vous pourrez compléter certaines informations plus tard.',
                                  style: SDTypography.bodySmall.copyWith(
                                    color: SDColors.primary800,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomCta(context),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 280 + top,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipPath(
            clipper: const _HeroWaveClipper(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  _heroAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) => Container(
                    color: SDColors.primary100,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.laptop_mac_rounded,
                      size: 64,
                      color: SDColors.primary600,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        SDColors.neutral900.withValues(alpha: 0.25),
                        Colors.transparent,
                        SDColors.neutral900.withValues(alpha: 0.05),
                      ],
                      stops: const [0, 0.45, 1],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: top + 8,
            right: 8,
            child: Material(
              color: SDColors.white.withValues(alpha: 0.92),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Fermer',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.close_rounded,
                  color: SDColors.neutral900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCta(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: SDColors.white,
        boxShadow: [
          BoxShadow(
            color: SDColors.neutral900.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SDButton(
        text: 'Créer mon profil freelance',
        fullWidth: true,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const FreelanceFormScreen(),
            ),
          );
        },
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: SDColors.primary50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: SDColors.primary700, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: SDTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: SDColors.neutral900,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: SDTypography.bodySmall.copyWith(
                  color: SDColors.neutral600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrepItem extends StatelessWidget {
  final String label;
  final bool isLast;

  const _PrepItem({required this.label, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: SDColors.primary600,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: SDColors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: SDTypography.bodyMedium.copyWith(
                    color: SDColors.neutral800,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            color: SDColors.neutral100,
          ),
      ],
    );
  }
}

/// Vague concave en bas du hero (même clip que Welcome Prestataire).
class _HeroWaveClipper extends CustomClipper<Path> {
  const _HeroWaveClipper();

  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - 36)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height + 8,
        size.width,
        size.height - 36,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
