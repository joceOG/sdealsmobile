import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../soutrapayblocm/soutra_wallet_bloc.dart';
import '../soutrapayblocm/soutra_wallet_event.dart';

class SoutraPayActivationScreen extends StatelessWidget {
  const SoutraPayActivationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF6B35), // Orange vif
              Color(0xFFFF8E53), // Orange moyen
              Color(0xFFFFB366), // Orange clair
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo ou icône SoutraPay amélioré
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Color(0xFFF8F9FA)],
                    ),
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Titre principal amélioré
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: const Text(
                    "Activez votre portefeuille SoutraPay",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.8,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Liste à puces des avantages
                _buildBulletPoint(
                    "Recharges gratuites depuis MTN, Wave, Orange, Moov, Visa"),
                _buildBulletPoint("Transferts instantanés sécurisés"),
                _buildBulletPoint("Paiements de services sans frais"),
                _buildBulletPoint("Historique détaillé de vos transactions"),

                const SizedBox(height: 32),

                // Logos partenaires avec vraies images améliorés
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.4), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          "Partenaires de paiement",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Première ligne - Opérateurs télécom
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: _buildPartnerLogoWithImage(
                                "MTN", "assets/logos/mtn_logo.png"),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildPartnerLogoWithImage(
                                "Orange", "assets/logos/orange_logo.png"),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildPartnerLogoWithImage(
                                "Moov", "assets/logos/moov_logo.png"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Deuxième ligne - Services de paiement
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: _buildPartnerLogoWithImage(
                                "Wave", "assets/logos/wave_logo.png"),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildPartnerLogoWithImage(
                                "Visa", "assets/logos/visa_logo.png"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Bouton d'activation amélioré
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Color(0xFFF8F9FA)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      // Logique d'activation du wallet via BLoC
                      final soutraWalletBloc =
                          BlocProvider.of<SoutraWalletBloc>(context);
                      soutraWalletBloc.add(ActivateSoutraWallet());

                      // Utilisation de GoRouter pour la navigation
                      GoRouter.of(context).go('/homepage');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: const Color(0xFFFF6B35),
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.rocket_launch, size: 24),
                        SizedBox(width: 12),
                        Text(
                          "Activer maintenant",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Mention des conditions d'utilisation
                GestureDetector(
                  onTap: () {
                    // Afficher les conditions d'utilisation
                  },
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      children: [
                        TextSpan(text: "En cliquant, vous acceptez les "),
                        TextSpan(
                          text: "Conditions d'utilisation",
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            height: 12,
            width: 12,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF0F0F0)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.check,
              size: 8,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ MÉTHODE AMÉLIORÉE POUR LOGOS AVEC IMAGES
  Widget _buildPartnerLogoWithImage(String name, String imagePath) {
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8F9FA)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(-2, -2),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo image avec meilleure gestion d'erreur
            Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback amélioré si l'image n'existe pas
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getColorForPartner(name).withOpacity(0.1),
                            _getColorForPartner(name).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIconForPartner(name),
                        color: _getColorForPartner(name),
                        size: 14,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Nom du partenaire
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
              decoration: BoxDecoration(
                color: _getColorForPartner(name).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  color: _getColorForPartner(name),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Méthodes helper pour les fallbacks
  IconData _getIconForPartner(String name) {
    switch (name.toLowerCase()) {
      case 'mtn':
        return Icons.phone_android;
      case 'orange':
        return Icons.phone_android;
      case 'moov':
        return Icons.phone_android;
      case 'wave':
        return Icons.account_balance_wallet;
      case 'visa':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  Color _getColorForPartner(String name) {
    switch (name.toLowerCase()) {
      case 'mtn':
        return Colors.yellow.shade700;
      case 'orange':
        return Colors.orange.shade600;
      case 'moov':
        return Colors.blue.shade600;
      case 'wave':
        return Colors.blue.shade800;
      case 'visa':
        return Colors.blue.shade900;
      default:
        return Colors.grey.shade600;
    }
  }
}
