import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../design_system/design_system.dart';
import '../../alertpagem/alertpageblocm/alertPageBlocM.dart';
import '../../alertpagem/alertpageblocm/alertPageEventM.dart';
import '../../alertpagem/screens/alertSettingsScreenM.dart';
import '../../preferencespagem/preferencespageblocm/preferencesPageBlocM.dart';
import '../../preferencespagem/screens/preferencesPageScreenM.dart';
import '../../securitypagem/screens/securityPageScreenM.dart';
import '../../securitypagem/securitypageblocm/securityPageBlocM.dart';
import 'language_settings_screen.dart';
import 'profile_menu_item.dart';

/// Hub Paramètres — regroupe langue, préférences, sécu, notifs prefs.
class ProfileSettingsHubScreen extends StatelessWidget {
  const ProfileSettingsHubScreen({super.key});

  static const double _hPad = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, _hPad, 0),
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, color: SDColors.neutral900),
                tooltip: 'Retour',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(_hPad, 4, _hPad, 8),
              child: Text(
                'Paramètres',
                style: SDTypography.displayMedium.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 12),
              child: Text(
                'Langue, sécurité et préférences de l’app',
                style: SDTypography.bodyMedium.copyWith(
                  color: SDColors.neutral600,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  MenuItem(
                    icon: Icons.language_outlined,
                    title: 'Langue & Devise',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (_) => PreferencesPageBlocM(),
                            child: const LanguageSettingsScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                  MenuItem(
                    icon: Icons.tune_outlined,
                    title: 'Préférences',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (_) => PreferencesPageBlocM(),
                            child: const PreferencesPageScreenM(),
                          ),
                        ),
                      );
                    },
                  ),
                  MenuItem(
                    icon: Icons.shield_outlined,
                    title: 'Sécurité du compte',
                    onTap: () {
                      final auth = context.read<AuthCubit>().state;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (_) {
                              final bloc = SecurityPageBlocM(
                                apiClient: ApiClient(),
                              );
                              if (auth is AuthAuthenticated) {
                                bloc.setAuth(
                                  token: auth.token,
                                  userId: auth.utilisateur.idutilisateur,
                                );
                              }
                              return bloc;
                            },
                            child: const SecurityPageScreenM(),
                          ),
                        ),
                      );
                    },
                  ),
                  MenuItem(
                    icon: Icons.notifications_active_outlined,
                    title: 'Préférences de notifications',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (_) => AlertPageBlocM()
                              ..add(const LoadAlertPreferencesM()),
                            child: const AlertSettingsScreenM(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
