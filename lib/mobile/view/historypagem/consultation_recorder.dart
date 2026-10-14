import 'package:flutter/foundation.dart';

import '../../../data/services/api_client.dart';

/// Enregistre une visite réelle de profil (prestataire / freelance).
/// Échec silencieux : l’historique ne doit pas bloquer la fiche.
class ConsultationRecorder {
  ConsultationRecorder._();

  static Future<void> recordProfileVisit({
    required String objetType,
    required String objetId,
    required String titre,
    String? image,
    String? categorie,
    ApiClient? apiClient,
  }) async {
    final id = objetId.trim();
    final name = titre.trim();
    if (id.isEmpty || name.isEmpty) return;
    if (objetType != 'PRESTATAIRE' && objetType != 'FREELANCE') return;

    try {
      final client = apiClient ?? ApiClient();
      await client.post('/history', body: {
        'objetType': objetType,
        'objetId': id,
        'titre': name,
        if (image != null && image.trim().isNotEmpty) 'image': image.trim(),
        if (categorie != null && categorie.trim().isNotEmpty)
          'categorie': categorie.trim(),
        'sessionId': 'sdealsmobile',
      });
    } catch (e) {
      debugPrint('ConsultationRecorder: $e');
    }
  }
}
