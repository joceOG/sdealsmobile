class UserPreferences {
  final String? id;
  final String utilisateur;
  final String langue;
  final String devise;
  final String pays;
  final String fuseauHoraire;
  final String formatDate;
  final String formatHeure;
  final String formatMonetaire;
  final String theme;
  final NotificationPreferences notifications;
  final LocalisationPreferences localisation;
  final RecherchePreferences recherche;
  final SecuritePreferences securite;
  final AnalyticsPreferences analytics;
  final AccessibilitePreferences accessibilite;
  final MobilePreferences mobile;
  final DateTime derniereModification;
  final String version;

  UserPreferences({
    this.id,
    required this.utilisateur,
    required this.langue,
    required this.devise,
    required this.pays,
    required this.fuseauHoraire,
    required this.formatDate,
    required this.formatHeure,
    required this.formatMonetaire,
    required this.theme,
    required this.notifications,
    required this.localisation,
    required this.recherche,
    required this.securite,
    required this.analytics,
    required this.accessibilite,
    required this.mobile,
    required this.derniereModification,
    required this.version,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      id: json['_id'],
      utilisateur: json['utilisateur']?['_id'] ?? json['utilisateur'] ?? '',
      langue: json['langue'] ?? 'fr',
      devise: json['devise'] ?? 'FCFA',
      pays: json['pays'] ?? 'CI',
      fuseauHoraire: json['fuseauHoraire'] ?? 'Africa/Abidjan',
      formatDate: json['formatDate'] ?? 'DD/MM/YYYY',
      formatHeure: json['formatHeure'] ?? '24h',
      formatMonetaire: json['formatMonetaire'] ?? '1 234,56',
      theme: json['theme'] ?? 'light',
      notifications:
          NotificationPreferences.fromJson(json['notifications'] ?? {}),
      localisation:
          LocalisationPreferences.fromJson(json['localisation'] ?? {}),
      recherche: RecherchePreferences.fromJson(json['recherche'] ?? {}),
      securite: SecuritePreferences.fromJson(json['securite'] ?? {}),
      analytics: AnalyticsPreferences.fromJson(json['analytics'] ?? {}),
      accessibilite:
          AccessibilitePreferences.fromJson(json['accessibilite'] ?? {}),
      mobile: MobilePreferences.fromJson(json['mobile'] ?? {}),
      derniereModification: DateTime.parse(
          json['derniereModification'] ?? DateTime.now().toIso8601String()),
      version: json['version'] ?? '1.0.0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'utilisateur': utilisateur,
      'langue': langue,
      'devise': devise,
      'pays': pays,
      'fuseauHoraire': fuseauHoraire,
      'formatDate': formatDate,
      'formatHeure': formatHeure,
      'formatMonetaire': formatMonetaire,
      'theme': theme,
      'notifications': notifications.toJson(),
      'localisation': localisation.toJson(),
      'recherche': recherche.toJson(),
      'securite': securite.toJson(),
      'analytics': analytics.toJson(),
      'accessibilite': accessibilite.toJson(),
      'mobile': mobile.toJson(),
      'derniereModification': derniereModification.toIso8601String(),
      'version': version,
    };
  }

  // 🔄 MÉTHODES UTILITAIRES
  bool get estFrancophone =>
      ['fr', 'CI', 'SN', 'ML', 'BF', 'NE', 'TG', 'BJ'].contains(langue) ||
      ['CI', 'SN', 'ML', 'BF', 'NE', 'TG', 'BJ'].contains(pays);

  bool get estAnglophone => langue == 'en' || ['US', 'GH', 'NG'].contains(pays);

  String get deviseLocale {
    const deviseParPays = {
      'CI': 'FCFA',
      'SN': 'FCFA',
      'ML': 'FCFA',
      'BF': 'FCFA',
      'NE': 'FCFA',
      'TG': 'FCFA',
      'BJ': 'FCFA',
      'FR': 'EUR',
      'US': 'USD'
    };
    return deviseParPays[pays] ?? devise;
  }

  String get langueLabel {
    switch (langue) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'pt':
        return 'Português';
      case 'ar':
        return 'العربية';
      default:
        return langue;
    }
  }

  String get deviseLabel {
    switch (devise) {
      case 'FCFA':
        return 'Franc CFA';
      case 'EUR':
        return 'Euro';
      case 'USD':
        return 'Dollar US';
      case 'XOF':
        return 'Franc CFA (XOF)';
      case 'XAF':
        return 'Franc CFA (XAF)';
      default:
        return devise;
    }
  }

  String get paysLabel {
    switch (pays) {
      case 'CI':
        return 'Côte d\'Ivoire';
      case 'FR':
        return 'France';
      case 'US':
        return 'États-Unis';
      case 'SN':
        return 'Sénégal';
      case 'ML':
        return 'Mali';
      case 'BF':
        return 'Burkina Faso';
      case 'NE':
        return 'Niger';
      case 'TG':
        return 'Togo';
      case 'BJ':
        return 'Bénin';
      case 'GH':
        return 'Ghana';
      case 'NG':
        return 'Nigeria';
      default:
        return pays;
    }
  }

  String get drapeau {
    switch (pays) {
      case 'CI':
        return '🇨🇮';
      case 'FR':
        return '🇫🇷';
      case 'US':
        return '🇺🇸';
      case 'SN':
        return '🇸🇳';
      case 'ML':
        return '🇲🇱';
      case 'BF':
        return '🇧🇫';
      case 'NE':
        return '🇳🇪';
      case 'TG':
        return '🇹🇬';
      case 'BJ':
        return '🇧🇯';
      case 'GH':
        return '🇬🇭';
      case 'NG':
        return '🇳🇬';
      default:
        return '🌍';
    }
  }

  String get symboleDevise {
    switch (devise) {
      case 'FCFA':
        return 'FCFA';
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      case 'XOF':
        return 'F';
      case 'XAF':
        return 'F';
      default:
        return devise;
    }
  }

  // 📱 MÉTHODES DE COPIE
  UserPreferences copyWith({
    String? id,
    String? utilisateur,
    String? langue,
    String? devise,
    String? pays,
    String? fuseauHoraire,
    String? formatDate,
    String? formatHeure,
    String? formatMonetaire,
    String? theme,
    NotificationPreferences? notifications,
    LocalisationPreferences? localisation,
    RecherchePreferences? recherche,
    SecuritePreferences? securite,
    AnalyticsPreferences? analytics,
    AccessibilitePreferences? accessibilite,
    MobilePreferences? mobile,
    DateTime? derniereModification,
    String? version,
  }) {
    return UserPreferences(
      id: id ?? this.id,
      utilisateur: utilisateur ?? this.utilisateur,
      langue: langue ?? this.langue,
      devise: devise ?? this.devise,
      pays: pays ?? this.pays,
      fuseauHoraire: fuseauHoraire ?? this.fuseauHoraire,
      formatDate: formatDate ?? this.formatDate,
      formatHeure: formatHeure ?? this.formatHeure,
      formatMonetaire: formatMonetaire ?? this.formatMonetaire,
      theme: theme ?? this.theme,
      notifications: notifications ?? this.notifications,
      localisation: localisation ?? this.localisation,
      recherche: recherche ?? this.recherche,
      securite: securite ?? this.securite,
      analytics: analytics ?? this.analytics,
      accessibilite: accessibilite ?? this.accessibilite,
      mobile: mobile ?? this.mobile,
      derniereModification: derniereModification ?? this.derniereModification,
      version: version ?? this.version,
    );
  }
}

class NotificationPreferences {
  final bool email;
  final bool push;
  final bool sms;
  final String langue;

  NotificationPreferences({
    required this.email,
    required this.push,
    required this.sms,
    required this.langue,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      email: json['email'] ?? true,
      push: json['push'] ?? true,
      sms: json['sms'] ?? false,
      langue: json['langue'] ?? 'fr',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'push': push,
      'sms': sms,
      'langue': langue,
    };
  }
}

class LocalisationPreferences {
  final String? ville;
  final String? codePostal;
  final Coordonnees? coordonnees;

  LocalisationPreferences({
    this.ville,
    this.codePostal,
    this.coordonnees,
  });

  factory LocalisationPreferences.fromJson(Map<String, dynamic> json) {
    return LocalisationPreferences(
      ville: json['ville'],
      codePostal: json['codePostal'],
      coordonnees: json['coordonnees'] != null
          ? Coordonnees.fromJson(json['coordonnees'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ville': ville,
      'codePostal': codePostal,
      'coordonnees': coordonnees?.toJson(),
    };
  }
}

class Coordonnees {
  final double latitude;
  final double longitude;

  Coordonnees({
    required this.latitude,
    required this.longitude,
  });

  factory Coordonnees.fromJson(Map<String, dynamic> json) {
    return Coordonnees(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class RecherchePreferences {
  final int rayon;
  final String triParDefaut;
  final bool afficherPrix;

  RecherchePreferences({
    required this.rayon,
    required this.triParDefaut,
    required this.afficherPrix,
  });

  factory RecherchePreferences.fromJson(Map<String, dynamic> json) {
    return RecherchePreferences(
      rayon: json['rayon'] ?? 10,
      triParDefaut: json['triParDefaut'] ?? 'distance',
      afficherPrix: json['afficherPrix'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rayon': rayon,
      'triParDefaut': triParDefaut,
      'afficherPrix': afficherPrix,
    };
  }
}

class SecuritePreferences {
  final bool authentificationDoubleFacteur;
  final bool notificationsConnexion;
  final bool partageDonnees;

  SecuritePreferences({
    required this.authentificationDoubleFacteur,
    required this.notificationsConnexion,
    required this.partageDonnees,
  });

  factory SecuritePreferences.fromJson(Map<String, dynamic> json) {
    return SecuritePreferences(
      authentificationDoubleFacteur:
          json['authentificationDoubleFacteur'] ?? false,
      notificationsConnexion: json['notificationsConnexion'] ?? true,
      partageDonnees: json['partageDonnees'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authentificationDoubleFacteur': authentificationDoubleFacteur,
      'notificationsConnexion': notificationsConnexion,
      'partageDonnees': partageDonnees,
    };
  }
}

class AnalyticsPreferences {
  final bool partageDonneesUsage;
  final bool cookies;

  AnalyticsPreferences({
    required this.partageDonneesUsage,
    required this.cookies,
  });

  factory AnalyticsPreferences.fromJson(Map<String, dynamic> json) {
    return AnalyticsPreferences(
      partageDonneesUsage: json['partageDonneesUsage'] ?? true,
      cookies: json['cookies'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'partageDonneesUsage': partageDonneesUsage,
      'cookies': cookies,
    };
  }
}

class AccessibilitePreferences {
  final String taillePolice;
  final String contraste;
  final bool lecteurEcran;

  AccessibilitePreferences({
    required this.taillePolice,
    required this.contraste,
    required this.lecteurEcran,
  });

  factory AccessibilitePreferences.fromJson(Map<String, dynamic> json) {
    return AccessibilitePreferences(
      taillePolice: json['taillePolice'] ?? 'normale',
      contraste: json['contraste'] ?? 'normal',
      lecteurEcran: json['lecteurEcran'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taillePolice': taillePolice,
      'contraste': contraste,
      'lecteurEcran': lecteurEcran,
    };
  }
}

class MobilePreferences {
  final bool vibrations;
  final bool son;
  final String orientation;

  MobilePreferences({
    required this.vibrations,
    required this.son,
    required this.orientation,
  });

  factory MobilePreferences.fromJson(Map<String, dynamic> json) {
    return MobilePreferences(
      vibrations: json['vibrations'] ?? true,
      son: json['son'] ?? true,
      orientation: json['orientation'] ?? 'auto',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vibrations': vibrations,
      'son': son,
      'orientation': orientation,
    };
  }
}



