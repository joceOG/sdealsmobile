import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/services/authCubit.dart';
import '../../common/widgets/unauthenticated_banner.dart';
import '../../../../design_system/design_system.dart';

/// SoutraPay n'est pas encore branché au backend.
/// Affiche un écran honnête plutôt qu'un wallet mock (recharge/transfert fictifs).
class WalletPageScreenM extends StatelessWidget {
  const WalletPageScreenM({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const UnauthenticatedBanner(
        title: 'Connexion requise',
        description:
            'Connectez-vous pour accéder à SoutraPay lorsque le service sera disponible.',
        appBarTitle: 'SoutraPay',
      );
    }

    return Scaffold(
      backgroundColor: SDColors.neutral50,
      appBar: SDWhiteAppBar.appBar(
        title: 'SoutraPay',
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  size: 72, color: SDColors.primary600),
              const SizedBox(height: 24),
              Text(
                'SoutraPay arrive bientôt',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Le portefeuille, les recharges et les transferts '
                'seront disponibles dès que le backend paiement sera branché. '
                'Aucune opération fictive n\'est proposée.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SDColors.neutral600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
