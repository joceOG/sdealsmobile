import '../../../../data/services/authCubit.dart';
import '../../../../data/services/auth_professional_access.dart';
import '../../../../data/utils/display_text.dart';
import '../../../../design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../common/auth_completion.dart';
import '../../common/publish_options.dart';
import '../../common/widgets/client_universe_pictograms.dart';
import '../../orderpagem/screens/service_requests_list_screen.dart';
import '../profilpageblocm/profilPageBlocM.dart';
import 'edit_profile_screen.dart';
import '../../avispagem/screens/avisPageScreenM.dart';
import '../../avispagem/avispageblocm/avisPageBlocM.dart';
import '../../favorispagem/screens/favorite_page_screen_m.dart';
import '../../favorispagem/favorispageblocm/favoritePageBlocM.dart';
import '../../historypagem/screens/historyPageScreenM.dart';
import '../../historypagem/historypageblocm/historyPageBlocM.dart';
import '../../alertpagem/screens/alertPageScreenM.dart';
import '../../alertpagem/alertpageblocm/alertPageBlocM.dart';
import '../../locationpagem/screens/locationPageScreenM.dart';
import '../../locationpagem/locationpageblocm/locationPageBlocM.dart';
import 'about_screen.dart';
import 'help_support_screen.dart';
import 'profile_menu_item.dart';
import 'profile_settings_hub_screen.dart';

class ProfilPageScreenM extends StatefulWidget {
  const ProfilPageScreenM({super.key});
  @override
  State<ProfilPageScreenM> createState() => _ProfilPageScreenStateM();
}

class _ProfilPageScreenStateM extends State<ProfilPageScreenM> {
  static const String _guestProfilIllustration = 'assets/profil_vide.png';

  static const double _hPad = 20;
  static const EdgeInsets _groupPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  @override
  void initState() {
    BlocProvider.of<ProfilPageBlocM>(context);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthCubit>().refreshRoles();
    });
  }

  void _showSoutraPayTarificationSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SoutraPayBottomSheet(ctx),
    );
  }

  Widget _buildTarificationRow(
    String title,
    String price,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SDTypography.bodyLarge.copyWith(
                    color: SDColors.neutral900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: SDTypography.bodySmall
                      .copyWith(color: SDColors.neutral500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            price,
            style: SDTypography.labelMedium.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      body: SafeArea(
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            if (authState is! AuthAuthenticated) {
              return GuestAuthState(
                pageTitle: 'Profil',
                title: 'Connectez-vous à votre profil',
                description:
                    'Gérez vos informations, favoris, demandes et votre activité Soutrali Deals.',
                illustrationAsset: _guestProfilIllustration,
                onPrimary: () => context.push('/login'),
                onSecondary: () => context.push('/register'),
              );
            }

            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _buildPageTitle('Profil'),
                _buildProfileHeader(context),
                const SizedBox(height: 8),
                _buildSectionLabel('Activité'),
                _profileGroup([
                  MenuItem(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Mes commandes',
                    padding: _groupPadding,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ServiceRequestsListScreen(),
                        ),
                      );
                    },
                  ),
                  MenuItem(
                    icon: Icons.favorite_border,
                    title: 'Favoris',
                    padding: _groupPadding,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (context) => FavoritePageBlocM(),
                            child: const FavoritePageScreenM(),
                          ),
                        ),
                      );
                    },
                  ),
                  MenuItem(
                    icon: Icons.star_outline,
                    title: 'Avis et évaluations',
                    padding: _groupPadding,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (context) => AvisPageBlocM(),
                            child: const AvisPageScreenM(),
                          ),
                        ),
                      );
                    },
                  ),
                  MenuItem(
                    icon: Icons.history,
                    title: 'Historique',
                    padding: _groupPadding,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (context) => HistoryPageBlocM(),
                            child: const HistoryPageScreenM(),
                          ),
                        ),
                      );
                    },
                  ),
                  MenuItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    padding: _groupPadding,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (context) => AlertPageBlocM(),
                            child: const AlertPageScreenM(),
                          ),
                        ),
                      );
                    },
                  ),
                ]),
                _buildPrestataireModeSection(),
                _buildSectionLabel('Professionnel'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _hPad),
                  child: Material(
                    color: SDColors.primary50,
                    borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
                    clipBehavior: Clip.antiAlias,
                    child: MenuItem(
                      icon: Icons.handyman_outlined,
                      leading: const ClientUniversePictogram.metiers(size: 32),
                      title: SDClientNav.becomeProfessional,
                      subtitle: 'Proposer vos services sur Soutrali Deals',
                      titleFontWeight: FontWeight.w600,
                      padding: _groupPadding,
                      onTap: () => showPublishOptions(context),
                    ),
                  ),
                ),
                _buildSectionLabel('Compte'),
                _profileGroup([
                  MenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Paramètres',
                    padding: _groupPadding,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileSettingsHubScreen(),
                        ),
                      );
                    },
                  ),
                  MenuItem(
                    icon: Icons.location_on_outlined,
                    title: 'Localisation',
                    padding: _groupPadding,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (context) => LocationPageBlocM(),
                            child: const LocationPageScreenM(),
                          ),
                        ),
                      );
                    },
                  ),
                  MenuItem(
                    icon: Icons.help_outline,
                    title: 'Aide et support',
                    padding: _groupPadding,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                  MenuItem(
                    icon: Icons.info_outline,
                    title: 'À propos',
                    padding: _groupPadding,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: MenuItem(
                    icon: Icons.logout,
                    title: 'Se déconnecter',
                    isLogout: true,
                    onTap: _showLogoutDialog,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Surface commune pour toute liste de menus standards du Profil.
  /// Fond [SDColors.neutral100] (#F5F5F5), proche de #F6F6F6. Pas de carte verte.
  Widget _profileGroup(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _hPad),
      child: Material(
        color: SDColors.neutral100,
        borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  color: SDColors.neutral200,
                  indent: 52,
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPageTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, 12, _hPad, 8),
      child: Text(
        title,
        style: SDTypography.displayMedium.copyWith(
          color: SDColors.neutral900,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, 24, _hPad, 8),
      child: Text(
        title,
        style: SDTypography.titleMedium.copyWith(
          color: SDColors.neutral900,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final String rawName =
        authState is AuthAuthenticated ? authState.utilisateur.fullName : '';
    final String userName = rawName.isEmpty ? 'Utilisateur' : rawName;
    final String? userPhoto = authState is AuthAuthenticated
        ? safeImageUrl(authState.utilisateur.photoProfil)
        : null;
    final hasNetworkPhoto = userPhoto != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, 4, _hPad, 8),
      child: Material(
        color: SDColors.primary50,
        borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
        child: InkWell(
          onTap: _navigateToEditProfile,
          borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(minHeight: SDSpacing.minTouchTarget),
            child: Padding(
              padding: const EdgeInsets.all(SDSpacing.spaceRelated),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: SDColors.primary500,
                    backgroundImage: hasNetworkPhoto
                        ? NetworkImage(userPhoto) as ImageProvider
                        : null,
                    child: !hasNetworkPhoto
                        ? Text(
                            userName.isNotEmpty
                                ? userName.characters.first.toUpperCase()
                                : '?',
                            style: SDTypography.cardTitle.copyWith(
                              color: SDColors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: SDTypography.cardTitle.copyWith(
                            fontWeight: FontWeight.w700,
                            color: SDColors.neutral900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: SDColors.primary700,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Modifier le profil',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SDTypography.caption.copyWith(
                                  color: SDColors.primary700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: SDColors.neutral400,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToEditProfile() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter')),
      );
      return;
    }

    final utilisateur = authState.utilisateur;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          initialUserData: {
            'nom': utilisateur.nom,
            'prenom': utilisateur.prenom ?? '',
            'telephone': utilisateur.telephone,
            'email': utilisateur.email ?? '',
            'genre': utilisateur.genre ?? '',
            'datedenaissance': utilisateur.dateNaissance ?? '',
            'photoProfil':
                utilisateur.photoProfil ?? 'assets/profile_picture.jpg',
          },
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: SDColors.white,
          title: const Text('Se déconnecter'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Annuler',
                style: SDTypography.labelLarge
                    .copyWith(color: SDColors.neutral900),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await context.read<AuthCubit>().logout();
                if (!context.mounted) return;
                exitToGuestHome(context);
              },
              child: Text(
                'Se déconnecter',
                style: SDTypography.labelLarge.copyWith(color: SDColors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPrestataireModeSection() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated || !state.canOperatePrestataire) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('Mes espaces'),
            _profileGroup([
              MenuItem(
                icon: Icons.handyman_outlined,
                title: 'Espace Métiers',
                padding: _groupPadding,
                onTap: () => _switchToPrestataireMode(context),
              ),
            ]),
          ],
        );
      },
    );
  }

  void _switchToPrestataireMode(BuildContext context) {
    try {
      context.read<AuthCubit>().switchActiveRole('PRESTATAIRE');
      Future.delayed(const Duration(milliseconds: 100), () {
        context.push('/providermain');
      });
    } catch (e) {
      context.push('/providermain');
    }
  }
}

// ─── Bottom sheet SoutraPay ───────────────────────────────────────────────────

class _SoutraPayBottomSheet extends StatelessWidget {
  const _SoutraPayBottomSheet(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: SDColors.neutral200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: SDColors.primary50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.payments_rounded,
                color: SDColors.primary600,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'SoutraPay arrive bientôt',
            textAlign: TextAlign.center,
            style: SDTypography.titleLarge.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les paiements SoutraPay ne sont pas encore disponibles dans cette version.',
            textAlign: TextAlign.center,
            style: SDTypography.bodyMedium.copyWith(
              color: SDColors.neutral600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SDButton(
            text: 'D\'accord',
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
