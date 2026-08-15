import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../design_system/design_system.dart';
import '../../../../data/services/authCubit.dart';
import 'package:go_router/go_router.dart';
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

  @override
  void initState() {
    BlocProvider.of<ProfilPageBlocM>(context);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthCubit>().refreshRoles();
    });
  }

  void _showSoutraPayTarificationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SDColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.fromLTRB(_hPad, 12, _hPad, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: SDColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tarification SoutraPay',
              style: SDTypography.displaySmall.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tarifs indicatifs (non branchés au backend paiement).',
              style: SDTypography.bodyMedium
                  .copyWith(color: SDColors.neutral600),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildTarificationRow(
                    'Création de compte',
                    'Gratuit',
                    'Créez votre compte SoutraPay sans frais',
                  ),
                  _buildTarificationRow(
                    'Rechargement de compte',
                    '0 FCFA',
                    'Aucun frais pour recharger votre compte',
                  ),
                  _buildTarificationRow(
                    'Transfert entre utilisateurs',
                    '0 FCFA',
                    'Envoyez de l\'argent sans frais entre comptes SoutraPay',
                  ),
                  _buildTarificationRow(
                    'Paiement aux marchands',
                    '0 FCFA',
                    'Réglez vos achats sans frais',
                  ),
                  _buildTarificationRow(
                    'Retrait vers compte bancaire',
                    '1,5%',
                    'Des frais minimes pour les retraits vers votre banque',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
              return ListView(
                children: [
                  _buildPageTitle('Profil'),
                  _buildLoginBanner(context),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                _buildPageTitle('Profil'),
                _buildProfileHeader(context),
                const SizedBox(height: 8),
                _buildSectionLabel('Activité'),
                MenuItem(
                  icon: Icons.inventory_2_outlined,
                  title: 'Mes commandes',
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
                  icon: Icons.rate_review_outlined,
                  title: 'Avis & évaluations',
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
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
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
                _buildSectionLabel('Paiements'),
                MenuItem(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Portefeuille',
                  onTap: () => Navigator.pushNamed(context, '/wallet'),
                ),
                MenuItem(
                  icon: Icons.payments_outlined,
                  title: 'Tarification',
                  onTap: () => _showSoutraPayTarificationSheet(context),
                ),
                _buildPrestataireModeSection(),
                _buildSectionLabel('Compte'),
                MenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Paramètres',
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
                  title: 'Aide & Support',
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
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AboutScreen(),
                      ),
                    );
                  },
                ),
                MenuItem(
                  icon: Icons.logout,
                  title: 'Se déconnecter',
                  isLogout: true,
                  onTap: _showLogoutDialog,
                ),
              ],
            );
          },
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
      padding: const EdgeInsets.fromLTRB(_hPad, 28, _hPad, 4),
      child: Text(
        title,
        style: SDTypography.titleMedium.copyWith(
          color: SDColors.neutral900,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildLoginBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 24),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: Image.asset(
              _guestProfilIllustration,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 88,
                  color: SDColors.neutral300,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Accédez à tous les services autour de vous',
            style: SDTypography.titleMedium.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Connectez-vous pour voir les freelances, vendeurs et artisans',
            style: SDTypography.bodyMedium.copyWith(
              color: SDColors.neutral600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SDColors.primary600,
                foregroundColor: SDColors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Se connecter',
                style: SDTypography.labelLarge.copyWith(
                  color: SDColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/register'),
              style: OutlinedButton.styleFrom(
                foregroundColor: SDColors.primary700,
                side: const BorderSide(color: SDColors.primary600, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Créer un compte',
                style: SDTypography.labelLarge.copyWith(
                  color: SDColors.primary700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final String userName = authState is AuthAuthenticated
        ? authState.utilisateur.fullName
        : 'Utilisateur';
    final String userEmail = authState is AuthAuthenticated
        ? (authState.utilisateur.email ?? '')
        : '';
    final String? userPhoto = authState is AuthAuthenticated
        ? authState.utilisateur.photoProfil
        : null;

    final hasNetworkPhoto = userPhoto != null &&
        userPhoto.isNotEmpty &&
        userPhoto.startsWith('http');

    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, 12, _hPad, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: SDColors.neutral200,
            backgroundImage:
                hasNetworkPhoto ? NetworkImage(userPhoto) as ImageProvider : null,
            child: !hasNetworkPhoto
                ? Text(
                    userName.isNotEmpty
                        ? userName.characters.first.toUpperCase()
                        : 'U',
                    style: SDTypography.titleLarge.copyWith(
                      color: SDColors.neutral900,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName,
                  style: SDTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: SDColors.neutral900,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (userEmail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    userEmail,
                    style: SDTypography.bodyMedium.copyWith(
                      color: SDColors.neutral600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _navigateToEditProfile,
                  child: Text(
                    'Éditer le profil',
                    style: SDTypography.bodyMedium.copyWith(
                      color: SDColors.neutral900,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: SDColors.neutral900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                if (!mounted) return;
                context.go('/login');
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
        if (state is! AuthAuthenticated ||
            !state.roles.contains('PRESTATAIRE')) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('Mes espaces'),
            MenuItem(
              icon: Icons.handyman_outlined,
              title: 'Espace Métiers',
              onTap: () => _switchToPrestataireMode(context),
            ),
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
