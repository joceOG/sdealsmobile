class Article {
  String? id;
  String nomArticle;
  String prixArticle;
  int quantiteArticle;
  String photoArticle;
  /// STAB-12C — requis pour POST /cart/add
  String? vendeurId;

  Article({
    this.id,
    required this.nomArticle,
    required this.prixArticle,
    required this.quantiteArticle,
    required this.photoArticle,
    this.vendeurId,
  });

  static String? _vendeurIdFrom(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      final s = raw.trim();
      return s.isEmpty || s == 'null' ? null : s;
    }
    if (raw is Map) {
      final id = raw['_id'] ?? raw['id'];
      final s = id?.toString().trim();
      if (s == null || s.isEmpty || s == 'null') return null;
      return s;
    }
    final s = raw.toString().trim();
    return s.isEmpty || s == 'null' ? null : s;
  }

  factory Article.fromJson(dynamic json) {
    final map = json is Map<String, dynamic>
        ? json
        : Map<String, dynamic>.from(json as Map);
    final prix = map['prixArticle'];
    final prixText = prix == null ? '' : prix.toString();
    final quantite = map['quantiteArticle'];
    final rawId =
        map['_id'] ?? map['id'] ?? map['idarticle'] ?? map['idArticle'];
    final photo = map['photoArticle']?.toString() ?? '';
    final nom = map['nomArticle']?.toString() ?? '';
    return Article(
      id: rawId?.toString(),
      nomArticle: nom,
      prixArticle: prixText,
      quantiteArticle: quantite is int
          ? quantite
          : int.tryParse(quantite?.toString() ?? '') ?? 0,
      photoArticle: photo == 'null' ? '' : photo,
      vendeurId: _vendeurIdFrom(map['vendeur']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nomArticle': nomArticle,
      'prixArticle': prixArticle,
      'quantiteArticle': quantiteArticle,
      'photoArticle': photoArticle,
      if (vendeurId != null) 'vendeurId': vendeurId,
    };
  }
}
