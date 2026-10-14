import 'package:flutter/material.dart';

import 'package:sdealsmobile/data/models/professional_capabilities.dart';
import 'package:sdealsmobile/design_system/design_system.dart';

/// Textes et style du bandeau statut après création prestataire (données API).
class ProviderCreationStatusPresentation {
  const ProviderCreationStatusPresentation({
    this.badgeLabel,
    required this.explanation,
    this.badgeBackground,
    this.badgeForeground,
    this.badgeIcon,
  });

  final String? badgeLabel;
  final String explanation;
  final Color? badgeBackground;
  final Color? badgeForeground;
  final IconData? badgeIcon;

  static ProviderCreationStatusPresentation resolve({
    ProfessionalProfileSnapshot? snapshot,
    List<dynamic> inconsistencies = const [],
    bool rolesRefreshFailed = false,
  }) {
    if (rolesRefreshFailed &&
        (snapshot == null || !snapshot.exists)) {
      return const ProviderCreationStatusPresentation(
        explanation:
            'Votre profil est enregistré. Le statut détaillé sera visible '
            'dès l’actualisation de votre compte dans l’onglet Profil.',
      );
    }

    if (snapshot != null &&
        snapshot.exists &&
        snapshot.canOperate &&
        snapshot.status?.toLowerCase() == 'active') {
      return const ProviderCreationStatusPresentation(
        badgeLabel: 'Profil opérationnel',
        badgeBackground: SDColors.primary50,
        badgeForeground: SDColors.primary800,
        badgeIcon: Icons.verified_outlined,
        explanation:
            'Votre profil Métiers est actif. Les actions disponibles '
            'dépendent de vos autorisations sur la plateforme.',
      );
    }

    final status = snapshot?.status?.toLowerCase();
    switch (status) {
      case 'pending':
        return const ProviderCreationStatusPresentation(
          badgeLabel: 'En attente de validation',
          badgeBackground: SDColors.warning100,
          badgeForeground: SDColors.warning700,
          badgeIcon: Icons.schedule_rounded,
          explanation:
              'Votre profil doit encore être validé avant de pouvoir '
              'exercer sur Soutrali Deals.',
        );
      case 'rejected':
        return const ProviderCreationStatusPresentation(
          badgeLabel: 'Profil refusé',
          badgeBackground: SDColors.error50,
          badgeForeground: SDColors.error600,
          badgeIcon: Icons.error_outline_rounded,
          explanation:
              'Votre dossier n’a pas été accepté. Consultez l’onglet Profil '
              'pour les prochaines étapes.',
        );
      case 'suspended':
        return const ProviderCreationStatusPresentation(
          badgeLabel: 'Profil suspendu',
          badgeBackground: SDColors.error50,
          badgeForeground: SDColors.error600,
          badgeIcon: Icons.pause_circle_outline_rounded,
          explanation:
              'Votre profil Métiers est temporairement indisponible. '
              'Consultez l’onglet Profil pour plus d’informations.',
        );
      case 'incomplete':
        return ProviderCreationStatusPresentation(
          badgeLabel: 'Profil incomplet',
          badgeBackground: SDColors.warning100,
          badgeForeground: SDColors.warning700,
          badgeIcon: Icons.info_outline_rounded,
          explanation: _incompleteExplanation(inconsistencies),
        );
    }

    if (snapshot != null && snapshot.exists) {
      return const ProviderCreationStatusPresentation(
        explanation:
            'Votre profil Métiers est enregistré. Consultez l’onglet Profil '
            'pour suivre son statut et les actions possibles.',
      );
    }

    return const ProviderCreationStatusPresentation(
      explanation:
          'Votre demande d’inscription a bien été prise en compte. '
          'Ouvrez l’onglet Profil pour voir l’état de votre espace Métiers.',
    );
  }

  static String _incompleteExplanation(List<dynamic> inconsistencies) {
    final labels = inconsistencies
        .map((e) {
          if (e is String) return e.trim();
          if (e is Map && e['message'] != null) {
            return e['message'].toString().trim();
          }
          if (e is Map && e['field'] != null) {
            return e['field'].toString().trim();
          }
          return e.toString().trim();
        })
        .where((s) => s.isNotEmpty)
        .toList();
    if (labels.isEmpty) {
      return 'Certaines informations sont encore à compléter. '
          'Consultez l’onglet Profil pour finaliser votre dossier.';
    }
    return 'Informations à compléter : ${labels.join(', ')}.';
  }
}
