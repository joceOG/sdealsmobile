import 'service.dart';
import 'utilisateur.dart';
import '../utils/display_text.dart';
import '../utils/media_url.dart';
import '../utils/string_list_normalizer.dart';

class Prestataire {
  String idprestataire;
  Utilisateur utilisateur;
  Service service;
  double prixprestataire;
  String localisation;
  LocalisationMaps? localisationMaps; // ✅ maintenant structuré
  String? note;
  bool verifier;

  // Identité
  String? cni1;
  String? cni2;
  String? selfie;
  String? numeroCNI;

  // Métier
  List<String>? specialite;
  String? anneeExperience;
  String? description;
  double? rayonIntervention;
  List<String>? zoneIntervention;
  double? tarifHoraireMin;
  double? tarifHoraireMax;

  // Diplômes / Certificats
  List<String>? diplomeCertificat;
  String? attestationAssurance;
  String? numeroAssurance;
  String? numeroRCCM;

  Prestataire({
    required this.idprestataire,
    required this.utilisateur,
    required this.service,
    required this.prixprestataire,
    required this.localisation,
    this.localisationMaps,
    this.note,
    this.verifier = false,
    this.cni1,
    this.cni2,
    this.selfie,
    this.numeroCNI,
    this.specialite,
    this.anneeExperience,
    this.description,
    this.rayonIntervention,
    this.zoneIntervention,
    this.tarifHoraireMin,
    this.tarifHoraireMax,
    this.diplomeCertificat,
    this.attestationAssurance,
    this.numeroAssurance,
    this.numeroRCCM,
  });

  // ✅ NOUVELLE FACTORY : Convertir depuis le backend avec nouveau modèle
  factory Prestataire.fromBackend(Map<String, dynamic> json) {
    double? toDoubleOrNull(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) {
        final normalized = value.replaceAll(',', '.').trim();
        return double.tryParse(normalized);
      }
      return null;
    }

    String? toStringOrNull(dynamic value) {
      if (value == null) return null;
      final s = value.toString().trim();
      return s.isEmpty ? null : s;
    }

    List<String>? toStringListOrNull(dynamic value) =>
        normalizeStringListOrNull(value);

    /// STAB-11b : champs KYC peuvent être bool (présence) en liste publique.
    String? kycUrlOrNull(dynamic value) => kycFieldAsPublicUrl(value);

    try {
      final id = json['_id'] as String? ?? json['idprestataire'] as String? ?? '';
      final utilisateur = json['utilisateur'] != null
          ? Utilisateur.fromJson(json['utilisateur'])
          : Utilisateur(
              idutilisateur: '',
              nom: 'Inconnu',
              prenom: '',
              genre: 'Homme',
              email: '',
              password: '',
              telephone: '',
              role: 'PRESTATAIRE');

      return Prestataire(
        idprestataire: id,
        utilisateur: utilisateur,
        service: json['service'] != null
            ? Service.fromJson(json['service'])
            : Service(
                idservice: '',
                nomservice: 'Service inconnu',
                imageservice: '',
                prixmoyen: '0'),
        prixprestataire: toDoubleOrNull(json['prixprestataire']) ?? 0.0,
        localisation: json['localisation']?.toString() ?? '',
        localisationMaps: json['localisationmaps'] != null
            ? LocalisationMaps.fromJson(json['localisationmaps'])
            : null,
        note: toStringOrNull(json['note']),
        verifier: json['verifier'] as bool? ?? false,
        cni1: kycUrlOrNull(json['cni1']),
        cni2: kycUrlOrNull(json['cni2']),
        selfie: kycUrlOrNull(json['selfie']),
        numeroCNI: toStringOrNull(json['numeroCNI']),
        specialite: toStringListOrNull(json['specialite']),
        anneeExperience: toStringOrNull(json['anneeExperience']),
        description: toStringOrNull(json['description']),
        rayonIntervention: toDoubleOrNull(json['rayonIntervention']),
        zoneIntervention: toStringListOrNull(json['zoneIntervention']),
        tarifHoraireMin: toDoubleOrNull(json['tarifHoraireMin']),
        tarifHoraireMax: toDoubleOrNull(json['tarifHoraireMax']),
        diplomeCertificat: toStringListOrNull(json['diplomeCertificat']),
        attestationAssurance: kycUrlOrNull(json['attestationAssurance']),
        numeroAssurance: toStringOrNull(json['numeroAssurance']),
        numeroRCCM: toStringOrNull(json['numeroRCCM']),
      );
    } catch (e) {
      print('Erreur conversion prestataire backend: $e');
      rethrow;
    }
  }

  factory Prestataire.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    final userRaw = map['utilisateur'];
    final serviceRaw = map['service'];
    return Prestataire(
      idprestataire: map['_id']?.toString() ?? map['idprestataire']?.toString() ?? '',
      utilisateur: userRaw is Map
          ? Utilisateur.fromJson(Map<String, dynamic>.from(userRaw))
          : Utilisateur(
              idutilisateur: '',
              nom: '',
              prenom: null,
              email: '',
              password: '',
              telephone: '',
              role: 'PRESTATAIRE',
            ),
      service: serviceRaw is Map
          ? Service.fromJson(Map<String, dynamic>.from(serviceRaw))
          : Service(
              idservice: '',
              nomservice: 'Service',
              imageservice: '',
              prixmoyen: '0',
            ),
      prixprestataire: (map['prixprestataire'] as num?)?.toDouble() ?? 0.0,
      localisation: cleanDisplayPart(map['localisation']) ?? '',
      localisationMaps: map['localisationmaps'] != null
          ? LocalisationMaps.fromJson(map['localisationmaps'])
          : null,
      note: cleanDisplayPart(map['note']),
      verifier: map['verifier'] as bool? ?? false,
      cni1: kycFieldAsPublicUrl(map['cni1']),
      cni2: kycFieldAsPublicUrl(map['cni2']),
      selfie: kycFieldAsPublicUrl(map['selfie']),
      numeroCNI: map['numeroCNI'] as String?,
      specialite: normalizeStringListOrNull(map['specialite']),
      anneeExperience: cleanDisplayPart(map['anneeExperience']),
      description: cleanDisplayPart(map['description']),
      rayonIntervention: map['rayonIntervention'] != null
          ? (map['rayonIntervention'] as num).toDouble()
          : null,
      zoneIntervention: normalizeStringListOrNull(map['zoneIntervention']),
      tarifHoraireMin: map['tarifHoraireMin'] != null
          ? (map['tarifHoraireMin'] as num).toDouble()
          : null,
      tarifHoraireMax: map['tarifHoraireMax'] != null
          ? (map['tarifHoraireMax'] as num).toDouble()
          : null,
      diplomeCertificat: normalizeStringListOrNull(map['diplomeCertificat']),
      attestationAssurance: kycFieldAsPublicUrl(map['attestationAssurance']),
      numeroAssurance: map['numeroAssurance'] as String?,
      numeroRCCM: map['numeroRCCM'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': idprestataire,
      'utilisateur': utilisateur.toJson(),
      'service': service.toJson(),
      'prixprestataire': prixprestataire,
      'localisation': localisation,
      'localisationmaps': localisationMaps?.toJson(),
      'note': note,
      'verifier': verifier,
      'cni1': cni1,
      'cni2': cni2,
      'selfie': selfie,
      'numeroCNI': numeroCNI,
      'specialite': specialite,
      'anneeExperience': anneeExperience,
      'description': description,
      'rayonIntervention': rayonIntervention,
      'zoneIntervention': zoneIntervention,
      'tarifHoraireMin': tarifHoraireMin,
      'tarifHoraireMax': tarifHoraireMax,
      'diplomeCertificat': diplomeCertificat,
      'attestationAssurance': attestationAssurance,
      'numeroAssurance': numeroAssurance,
      'numeroRCCM': numeroRCCM,
    };
  }

  Map<String, dynamic> toMap() => toJson();
}

class LocalisationMaps {
  double latitude;
  double longitude;

  LocalisationMaps({required this.latitude, required this.longitude});

  factory LocalisationMaps.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return LocalisationMaps(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  Map<String, dynamic> toMap() => toJson();
}
