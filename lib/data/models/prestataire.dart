import 'service.dart';
import 'utilisateur.dart';
import '../utils/display_text.dart';

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

    List<String>? toStringListOrNull(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        final out = value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        return out.isEmpty ? null : out;
      }
      return null;
    }

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
        // ✅ CORRIGÉ : Mapping correct du backend
        prixprestataire: toDoubleOrNull(json['prixprestataire']) ?? 0.0,
        // ✅ CORRIGÉ : Mapping correct du backend
        localisation: json['localisation']?.toString() ?? '',
        localisationMaps: json['localisationmaps'] != null
            ? LocalisationMaps.fromJson(json['localisationmaps'])
            : null,
        // ✅ CORRIGÉ : Mapping correct du backend
        note: toStringOrNull(json['note']),
        // ✅ CORRIGÉ : Mapping correct du backend
        verifier: json['verifier'] as bool? ?? false,
        cni1: json['cni1'] as String?,
        cni2: json['cni2'] as String?,
        selfie: json['selfie'] as String?,
        numeroCNI: json['numeroCNI'] as String?,
        // ✅ CORRIGÉ : Mapping correct du backend
        specialite: toStringListOrNull(json['specialite']),
        anneeExperience: toStringOrNull(json['anneeExperience']),
        description: toStringOrNull(json['description']),
        rayonIntervention: toDoubleOrNull(json['rayonIntervention']),
        zoneIntervention: json['zoneIntervention'] != null
            ? List<String>.from(json['zoneIntervention'])
            : null,
        tarifHoraireMin: toDoubleOrNull(json['tarifHoraireMin']),
        tarifHoraireMax: toDoubleOrNull(json['tarifHoraireMax']),
        diplomeCertificat: json['diplomeCertificat'] != null
            ? List<String>.from(json['diplomeCertificat'])
            : null,
        attestationAssurance: json['attestationAssurance'] as String?,
        numeroAssurance: json['numeroAssurance'] as String?,
        numeroRCCM: json['numeroRCCM'] as String?,
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
      cni1: map['cni1'] as String?,
      cni2: map['cni2'] as String?,
      selfie: safeImageUrl(map['selfie']),
      numeroCNI: map['numeroCNI'] as String?,
      specialite: map['specialite'] != null
          ? List<String>.from(map['specialite'])
          : null,
      anneeExperience: cleanDisplayPart(map['anneeExperience']),
      description: cleanDisplayPart(map['description']),
      rayonIntervention: map['rayonIntervention'] != null
          ? (map['rayonIntervention'] as num).toDouble()
          : null,
      zoneIntervention: map['zoneIntervention'] != null
          ? List<String>.from(map['zoneIntervention'])
          : null,
      tarifHoraireMin: map['tarifHoraireMin'] != null
          ? (map['tarifHoraireMin'] as num).toDouble()
          : null,
      tarifHoraireMax: map['tarifHoraireMax'] != null
          ? (map['tarifHoraireMax'] as num).toDouble()
          : null,
      diplomeCertificat: map['diplomeCertificat'] != null
          ? List<String>.from(map['diplomeCertificat'])
          : null,
      attestationAssurance: map['attestationAssurance'] as String?,
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
