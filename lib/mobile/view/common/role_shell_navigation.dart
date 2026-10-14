import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sdealsmobile/data/models/utilisateur.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';

/// Bascule entre le shell client (`/homepage`) et le shell prestataire
/// (`/providermain`).
///
/// `go` remplace la pile au lieu d'empiler (`push`) : sinon chaque bascule
/// ajoutait une route (/homepage → /providermain → /homepage …), le retour
/// Android revenait sur l'autre shell, et dépiler `/providermain` laissait
/// `Home` figé sur son spinner de redirection.
///
/// Le changement de rôle reste porté par [AuthCubit.switchActiveRole] :
/// aucune capacité n'est contournée ici.
void goToClientShell(BuildContext context) {
  context.read<AuthCubit>().switchActiveRole('CLIENT');
  final router = GoRouter.of(context);
  if (_currentPath(router) == '/homepage') return;
  router.go('/homepage');
}

/// Voir [goToClientShell]. [switchRole] à `false` quand le rôle actif est
/// déjà PRESTATAIRE (redirection automatique de `Home`).
void goToProviderShell(
  BuildContext context, {
  Utilisateur? utilisateur,
  bool switchRole = true,
}) {
  if (switchRole) {
    context.read<AuthCubit>().switchActiveRole('PRESTATAIRE');
  }
  final router = GoRouter.of(context);
  if (_currentPath(router) == '/providermain') return;
  router.go('/providermain', extra: utilisateur);
}

String _currentPath(GoRouter router) {
  try {
    return router.location.split('?').first;
  } catch (_) {
    return '';
  }
}
