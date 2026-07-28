import 'package:flutter/material.dart';
import '../screens/provider_profile_screen.dart';
import '../screens/detailPageScreenM.dart';

/// 🎯 Helper de navigation pour une gestion propre et type-safe
/// des navigations vers les profils et détails
class NavigationHelper {
  /// Navigation vers le profil complet d'un prestataire
  /// 
  /// [providerId] : ID unique du prestataire (obligatoire)
  /// [providerData] : Données optionnelles en cache pour affichage instantané
  static void navigateToProviderProfile(
    BuildContext context, {
    required String providerId,
    Map<String, dynamic>? providerData,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderProfileScreen(
          providerId: providerId,
          providerData: providerData,
        ),
      ),
    );
  }

  /// Navigation vers les détails d'un service
  /// 
  /// [serviceName] : Nom du service (obligatoire)
  /// [serviceId] : ID optionnel du service
  /// [imageUrl] : URL de l'image du service
  static void navigateToServiceDetails(
    BuildContext context, {
    required String serviceName,
    String? serviceId,
    required String imageUrl,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPage(
          title: serviceName,
          image: imageUrl,
          serviceId: serviceId,
        ),
      ),
    );
  }

  /// Navigation vers les détails d'une catégorie
  /// (utilise la même page que les services)
  static void navigateToCategoryDetails(
    BuildContext context, {
    required String categoryName,
    required String imageUrl,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPage(
          title: categoryName,
          image: imageUrl,
        ),
      ),
    );
  }
}

