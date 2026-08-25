import 'package:sdealsmobile/data/models/groupe.dart';

class Categorie {
  String idcategorie;
  String nomcategorie;
  String imagecategorie;
  Groupe groupe; // objet

  Categorie({
    required this.idcategorie,
    required this.nomcategorie,
    required this.imagecategorie,
    required this.groupe,
  });

  factory Categorie.fromJson(dynamic json) {
    // Hive / cache renvoie souvent Map<dynamic, dynamic>, pas Map<String, dynamic>.
    final map = Map<String, dynamic>.from(json as Map);
    final g = map['groupe'];
    return Categorie(
      idcategorie: map['_id'] as String? ?? map['idcategorie'] as String? ?? '',
      nomcategorie: map['nomcategorie'] as String? ?? '',
      imagecategorie: map['imagecategorie'] as String? ?? '',
      // Gère populate (Map) ou simple ObjectId string
      groupe: g is Map
          ? Groupe.fromJson(Map<String, dynamic>.from(g))
          : Groupe(
              idgroupe: g?.toString() ?? '',
              nomgroupe: '',
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': idcategorie,
      'nomcategorie': nomcategorie,
      'imagecategorie': imagecategorie,
      'groupe': groupe.toJson(),
    };
  }

  // Optionnel : alias pour compat
  Map<String, dynamic> toMap() => toJson();
}
