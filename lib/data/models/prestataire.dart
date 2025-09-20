import 'utilisateur.dart';
import 'service.dart';

class LocalisationMaps {
  double latitude;
  double longitude;

  LocalisationMaps({required this.latitude, required this.longitude});

  factory LocalisationMaps.fromJson(Map<String, dynamic> json) {
    return LocalisationMaps(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  Map<String, dynamic> toMap() => toJson();
}

class Prestataire {
  String idprestataire;
  Utilisateur utilisateur;
  Service service;
  double prixprestataire;
  String localisation;
  LocalisationMaps? localisationMaps;
  String? note;
  bool verifier;

  String? cni1;
  String? cni2;
  String? selfie;
  String? numeroCNI;

  List<String>? specialite;
  String? anneeExperience;
  String? description;
  double? rayonIntervention;
  List<String>? zoneIntervention;
  double? tarifHoraireMin;
  double? tarifHoraireMax;

  List<String>? diplomeCertificat;
  String? attestationAssurance;
  String? numeroAssurance;
  String? numeroRCCM;

  double? nbMission;
  double? revenus;

  /// ✅ Liste de clients (utilisateurs)
  List<Utilisateur>? clients;

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
    this.nbMission,
    this.revenus,
    this.clients, // ✅ ajouté
  });

  /// Construire depuis Map / JSON
  factory Prestataire.fromJson(Map<String, dynamic> json) {
    return Prestataire(
      idprestataire: json['_id'] ?? '',
      utilisateur:
      Utilisateur.fromMap(json['utilisateur'] as Map<String, dynamic>),
      service: Service.fromMap(json['service'] as Map<String, dynamic>),
      prixprestataire: (json['prixprestataire'] as num).toDouble(),
      localisation: json['localisation'] ?? '',
      localisationMaps: json['localisationmaps'] != null
          ? LocalisationMaps.fromJson(
          json['localisationmaps'] as Map<String, dynamic>)
          : null,
      note: json['note'] as String?,
      verifier: json['verifier'] as bool? ?? false,
      cni1: json['cni1'] as String?,
      cni2: json['cni2'] as String?,
      selfie: json['selfie'] as String?,
      numeroCNI: json['numeroCNI'] as String?,
      specialite: json['specialite'] != null
          ? List<String>.from(json['specialite'])
          : null,
      anneeExperience: json['anneeExperience'] as String?,
      description: json['description'] as String?,
      rayonIntervention: json['rayonIntervention'] != null
          ? (json['rayonIntervention'] as num).toDouble()
          : null,
      zoneIntervention: json['zoneIntervention'] != null
          ? List<String>.from(json['zoneIntervention'])
          : null,
      tarifHoraireMin: json['tarifHoraireMin'] != null
          ? (json['tarifHoraireMin'] as num).toDouble()
          : null,
      tarifHoraireMax: json['tarifHoraireMax'] != null
          ? (json['tarifHoraireMax'] as num).toDouble()
          : null,
      diplomeCertificat: json['diplomeCertificat'] != null
          ? List<String>.from(json['diplomeCertificat'])
          : null,
      attestationAssurance: json['attestationAssurance'] as String?,
      numeroAssurance: json['numeroAssurance'] as String?,
      numeroRCCM: json['numeroRCCM'] as String?,
      nbMission:
      json['nbMission'] != null ? (json['nbMission'] as num).toDouble() : null,
      revenus:
      json['revenus'] != null ? (json['revenus'] as num).toDouble() : null,

      /// ✅ mapping des clients
      clients: json['clients'] != null
          ? (json['clients'] as List)
          .map((c) => Utilisateur.fromJson(c as Map<String, dynamic>))
          .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
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
    'nbMission': nbMission,
    'revenus': revenus,

    /// ✅ sérialisation clients
    'clients': clients?.map((c) => c.toJson()).toList(),
  };

  Map<String, dynamic> toMap() => toJson();
}
