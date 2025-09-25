import 'utilisateur.dart';

class Avis {
  String id;
  Utilisateur auteur;
  String
      objetType; // PRESTATAIRE, VENDEUR, FREELANCE, ARTICLE, SERVICE, PRESTATION, COMMANDE
  String objetId;
  int note; // 1-5
  String titre;
  String commentaire;
  List<CategorieEvaluation>? categories;
  List<MediaAvis>? medias;
  bool recommande;
  int utile;
  int pasUtile;
  ReponseAvis? reponse;
  String statut; // EN_ATTENTE, PUBLIE, MODERE, SUPPRIME
  bool signale;
  List<String>? motifsSignalement;
  LocalisationAvis? localisation;
  List<String>? tags;
  bool anonyme;
  int vues;
  int partages;
  DateTime createdAt;
  DateTime updatedAt;

  Avis({
    required this.id,
    required this.auteur,
    required this.objetType,
    required this.objetId,
    required this.note,
    required this.titre,
    required this.commentaire,
    this.categories,
    this.medias,
    this.recommande = true,
    this.utile = 0,
    this.pasUtile = 0,
    this.reponse,
    this.statut = 'EN_ATTENTE',
    this.signale = false,
    this.motifsSignalement,
    this.localisation,
    this.tags,
    this.anonyme = false,
    this.vues = 0,
    this.partages = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Avis.fromJson(Map<String, dynamic> json) {
    return Avis(
      id: json['_id'] ?? json['id'] ?? '',
      auteur: Utilisateur.fromJson(json['auteur']),
      objetType: json['objetType'] ?? '',
      objetId: json['objetId'] ?? '',
      note: json['note'] ?? 0,
      titre: json['titre'] ?? '',
      commentaire: json['commentaire'] ?? '',
      categories: json['categories'] != null
          ? (json['categories'] as List)
              .map((c) => CategorieEvaluation.fromJson(c))
              .toList()
          : null,
      medias: json['medias'] != null
          ? (json['medias'] as List).map((m) => MediaAvis.fromJson(m)).toList()
          : null,
      recommande: json['recommande'] ?? true,
      utile: json['utile'] ?? 0,
      pasUtile: json['pasUtile'] ?? 0,
      reponse: json['reponse'] != null
          ? ReponseAvis.fromJson(json['reponse'])
          : null,
      statut: json['statut'] ?? 'EN_ATTENTE',
      signale: json['signale'] ?? false,
      motifsSignalement: json['motifsSignalement'] != null
          ? List<String>.from(json['motifsSignalement'])
          : null,
      localisation: json['localisation'] != null
          ? LocalisationAvis.fromJson(json['localisation'])
          : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      anonyme: json['anonyme'] ?? false,
      vues: json['vues'] ?? 0,
      partages: json['partages'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auteur': auteur.toJson(),
      'objetType': objetType,
      'objetId': objetId,
      'note': note,
      'titre': titre,
      'commentaire': commentaire,
      'categories': categories?.map((c) => c.toJson()).toList(),
      'medias': medias?.map((m) => m.toJson()).toList(),
      'recommande': recommande,
      'utile': utile,
      'pasUtile': pasUtile,
      'reponse': reponse?.toJson(),
      'statut': statut,
      'signale': signale,
      'motifsSignalement': motifsSignalement,
      'localisation': localisation?.toJson(),
      'tags': tags,
      'anonyme': anonyme,
      'vues': vues,
      'partages': partages,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Méthodes utilitaires
  double get scoreUtilite {
    final total = utile + pasUtile;
    return total > 0 ? (utile / total) * 100 : 0;
  }

  int get ageAvis {
    final now = DateTime.now();
    return now.difference(createdAt).inDays;
  }

  bool get isRecent => ageAvis <= 7; // Moins de 7 jours
  bool get isPopulaire => utile > 10; // Plus de 10 votes utiles
}

class CategorieEvaluation {
  String nom; // QUALITE, PONCTUALITE, COMMUNICATION, etc.
  int note; // 1-5

  CategorieEvaluation({
    required this.nom,
    required this.note,
  });

  factory CategorieEvaluation.fromJson(Map<String, dynamic> json) {
    return CategorieEvaluation(
      nom: json['nom'] ?? '',
      note: json['note'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'note': note,
    };
  }
}

class MediaAvis {
  String type; // IMAGE, VIDEO
  String url;
  String? description;

  MediaAvis({
    required this.type,
    required this.url,
    this.description,
  });

  factory MediaAvis.fromJson(Map<String, dynamic> json) {
    return MediaAvis(
      type: json['type'] ?? '',
      url: json['url'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'url': url,
      'description': description,
    };
  }
}

class ReponseAvis {
  String contenu;
  DateTime date;
  Utilisateur auteur;

  ReponseAvis({
    required this.contenu,
    required this.date,
    required this.auteur,
  });

  factory ReponseAvis.fromJson(Map<String, dynamic> json) {
    return ReponseAvis(
      contenu: json['contenu'] ?? '',
      date: DateTime.parse(json['date']),
      auteur: Utilisateur.fromJson(json['auteur']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contenu': contenu,
      'date': date.toIso8601String(),
      'auteur': auteur.toJson(),
    };
  }
}

class LocalisationAvis {
  String? ville;
  String? pays;

  LocalisationAvis({
    this.ville,
    this.pays,
  });

  factory LocalisationAvis.fromJson(Map<String, dynamic> json) {
    return LocalisationAvis(
      ville: json['ville'],
      pays: json['pays'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ville': ville,
      'pays': pays,
    };
  }
}



