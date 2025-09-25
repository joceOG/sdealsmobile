import 'package:sdealsmobile/data/models/utilisateur.dart';

class LocalisationFavorite {
  final String ville;
  final String pays;

  LocalisationFavorite({
    required this.ville,
    required this.pays,
  });

  factory LocalisationFavorite.fromJson(Map<String, dynamic> json) {
    return LocalisationFavorite(
      ville: json['ville'] ?? '',
      pays: json['pays'] ?? 'Côte d\'Ivoire',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ville': ville,
      'pays': pays,
    };
  }
}

class Favorite {
  final String? id;
  final Utilisateur utilisateur;
  final String
      objetType; // PRESTATAIRE, VENDEUR, FREELANCE, ARTICLE, SERVICE, PRESTATION, COMMANDE
  final String objetId;
  final String titre;
  final String? description;
  final String? image;
  final double? prix;
  final String? devise;
  final String? categorie;
  final List<String>? tags;
  final LocalisationFavorite? localisation;
  final double? note;
  final String statut; // ACTIF, ARCHIVE, SUPPRIME
  final int vues;
  final String? listePersonnalisee;
  final String? notesPersonnelles;
  final bool alertePrix;
  final bool alerteDisponibilite;
  final DateTime dateAjout;
  final DateTime dateDerniereConsultation;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Favorite({
    this.id,
    required this.utilisateur,
    required this.objetType,
    required this.objetId,
    required this.titre,
    this.description,
    this.image,
    this.prix,
    this.devise,
    this.categorie,
    this.tags,
    this.localisation,
    this.note,
    this.statut = 'ACTIF',
    this.vues = 0,
    this.listePersonnalisee,
    this.notesPersonnelles,
    this.alertePrix = false,
    this.alerteDisponibilite = false,
    required this.dateAjout,
    required this.dateDerniereConsultation,
    this.createdAt,
    this.updatedAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['_id'],
      utilisateur: Utilisateur.fromJson(json['utilisateur']),
      objetType: json['objetType'],
      objetId: json['objetId'],
      titre: json['titre'],
      description: json['description'],
      image: json['image'],
      prix: json['prix']?.toDouble(),
      devise: json['devise'],
      categorie: json['categorie'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      localisation: json['localisation'] != null
          ? LocalisationFavorite.fromJson(json['localisation'])
          : null,
      note: json['note']?.toDouble(),
      statut: json['statut'] ?? 'ACTIF',
      vues: json['vues'] ?? 0,
      listePersonnalisee: json['listePersonnalisee'],
      notesPersonnelles: json['notesPersonnelles'],
      alertePrix: json['alertePrix'] ?? false,
      alerteDisponibilite: json['alerteDisponibilite'] ?? false,
      dateAjout: DateTime.parse(json['dateAjout']),
      dateDerniereConsultation:
          DateTime.parse(json['dateDerniereConsultation']),
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'utilisateur': utilisateur.toJson(),
      'objetType': objetType,
      'objetId': objetId,
      'titre': titre,
      'description': description,
      'image': image,
      'prix': prix,
      'devise': devise,
      'categorie': categorie,
      'tags': tags,
      'localisation': localisation?.toJson(),
      'note': note,
      'statut': statut,
      'vues': vues,
      'listePersonnalisee': listePersonnalisee,
      'notesPersonnelles': notesPersonnelles,
      'alertePrix': alertePrix,
      'alerteDisponibilite': alerteDisponibilite,
      'dateAjout': dateAjout.toIso8601String(),
      'dateDerniereConsultation': dateDerniereConsultation.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // 🔄 MÉTHODES UTILITAIRES
  bool get estActif => statut == 'ACTIF';
  bool get estArchive => statut == 'ARCHIVE';
  bool get estSupprime => statut == 'SUPPRIME';

  bool get estRecent {
    final maintenant = DateTime.now();
    final difference = maintenant.difference(dateAjout);
    return difference.inDays < 7; // 7 jours
  }

  String get prixFormate {
    if (prix == null) return 'Prix non disponible';
    return '${prix!.toStringAsFixed(0)} ${devise ?? 'FCFA'}';
  }

  String get localisationFormatee {
    if (localisation == null) return 'Localisation non disponible';
    return '${localisation!.ville}, ${localisation!.pays}';
  }

  String get tagsFormates {
    if (tags == null || tags!.isEmpty) return '';
    return tags!.join(', ');
  }
}



