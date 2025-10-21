import 'article.dart';
import 'vendeur.dart';

/// 🛍️ Modèle pour un article dans le panier
class CartItem {
  final String id; // ID de l'item dans le panier (subdocument _id)
  final String articleId;
  final String vendeurId;
  final String nomArticle;
  final String imageArticle;
  final double prixUnitaire;
  final int quantite;
  final double prixTotal;
  final Map<String, String> variantes;
  final DateTime dateAjout;

  // Objets complets (si populés)
  final Article? article;
  final Vendeur? vendeur;

  CartItem({
    required this.id,
    required this.articleId,
    required this.vendeurId,
    required this.nomArticle,
    required this.imageArticle,
    required this.prixUnitaire,
    required this.quantite,
    required this.prixTotal,
    this.variantes = const {},
    required this.dateAjout,
    this.article,
    this.vendeur,
  });

  /// Factory depuis JSON backend
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['_id'] ?? '',
      articleId: json['article'] is String
          ? json['article']
          : (json['article']?['_id'] ?? ''),
      vendeurId: json['vendeur'] is String
          ? json['vendeur']
          : (json['vendeur']?['_id'] ?? ''),
      nomArticle: json['nomArticle'] ?? '',
      imageArticle: json['imageArticle'] ?? '',
      prixUnitaire: (json['prixUnitaire'] ?? 0).toDouble(),
      quantite: json['quantite'] ?? 1,
      prixTotal: (json['prixTotal'] ?? 0).toDouble(),
      variantes: json['variantes'] != null
          ? Map<String, String>.from(json['variantes'])
          : {},
      dateAjout: json['dateAjout'] != null
          ? DateTime.parse(json['dateAjout'])
          : DateTime.now(),
      article:
          json['article'] is Map ? Article.fromJson(json['article']) : null,
      vendeur:
          json['vendeur'] is Map ? Vendeur.fromJson(json['vendeur']) : null,
    );
  }

  /// Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'article': articleId,
      'vendeur': vendeurId,
      'nomArticle': nomArticle,
      'imageArticle': imageArticle,
      'prixUnitaire': prixUnitaire,
      'quantite': quantite,
      'prixTotal': prixTotal,
      'variantes': variantes,
      'dateAjout': dateAjout.toIso8601String(),
    };
  }

  /// CopyWith pour modifications immutables
  CartItem copyWith({
    String? id,
    String? articleId,
    String? vendeurId,
    String? nomArticle,
    String? imageArticle,
    double? prixUnitaire,
    int? quantite,
    double? prixTotal,
    Map<String, String>? variantes,
    DateTime? dateAjout,
    Article? article,
    Vendeur? vendeur,
  }) {
    return CartItem(
      id: id ?? this.id,
      articleId: articleId ?? this.articleId,
      vendeurId: vendeurId ?? this.vendeurId,
      nomArticle: nomArticle ?? this.nomArticle,
      imageArticle: imageArticle ?? this.imageArticle,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      quantite: quantite ?? this.quantite,
      prixTotal: prixTotal ?? this.prixTotal,
      variantes: variantes ?? this.variantes,
      dateAjout: dateAjout ?? this.dateAjout,
      article: article ?? this.article,
      vendeur: vendeur ?? this.vendeur,
    );
  }
}

/// 🎁 Modèle pour un code promo
class PromoCode {
  final String code;
  final double reduction;
  final String typeReduction; // 'POURCENTAGE' ou 'MONTANT_FIXE'

  PromoCode({
    required this.code,
    required this.reduction,
    required this.typeReduction,
  });

  factory PromoCode.fromJson(Map<String, dynamic> json) {
    return PromoCode(
      code: json['code'] ?? '',
      reduction: (json['reduction'] ?? 0).toDouble(),
      typeReduction: json['typeReduction'] ?? 'MONTANT_FIXE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'reduction': reduction,
      'typeReduction': typeReduction,
    };
  }

  bool get isValid => code.isNotEmpty && reduction > 0;

  String get descriptionReduction {
    if (typeReduction == 'POURCENTAGE') {
      return '-${reduction.toStringAsFixed(0)}%';
    } else {
      return '-${reduction.toStringAsFixed(0)} FCFA';
    }
  }
}

/// 📍 Modèle pour l'adresse de livraison
class DeliveryAddress {
  final String nom; // Nom du destinataire
  final String telephone;
  final String adresse;
  final String ville;
  final String codePostal;
  final String pays;
  final String? instructions; // Instructions de livraison (optionnel)

  DeliveryAddress({
    required this.nom,
    required this.telephone,
    required this.adresse,
    required this.ville,
    required this.codePostal,
    this.pays = 'Côte d\'Ivoire',
    this.instructions,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      nom: json['nom'] ?? '',
      telephone: json['telephone'] ?? '',
      adresse: json['adresse'] ?? '',
      ville: json['ville'] ?? '',
      codePostal: json['codePostal'] ?? '',
      pays: json['pays'] ?? 'Côte d\'Ivoire',
      instructions: json['instructions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'telephone': telephone,
      'adresse': adresse,
      'ville': ville,
      'codePostal': codePostal,
      'pays': pays,
      if (instructions != null) 'instructions': instructions,
    };
  }

  bool get isComplete {
    return nom.isNotEmpty &&
        adresse.isNotEmpty &&
        ville.isNotEmpty &&
        telephone.isNotEmpty;
  }

  String get fullAddress {
    return '$adresse, $ville $codePostal, $pays';
  }
}

/// 🛒 Modèle principal du panier
class Cart {
  final String id;
  final String utilisateurId;
  final List<CartItem> articles;
  final double montantArticles;
  final double fraisLivraison;
  final double fraisService;
  final double montantTotal;
  final PromoCode? codePromo;
  final String statut;
  final DateTime? dateExpiration;
  final DateTime? dateConversion;
  final String? commandeId;
  final String? notes;
  final DeliveryAddress? adresseLivraison;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cart({
    required this.id,
    required this.utilisateurId,
    this.articles = const [],
    this.montantArticles = 0,
    this.fraisLivraison = 0,
    this.fraisService = 0,
    this.montantTotal = 0,
    this.codePromo,
    this.statut = 'ACTIF',
    this.dateExpiration,
    this.dateConversion,
    this.commandeId,
    this.notes,
    this.adresseLivraison,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory depuis JSON backend
  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['_id'] ?? '',
      utilisateurId: json['utilisateur'] is String
          ? json['utilisateur']
          : (json['utilisateur']?['_id'] ?? ''),
      articles: json['articles'] != null
          ? (json['articles'] as List)
              .map((item) => CartItem.fromJson(item))
              .toList()
          : [],
      montantArticles: (json['montantArticles'] ?? 0).toDouble(),
      fraisLivraison: (json['fraisLivraison'] ?? 0).toDouble(),
      fraisService: (json['fraisService'] ?? 0).toDouble(),
      montantTotal: (json['montantTotal'] ?? 0).toDouble(),
      codePromo: json['codePromo'] != null && json['codePromo']['code'] != null
          ? PromoCode.fromJson(json['codePromo'])
          : null,
      statut: json['statut'] ?? 'ACTIF',
      dateExpiration: json['dateExpiration'] != null
          ? DateTime.parse(json['dateExpiration'])
          : null,
      dateConversion: json['dateConversion'] != null
          ? DateTime.parse(json['dateConversion'])
          : null,
      commandeId: json['commandeId'],
      notes: json['notes'],
      adresseLivraison: json['adresseLivraison'] != null
          ? DeliveryAddress.fromJson(json['adresseLivraison'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  /// Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'utilisateur': utilisateurId,
      'articles': articles.map((item) => item.toJson()).toList(),
      'montantArticles': montantArticles,
      'fraisLivraison': fraisLivraison,
      'fraisService': fraisService,
      'montantTotal': montantTotal,
      'codePromo': codePromo?.toJson(),
      'statut': statut,
      'dateExpiration': dateExpiration?.toIso8601String(),
      'dateConversion': dateConversion?.toIso8601String(),
      'commandeId': commandeId,
      'notes': notes,
      'adresseLivraison': adresseLivraison?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// CopyWith pour modifications immutables
  Cart copyWith({
    String? id,
    String? utilisateurId,
    List<CartItem>? articles,
    double? montantArticles,
    double? fraisLivraison,
    double? fraisService,
    double? montantTotal,
    PromoCode? codePromo,
    String? statut,
    DateTime? dateExpiration,
    DateTime? dateConversion,
    String? commandeId,
    String? notes,
    DeliveryAddress? adresseLivraison,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cart(
      id: id ?? this.id,
      utilisateurId: utilisateurId ?? this.utilisateurId,
      articles: articles ?? this.articles,
      montantArticles: montantArticles ?? this.montantArticles,
      fraisLivraison: fraisLivraison ?? this.fraisLivraison,
      fraisService: fraisService ?? this.fraisService,
      montantTotal: montantTotal ?? this.montantTotal,
      codePromo: codePromo ?? this.codePromo,
      statut: statut ?? this.statut,
      dateExpiration: dateExpiration ?? this.dateExpiration,
      dateConversion: dateConversion ?? this.dateConversion,
      commandeId: commandeId ?? this.commandeId,
      notes: notes ?? this.notes,
      adresseLivraison: adresseLivraison ?? this.adresseLivraison,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Getters utiles
  bool get isEmpty => articles.isEmpty;
  bool get isNotEmpty => articles.isNotEmpty;
  int get totalItems => articles.fold(0, (sum, item) => sum + item.quantite);
  bool get isExpired =>
      dateExpiration != null && DateTime.now().isAfter(dateExpiration!);
  bool get hasPromoCode => codePromo != null && codePromo!.isValid;
  bool get hasDeliveryAddress =>
      adresseLivraison != null && adresseLivraison!.isComplete;
  bool get canCheckout => isNotEmpty && hasDeliveryAddress && !isExpired;

  /// Trouver un article dans le panier
  CartItem? findItem(String articleId, {Map<String, String>? variantes}) {
    try {
      return articles.firstWhere(
        (item) {
          final sameArticle = item.articleId == articleId;
          if (variantes == null) return sameArticle;

          final sameVariantes = item.variantes.length == variantes.length &&
              item.variantes.entries.every((e) => variantes[e.key] == e.value);

          return sameArticle && sameVariantes;
        },
      );
    } catch (e) {
      return null;
    }
  }

  /// Vérifier si un article est dans le panier
  bool containsArticle(String articleId, {Map<String, String>? variantes}) {
    final item = findItem(articleId, variantes: variantes);
    return item != null && item.id.isNotEmpty;
  }

  /// Obtenir la quantité d'un article
  int getArticleQuantity(String articleId, {Map<String, String>? variantes}) {
    final item = findItem(articleId, variantes: variantes);
    return item != null && item.id.isNotEmpty ? item.quantite : 0;
  }

  /// Panier vide par défaut
  static Cart empty(String utilisateurId) {
    return Cart(
      id: '',
      utilisateurId: utilisateurId,
      articles: [],
      montantArticles: 0,
      fraisLivraison: 0,
      fraisService: 0,
      montantTotal: 0,
      statut: 'ACTIF',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Cart(id: $id, articles: ${articles.length}, total: $montantTotal FCFA)';
  }
}
