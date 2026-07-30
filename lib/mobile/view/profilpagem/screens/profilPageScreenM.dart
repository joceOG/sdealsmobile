import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../design_system/design_system.dart'; // ✅ Import DS
import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart'; // ✅ Import AuthCubit
import 'package:go_router/go_router.dart';
import '../../loginpagem/screens/loginPageScreenM.dart';
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
import '../../preferencespagem/screens/preferencesPageScreenM.dart';
import '../../preferencespagem/preferencespageblocm/preferencesPageBlocM.dart';
import '../../securitypagem/screens/securityPageScreenM.dart';
import '../../securitypagem/securitypageblocm/securityPageBlocM.dart';
import '../../locationpagem/screens/locationPageScreenM.dart';
import '../../locationpagem/locationpageblocm/locationPageBlocM.dart';

class ProfilPageScreenM extends StatefulWidget {
  const ProfilPageScreenM({super.key});
  @override
  State<ProfilPageScreenM> createState() => _ProfilPageScreenStateM();
}

class _ProfilPageScreenStateM extends State<ProfilPageScreenM> {
  /// Illustration écran profil non connecté.
  static const String _guestProfilIllustration = 'assets/profil_vide.png';

  @override
  void initState() {
    BlocProvider.of<ProfilPageBlocM>(context);
    super.initState();
  }

  // Affiche la feuille des tarifs SoutraPay
  void _showSoutraPayTarificationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(SDSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 5,
                width: 50,
                decoration: BoxDecoration(
                  color: SDColors.neutral300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: SDSpacing.md),
            Text(
              "Tarification SoutraPay",
              style: SDTypography.displaySmall.copyWith(
                color: SDColors.neutral900,
              ),
            ),
            SizedBox(height: SDSpacing.xs),
            Text(
              "Tous les tarifs et frais applicables aux services SoutraPay",
              style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral600),
            ),
            SizedBox(height: SDSpacing.lg),
            Expanded(
              child: ListView(
                children: [
                  _buildTarificationCard(
                    "Création de compte",
                    "Gratuit",
                    "Créez votre compte SoutraPay sans frais",
                    Icons.person_add,
                    SDColors.success,
                  ),
                  _buildTarificationCard(
                    "Rechargement de compte",
                    "0 FCFA",
                    "Aucun frais pour recharger votre compte",
                    Icons.account_balance_wallet,
                    SDColors.info,
                  ),
                  _buildTarificationCard(
                    "Transfert entre utilisateurs",
                    "0 FCFA",
                    "Envoyez de l'argent sans frais entre comptes SoutraPay",
                    Icons.swap_horiz,
                    SDColors.warning,
                  ),
                  _buildTarificationCard(
                    "Paiement aux marchands",
                    "0 FCFA",
                    "Réglez vos achats sans frais",
                    Icons.shopping_cart,
                    SDColors.secondary,
                  ),
                  _buildTarificationCard(
                    "Retrait vers compte bancaire",
                    "1,5%",
                    "Des frais minimes pour les retraits vers votre banque",
                    Icons.account_balance,
                    SDColors.primary600,
                  ),
                ],
              ),
            ),
            SizedBox(height: SDSpacing.xs),
            Text(
              "Note: Les tarifs sont sujets à modification. Consultez régulièrement cette page pour les mises à jour.",
              style: SDTypography.bodySmall.copyWith(
                fontStyle: FontStyle.italic,
                color: SDColors.neutral600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Carte pour afficher un élément de tarification
  Widget _buildTarificationCard(String title, String price, String description,
      IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: SDSpacing.sm),
      padding: SDSpacing.cardPadding,
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: SDColors.neutral900.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(SDSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(width: SDSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SDTypography.titleSmall.copyWith(
                    color: SDColors.neutral900,
                  ),
                ),
                SizedBox(height: SDSpacing.xxxs),
                Text(
                  description,
                  style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: SDSpacing.sm, vertical: SDSpacing.xxxs),
            decoration: BoxDecoration(
              color: price.contains("Gratuit") || price.contains("0 FCFA")
                  ? SDColors.success.withOpacity(0.1)
                  : SDColors.neutral200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              price,
              style: SDTypography.labelSmall.copyWith(
                color: price.contains("Gratuit") || price.contains("0 FCFA")
                    ? SDColors.success
                    : SDColors.neutral800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.neutral50,
      appBar: SDWhiteAppBar.appBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: 'Profil',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Navigation vers paramètres si nécessaire
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Bannière de connexion si non connecté
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                if (authState is! AuthAuthenticated) {
                  return _buildLoginBanner(context);
                }
                return SizedBox.shrink();
              },
            ),
            
            // En-tête du profil (seulement si connecté)
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                if (authState is AuthAuthenticated) {
                  return Column(
                    children: [
                      _buildProfileHeader(context),
                      SizedBox(height: SDSpacing.md),
                    ],
                  );
                }
                return SizedBox.shrink();
              },
            ),

            // Section "Mon activité"
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                if (authState is AuthAuthenticated) {
                  return Column(
                    children: [
                      const SectionTitle(title: 'Mon activité'),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: SDSpacing.md),
                        decoration: BoxDecoration(
                          color: SDColors.white,
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                          boxShadow: [
                            BoxShadow(
                              color: SDColors.neutral200.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            MenuItem(
                              icon: Icons.inventory_2,
                              title: "Mes commandes",
                              subtitle: "Voir les commandes passées et en cours",
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const _ServiceRequestsEntry(),
                                  ),
                                );
                              },
                            ),
                            MenuItem(
                              icon: Icons.rate_review,
                              title: "Mes avis & évaluations",
                              subtitle: "Historique des commentaires laissés",
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
                              icon: Icons.favorite,
                              title: "Favoris / Listes enregistrées",
                              subtitle: "Articles, prestataires ou annonces sauvegardés",
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
                              icon: Icons.history,
                              title: "Historique des consultations",
                              subtitle: "Voir toutes vos consultations récentes",
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
                              icon: Icons.notifications,
                              title: "Mes alertes",
                              subtitle: "Notifs personnalisées : offres, rappels",
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
                              icon: Icons.language,
                              title: "Langue & Devise",
                              subtitle: "Configurer langue, devise, localisation",
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => BlocProvider(
                                      create: (context) => PreferencesPageBlocM(),
                                      child: const PreferencesPageScreenM(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return SizedBox.shrink();
              },
            ),

            // Section "Mon SoutraPay"
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                if (authState is AuthAuthenticated) {
                  return Column(
                    children: [
                      const SectionTitle(title: 'Mon SoutraPay'),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: SDSpacing.md),
                        decoration: BoxDecoration(
                          color: SDColors.white,
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                          boxShadow: [
                            BoxShadow(
                              color: SDColors.neutral200.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            MenuItem(
                              icon: Icons.account_balance_wallet,
                              title: "Portefeuille SoutraPay",
                              subtitle: "Gérer mon portefeuille électronique",
                              onTap: () {
                                Navigator.pushNamed(context, '/wallet');
                              },
                            ),
                            MenuItem(
                              icon: Icons.monetization_on,
                              title: "Tarification SoutraPay",
                              subtitle: "Consultez les frais et tarifs",
                              onTap: () {
                                _showSoutraPayTarificationSheet(context);
                              },
                              badge: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: SDColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "Gratuit",
                                  style: SDTypography.labelSmall.copyWith(
                                      color: SDColors.success, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return SizedBox.shrink();
              },
            ),

            // Section "Mes interactions"
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                if (authState is AuthAuthenticated) {
                  return Column(
                    children: [
                      const SectionTitle(title: 'Mes interactions'),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: SDSpacing.md),
                        decoration: BoxDecoration(
                          color: SDColors.white,
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                          boxShadow: [
                            BoxShadow(
                              color: SDColors.neutral200.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            MenuItem(
                              icon: Icons.receipt_long,
                              title: "Factures & paiements",
                              subtitle: "Accès aux reçus, abonnements, paiements",
                              onTap: () {
                                // Navigation vers les factures
                              },
                            ),
                            MenuItem(
                              icon: Icons.card_giftcard,
                              title: "Parrainage & récompenses",
                              subtitle: "Invitez des amis, gagnez des bonus",
                              onTap: () {
                                // Navigation vers le parrainage
                              },
                            ),
                            MenuItem(
                              icon: Icons.local_offer,
                              title: "Offres personnalisées",
                              subtitle: "Voir les bons plans proposés selon vos intérêts",
                              onTap: () {
                                // Navigation vers les offres
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return SizedBox.shrink();
              },
            ),

            // 🎯 SECTION MODE PRESTATAIRE
            _buildPrestataireModeSection(),

            // Section "Paramètres"
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                if (authState is AuthAuthenticated) {
                  return Column(
                    children: [
                      const SectionTitle(title: 'Paramètres'),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: SDSpacing.md),
                        decoration: BoxDecoration(
                          color: SDColors.white,
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                          boxShadow: [
                            BoxShadow(
                              color: SDColors.neutral200.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            MenuItem(
                              icon: Icons.language,
                              title: "Langue & Devise",
                              subtitle: "Personnalisation par langue (fr, en, nouchi)",
                              onTap: () {
                                // Navigation vers les paramètres de langue
                              },
                            ),
                            MenuItem(
                              icon: Icons.location_on,
                              title: "Localisation",
                              subtitle: "Gérer votre adresse, géolocalisation",
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
                              icon: Icons.security,
                              title: "Sécurité du compte",
                              subtitle: "Mot de passe, double authentification",
                              onTap: () {
                                final auth = context.read<AuthCubit>().state;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => BlocProvider(
                                      create: (context) {
                                        final bloc = SecurityPageBlocM(
                                          apiClient: ApiClient(),
                                        );
                                        if (auth is AuthAuthenticated) {
                                          bloc.setAuth(
                                            token: auth.token,
                                            userId:
                                                auth.utilisateur.idutilisateur,
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
                              icon: Icons.settings,
                              title: "Préférences utilisateurs",
                              subtitle: "Notifications, catégories favorites",
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => BlocProvider(
                                      create: (context) => PreferencesPageBlocM(),
                                      child: const PreferencesPageScreenM(),
                                    ),
                                  ),
                                );
                              },
                            ),
                            MenuItem(
                              icon: Icons.logout,
                              title: "Se déconnecter",
                              subtitle: "",
                              isLogout: true,
                              onTap: () {
                                _showLogoutDialog();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return SizedBox.shrink();
              },
            ),
            SizedBox(height: SDSpacing.md),
          ],
        ),
      ),
    );
  }

  /// Invité : carte claire + illustration `assets/profil_vide.png` (pas de gros bandeau dégradé).
  Widget _buildLoginBanner(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(SDSpacing.md),
      padding: EdgeInsets.fromLTRB(SDSpacing.lg, SDSpacing.md, SDSpacing.lg, SDSpacing.lg),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: SDColors.neutral900.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Image.asset(
              _guestProfilIllustration,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => Center(
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 88,
                  color: SDColors.neutral300,
                ),
              ),
            ),
          ),
          SizedBox(height: SDSpacing.md),
          Text(
            'Accédez à tous les services autour de vous',
            style: SDTypography.titleMedium.copyWith(
              color: SDColors.primary800,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SDSpacing.xs),
          Text(
            'Connectez-vous pour voir les freelances, vendeurs et artisans',
            style: SDTypography.bodyMedium.copyWith(
              color: SDColors.neutral600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SDSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 300) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LoginPageScreenM(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SDColors.primary600,
                          foregroundColor: SDColors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: SDSpacing.lg,
                            vertical: SDSpacing.sm,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                          ),
                        ),
                        child: Text(
                          'Se connecter',
                          style: SDTypography.labelMedium.copyWith(
                            color: SDColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: SDSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          context.push('/register');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SDColors.primary700,
                          side: const BorderSide(color: SDColors.primary600, width: 1.5),
                          padding: EdgeInsets.symmetric(
                            horizontal: SDSpacing.lg,
                            vertical: SDSpacing.sm,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                          ),
                        ),
                        child: Text(
                          'Créer un compte',
                          style: SDTypography.labelMedium.copyWith(
                            color: SDColors.primary700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LoginPageScreenM(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SDColors.primary600,
                        foregroundColor: SDColors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: SDSpacing.md,
                          vertical: SDSpacing.sm,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                        ),
                      ),
                      child: Text(
                        'Se connecter',
                        style: SDTypography.labelMedium.copyWith(
                          color: SDColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(width: SDSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context.push('/register');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SDColors.primary700,
                        side: const BorderSide(color: SDColors.primary600, width: 1.5),
                        padding: EdgeInsets.symmetric(
                          horizontal: SDSpacing.md,
                          vertical: SDSpacing.sm,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                        ),
                      ),
                      child: Text(
                        'Créer un compte',
                        style: SDTypography.labelMedium.copyWith(
                          color: SDColors.primary700,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // En-tête identité : avatar à gauche, texte à droite (compact, lisible)
  Widget _buildProfileHeader(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final String userName = authState is AuthAuthenticated
        ? authState.utilisateur.fullName
        : "Utilisateur";
    final String userEmail = authState is AuthAuthenticated
        ? (authState.utilisateur.email ?? "email@exemple.com")
        : "email@exemple.com";
    final String? userPhoto = authState is AuthAuthenticated
        ? authState.utilisateur.photoProfil
        : null;

    final hasNetworkPhoto = userPhoto != null &&
        userPhoto.isNotEmpty &&
        userPhoto.startsWith('http');

    return Container(
      margin: EdgeInsets.fromLTRB(SDSpacing.md, SDSpacing.sm, SDSpacing.md, SDSpacing.xs),
      padding: EdgeInsets.all(SDSpacing.md),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: SDColors.neutral900.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: SDColors.primary600,
            backgroundImage:
                hasNetworkPhoto ? NetworkImage(userPhoto!) as ImageProvider : null,
            child: !hasNetworkPhoto
                ? Text(
                    userName.isNotEmpty ? userName.characters.first.toUpperCase() : 'U',
                    style: SDTypography.titleLarge.copyWith(
                      color: SDColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          SizedBox(width: SDSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName,
                  style: SDTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: SDColors.neutral900,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: SDSpacing.xxxs),
                Text(
                  userEmail,
                  style: SDTypography.bodyMedium.copyWith(
                    color: SDColors.neutral600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: SDSpacing.xs),
                TextButton(
                  onPressed: () => _navigateToEditProfile(),
                  style: TextButton.styleFrom(
                    foregroundColor: SDColors.primary600,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Éditer le profil',
                    style: SDTypography.labelLarge.copyWith(
                      color: SDColors.primary600,
                      fontWeight: FontWeight.w600,
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

  // Retourne l'icône correspondant au statut de l'utilisateur
  Widget _getStatusIcon(String userStatus) {
    switch (userStatus) {
      case "Compte vérifié":
        return Icon(Icons.verified, color: SDColors.white);
      case "Premium":
        return Icon(Icons.lock, color: SDColors.white);
      default:
        return Icon(Icons.person, color: SDColors.white);
    }
  }

  // Navigation vers l'écran d'édition du profil
  void _navigateToEditProfile() async {
    // ✅ Récupérer les données utilisateur depuis AuthCubit
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

    // Rafraîchir la page si des modifications ont été apportées
    if (result == true) {
      setState(() {
        // Rafraîchir les données du profil
      });
    }
  }

  // Dialogue de confirmation pour la déconnexion
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Se déconnecter"),
          content: const Text("Êtes-vous sûr de vouloir vous déconnecter ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPageScreenM(),
                  ),
                );
              },
              child: Text("Se déconnecter",
                  style: SDTypography.labelLarge.copyWith(color: SDColors.error)),
            ),
          ],
        );
      },
    );
  }

  // 🎯 SECTION MODE PRESTATAIRE
  Widget _buildPrestataireModeSection() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        // 🔍 DEBUG : Toujours afficher pour test
        print('🔍 DEBUG - AuthState: $state');
        if (state is AuthAuthenticated) {
          print('🔍 DEBUG - Roles: ${state.roles}');
          print(
              '🔍 DEBUG - Contains PRESTATAIRE: ${state.roles.contains('PRESTATAIRE')}');
        }

        // Vérifier si l'utilisateur a le rôle PRESTATAIRE
        if (state is AuthAuthenticated && state.roles.contains('PRESTATAIRE')) {
          return Column(
            children: [
              const SectionTitle(title: 'Mode Prestataire'),
              Container(
                margin: EdgeInsets.symmetric(horizontal: SDSpacing.md),
                decoration: BoxDecoration(
                  color: SDColors.white,
                  borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: SDColors.neutral200.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: SDSpacing.md, vertical: SDSpacing.sm),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SDColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.handyman,
                      color: SDColors.white,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Mode Prestataire',
                    style: SDTypography.titleMedium.copyWith(
                      color: SDColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Accéder à votre interface prestataire',
                    style: TextStyle(
                      color: SDColors.white.withOpacity(0.7),
                    ),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: SDColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Disponible',
                      style: TextStyle(
                        color: SDColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () => _switchToPrestataireMode(context),
                ),
              ),
            ],
          );
        }

        // 🔍 DEBUG : Afficher une version de test
        return Column(
          children: [
            const SectionTitle(title: '🔧 Mode Prestataire (DEBUG)'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SDColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.handyman,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                title: Text(
                  'Mode Prestataire (DEBUG)',
                  style: SDTypography.titleMedium.copyWith(
                    color: SDColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Version de test - toujours visible',
                  style: TextStyle(
                    color: SDColors.white.withOpacity(0.7),
                  ),
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: SDColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'DEBUG',
                    style: TextStyle(
                      color: SDColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () => _switchToPrestataireMode(context),
              ),
            ),
          ],
        );
      },
    );
  }

  // 🔄 SWITCH VERS MODE PRESTATAIRE
  void _switchToPrestataireMode(BuildContext context) {
    try {
      context.read<AuthCubit>().switchActiveRole('PRESTATAIRE');
      Future.delayed(const Duration(milliseconds: 100), () {
        context.push('/providermain');
      });
    } catch (e) {
      print('Erreur lors du switch vers prestataire: $e');
      context.push('/providermain');
    }
  }
}

// Petit wrapper pour éviter les imports massifs ici
class _ServiceRequestsEntry extends StatelessWidget {
  const _ServiceRequestsEntry();
  @override
  Widget build(BuildContext context) {
    return const _ServiceRequestsEntryImpl();
  }
}

class _ServiceRequestsEntryImpl extends StatelessWidget {
  const _ServiceRequestsEntryImpl();
  @override
  Widget build(BuildContext context) {
    // import paresseux via Builder pour ne pas casser d'autres écrans
    return Builder(
      builder: (context) {
        // ignore: unnecessary_import
        return Navigator(
          onGenerateRoute: (settings) => MaterialPageRoute(
            builder: (_) {
              // import tardif du screen réel
              // ignore: unused_import
              return _ServiceRequestsReal();
            },
          ),
        );
      },
    );
  }
}

class _ServiceRequestsReal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // import direct du fichier écran
    // Pour limiter les changements d'import en tête de fichier principal
    // on crée ce proxy.
    // ignore: unnecessary_import
    return const _ServiceRequestsProxy();
  }
}

class _ServiceRequestsProxy extends StatelessWidget {
  const _ServiceRequestsProxy();
  @override
  Widget build(BuildContext context) {
    // Import réel
    // ignore: unused_import
    return _ServiceRequestsScaffold();
  }
}

// Décompose en widget concret pour brancher le vrai écran
class _ServiceRequestsScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Import réellement utilisé
    // On référence directement l'écran créé dans orderpagem
    // pour ne pas ajouter d'import en haut
    return const ServiceRequestsListScreen();
  }
}

// Widget pour les titres de section - DESIGN AMÉLIORÉ
class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: SDSpacing.md,
        bottom: SDSpacing.sm,
        left: SDSpacing.md,
        right: SDSpacing.md,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: SDTypography.labelLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: SDColors.primary600,
            letterSpacing: 0.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// Widget pour les éléments de menu - DESIGN AMÉLIORÉ (VERT)
class MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLogout;
  final VoidCallback onTap;
  final Widget? badge;

  const MenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle = "",
    this.isLogout = false,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: SDSpacing.sm, horizontal: SDSpacing.md),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: SDColors.neutral100,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Icône à gauche (VERT)
            Icon(
              icon,
              color: isLogout ? SDColors.error500 : SDColors.primary600,
              size: 24,
            ),
            SizedBox(width: SDSpacing.md),
            // Texte au centre (VERT)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SDTypography.bodyMedium.copyWith(
                      color: isLogout ? SDColors.error500 : SDColors.primary600,
                      fontWeight: isLogout ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: SDSpacing.xxxs),
                    Text(
                      subtitle,
                      style: SDTypography.bodySmall.copyWith(
                        color: SDColors.neutral500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Badge et chevron à droite
            if (badge != null) ...[
              badge!,
              SizedBox(width: SDSpacing.xs),
            ],
            Icon(
              Icons.chevron_right,
              color: SDColors.primary600,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
