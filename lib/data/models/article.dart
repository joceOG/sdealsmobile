class Article {
  String? id;
  String nomArticle;
  String prixArticle;
  int quantiteArticle;
  String photoArticle;

  Article({
    this.id,
    required this.nomArticle,
    required this.prixArticle,
    required this.quantiteArticle,
    required this.photoArticle,
  });

  factory Article.fromJson(dynamic json) {
    final prix = json['prixArticle'];
    final prixText = prix == null ? '' : prix.toString();
    final quantite = json['quantiteArticle'];
    final rawId =
        json['_id'] ?? json['id'] ?? json['idarticle'] ?? json['idArticle'];
    return Article(
      id: rawId?.toString(),
      nomArticle: json['nomArticle'] as String,
      prixArticle: prixText,
      quantiteArticle: quantite is int
          ? quantite
          : int.tryParse(quantite.toString()) ?? 0,
      photoArticle: json['photoArticle'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nomArticle': nomArticle,
      'prixArticle': prixArticle,
      'quantiteArticle': quantiteArticle,
      'photoArticle': photoArticle,
    };
  }
}
