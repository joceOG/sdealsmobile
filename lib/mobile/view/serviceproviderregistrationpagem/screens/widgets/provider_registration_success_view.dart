import 'package:flutter/material.dart';

import 'package:sdealsmobile/design_system/design_system.dart';

import 'provider_creation_status_presentation.dart';

/// Écran de confirmation après création prestataire (API 200/201 uniquement).
class ProviderRegistrationSuccessView extends StatelessWidget {
  const ProviderRegistrationSuccessView({
    super.key,
    required this.statusPresentation,
    required this.serviceName,
    required this.zonesLabel,
    required this.onBackToProfile,
    this.refreshingStatus = false,
    this.pageTitle = 'Profil prestataire',
    this.headline = 'Votre profil a été créé',
    this.subhead = 'Vos informations ont bien été enregistrées.',
    this.activityTitle = 'Votre activité',
    this.primaryLabel = 'Service',
    this.secondaryLabel = 'Zones d’intervention',
    this.footerNote =
        'Retrouvez le statut de votre profil dans l’onglet Profil, section Espaces professionnels.',
  });

  final ProviderCreationStatusPresentation statusPresentation;
  final String serviceName;
  final String zonesLabel;
  final VoidCallback onBackToProfile;
  final bool refreshingStatus;
  final String pageTitle;
  final String headline;
  final String subhead;
  final String activityTitle;
  final String primaryLabel;
  final String secondaryLabel;
  final String footerNote;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: SDWhiteAppBar.appBar(
        centerTitle: true,
        title: pageTitle,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _SuccessIcon(),
                    const SizedBox(height: 24),
                    Text(
                      headline,
                      textAlign: TextAlign.center,
                      style: SDTypography.displaySmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: SDColors.neutral900,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subhead,
                      textAlign: TextAlign.center,
                      style: SDTypography.bodyLarge.copyWith(
                        color: SDColors.neutral600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (refreshingStatus)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: SDColors.primary600,
                          ),
                        ),
                      )
                    else
                      _StatusBlock(presentation: statusPresentation),
                    const SizedBox(height: 24),
                    _ActivityRecapCard(
                      title: activityTitle,
                      primaryLabel: primaryLabel,
                      secondaryLabel: secondaryLabel,
                      serviceName: serviceName,
                      zonesLabel: zonesLabel,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      footerNote,
                      textAlign: TextAlign.center,
                      style: SDTypography.bodySmall.copyWith(
                        color: SDColors.neutral500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12 + bottom),
              child: SDButton(
                text: 'Retour à mon profil',
                fullWidth: true,
                onPressed: onBackToProfile,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: SDColors.primary50,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.assignment_ind_outlined,
              size: 48,
              color: SDColors.primary700,
            ),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: SDColors.primary600,
                shape: BoxShape.circle,
                border: Border.all(color: SDColors.white, width: 2),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: SDColors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBlock extends StatelessWidget {
  const _StatusBlock({required this.presentation});

  final ProviderCreationStatusPresentation presentation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (presentation.badgeLabel != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: presentation.badgeBackground ?? SDColors.neutral100,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (presentation.badgeIcon != null) ...[
                  Icon(
                    presentation.badgeIcon,
                    size: 18,
                    color: presentation.badgeForeground ?? SDColors.neutral700,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  presentation.badgeLabel!,
                  style: SDTypography.labelLarge.copyWith(
                    color: presentation.badgeForeground ?? SDColors.neutral800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          presentation.explanation,
          textAlign: TextAlign.center,
          style: SDTypography.bodyMedium.copyWith(
            color: SDColors.neutral600,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _ActivityRecapCard extends StatelessWidget {
  const _ActivityRecapCard({
    required this.title,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.serviceName,
    required this.zonesLabel,
  });

  final String title;
  final String primaryLabel;
  final String secondaryLabel;
  final String serviceName;
  final String zonesLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: SDTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: SDColors.neutral900,
            ),
          ),
          const SizedBox(height: 12),
          _RecapField(label: primaryLabel, value: serviceName),
          const Divider(height: 1, color: SDColors.neutral100),
          _RecapField(label: secondaryLabel, value: zonesLabel),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RecapField extends StatelessWidget {
  const _RecapField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: SDTypography.labelSmall.copyWith(
              color: SDColors.neutral500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: SDTypography.bodyMedium.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
