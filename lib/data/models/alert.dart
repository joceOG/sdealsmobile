class Alert {
  final String? id;
  final String utilisateur;
  final String titre;
  final String description;
  final String type;
  final String? sousType;
  final String? referenceId;
  final String? referenceType;
  final String statut;
  final String priorite;
  final DateTime? dateLue;
  final DateTime? dateArchivage;
  final bool envoiEmail;
  final bool envoiPush;
  final bool envoiSMS;
  final Map<String, dynamic>? donnees;
  final String? urlAction;
  final DateTime? dateExpiration;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? expediteurId;
  final String? expediteurNom;
  final String? expediteurPrenom;
  final String? expediteurPhoto;

  Alert({
    this.id,
    required this.utilisateur,
    required this.titre,
    required this.description,
    required this.type,
    this.sousType,
    this.referenceId,
    this.referenceType,
    required this.statut,
    required this.priorite,
    this.dateLue,
    this.dateArchivage,
    required this.envoiEmail,
    required this.envoiPush,
    required this.envoiSMS,
    this.donnees,
    this.urlAction,
    this.dateExpiration,
    required this.createdAt,
    required this.updatedAt,
    this.expediteurId,
    this.expediteurNom,
    this.expediteurPrenom,
    this.expediteurPhoto,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['_id'],
      utilisateur: json['utilisateur']?['_id'] ?? json['utilisateur'] ?? '',
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      sousType: json['sousType'],
      referenceId: json['referenceId'],
      referenceType: json['referenceType'],
      statut: json['statut'] ?? 'NON_LUE',
      priorite: json['priorite'] ?? 'NORMALE',
      dateLue: json['dateLue'] != null ? DateTime.parse(json['dateLue']) : null,
      dateArchivage: json['dateArchivage'] != null
          ? DateTime.parse(json['dateArchivage'])
          : null,
      envoiEmail: json['envoiEmail'] ?? false,
      envoiPush: json['envoiPush'] ?? true,
      envoiSMS: json['envoiSMS'] ?? false,
      donnees: json['donnees'] != null
          ? Map<String, dynamic>.from(json['donnees'])
          : null,
      urlAction: json['urlAction'],
      dateExpiration: json['dateExpiration'] != null
          ? DateTime.parse(json['dateExpiration'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      expediteurId: json['expediteur']?['_id'],
      expediteurNom: json['expediteur']?['nom'],
      expediteurPrenom: json['expediteur']?['prenom'],
      expediteurPhoto: json['expediteur']?['photoProfil'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'utilisateur': utilisateur,
      'titre': titre,
      'description': description,
      'type': type,
      'sousType': sousType,
      'referenceId': referenceId,
      'referenceType': referenceType,
      'statut': statut,
      'priorite': priorite,
      'dateLue': dateLue?.toIso8601String(),
      'dateArchivage': dateArchivage?.toIso8601String(),
      'envoiEmail': envoiEmail,
      'envoiPush': envoiPush,
      'envoiSMS': envoiSMS,
      'donnees': donnees,
      'urlAction': urlAction,
      'dateExpiration': dateExpiration?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'expediteur': expediteurId != null
          ? {
              '_id': expediteurId,
              'nom': expediteurNom,
              'prenom': expediteurPrenom,
              'photoProfil': expediteurPhoto,
            }
          : null,
    };
  }

  // 🔄 MÉTHODES UTILITAIRES
  bool get estLue => statut == 'LUE';
  bool get estNonLue => statut == 'NON_LUE';
  bool get estArchivee => statut == 'ARCHIVEE';
  bool get estExpiree =>
      dateExpiration != null && DateTime.now().isAfter(dateExpiration!);
  bool get estRecente => DateTime.now().difference(createdAt).inHours < 24;

  String get typeLabel {
    switch (type) {
      case 'COMMANDE':
        return 'Commande';
      case 'PRESTATION':
        return 'Prestation';
      case 'PAIEMENT':
        return 'Paiement';
      case 'VERIFICATION':
        return 'Vérification';
      case 'MESSAGE':
        return 'Message';
      case 'SYSTEME':
        return 'Système';
      case 'PROMOTION':
        return 'Promotion';
      case 'RAPPEL':
        return 'Rappel';
      default:
        return type;
    }
  }

  String get prioriteLabel {
    switch (priorite) {
      case 'BASSE':
        return 'Basse';
      case 'NORMALE':
        return 'Normale';
      case 'HAUTE':
        return 'Haute';
      case 'CRITIQUE':
        return 'Critique';
      default:
        return priorite;
    }
  }

  String get statutLabel {
    switch (statut) {
      case 'NON_LUE':
        return 'Non lue';
      case 'LUE':
        return 'Lue';
      case 'ARCHIVEE':
        return 'Archivée';
      default:
        return statut;
    }
  }

  // 🎨 COULEURS POUR L'UI
  String get typeColor {
    switch (type) {
      case 'COMMANDE':
        return 'blue';
      case 'PRESTATION':
        return 'green';
      case 'PAIEMENT':
        return 'orange';
      case 'VERIFICATION':
        return 'purple';
      case 'MESSAGE':
        return 'teal';
      case 'SYSTEME':
        return 'grey';
      case 'PROMOTION':
        return 'pink';
      case 'RAPPEL':
        return 'amber';
      default:
        return 'grey';
    }
  }

  String get prioriteColor {
    switch (priorite) {
      case 'BASSE':
        return 'green';
      case 'NORMALE':
        return 'blue';
      case 'HAUTE':
        return 'orange';
      case 'CRITIQUE':
        return 'red';
      default:
        return 'grey';
    }
  }

  String get statutColor {
    switch (statut) {
      case 'NON_LUE':
        return 'red';
      case 'LUE':
        return 'green';
      case 'ARCHIVEE':
        return 'grey';
      default:
        return 'grey';
    }
  }

  // 📱 ICÔNES POUR L'UI
  String get typeIcon {
    switch (type) {
      case 'COMMANDE':
        return 'shopping_cart';
      case 'PRESTATION':
        return 'work';
      case 'PAIEMENT':
        return 'payment';
      case 'VERIFICATION':
        return 'verified';
      case 'MESSAGE':
        return 'message';
      case 'SYSTEME':
        return 'settings';
      case 'PROMOTION':
        return 'local_offer';
      case 'RAPPEL':
        return 'schedule';
      default:
        return 'notifications';
    }
  }

  String get prioriteIcon {
    switch (priorite) {
      case 'BASSE':
        return 'keyboard_arrow_down';
      case 'NORMALE':
        return 'remove';
      case 'HAUTE':
        return 'keyboard_arrow_up';
      case 'CRITIQUE':
        return 'priority_high';
      default:
        return 'notifications';
    }
  }

  // 📅 FORMATAGE DES DATES
  String get dateFormatee {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} j';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  // 🔔 CANAUX D'ENVOI
  List<String> get canauxActifs {
    final canaux = <String>[];
    if (envoiEmail) canaux.add('Email');
    if (envoiPush) canaux.add('Push');
    if (envoiSMS) canaux.add('SMS');
    return canaux;
  }

  String get canauxFormates => canauxActifs.join(', ');

  // 📊 MÉTRIQUES
  bool get aExpire =>
      dateExpiration != null && DateTime.now().isAfter(dateExpiration!);
  bool get estUrgente => priorite == 'HAUTE' || priorite == 'CRITIQUE';
  bool get necessiteAction => urlAction != null && urlAction!.isNotEmpty;
}



