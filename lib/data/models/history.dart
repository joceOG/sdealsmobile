class History {
  final String? id;
  final String utilisateur;
  final String objetType;
  final String? objetId;
  final String titre;
  final String? description;
  final String? image;
  final double? prix;
  final String? devise;
  final String? categorie;
  final List<String>? tags;
  final Localisation? localisation;
  final double? note;
  final String statut;
  final int dureeConsultation;
  final int nombreVues;
  final String sessionId;
  final String? userAgent;
  final String? ipAddress;
  final LocalisationUtilisateur? localisationUtilisateur;
  final String? url;
  final String? referrer;
  final List<String>? tagsConsultation;
  final Interactions? interactions;
  final List<Action>? actions;
  final DeviceInfo? deviceInfo;
  final DateTime dateConsultation;
  final DateTime dateDerniereConsultation;
  final DateTime createdAt;
  final DateTime updatedAt;

  History({
    this.id,
    required this.utilisateur,
    required this.objetType,
    this.objetId,
    required this.titre,
    this.description,
    this.image,
    this.prix,
    this.devise,
    this.categorie,
    this.tags,
    this.localisation,
    this.note,
    required this.statut,
    required this.dureeConsultation,
    required this.nombreVues,
    required this.sessionId,
    this.userAgent,
    this.ipAddress,
    this.localisationUtilisateur,
    this.url,
    this.referrer,
    this.tagsConsultation,
    this.interactions,
    this.actions,
    this.deviceInfo,
    required this.dateConsultation,
    required this.dateDerniereConsultation,
    required this.createdAt,
    required this.updatedAt,
  });

  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      id: json['_id'],
      utilisateur: json['utilisateur']?['_id'] ?? json['utilisateur'] ?? '',
      objetType: json['objetType'] ?? '',
      objetId: json['objetId'],
      titre: json['titre'] ?? '',
      description: json['description'],
      image: json['image'],
      prix: json['prix']?.toDouble(),
      devise: json['devise'],
      categorie: json['categorie'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      localisation: json['localisation'] != null
          ? Localisation.fromJson(json['localisation'])
          : null,
      note: json['note']?.toDouble(),
      statut: json['statut'] ?? 'ACTIVE',
      dureeConsultation: json['dureeConsultation'] ?? 0,
      nombreVues: json['nombreVues'] ?? 1,
      sessionId: json['sessionId'] ?? '',
      userAgent: json['userAgent'],
      ipAddress: json['ipAddress'],
      localisationUtilisateur: json['localisationUtilisateur'] != null
          ? LocalisationUtilisateur.fromJson(json['localisationUtilisateur'])
          : null,
      url: json['url'],
      referrer: json['referrer'],
      tagsConsultation: json['tagsConsultation'] != null
          ? List<String>.from(json['tagsConsultation'])
          : null,
      interactions: json['interactions'] != null
          ? Interactions.fromJson(json['interactions'])
          : null,
      actions: json['actions'] != null
          ? (json['actions'] as List)
              .map((action) => Action.fromJson(action))
              .toList()
          : null,
      deviceInfo: json['deviceInfo'] != null
          ? DeviceInfo.fromJson(json['deviceInfo'])
          : null,
      dateConsultation: DateTime.parse(json['dateConsultation']),
      dateDerniereConsultation:
          DateTime.parse(json['dateDerniereConsultation']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'utilisateur': utilisateur,
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
      'dureeConsultation': dureeConsultation,
      'nombreVues': nombreVues,
      'sessionId': sessionId,
      'userAgent': userAgent,
      'ipAddress': ipAddress,
      'localisationUtilisateur': localisationUtilisateur?.toJson(),
      'url': url,
      'referrer': referrer,
      'tagsConsultation': tagsConsultation,
      'interactions': interactions?.toJson(),
      'actions': actions?.map((action) => action.toJson()).toList(),
      'deviceInfo': deviceInfo?.toJson(),
      'dateConsultation': dateConsultation.toIso8601String(),
      'dateDerniereConsultation': dateDerniereConsultation.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // 🔄 MÉTHODES UTILITAIRES
  String get dureeFormatee {
    final heures = dureeConsultation ~/ 3600;
    final minutes = (dureeConsultation % 3600) ~/ 60;
    final secondes = dureeConsultation % 60;

    if (heures > 0) {
      return '${heures}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secondes}s';
    } else {
      return '${secondes}s';
    }
  }

  bool get estRecent {
    final maintenant = DateTime.now();
    final difference = maintenant.difference(dateConsultation);
    return difference.inHours < 24;
  }

  bool get estAujourdhui {
    final aujourdhui = DateTime.now();
    return dateConsultation.day == aujourdhui.day &&
        dateConsultation.month == aujourdhui.month &&
        dateConsultation.year == aujourdhui.year;
  }

  bool get estCetteSemaine {
    final maintenant = DateTime.now();
    final difference = maintenant.difference(dateConsultation);
    return difference.inDays < 7;
  }
}

class Localisation {
  final String? ville;
  final String? pays;

  Localisation({
    this.ville,
    this.pays,
  });

  factory Localisation.fromJson(Map<String, dynamic> json) {
    return Localisation(
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

class LocalisationUtilisateur {
  final double? latitude;
  final double? longitude;
  final String? ville;
  final String? pays;

  LocalisationUtilisateur({
    this.latitude,
    this.longitude,
    this.ville,
    this.pays,
  });

  factory LocalisationUtilisateur.fromJson(Map<String, dynamic> json) {
    return LocalisationUtilisateur(
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      ville: json['ville'],
      pays: json['pays'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'ville': ville,
      'pays': pays,
    };
  }
}

class Interactions {
  final int clics;
  final int scrolls;
  final int tempsSurPage;

  Interactions({
    required this.clics,
    required this.scrolls,
    required this.tempsSurPage,
  });

  factory Interactions.fromJson(Map<String, dynamic> json) {
    return Interactions(
      clics: json['clics'] ?? 0,
      scrolls: json['scrolls'] ?? 0,
      tempsSurPage: json['tempsSurPage'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clics': clics,
      'scrolls': scrolls,
      'tempsSurPage': tempsSurPage,
    };
  }
}

class Action {
  final String type;
  final DateTime timestamp;
  final String? details;

  Action({
    required this.type,
    required this.timestamp,
    this.details,
  });

  factory Action.fromJson(Map<String, dynamic> json) {
    return Action(
      type: json['type'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      details: json['details'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
    };
  }
}

class DeviceInfo {
  final String type;
  final String? os;
  final String? browser;
  final String? version;

  DeviceInfo({
    required this.type,
    this.os,
    this.browser,
    this.version,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      type: json['type'] ?? '',
      os: json['os'],
      browser: json['browser'],
      version: json['version'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'os': os,
      'browser': browser,
      'version': version,
    };
  }
}



