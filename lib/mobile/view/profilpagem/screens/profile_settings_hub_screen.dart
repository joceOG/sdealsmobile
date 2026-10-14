import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../data/utils/legal_urls.dart';
import '../../../../design_system/design_system.dart';
import '../../alertpagem/alertpageblocm/alertPageBlocM.dart';
import '../../alertpagem/alertpageblocm/alertPageEventM.dart';
import '../../alertpagem/screens/alertSettingsScreenM.dart';
import '../../securitypagem/screens/securityPageScreenM.dart';
import '../../securitypagem/securitypageblocm/securityPageBlocM.dart';
import 'about_screen.dart';
import 'delete_account_screen.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';
import 'language_settings_screen.dart';
import 'profile_menu_item.dart';

/// Hub Paramètres — Compte, Préférences, Aide et informations.
class ProfileSettingsHubScreen extends StatelessWidget {
  const ProfileSettingsHubScreen({super.key});

  static const double _hPad = 20;
  static const EdgeInsets _itemPad =
      EdgeInsets.symmetric(horizontal: 14, vertical: 12);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topBar(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 24),
                children: [
                  _sectionLabel('Compte'),
                  _group([
                    MenuItem(
                      icon: Icons.person_outline,
                      leading: _iconWell(Icons.person_outline),
                      title: 'Informations personnelles',
                      subtitle: 'Nom, photo et coordonnées',
                      padding: _itemPad,
                      onTap: () => _openEditProfile(context),
                    ),
                    MenuItem(
                      icon: Icons.shield_outlined,
                      leading: _iconWell(Icons.shield_outlined),
                      title: 'Sécurité du compte',
                      subtitle: 'Accès et protection',
                      padding: _itemPad,
                      onTap: () => _openSecurity(context),
                    ),
                  ]),
                  _sectionLabel('Préférences'),
                  _group([
                    MenuItem(
                      icon: Icons.notifications_none_rounded,
                      leading: _iconWell(Icons.notifications_none_rounded),
                      title: 'Notifications',
                      subtitle: 'Gérer mes préférences',
                      padding: _itemPad,
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
                    MenuItem(
                      icon: Icons.language,
                      leading: _iconWell(Icons.language),
                      title: 'Langue de l’application',
                      subtitle: 'Français',
                      padding: _itemPad,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LanguageSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ]),
                  _sectionLabel('Aide et informations'),
                  _group([
                    MenuItem(
                      icon: Icons.headset_mic_outlined,
                      leading: _iconWell(Icons.headset_mic_outlined),
                      title: 'Aide et support',
                      padding: _itemPad,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HelpSupportScreen(),
                          ),
                        );
                      },
                    ),
                    MenuItem(
                      icon: Icons.description_outlined,
                      leading: _iconWell(Icons.description_outlined),
                      title: 'Conditions d’utilisation',
                      padding: _itemPad,
                      onTap: () => openLegalUrl(context, LegalUrls.cgu),
                    ),
                    MenuItem(
                      icon: Icons.policy_outlined,
                      leading: _iconWell(Icons.policy_outlined),
                      title: 'Politique de confidentialité',
                      padding: _itemPad,
                      onTap: () =>
                          openLegalUrl(context, LegalUrls.confidentialite),
                    ),
                    MenuItem(
                      icon: Icons.info_outline,
                      leading: _iconWell(Icons.info_outline),
                      title: 'À propos de Soutrali',
                      padding: _itemPad,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AboutScreen(),
                          ),
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _group([
                    MenuItem(
                      icon: Icons.person_remove_outlined,
                      leading: _iconWell(
                        Icons.person_remove_outlined,
                        background: SDColors.error50,
                        foreground: SDColors.error500,
                      ),
                      title: 'Supprimer mon compte',
                      isLogout: true,
                      padding: _itemPad,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DeleteAccountScreen(),
                          ),
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 28),
                  Text(
                    'SOUTRALI DEALS',
                    textAlign: TextAlign.center,
                    style: SDTypography.labelSmall.copyWith(
                      color: SDColors.neutral400,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back, color: SDColors.neutral900),
            tooltip: 'Retour',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paramètres',
                  style: SDTypography.titleLarge.copyWith(
                    color: SDColors.neutral900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Gérez votre compte et vos préférences.',
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        title,
        style: SDTypography.titleSmall.copyWith(
          color: SDColors.neutral900,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _group(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SDColors.neutral200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                color: SDColors.neutral200,
                indent: 68,
              ),
            children[i],
          ],
        ],
      ),
    );
  }

  static Widget _iconWell(
    IconData icon, {
    Color background = SDColors.primary50,
    Color foreground = SDColors.primary700,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: foreground, size: 20),
    );
  }

  static void _openEditProfile(BuildContext context) {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return;
    final utilisateur = auth.utilisateur;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          initialUserData: {
            'nom': utilisateur.nom,
            'prenom': utilisateur.prenom ?? '',
            'telephone': utilisateur.telephone,
            'email': utilisateur.email ?? '',
            'genre': utilisateur.genre ?? '',
            'datedenaissance': utilisateur.dateNaissance ?? '',
            'photoProfil': utilisateur.photoProfil,
          },
        ),
      ),
    );
  }

  static void _openSecurity(BuildContext context) {
    final auth = context.read<AuthCubit>().state;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) {
            final bloc = SecurityPageBlocM(apiClient: ApiClient());
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
  }
}
