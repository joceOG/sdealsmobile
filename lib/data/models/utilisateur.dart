import '../utils/display_text.dart';

class Utilisateur {
  String idutilisateur;
  String nom;
  String? prenom;
  String? dateNaissance;
  String? email;
  String password;
  String telephone;
  String? genre;
  String? note;
  String? photoProfil;
  List<String>? tokens;
  String? token; // ✅ Nouveau champ pour stocker le token actif
  DateTime? createdAt;
  DateTime? updatedAt;
  String role; // ✅ Champ obligatoire
  bool verifie; // ✅ Champ pour indiquer si l'utilisateur est vérifié
  bool telephoneVerified; // STAB-12D — preuve OTP téléphone

  Utilisateur({
    required this.idutilisateur,
    required this.nom,
    this.prenom,
    this.dateNaissance,
    required this.email,
    required this.password,
    required this.telephone,
    this.genre,
    this.note,
    this.photoProfil,
    this.tokens,
    this.token, // ✅
    this.createdAt,
    this.updatedAt,
    required this.role,
    this.verifie = false, // ✅ Par défaut non vérifié
    this.telephoneVerified = false,
  });

  /// STAB-12B — jamais « null alice » / « Alice null ».
  String get fullName => joinPersonName(
        prenom: prenom,
        nom: nom,
        fallback: '',
      );

  /// Convertir JSON → Utilisateur
  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      idutilisateur:
          json['_id']?.toString() ?? json['idutilisateur']?.toString() ?? '',
      nom: cleanDisplayPart(json['nom']) ?? '',
      prenom: cleanDisplayPart(json['prenom']),
      dateNaissance: cleanDisplayPart(json['datedenaissance']),
      email: cleanDisplayPart(json['email']) ?? '',
      password: json['password']?.toString() ?? '',
      telephone: cleanDisplayPart(json['telephone']) ?? '',
      genre: cleanDisplayPart(json['genre']),
      note: cleanDisplayPart(json['note']),
      photoProfil: safeImageUrl(json['photoProfil']),
      tokens: json['tokens'] != null
          ? List<String>.from(
              (json['tokens'] as List)
                  .map((t) =>
                      t is Map ? (t['token'] as String? ?? '') : t.toString())
                  .where((token) => token.isNotEmpty),
            )
          : [],
      token: json['token']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      role: cleanDisplayPart(json['role']) ?? '',
      verifie: json['verifie'] == true,
      telephoneVerified: json['telephoneVerified'] == true,
    );
  }

  /// JSON pour persistance locale / affichage.
  /// Jamais de mot de passe, JWT, refresh ni tokens FCM.
  Map<String, dynamic> toJson() {
    return {
      '_id': idutilisateur,
      'nom': nom,
      'prenom': prenom,
      'datedenaissance': dateNaissance,
      'email': email,
      'telephone': telephone,
      'genre': genre,
      'note': note,
      'photoProfil': photoProfil,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'role': role,
      'verifie': verifie,
      'telephoneVerified': telephoneVerified,
    };
  }

  /// Nettoie un JSON legacy (prefs) avant restauration.
  static Map<String, dynamic> sanitizePersistedJson(Map<String, dynamic> raw) {
    final out = Map<String, dynamic>.from(raw);
    out.remove('password');
    out.remove('token');
    out.remove('tokens');
    out.remove('refreshToken');
    out.remove('refresh_token');
    out.remove('fcmToken');
    out.remove('fcmTokens');
    return out;
  }

  Map<String, dynamic> toMap() => toJson();

  factory Utilisateur.fromMap(Map<String, dynamic> map) =>
      Utilisateur.fromJson(map);
}
