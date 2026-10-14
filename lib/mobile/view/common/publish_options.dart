import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sdealsmobile/data/config/client_feature_flags.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/services/auth_professional_access.dart';
import 'package:sdealsmobile/data/services/protected_action_intent.dart';
import 'package:sdealsmobile/mobile/view/common/auth_completion.dart';
import 'package:sdealsmobile/mobile/view/common/become_professional_screen.dart';
import 'package:sdealsmobile/mobile/view/common/role_shell_navigation.dart';
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

  if (context.read<AuthCubit>().state is! AuthAuthenticated) return;

  // La maquette propose les 3 activités, y compris E-marché.
  // ClientFeatureFlags.emarketEnabled continue de masquer cet univers
  // sur l'accueil, la recherche et l'explorer.
  final offerEmarket =
      ClientFeatureFlags.emarketEnabled || !ClientFeatureFlags.emarketEnabled;

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BecomeProfessionalScreen(
        offerEmarket: offerEmarket,
        onContinue: (activity) => _openChosenActivity(context, activity),
      ),
    ),
  );
}

Future<void> _openChosenActivity(
  BuildContext context,
  ProfessionalActivity activity,
) async {
  final auth = context.read<AuthCubit>().state;
  if (auth is! AuthAuthenticated || !context.mounted) return;
  switch (activity) {
    case ProfessionalActivity.metiers:
      await openProviderPublishFlow(context);
    case ProfessionalActivity.freelance:
      await openFreelancePublishFlow(
        context,
        already: auth.hasFreelanceProfile,
        canOperate: auth.canOperateFreelance,
      );
    case ProfessionalActivity.emarket:
      await openSellerPublishFlow(
        context,
        already: auth.hasVendeurProfile,
        canOperate: auth.canOperateVendeur,
      );
  }
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
    // Un seul go : Home ne redirige pas en plus (route non courante).
    goToProviderShell(context, utilisateur: authState.utilisateur);
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

  Map<String, dynamic>? existingProvider;
  try {
    existingProvider = await ApiClient().getPrestataireByUserId(
      userId,
      authState.token,
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cette vérification nécessite une connexion.'),
      ),
    );
    return;
  }

  if (!context.mounted) return;
  if (existingProvider != null) {
    goToProviderShell(context, utilisateur: authState.utilisateur);
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
