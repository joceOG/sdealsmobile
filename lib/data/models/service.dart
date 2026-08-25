import 'categorie.dart';

class Service {
  String idservice;
  String nomservice;
  String imageservice;
  String prixmoyen;
  Categorie? categorie; // nullable

  Service({
    required this.idservice,
    required this.nomservice,
    required this.imageservice,
    required this.prixmoyen,
    this.categorie,
  });

  /// Construire depuis JSON / Map (Hive peut renvoyer Map<dynamic, dynamic>).
  factory Service.fromJson(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);
    final catRaw = map['categorie'];
    return Service(
      idservice: map['_id'] as String? ?? map['idservice'] as String? ?? '',
      nomservice: map['nomservice'] as String? ?? '',
      imageservice: map['imageservice'] as String? ?? '',
      prixmoyen:
          map['prixmoyen'] as String? ?? map['prixservice']?.toString() ?? '0',
      categorie: catRaw != null ? Categorie.fromJson(catRaw) : null,
    );
  }

  /// Alias fromMap pour compatibilité
  factory Service.fromMap(Map<String, dynamic> map) => Service.fromJson(map);

  /// Convertir en Map / JSON
  Map<String, dynamic> toJson() => {
    '_id': idservice,
    'nomservice': nomservice,
    'imageservice': imageservice,
    'prixmoyen': prixmoyen,
    'categorie': categorie?.toJson(),
  };

  Map<String, dynamic> toMap() => toJson();
}
