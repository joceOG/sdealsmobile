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

  /// Construire depuis JSON / Map
  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      idservice: json['_id'] as String? ?? json['idservice'] as String? ?? '',
      nomservice: json['nomservice'] as String? ?? '',
      imageservice: json['imageservice'] as String? ?? '',
      prixmoyen: json['prixmoyen'] as String? ?? json['prixservice']?.toString() ?? '0',
      categorie: json['categorie'] != null
          ? Categorie.fromJson(json['categorie'] as Map<String, dynamic>)
          : null,
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
