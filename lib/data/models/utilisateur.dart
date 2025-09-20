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
  });

  /// Convertir JSON → Utilisateur
  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      idutilisateur: json['_id'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'],
      dateNaissance: json['datedenaissance'],
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      telephone: json['telephone'] ?? '',
      genre: json['genre'],
      note: json['note'],
      photoProfil: json['photoProfil'],
      tokens: json['tokens'] != null
          ? List<String>.from(
        (json['tokens'] as List).map((t) => t['token'] as String),
      )
          : [],
      token: json['token'], // ✅ pris en compte si présent dans la réponse API
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      role: json['role'] ?? '',
    );
  }

  /// Convertir Utilisateur → JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': idutilisateur,
      'nom': nom,
      'prenom': prenom,
      'datedenaissance': dateNaissance,
      'email': email,
      'password': password,
      'telephone': telephone,
      'genre': genre,
      'note': note,
      'photoProfil': photoProfil,
      'tokens': tokens != null
          ? tokens!.map((t) => {'token': t}).toList()
          : [],
      'token': token, // ✅ exporté aussi
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'role': role,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  factory Utilisateur.fromMap(Map<String, dynamic> map) =>
      Utilisateur.fromJson(map);
}
