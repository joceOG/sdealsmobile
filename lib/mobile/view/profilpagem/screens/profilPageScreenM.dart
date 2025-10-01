import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/services/api_client.dart';
import '../../loginpagem/screens/loginPageScreenM.dart';
import '../../orderpagem/screens/service_requests_list_screen.dart';
import '../profilpageblocm/profilPageBlocM.dart';
import 'edit_profile_screen.dart';
import '../../avispagem/screens/avisPageScreenM.dart';
import '../../avispagem/avispageblocm/avisPageBlocM.dart';
import '../../favorispagem/screens/favoritePageScreenM.dart';
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
  // Simuler des données utilisateur
  final String userName = "Afisu Yussuf";
  final String userStatus = "Compte vérifié"; // Ou "Client simple", "Premium"

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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 5,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Tarification SoutraPay",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Tous les tarifs et frais applicables aux services SoutraPay",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView(
                children: [
                  _buildTarificationCard(
                    "Création de compte",
                    "Gratuit",
                    "Créez votre compte SoutraPay sans frais",
                    Icons.person_add,
                    Colors.green,
                  ),
                  _buildTarificationCard(
                    "Rechargement de compte",
                    "0 FCFA",
                    "Aucun frais pour recharger votre compte",
                    Icons.account_balance_wallet,
                    Colors.blue,
                  ),
                  _buildTarificationCard(
                    "Transfert entre utilisateurs",
                    "0 FCFA",
                    "Envoyez de l'argent sans frais entre comptes SoutraPay",
                    Icons.swap_horiz,
                    Colors.orange,
                  ),
                  _buildTarificationCard(
                    "Paiement aux marchands",
                    "0 FCFA",
                    "Réglez vos achats sans frais",
                    Icons.shopping_cart,
                    Colors.purple,
                  ),
                  _buildTarificationCard(
                    "Retrait vers compte bancaire",
                    "1,5%",
                    "Des frais minimes pour les retraits vers votre banque",
                    Icons.account_balance,
                    Colors.indigo,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Note: Les tarifs sont sujets à modification. Consultez régulièrement cette page pour les mises à jour.",
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: price.contains("Gratuit") || price.contains("0 FCFA")
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              price,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: price.contains("Gratuit") || price.contains("0 FCFA")
                    ? Colors.green
                    : Colors.black87,
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
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: const Text("Mon Profil"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // En-tête du profil
            _buildProfileHeader(),
            const SizedBox(height: 20),

            // Section "Mon activité"
            const SectionTitle(title: '🧭 Mon activité'),
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

            // Section "Mon SoutraPay"
            const SectionTitle(title: '💳 Mon SoutraPay'),
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Gratuit",
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Section "Mes interactions"
            const SectionTitle(title: '💼 Mes interactions'),
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

            // Section "Paramètres"
            const SectionTitle(title: '⚙️ Paramètres'),
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BlocProvider(
                      create: (context) => SecurityPageBlocM(
                        apiClient: ApiClient(),
                      ),
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // En-tête du profil avec photo, nom et statut
  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Photo de profil
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/profile_picture.jpg'),
            ),
          ),
          const SizedBox(height: 10),
          // Nom d'utilisateur
          Text(
            userName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          // Statut utilisateur avec icône
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _getStatusIcon(),
              const SizedBox(width: 5),
              Text(
                userStatus,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Bouton Modifier le profil
          ElevatedButton.icon(
            onPressed: () => _navigateToEditProfile(),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Modifier le profil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Retourne l'icône correspondant au statut de l'utilisateur
  Widget _getStatusIcon() {
    switch (userStatus) {
      case "Compte vérifié":
        return const Icon(Icons.verified, color: Colors.white);
      case "Premium":
        return const Icon(Icons.lock, color: Colors.white);
      default:
        return const Icon(Icons.person, color: Colors.white);
    }
  }

  // Navigation vers l'écran d'édition du profil
  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          initialUserData: {
            'nom': userName.split(' ').first,
            'prenom': userName.split(' ').length > 1
                ? userName.split(' ').skip(1).join(' ')
                : '',
            'telephone': '', // À récupérer depuis l'API
            'email': '', // À récupérer depuis l'API
            'genre': '',
            'datedenaissance': '',
            'photoProfil': 'assets/profile_picture.jpg',
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
              child: const Text("Se déconnecter",
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
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

// Widget pour les titres de section
class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

// Widget pour les éléments de menu
class MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLogout;
  final VoidCallback onTap;
  final Widget? badge; // Ajout du paramètre badge pour les indicateurs visuels

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: isLogout ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            leading: Icon(icon, color: isLogout ? Colors.red : Colors.green),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: isLogout ? Colors.red : Colors.black,
                fontWeight: isLogout ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: subtitle.isNotEmpty
                ? Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isLogout ? Colors.red.shade300 : Colors.black54,
                    ),
                  )
                : null,
            trailing: badge != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      badge!,
                      const SizedBox(width: 8),
                      isLogout
                          ? const Icon(Icons.logout, color: Colors.red)
                          : const Icon(Icons.arrow_forward_ios,
                              color: Colors.green),
                    ],
                  )
                : isLogout
                    ? const Icon(Icons.logout, color: Colors.red)
                    : const Icon(Icons.arrow_forward_ios, color: Colors.green),
          ),
        ),
      ),
    );
  }
}
