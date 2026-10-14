import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';

/// Mur « invité » prudent : tant que la session locale est en cours de
/// restauration, on ne sait pas si l'utilisateur est connecté. Afficher
/// « Connectez-vous » à ce moment-là serait une conclusion prématurée.
///
/// - restauration en cours → indicateur discret
/// - restaurée / absente / en erreur → [guestBuilder] (si la session
///   revient plus tard, le parent se reconstruit via l'état d'auth)
class SessionGuestGate extends StatelessWidget {
  const SessionGuestGate({super.key, required this.guestBuilder});

  final WidgetBuilder guestBuilder;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AuthCubit>();
    return ValueListenableBuilder<SessionRestoreStatus>(
      valueListenable: cubit.restoreStatus,
      builder: (context, status, _) {
        // Patience seulement si l'interface est ouverte avant la fin de la
        // restauration (splash dépassé). Sinon : mur invité habituel.
        if (status != SessionRestoreStatus.restoring ||
            !cubit.interfaceShownBeforeRestore) {
          return guestBuilder(context);
        }
        return Center(
          child: Semantics(
            label: 'Restauration de la session',
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }
}
