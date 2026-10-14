import 'package:flutter/material.dart';
import 'package:sdealsmobile/design_system/design_system.dart';

enum ProfessionalActivity { metiers, freelance, emarket }

/// Choix d'activité avant création d'un profil professionnel.
class BecomeProfessionalScreen extends StatefulWidget {
  const BecomeProfessionalScreen({
    super.key,
    this.offerEmarket = true,
    required this.onContinue,
  });

  final bool offerEmarket;
  final Future<void> Function(ProfessionalActivity activity) onContinue;

  static const metierImage = 'assets/Devenir professionel/devenir metier.png';
  static const freelanceImage =
      'assets/Devenir professionel/devenir freelance.png';
  static const vendeurImage = 'assets/Devenir professionel/devenir vendeur.png';

  @override
  State<BecomeProfessionalScreen> createState() =>
      _BecomeProfessionalScreenState();
}

class _BecomeProfessionalScreenState extends State<BecomeProfessionalScreen> {
  ProfessionalActivity _choice = ProfessionalActivity.metiers;

  String get _profileLine {
    switch (_choice) {
      case ProfessionalActivity.metiers:
        return 'Vous allez créer un profil Prestataire.';
      case ProfessionalActivity.freelance:
        return 'Vous allez créer un profil Freelance.';
      case ProfessionalActivity.emarket:
        return 'Vous allez créer un profil Vendeur.';
    }
  }

  Future<void> _continue() => widget.onContinue(_choice);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: AppBar(
        backgroundColor: SDColors.primary50,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon:
              const Icon(Icons.arrow_back_rounded, color: SDColors.neutral900),
        ),
        title: Text(
          'SOUTRALI\nDEALS',
          textAlign: TextAlign.center,
          style: SDTypography.labelSmall.copyWith(
            color: SDColors.primary900,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: 0.6,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        children: [
          Text(
            'Devenir professionnel',
            style: SDTypography.displayMedium.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choisissez l’activité que vous souhaitez proposer.',
            style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral600),
          ),
          const SizedBox(height: 18),
          _ActivityCard(
            selected: _choice == ProfessionalActivity.metiers,
            eyebrow: 'MÉTIERS',
            title: 'Proposer mes\nservices',
            subtitle: 'Travaux, dépannage,\nentretien...',
            image: BecomeProfessionalScreen.metierImage,
            onTap: () => setState(() => _choice = ProfessionalActivity.metiers),
          ),
          const SizedBox(height: 12),
          _ActivityCard(
            selected: _choice == ProfessionalActivity.freelance,
            eyebrow: 'FREELANCE',
            title: 'Partager mes\ncompétences',
            subtitle: 'Design, développement,\nrédaction...',
            image: BecomeProfessionalScreen.freelanceImage,
            onTap: () =>
                setState(() => _choice = ProfessionalActivity.freelance),
          ),
          if (widget.offerEmarket) ...[
            const SizedBox(height: 12),
            _ActivityCard(
              selected: _choice == ProfessionalActivity.emarket,
              eyebrow: 'E-MARCHÉ',
              title: 'Vendre mes\nproduits',
              subtitle: 'Créez votre boutique et\nprésentez vos articles.',
              image: BecomeProfessionalScreen.vendeurImage,
              onTap: () =>
                  setState(() => _choice = ProfessionalActivity.emarket),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.layers_outlined,
                    size: 18,
                    color: SDColors.neutral500,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Un même compte peut avoir plusieurs profils professionnels.',
                      style: SDTypography.bodySmall
                          .copyWith(color: SDColors.neutral600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _profileLine,
                textAlign: TextAlign.center,
                style: SDTypography.bodySmall.copyWith(
                  color: SDColors.neutral500,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: SDColors.primary600,
                    foregroundColor: SDColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    textStyle: SDTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Continuer  →'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.selected,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.onTap,
  });

  final bool selected;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? SDColors.primary50 : SDColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? SDColors.primary600 : SDColors.neutral200,
          width: selected ? 1.6 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 148,
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow,
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.neutral500,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: SDTypography.titleMedium.copyWith(
                          color: SDColors.neutral900,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        subtitle,
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.neutral600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 132,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      image,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, __, ___) => ColoredBox(
                        color: SDColors.primary100,
                        child: Icon(
                          Icons.image_outlined,
                          color: SDColors.primary700,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _ChoiceMark(selected: selected),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceMark extends StatelessWidget {
  const _ChoiceMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? SDColors.primary600 : SDColors.white,
        border: Border.all(
          color: selected ? SDColors.primary600 : SDColors.neutral300,
          width: 1.6,
        ),
      ),
      child: selected
          ? const Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SDColors.white,
                ),
                child: SizedBox(width: 8, height: 8),
              ),
            )
          : null,
    );
  }
}
