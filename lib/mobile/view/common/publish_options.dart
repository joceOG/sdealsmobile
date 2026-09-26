import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sdealsmobile/data/config/client_feature_flags.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/services/auth_professional_access.dart';
import 'package:sdealsmobile/data/services/protected_action_intent.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/common/auth_completion.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/auth_form_widgets.dart';
import 'package:sdealsmobile/mobile/view/freelance_registration/screens/freelance_welcome_screen.dart';
import 'package:sdealsmobile/mobile/view/seller_registration/screens/emarket_welcome_screen.dart';

/// Seul mécanisme d'ouverture des choix de publication.
/// Réutilisé depuis Profil. Ne pas en créer un second.
Future<void> showPublishOptions(BuildContext context) async {
  final auth = context.read<AuthCubit>().state;
  if (auth is! AuthAuthenticated) {
    showGuestAuthSheet(
      context,
      icon: Icons.add_rounded,
      title: 'Connectez-vous pour publier',
      description:
          'Créez un compte ou connectez-vous pour proposer un service, une mission ou une annonce.',
    );
    return;
  }

  final authState = context.read<AuthCubit>().state;
  if (authState is! AuthAuthenticated) return;

  final isProviderActive = authState.canOperatePrestataire;
  final isFreelanceActive = authState.canOperateFreelance;
  final isSellerActive = authState.canOperateVendeur;
  final hasProviderProfile = authState.hasPrestataireProfile;
  final hasFreelanceProfile = authState.hasFreelanceProfile;
  final hasSellerProfile = authState.hasVendeurProfile;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      decoration: const BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SDSpacing.radiusSheet),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            SDSpacing.screenMargin,
            10,
            SDSpacing.screenMargin,
            SDSpacing.screenMargin,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: SDColors.neutral300,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(height: SDSpacing.spaceRelated),
              Text(
                'Comment souhaitez-vous proposer vos services ?',
                style: SDTypography.screenTitle
                    .copyWith(color: SDColors.neutral900),
              ),
              const SizedBox(height: SDSpacing.spaceSmall),
              Text(
                'Choisissez votre activité pour commencer.',
                style: SDTypography.body.copyWith(color: SDColors.neutral700),
              ),
              const SizedBox(height: SDSpacing.spaceRelated),
              _PublishPartnerCard(
                icon: Icons.handyman_outlined,
                title: 'Métiers',
                benefit: 'Proposer des services près de chez vous',
                ctaLabel: 'Devenir professionnel',
                alreadyPartner: isProviderActive,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await openProviderPublishFlow(context);
                },
              ),
              _PublishPartnerCard(
                icon: Icons.laptop_mac_outlined,
                title: 'Freelance',
                benefit: 'Proposer des compétences à distance',
                ctaLabel: 'Devenir freelance',
                alreadyPartner: isFreelanceActive,
                onTap: () {
                  Navigator.pop(sheetContext);
                  openFreelancePublishFlow(
                    context,
                    already: hasFreelanceProfile,
                    canOperate: isFreelanceActive,
                  );
                },
              ),
              if (ClientFeatureFlags.emarketEnabled)
                _PublishPartnerCard(
                  icon: Icons.shopping_bag_outlined,
                  title: hasSellerProfile ? 'Espace Boutique' : 'Boutique',
                  benefit: isSellerActive
                      ? 'Gérer produits et commandes'
                      : 'Vendez vos produits partout en CI',
                  ctaLabel: isSellerActive
                      ? 'Gérer ma boutique'
                      : 'Ouvrir une boutique',
                  alreadyPartner: isSellerActive,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    openSellerPublishFlow(
                      context,
                      already: hasSellerProfile,
                      canOperate: isSellerActive,
                    );
                  },
                ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                style: TextButton.styleFrom(
                  minimumSize: const Size(
                    SDSpacing.minTouchTarget,
                    SDSpacing.minTouchTarget,
                  ),
                ),
                child: Text(
                  'Fermer',
                  style: SDTypography.labelMedium.copyWith(
                    color: SDColors.neutral500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> openProviderPublishFlow(BuildContext context) async {
  final ready = await ensureAuthenticatedForAction(
    context: context,
    type: ProtectedActionType.publish,
    originRoute: 'home',
    explanation: 'Connectez-vous pour publier',
  );
  if (!ready || !context.mounted) return;
  final authState = context.read<AuthCubit>().state;
  if (authState is! AuthAuthenticated) return;

  final userId = authState.utilisateur.idutilisateur;
  if (userId.isEmpty) {
    context.push('/serviceProviderRegistration');
    return;
  }

  if (authState.canOperatePrestataire) {
    context.read<AuthCubit>().switchActiveRole('PRESTATAIRE');
    context.push('/providermain', extra: authState.utilisateur);
    return;
  }

  if (authState.hasPrestataireProfile) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Votre profil Métiers n’est pas encore opérationnel. Finalisez ou attendez la validation.',
        ),
      ),
    );
    context.push('/serviceProviderWelcome', extra: <dynamic>[]);
    return;
  }

  final existingProvider = await ApiClient().getPrestataireByUserId(
    userId,
    authState.token,
  );

  if (!context.mounted) return;
  if (existingProvider != null) {
    context.read<AuthCubit>().switchActiveRole('PRESTATAIRE');
    context.push('/providermain', extra: authState.utilisateur);
    return;
  }

  context.push('/serviceProviderWelcome', extra: <dynamic>[]);
}

Future<void> openFreelancePublishFlow(
  BuildContext context, {
  required bool already,
  bool canOperate = false,
}) async {
  final ready = await ensureAuthenticatedForAction(
    context: context,
    type: ProtectedActionType.publish,
    originRoute: 'home',
    explanation: 'Connectez-vous pour publier',
  );
  if (!ready || !context.mounted) return;
  final authState = context.read<AuthCubit>().state;
  if (authState is! AuthAuthenticated) return;
  if (canOperate) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Espace freelance : gestion des missions à venir.',
        ),
      ),
    );
    return;
  }
  if (already) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Profil freelance en cours de validation ou à finaliser.',
        ),
      ),
    );
    return;
  }
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const FreelanceWelcomeScreen(),
    ),
  );
}

Future<void> openSellerPublishFlow(
  BuildContext context, {
  required bool already,
  bool canOperate = false,
}) async {
  final ready = await ensureAuthenticatedForAction(
    context: context,
    type: ProtectedActionType.publish,
    originRoute: 'home',
    explanation: 'Connectez-vous pour publier',
  );
  if (!ready || !context.mounted) return;
  final authState = context.read<AuthCubit>().state;
  if (authState is! AuthAuthenticated) return;
  if (canOperate) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Espace boutique : gestion catalogue à venir.',
        ),
      ),
    );
    return;
  }
  if (already) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Boutique en attente de validation ou indisponible.',
        ),
      ),
    );
    return;
  }
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const EmarketWelcomeScreen(),
    ),
  );
}

class _PublishPartnerCard extends StatelessWidget {
  const _PublishPartnerCard({
    required this.icon,
    required this.title,
    required this.benefit,
    required this.ctaLabel,
    required this.alreadyPartner,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String benefit;
  final String ctaLabel;
  final bool alreadyPartner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: SDColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
          side: const BorderSide(color: SDColors.neutral200),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(minHeight: SDSpacing.minTouchTarget),
            child: Padding(
              padding: const EdgeInsets.all(SDSpacing.spaceRelated),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: SDSpacing.iconStandard,
                    color: SDColors.primary600,
                  ),
                  const SizedBox(width: SDSpacing.spaceRelated),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: SDTypography.titleSmall.copyWith(
                                  color: SDColors.neutral900,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            if (alreadyPartner) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: SDColors.primary50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Actif',
                                  style: SDTypography.labelSmall.copyWith(
                                    color: SDColors.primary700,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          benefit,
                          style: SDTypography.bodySmall.copyWith(
                            color: SDColors.neutral600,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ctaLabel,
                          style: SDTypography.caption.copyWith(
                            color: SDColors.primary600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: SDColors.neutral400,
                    size: SDSpacing.iconStandard,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
