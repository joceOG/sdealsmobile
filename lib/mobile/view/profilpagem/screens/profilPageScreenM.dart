import '../../../../data/config/client_feature_flags.dart';
import '../../../../data/models/professional_capabilities.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../data/utils/display_text.dart';
import '../../../../design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../common/publish_options.dart';
import '../../common/widgets/session_guest_gate.dart';
import '../../common/widgets/client_universe_pictograms.dart';
import '../../common/widgets/logout_confirm_dialog.dart';
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
  /// Secours tant que le JSON Lottie n'est pas déposé dans les assets.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      body: SafeArea(
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            if (authState is! AuthAuthenticated) {
              return SessionGuestGate(
                guestBuilder: (context) => GuestAuthState(
                  pageTitle: 'Profil',
                  title: 'Retrouvez tout au même endroit',
                  description:
                      'Vos favoris, vos échanges et le suivi de vos demandes.',
                  illustration: SDIllustration(
                    asset: SDIllustrations.profileGuest,
                    fallback: Image.asset(
                      _guestProfilIllustration,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                  onPrimary: () => context.push('/login'),
                  onSecondary: () => context.push('/register'),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                _buildPageTitle('Profil'),
                _buildProfileHeader(context, authState),
                const SizedBox(height: 8),
                _buildSectionLabel('Mes activités'),
                _profileGroup([
                  MenuItem(
                    icon: Icons.assignment_outlined,
                    title: 'Mes demandes de services',
                    subtitle: 'Interventions et prestations',
                    padding: _groupPadding,
                    onTap: () => _openOrders(context),
                  ),
                  if (ClientFeatureFlags.emarketEnabled)
                    MenuItem(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Mes achats E-marché',
                      subtitle: 'Articles et commandes',
                      padding: _groupPadding,
                      onTap: () => _openOrders(context, achats: true),
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
                ]),
                ..._professionalSection(context, authState),
                _buildSectionLabel('Mon compte'),
                _profileGroup([
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
                  padding: const EdgeInsets.symmetric(horizontal: _hPad),
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

  Widget _buildProfileHeader(
    BuildContext context,
    AuthAuthenticated authState,
  ) {
    final user = authState.utilisateur;
    final userName =
        user.fullName.trim().isEmpty ? 'Utilisateur' : user.fullName.trim();
    final userPhoto = safeImageUrl(user.photoProfil);
    final hasNetworkPhoto = userPhoto != null &&
        (userPhoto.startsWith('http://') || userPhoto.startsWith('https://'));

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
                    radius: 28,
                    backgroundColor: SDColors.primary100,
                    backgroundImage: hasNetworkPhoto
                        ? NetworkImage(userPhoto) as ImageProvider
                        : null,
                    child: !hasNetworkPhoto
                        ? Text(
                            _initialsFor(user.prenom, user.nom),
                            style: SDTypography.cardTitle.copyWith(
                              color: SDColors.primary700,
                              fontWeight: FontWeight.w800,
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
                                'Modifier mon profil',
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
            'photoProfil': utilisateur.photoProfil,
          },
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _showLogoutDialog() {
    LogoutConfirmDialog.show(context);
  }

  void _openOrders(BuildContext context, {bool achats = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceRequestsListScreen(initialAchats: achats),
      ),
    );
  }

  String _initialsFor(String? prenom, String nom) {
    final first = cleanDisplayPart(prenom);
    final last = cleanDisplayPart(nom);
    String letter(String? value) {
      if (value == null || value.isEmpty) return '';
      return value.characters.first.toUpperCase();
    }

    final combo = '${letter(first)}${letter(last)}';
    if (combo.isNotEmpty) return combo;
    return '?';
  }

  String? _statusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'active':
        return 'Actif';
      case 'rejected':
        return 'Refusé';
      case 'suspended':
        return 'Suspendu';
      default:
        return null;
    }
  }

  Widget _statusChip(String label) {
    Color bg = SDColors.neutral100;
    Color fg = SDColors.neutral700;
    switch (label) {
      case 'En attente':
        bg = SDColors.warning100;
        fg = SDColors.warning700;
      case 'Actif':
        bg = SDColors.primary50;
        fg = SDColors.primary700;
      case 'Refusé':
      case 'Suspendu':
        bg = SDColors.error50;
        fg = SDColors.error600;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: SDTypography.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  List<Widget> _professionalSection(
    BuildContext context,
    AuthAuthenticated auth,
  ) {
    final caps = auth.professional;
    final spaces = <Widget>[];
    if (caps != null) {
      if (caps.prestataire.exists) {
        spaces.add(
          _spaceRow(
            context,
            icon: Icons.handyman_outlined,
            leading: const ClientUniversePictogram.metiers(size: 28),
            title: 'Espace Métiers',
            snapshot: caps.prestataire,
            onTap: () => openProviderPublishFlow(context),
          ),
        );
      }
      if (caps.freelance.exists) {
        spaces.add(
          _spaceRow(
            context,
            icon: Icons.laptop_mac_outlined,
            leading: const ClientUniversePictogram.freelance(size: 28),
            title: 'Espace Freelance',
            snapshot: caps.freelance,
          ),
        );
      }
      if (caps.vendeur.exists) {
        spaces.add(
          _spaceRow(
            context,
            icon: Icons.storefront_outlined,
            title: 'Espace E-marché',
            snapshot: caps.vendeur,
          ),
        );
      }
    }

    final missing = <bool>[
      !(caps?.prestataire.exists ?? false),
      !(caps?.freelance.exists ?? false),
      !(caps?.vendeur.exists ?? false),
    ];
    final canAdd = missing.any((m) => m);
    final noneExist = spaces.isEmpty;

    return [
      _buildSectionLabel('Espaces professionnels'),
      if (spaces.isNotEmpty) _profileGroup(spaces),
      if (canAdd) ...[
        if (spaces.isNotEmpty) const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _hPad),
          child: Material(
            color: SDColors.primary50,
            borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
            clipBehavior: Clip.antiAlias,
            child: MenuItem(
              icon: Icons.work_outline,
              leading: noneExist
                  ? const ClientUniversePictogram.metiers(size: 32)
                  : const Icon(
                      Icons.add_circle_outline,
                      color: SDColors.primary700,
                      size: 28,
                    ),
              title: noneExist
                  ? SDClientNav.becomeProfessional
                  : 'Ajouter une autre activité',
              subtitle: 'Métiers, Freelance ou E-marché',
              titleFontWeight: FontWeight.w600,
              padding: _groupPadding,
              onTap: () => showPublishOptions(context),
            ),
          ),
        ),
      ],
    ];
  }

  Widget _spaceRow(
    BuildContext context, {
    required IconData icon,
    Widget? leading,
    required String title,
    required ProfessionalProfileSnapshot snapshot,
    VoidCallback? onTap,
  }) {
    final status = _statusLabel(snapshot.status);
    final subtitle = snapshot.canOperate
        ? (status ?? 'Actif')
        : (status ?? 'Non opérationnel');
    return MenuItem(
      icon: icon,
      leading: leading,
      title: title,
      subtitle: subtitle,
      padding: _groupPadding,
      trailing: onTap == null && status != null ? _statusChip(status) : null,
      onTap: onTap,
    );
  }
}
