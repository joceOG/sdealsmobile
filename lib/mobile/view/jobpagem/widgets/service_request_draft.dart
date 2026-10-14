import '../../../../data/services/api_client.dart';

/// Contexte fixe pour une demande ciblée (prestataire + service).
class ServiceRequestContext {
  final String token;
  final String utilisateurId;
  final String prestataireId;
  final String serviceId;
  final String serviceName;
  final String providerName;
  final String providerMetier;
  final String? providerPhotoUrl;
  final num prix;
  final ApiClient apiClient;

  const ServiceRequestContext({
    required this.token,
    required this.utilisateurId,
    required this.prestataireId,
    required this.serviceId,
    required this.serviceName,
    required this.providerName,
    required this.providerMetier,
    this.providerPhotoUrl,
    this.prix = 0,
    required this.apiClient,
  });
}

/// Saisie client — alignée sur le formulaire historique (adresse, ville, notes).
class ServiceRequestDraft {
  final String besoin;
  final String adresse;
  final String ville;
  final String precisionLieu;

  const ServiceRequestDraft({
    required this.besoin,
    required this.adresse,
    required this.ville,
    this.precisionLieu = '',
  });

  static const int besoinMaxLength = 300;

  /// `notesClient` envoyé à l’API (identique à l’ancien sheet).
  String get notesClient {
    final parts = <String>[
      if (precisionLieu.trim().isNotEmpty) 'Précision: ${precisionLieu.trim()}',
      besoin.trim(),
    ];
    return parts.join('\n');
  }

  /// Libellé lieu pour récap / succès (maquette « Cocody · Angré »).
  String get lieuAffiche {
    final a = adresse.trim();
    final v = ville.trim();
    if (a.isEmpty && v.isEmpty) return '';
    if (v.isEmpty) return a;
    if (a.isEmpty) return v;
    if (a.toLowerCase().contains(v.toLowerCase())) return a;
    return '$a · $v';
  }

  String? validateForVerification() {
    if (besoin.trim().isEmpty) {
      return 'Veuillez décrire votre besoin';
    }
    if (adresse.trim().isEmpty) {
      return 'Veuillez indiquer le lieu d\'intervention';
    }
    if (ville.trim().isEmpty) {
      return 'Veuillez saisir la ville';
    }
    if (besoin.trim().length > besoinMaxLength) {
      return 'Votre besoin ne doit pas dépasser $besoinMaxLength caractères';
    }
    return null;
  }
}

Future<Map<String, dynamic>> submitServiceRequest({
  required ServiceRequestContext context,
  required ServiceRequestDraft draft,
}) {
  return context.apiClient.createPrestation(
    token: context.token,
    utilisateurId: context.utilisateurId,
    prestataireId: context.prestataireId,
    serviceId: context.serviceId,
    adresse: draft.adresse.trim(),
    ville: draft.ville.trim(),
    notesClient: draft.notesClient,
    montant: context.prix > 0 ? context.prix : null,
  );
}
