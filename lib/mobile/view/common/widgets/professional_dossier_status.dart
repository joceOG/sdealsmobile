import 'package:flutter/material.dart';

import 'package:sdealsmobile/design_system/design_system.dart';

/// Présentation d’un dossier professionnel à partir du statut backend.
/// `canOperate == false` seul ne signifie pas « incomplet ».
class ProfessionalDossierCopy {
  const ProfessionalDossierCopy({
    required this.title,
    required this.message,
    this.actionLabel,
  });

  final String title;
  final String message;
  final String? actionLabel;

  static ProfessionalDossierCopy? resolve({
    String? status,
    bool canOperate = false,
    String? motif,
    bool apiUnavailable = false,
  }) {
    if (apiUnavailable) return null;
    final raw = status?.trim().toLowerCase() ?? '';
    switch (raw) {
      case 'incomplete':
        return const ProfessionalDossierCopy(
          title: 'Inscription incomplète',
          message:
              'Des informations de votre dossier sont encore à compléter avant la suite du traitement.',
          actionLabel: 'Compléter mon profil',
        );
      case 'pending':
        return const ProfessionalDossierCopy(
          title: 'Dossier transmis',
          message:
              'Votre demande est enregistrée et en attente de traitement.',
        );
      case 'rejected':
        final reason = motif?.trim();
        return ProfessionalDossierCopy(
          title: 'Dossier refusé',
          message: (reason != null && reason.isNotEmpty)
              ? reason
              : 'Votre dossier n’a pas été accepté.',
          actionLabel: 'Revoir mon dossier',
        );
      case 'suspended':
        return const ProfessionalDossierCopy(
          title: 'Profil suspendu',
          message:
              'Ce profil est suspendu. Les actions métier restent limitées à ce que la plateforme autorise.',
        );
      case 'active':
      case 'valide':
      case 'validated':
        if (canOperate) {
          return const ProfessionalDossierCopy(
            title: 'Profil validé',
            message:
                'La validation est confirmée. Les actions disponibles dépendent de vos autorisations.',
          );
        }
        return const ProfessionalDossierCopy(
          title: 'Profil validé',
          message:
              'La validation est confirmée. L’exercice n’est pas encore autorisé pour ce profil.',
        );
      default:
        return null;
    }
  }
}

class ProviderCompletionItem {
  const ProviderCompletionItem({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;
}

/// Pièces réellement absentes du dossier. La localisation est obligatoire
/// pour sortir de « incomplete » ; la pièce et le selfie servent au badge.
List<ProviderCompletionItem> missingProviderCompletionItems(
  Map<String, dynamic>? doc,
) {
  if (doc == null) return const [];
  final items = <ProviderCompletionItem>[];
  final cni1 = doc['cni1']?.toString().trim() ?? '';
  final cni2 = doc['cni2']?.toString().trim() ?? '';
  final selfie = doc['selfie']?.toString().trim() ?? '';
  final maps = doc['localisationmaps'];
  final hasLocation = maps is Map &&
      maps['latitude'] != null &&
      maps['longitude'] != null;

  if (cni1.isEmpty || cni2.isEmpty) {
    items.add(const ProviderCompletionItem(
      title: 'Pièce d’identité',
      icon: Icons.badge_outlined,
    ));
  }
  if (selfie.isEmpty) {
    items.add(const ProviderCompletionItem(
      title: 'Selfie de vérification',
      icon: Icons.photo_camera_outlined,
    ));
  }
  if (!hasLocation) {
    items.add(const ProviderCompletionItem(
      title: 'Localisation',
      icon: Icons.place_outlined,
    ));
  }
  return items;
}

class IncompleteProviderDossier extends StatelessWidget {
  const IncompleteProviderDossier({
    super.key,
    required this.items,
    required this.onComplete,
  });

  final List<ProviderCompletionItem> items;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SDColors.primary50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SDColors.primary100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: SDColors.primary700,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VOTRE DOSSIER',
                      style: SDTypography.labelSmall.copyWith(
                        color: SDColors.primary700,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Inscription à compléter',
                      style: SDTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: SDColors.neutral900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Complétez les éléments demandés pour poursuivre votre inscription.',
            style: SDTypography.bodyMedium.copyWith(
              color: SDColors.neutral600,
              height: 1.4,
            ),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Éléments à compléter',
              style: SDTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: SDColors.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in items) ...[
              Material(
                color: SDColors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onComplete,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SDColors.neutral200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: SDColors.primary50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item.icon,
                            color: SDColors.primary600,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: SDTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: SDColors.neutral900,
                                ),
                              ),
                              Text(
                                'À compléter',
                                style: SDTypography.bodySmall.copyWith(
                                  color: SDColors.neutral500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: SDColors.neutral400,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
          const SizedBox(height: 8),
          SDButton(
            text: 'Compléter mon profil',
            fullWidth: true,
            onPressed: onComplete,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 16,
                color: SDColors.neutral500,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Certaines fonctionnalités restent indisponibles jusqu’à la validation de votre dossier.',
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfessionalDossierCard extends StatelessWidget {
  const ProfessionalDossierCard({
    super.key,
    required this.copy,
    this.onAction,
  });

  final ProfessionalDossierCopy copy;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.title,
            style: SDTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: SDColors.neutral900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            copy.message,
            style: SDTypography.bodyMedium.copyWith(
              color: SDColors.neutral600,
              height: 1.4,
            ),
          ),
          if (copy.actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            SDButton(
              text: copy.actionLabel!,
              fullWidth: true,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
