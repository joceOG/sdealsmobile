import 'package:sdealsmobile/mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageEventM.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageStateM.dart';

import 'package:bloc/bloc.dart';

import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/models/vendeur.dart';
import 'package:sdealsmobile/data/models/cart_model.dart';
import 'package:sdealsmobile/data/services/api_client.dart';

class ShoppingPageBlocM extends Bloc<ShoppingPageEventM, ShoppingPageStateM> {
  final ApiClient _apiClient = ApiClient();

  ShoppingPageBlocM() : super(ShoppingPageStateM.initial()) {
    // Events originaux
    on<LoadCategorieDataM>(_onLoadCategorieDataM);

    // Nouveaux events pour produits et filtrage
    on<LoadProductsEvent>(_onLoadProductsEvent);
    on<ApplyFilterEvent>(_onApplyFilterEvent);
    on<SearchProductsEvent>(_onSearchProductsEvent);
    on<ApplyPriceRangeEvent>(_onApplyPriceRangeEvent);
    on<SelectBrandEvent>(_onSelectBrandEvent);
    on<SelectConditionEvent>(_onSelectConditionEvent);
    on<SelectDeliveryEvent>(_onSelectDeliveryEvent);
    on<SelectLocationEvent>(_onSelectLocationEvent);
    on<ResetFiltersEvent>(_onResetFiltersEvent);

    // Events pour les favoris
    on<ToggleFavoriteEvent>(_onToggleFavoriteEvent);

    // Events pour la comparaison
    on<AddToCompareEvent>(_onAddToCompareEvent);
    on<RemoveFromCompareEvent>(_onRemoveFromCompareEvent);
    on<ClearCompareListEvent>(_onClearCompareListEvent);

    // ✅ NOUVEAUX EVENTS POUR LES VENDEURS
    on<LoadVendeursEvent>(_onLoadVendeursEvent);
    on<ToggleViewEvent>(_onToggleViewEvent);
    on<FilterVendeursEvent>(_onFilterVendeursEvent);
    on<ToggleVendeurFavoriteEvent>(_onToggleVendeurFavoriteEvent);

    // 🛒 NOUVEAUX EVENTS POUR LE PANIER
    on<LoadCartEvent>(_onLoadCart);
    on<AddToCartEvent>(_onAddToCart);
    on<UpdateCartItemQuantityEvent>(_onUpdateCartItemQuantity);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<ClearCartEvent>(_onClearCart);
    on<ApplyPromoCodeEvent>(_onApplyPromoCode);
    on<UpdateDeliveryAddressEvent>(_onUpdateDeliveryAddress);
    on<CheckoutEvent>(_onCheckout);
  }

  // Event handler pour charger les catégories spécifiquement du groupe E-marché
  Future<void> _onLoadCategorieDataM(
    LoadCategorieDataM event,
    Emitter<ShoppingPageStateM> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: ''));

    try {
      // Utiliser le nom exact comme dans le dashboard "E-marché" (avec le trait d'union et accent)
      var nomgroupe = "E-marché";
      print("Chargement des catégories pour le groupe: $nomgroupe");
      List<Categorie> categories = await _apiClient.fetchCategorie(nomgroupe);

      // Si aucune catégorie n'est trouvée, essayer une variante sans accent
      if (categories.isEmpty) {
        nomgroupe = "E-marche"; // Sans accent
        print("Essai avec le nom de groupe: $nomgroupe");
        categories = await _apiClient.fetchCategorie(nomgroupe);
      }

      // Si toujours aucune catégorie, afficher les groupes disponibles pour le débogage
      if (categories.isEmpty) {
        print(
            'Aucune catégorie trouvée pour le groupe E-marché, affichage des groupes disponibles:');
        final allCategories = await _apiClient.fetchAllCategories();
        final groupes = allCategories.map((c) => c.groupe).toSet().toList();
        print('Groupes disponibles: $groupes');

        emit(state.copyWith(
          error: "Aucune catégorie trouvée pour le groupe E-marché",
          isLoading: false,
        ));
        return;
      }

      print('Catégories trouvées pour "$nomgroupe": ${categories.length}');
      emit(state.copyWith(
        listItems: categories,
        isLoading: false,
      ));
    } catch (e) {
      print('Erreur lors du chargement des catégories E-marché: $e');
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  // NOUVEAUX GESTIONNAIRES D'ÉVÉNEMENTS

  // Gérer le chargement des produits
  Future<void> _onLoadProductsEvent(
    LoadProductsEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      // Utiliser l'API client pour charger les articles réels
      ApiClient apiClient = ApiClient();

      // Tenter de récupérer les articles depuis l'API
      try {
        print("Tentative de chargement des articles depuis l'API...");
        final articles = await apiClient.fetchArticle();

        if (articles.isNotEmpty) {
          print("Articles récupérés avec succès: ${articles.length}");

          // Convertir les articles de l'API en objets Product
          List<Product> products = [];

          // Déboguer chaque article avant conversion
          for (var article in articles) {
            try {
              print(
                  'Article: ${article.nomArticle}, prix: ${article.prixArticle}, image: ${article.photoArticle}');

              // S'assurer que les valeurs sont valides ou fournir des valeurs par défaut
              String imageUrl = article.photoArticle;
              // Si l'URL de l'image n'est pas valide ou vide, utiliser une image par défaut
              if (imageUrl.isEmpty ||
                  (!imageUrl.startsWith('http') &&
                      !imageUrl.startsWith('https'))) {
                imageUrl = 'assets/products/default.png';
              }

              products.add(Product(
                id: article.hashCode
                    .toString(), // Utiliser hashCode comme ID unique
                name: article.nomArticle.isEmpty
                    ? 'Article sans nom'
                    : article.nomArticle,
                image: imageUrl,
                size: 'Quantité: ${article.quantiteArticle.toString()}',
                price: article.prixArticle.isEmpty
                    ? '0 FCFA'
                    : article.prixArticle,
                brand: 'Non spécifié', // Pas de champ marque disponible
                rating: 0.0, // Pas de champ note disponible
              ));
            } catch (e) {
              print('Erreur lors de la conversion de l\'article: $e');
            }
          }

          print('Produits convertis: ${products.length}');

          emit(state.copyWith(
            products: products,
            filteredProducts: products, // ✅ Initialiser filteredProducts
            isLoading: false,
          ));
          return;
        } else {
          print("Aucun article trouvé dans l'API ou erreur de récupération");
        }
      } catch (apiError) {
        print("Erreur lors de la récupération des articles: $apiError");
      }

      // Si l'API échoue, utiliser les données fictives comme fallback
      List<Product> mockProducts = [
        Product(
            id: '1',
            name: 'Nike Air Max',
            image: 'assets/products/1.png',
            size: 'Pointures 42-43',
            price: '25.000 Fcfa',
            brand: 'Nike'),
        Product(
            id: '2',
            name: 'Adidas Superstar',
            image: 'assets/products/2.png',
            size: 'Pointures 42-43',
            price: '30.000 Fcfa',
            brand: 'Adidas',
            isFavorite: false),
        Product(
            id: '3',
            name: 'Puma Suede',
            image: 'assets/products/3.png',
            size: 'Pointures 40-44',
            price: '22.000 Fcfa',
            brand: 'Puma'),
        Product(
            id: '4',
            name: 'Reebok Classic',
            image: 'assets/products/4.png',
            size: 'Pointures 41-45',
            price: '28.000 Fcfa',
            brand: 'Reebok',
            isFavorite: false),
        Product(
            id: '5',
            name: 'Fila Disruptor',
            image: 'assets/products/5.png',
            size: 'Pointures 39-43',
            price: '20.000 Fcfa',
            brand: 'Fila'),
        Product(
            id: '6',
            name: 'Converse Chuck Taylor',
            image: 'assets/products/6.png',
            size: 'Pointures 38-42',
            price: '27.000 Fcfa',
            brand: 'Converse'),
        Product(
            id: '7',
            name: 'Vans Old Skool',
            image: 'assets/products/7.png',
            size: 'Pointures 40-44',
            price: '24.000 Fcfa',
            brand: 'Vans'),
        Product(
            id: '8',
            name: 'New Balance 574',
            image: 'assets/products/8.png',
            size: 'Pointures 41-45',
            price: '29.000 Fcfa',
            brand: 'New Balance'),
        Product(
            id: '9',
            name: 'Asics Gel Lyte',
            image: 'assets/products/9.png',
            size: 'Pointures 40-43',
            price: '23.000 Fcfa',
            brand: 'Asics'),
        Product(
            id: '10',
            name: 'Air Jordan 4',
            image: 'assets/products/10.png',
            size: 'Pointures 42-46',
            price: '35.000 Fcfa',
            brand: 'Jordan',
            rating: 4.9),
      ];

      emit(state.copyWith(
          products: mockProducts,
          filteredProducts: mockProducts,
          isLoading: false));
    } catch (error) {
      emit(state.copyWith(error: error.toString(), isLoading: false));
    }
  }

  // Méthode pour filtrer les produits selon les critères actuels
  List<Product> _applyFilters(List<Product> products) {
    if (products.isEmpty) return [];

    // Commencer avec tous les produits
    List<Product> filteredList = List.from(products);

    // Appliquer filtre par recherche
    if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
      final query = state.searchQuery!.toLowerCase();
      filteredList = filteredList
          .where((product) =>
              product.name.toLowerCase().contains(query) ||
              product.brand.toLowerCase().contains(query))
          .toList();
    }

    // Appliquer filtre par marque
    if (state.selectedBrand != null && state.selectedBrand!.isNotEmpty) {
      filteredList = filteredList
          .where((product) => product.brand == state.selectedBrand)
          .toList();
    }

    // Autres filtres seraient appliqués de la même manière
    // Pour la plage de prix, on devrait convertir les string price en double

    return filteredList;
  }

  // Gérer l'application d'un filtre général
  void _onApplyFilterEvent(
    ApplyFilterEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) {
    emit(state.copyWith(selectedFilter: event.filterName));

    // Réappliquer tous les filtres
    final filteredProducts = _applyFilters(state.products ?? []);
    emit(state.copyWith(filteredProducts: filteredProducts));
  }

  // Gérer la recherche
  void _onSearchProductsEvent(
    SearchProductsEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));

    // Réappliquer tous les filtres
    final filteredProducts = _applyFilters(state.products ?? []);
    emit(state.copyWith(filteredProducts: filteredProducts));
  }

  // Gérer le filtre de plage de prix
  void _onApplyPriceRangeEvent(
    ApplyPriceRangeEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) {
    emit(state.copyWith(priceRange: event.priceRange));

    // Réappliquer tous les filtres
    final filteredProducts = _applyFilters(state.products ?? []);
    emit(state.copyWith(filteredProducts: filteredProducts));
  }

  // Gérer le filtre par marque
  void _onSelectBrandEvent(
    SelectBrandEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) {
    emit(state.copyWith(selectedBrand: event.brand));

    // Réappliquer tous les filtres
    final filteredProducts = _applyFilters(state.products ?? []);
    emit(state.copyWith(filteredProducts: filteredProducts));
  }

  // Gérer le filtre par état
  void _onSelectConditionEvent(
    SelectConditionEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) {
    emit(state.copyWith(selectedCondition: event.condition));

    // Réappliquer tous les filtres
    final filteredProducts = _applyFilters(state.products ?? []);
    emit(state.copyWith(filteredProducts: filteredProducts));
  }

  // Gérer le filtre par livraison
  void _onSelectDeliveryEvent(
    SelectDeliveryEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) {
    emit(state.copyWith(selectedDelivery: event.delivery));

    // Réappliquer tous les filtres
    final filteredProducts = _applyFilters(state.products ?? []);
    emit(state.copyWith(filteredProducts: filteredProducts));
  }

  // Gérer le filtre par localisation
  void _onSelectLocationEvent(
    SelectLocationEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) {
    emit(state.copyWith(selectedLocation: event.location));

    // Réappliquer tous les filtres
    final filteredProducts = _applyFilters(state.products ?? []);
    emit(state.copyWith(filteredProducts: filteredProducts));
  }

  // Réinitialiser tous les filtres
  void _onResetFiltersEvent(
    ResetFiltersEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) {
    emit(state.copyWith(
      selectedFilter: '',
      searchQuery: '',
      selectedBrand: null,
      priceRange: null,
      selectedCondition: null,
      selectedDelivery: null,
      selectedLocation: null,
      filteredProducts: state.products, // Remettre tous les produits
    ));
  }

  // Gérer les favoris
  void _onToggleFavoriteEvent(
    ToggleFavoriteEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) {
    final List<String> updatedFavorites =
        List.from(state.favoriteProductIds ?? []);

    // Vérifier si le produit est déjà dans les favoris
    if (updatedFavorites.contains(event.productId)) {
      updatedFavorites.remove(event.productId);
    } else {
      updatedFavorites.add(event.productId);
    }

    // Mettre à jour la liste des favoris
    emit(state.copyWith(favoriteProductIds: updatedFavorites));

    // Mettre à jour les produits pour refléter le changement
    if (state.products != null) {
      final updatedProducts = state.products!.map((product) {
        if (product.id == event.productId) {
          // Créer un nouveau produit avec isFavorite inversé
          return Product(
            id: product.id,
            name: product.name,
            image: product.image,
            size: product.size,
            price: product.price,
            brand: product.brand,
            isFavorite: updatedFavorites.contains(product.id),
            rating: product.rating,
          );
        }
        return product;
      }).toList();

      // Mettre à jour également les produits filtrés si nécessaire
      final updatedFilteredProducts = _applyFilters(updatedProducts);

      emit(state.copyWith(
        products: updatedProducts,
        filteredProducts: updatedFilteredProducts,
      ));
    }
  }

  // Gérer l'ajout d'un produit à la liste de comparaison
  void _onAddToCompareEvent(
    AddToCompareEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) {
    // Limite de 4 produits max pour la comparaison
    if ((state.productsToCompare?.length ?? 0) >= 4) {
      return; // Ne pas ajouter plus de 4 produits
    }

    // Vérifier si le produit est déjà dans la liste de comparaison
    final existingProducts = state.productsToCompare ?? [];
    if (existingProducts.any((p) => p.id == event.product.id)) {
      return; // Produit déjà dans la liste
    }

    // Ajouter le produit à la liste de comparaison
    final List<Product> updatedCompareList = List.from(existingProducts);
    updatedCompareList.add(event.product);

    emit(state.copyWith(productsToCompare: updatedCompareList));
  }

  // Gérer le retrait d'un produit de la liste de comparaison
  void _onRemoveFromCompareEvent(
    RemoveFromCompareEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) {
    final existingProducts = state.productsToCompare ?? [];
    final updatedCompareList =
        existingProducts.where((p) => p.id != event.productId).toList();

    emit(state.copyWith(productsToCompare: updatedCompareList));
  }

  // Vider la liste de comparaison
  void _onClearCompareListEvent(
    ClearCompareListEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) {
    emit(state.copyWith(productsToCompare: []));
  }

  // ✅ NOUVEAUX HANDLERS POUR LES VENDEURS

  // Event handler pour charger les vendeurs
  Future<void> _onLoadVendeursEvent(
    LoadVendeursEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: ''));

    try {
      print("Chargement des vendeurs depuis l'API...");
      List<Map<String, dynamic>> vendeursData =
          await _apiClient.fetchVendeurs();

      // ✅ NETTOYER LES DONNÉES AVANT PARSING (FIX UNICODE)
      List<Map<String, dynamic>> vendeursCleans = vendeursData.map((data) {
        return _cleanVendeurData(data);
      }).toList();

      // Convertir les données nettoyées en modèles Vendeur
      List<Vendeur> vendeurs =
          vendeursCleans.map((data) => Vendeur.fromJson(data)).toList();

      print("Vendeurs chargés: ${vendeurs.length}");

      emit(state.copyWith(
        isLoading: false,
        vendeurs: vendeurs,
        filteredVendeurs: vendeurs, // Initialement, afficher tous les vendeurs
        error: '',
      ));
    } catch (e) {
      print("Erreur lors du chargement des vendeurs: $e");
      emit(state.copyWith(
        isLoading: false,
        error: "Erreur lors du chargement des vendeurs: $e",
      ));
    }
  }

  // Event handler pour basculer entre produits et vendeurs
  void _onToggleViewEvent(
    ToggleViewEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) {
    emit(state.copyWith(showVendeurs: event.showVendeurs));

    // Charger les vendeurs si on bascule vers la vue vendeurs et qu'ils ne sont pas encore chargés
    if (event.showVendeurs &&
        (state.vendeurs == null || state.vendeurs!.isEmpty)) {
      add(LoadVendeursEvent());
    }
  }

  // Event handler pour filtrer les vendeurs
  void _onFilterVendeursEvent(
    FilterVendeursEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) {
    if (state.vendeurs == null) return;

    List<Vendeur> filteredVendeurs = state.vendeurs!.where((vendeur) {
      // Filtre par recherche textuelle
      if (event.searchQuery != null && event.searchQuery!.isNotEmpty) {
        final query = event.searchQuery!.toLowerCase();
        final matchesShopName = vendeur.shopName.toLowerCase().contains(query);
        final matchesDescription =
            vendeur.shopDescription.toLowerCase().contains(query);
        final matchesUserName =
            vendeur.utilisateur?.fullName.toLowerCase().contains(query) ??
                false;
        final matchesTags =
            vendeur.tags.any((tag) => tag.toLowerCase().contains(query));

        if (!matchesShopName &&
            !matchesDescription &&
            !matchesUserName &&
            !matchesTags) {
          return false;
        }
      }

      // Filtre par type de business
      if (event.businessType != null && event.businessType!.isNotEmpty) {
        if (vendeur.businessType != event.businessType) {
          return false;
        }
      }

      // Filtre par catégorie
      if (event.category != null && event.category!.isNotEmpty) {
        if (!vendeur.businessCategories.contains(event.category)) {
          return false;
        }
      }

      // Filtre par note minimum
      if (event.minRating != null) {
        if (vendeur.rating < event.minRating!) {
          return false;
        }
      }

      return true;
    }).toList();

    // Trier par note décroissante, puis par nombre de commandes
    filteredVendeurs.sort((a, b) {
      if (a.rating != b.rating) {
        return b.rating.compareTo(a.rating);
      }
      return b.completedOrders.compareTo(a.completedOrders);
    });

    emit(state.copyWith(
      filteredVendeurs: filteredVendeurs,
      searchQuery: event.searchQuery,
    ));
  }

  // Event handler pour ajouter/supprimer un vendeur des favoris
  void _onToggleVendeurFavoriteEvent(
    ToggleVendeurFavoriteEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) {
    List<String> favoriteIds = List.from(state.favoriteVendeurIds ?? []);

    if (favoriteIds.contains(event.vendeurId)) {
      favoriteIds.remove(event.vendeurId);
    } else {
      favoriteIds.add(event.vendeurId);
    }

    emit(state.copyWith(favoriteVendeurIds: favoriteIds));

    // TODO: Persister les favoris localement (SharedPreferences)
    print(
        "Vendeur ${event.vendeurId} ${favoriteIds.contains(event.vendeurId) ? 'ajouté aux' : 'retiré des'} favoris");
  }

  // ✅ MÉTHODE ULTRA-ROBUSTE : Nettoyer toutes les données Unicode corrompues
  Map<String, dynamic> _cleanVendeurData(Map<String, dynamic> data) {
    Map<String, dynamic> cleanData = {};

    data.forEach((key, value) {
      if (value is String) {
        // Nettoyer les strings Unicode corrompus
        cleanData[key] = _cleanUnicodeString(value);
      } else if (value is Map<String, dynamic>) {
        // Récursif pour les objets imbriqués
        cleanData[key] = _cleanVendeurData(value);
      } else if (value is List) {
        // Nettoyer les listes
        cleanData[key] = value.map((item) {
          if (item is String) {
            return _cleanUnicodeString(item);
          } else if (item is Map<String, dynamic>) {
            return _cleanVendeurData(item);
          }
          return item;
        }).toList();
      } else {
        // Garder les autres types tels quels
        cleanData[key] = value;
      }
    });

    return cleanData;
  }

  // ✅ NETTOYAGE ULTRA-DÉFENSIF DES STRINGS UNICODE
  String _cleanUnicodeString(String input) {
    if (input.isEmpty) return input;

    try {
      String cleaned = input
          // Remplacer les caractères Unicode corrompus spécifiques
          .replaceAll('�', '')
          .replaceAll('Ã´', 'ô')
          .replaceAll('Ã©', 'é')
          .replaceAll('Ã¨', 'è')
          .replaceAll('Ã ', 'à')
          .replaceAll('Ã»', 'û')
          .replaceAll('Ã§', 'ç')
          .replaceAll('Ã¢', 'â')
          .replaceAll('Ã®', 'î')
          .replaceAll('Ã¯', 'ï')
          .replaceAll('Ã¼', 'ü')
          .replaceAll('Ã«', 'ë')
          .replaceAll('Ã', 'À')
          .replaceAll('Â', '')
          // Nettoyer les bytes invisibles
          .replaceAll(RegExp(r'[\u0000-\u001F\u007F-\u009F]'), '')
          // Supprimer les caractères de contrôle
          .replaceAll(RegExp(r'[\uFFFD\uFEFF]'), '')
          .trim();

      // Si le string devient devient vide après nettoyage, retourner une valeur par défaut
      return cleaned.isEmpty ? 'Non spécifié' : cleaned;
    } catch (e) {
      print('Erreur nettoyage string: $e pour input: $input');
      return 'Non spécifié';
    }
  }

  // 🛒 ==================== HANDLERS DU PANIER ====================

  // ✅ CHARGER LE PANIER
  Future<void> _onLoadCart(
    LoadCartEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) async {
    emit(state.copyWith(isCartLoading: true, cartError: null));

    try {
      print('📦 Chargement du panier pour l\'utilisateur: ${event.userId}');

      final response = await _apiClient.getCart(event.userId);
      final cart = Cart.fromJson(response);

      print(
          '✅ Panier chargé: ${cart.articles.length} articles, total: ${cart.montantTotal} FCFA');

      emit(state.copyWith(
        cart: cart,
        isCartLoading: false,
      ));
    } catch (error) {
      print('❌ Erreur chargement panier: $error');
      emit(state.copyWith(
        cartError: 'Impossible de charger le panier: ${error.toString()}',
        isCartLoading: false,
      ));
    }
  }

  // ✅ AJOUTER UN ARTICLE AU PANIER
  Future<void> _onAddToCart(
    AddToCartEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) async {
    emit(state.copyWith(isAddingToCart: true, cartError: null));

    try {
      print(
          '🛒 Ajout au panier: Article ${event.articleId}, Quantité: ${event.quantite}');

      final response = await _apiClient.addToCart(
        userId: event.userId,
        articleId: event.articleId,
        vendeurId: event.vendeurId,
        quantite: event.quantite,
        variantes: event.variantes,
      );

      final cart = Cart.fromJson(response['cart']);

      print('✅ Article ajouté au panier. Total: ${cart.montantTotal} FCFA');

      emit(state.copyWith(
        cart: cart,
        isAddingToCart: false,
      ));
    } catch (error) {
      print('❌ Erreur ajout au panier: $error');
      emit(state.copyWith(
        cartError: 'Impossible d\'ajouter l\'article: ${error.toString()}',
        isAddingToCart: false,
      ));
    }
  }

  // ✅ MODIFIER LA QUANTITÉ D'UN ARTICLE
  Future<void> _onUpdateCartItemQuantity(
    UpdateCartItemQuantityEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) async {
    emit(state.copyWith(isCartLoading: true, cartError: null));

    try {
      print(
          '🔢 Mise à jour quantité: Item ${event.itemId}, Nouvelle quantité: ${event.quantite}');

      final response = await _apiClient.updateCartItemQuantity(
        userId: event.userId,
        itemId: event.itemId,
        quantite: event.quantite,
      );

      final cart = Cart.fromJson(response['cart']);

      print('✅ Quantité mise à jour. Total: ${cart.montantTotal} FCFA');

      emit(state.copyWith(
        cart: cart,
        isCartLoading: false,
      ));
    } catch (error) {
      print('❌ Erreur mise à jour quantité: $error');
      emit(state.copyWith(
        cartError: 'Impossible de modifier la quantité: ${error.toString()}',
        isCartLoading: false,
      ));
    }
  }

  // ✅ RETIRER UN ARTICLE DU PANIER
  Future<void> _onRemoveFromCart(
    RemoveFromCartEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) async {
    emit(state.copyWith(isCartLoading: true, cartError: null));

    try {
      print('🗑️ Retrait de l\'article: ${event.itemId}');

      final response = await _apiClient.removeFromCart(
        userId: event.userId,
        itemId: event.itemId,
      );

      final cart = Cart.fromJson(response['cart']);

      print('✅ Article retiré. Reste ${cart.articles.length} articles');

      emit(state.copyWith(
        cart: cart,
        isCartLoading: false,
      ));
    } catch (error) {
      print('❌ Erreur retrait article: $error');
      emit(state.copyWith(
        cartError: 'Impossible de retirer l\'article: ${error.toString()}',
        isCartLoading: false,
      ));
    }
  }

  // ✅ VIDER LE PANIER
  Future<void> _onClearCart(
    ClearCartEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) async {
    emit(state.copyWith(isCartLoading: true, cartError: null));

    try {
      print('🧹 Vidage du panier');

      final response = await _apiClient.clearCart(event.userId);
      final cart = Cart.fromJson(response['cart']);

      print('✅ Panier vidé');

      emit(state.copyWith(
        cart: cart,
        isCartLoading: false,
      ));
    } catch (error) {
      print('❌ Erreur vidage panier: $error');
      emit(state.copyWith(
        cartError: 'Impossible de vider le panier: ${error.toString()}',
        isCartLoading: false,
      ));
    }
  }

  // ✅ APPLIQUER UN CODE PROMO
  Future<void> _onApplyPromoCode(
    ApplyPromoCodeEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) async {
    emit(state.copyWith(isCartLoading: true, cartError: null));

    try {
      print('🎁 Application du code promo: ${event.code}');

      final response = await _apiClient.applyPromoCode(
        userId: event.userId,
        code: event.code,
        reduction: event.reduction,
        typeReduction: event.typeReduction,
      );

      final cart = Cart.fromJson(response['cart']);

      print('✅ Code promo appliqué. Nouveau total: ${cart.montantTotal} FCFA');

      emit(state.copyWith(
        cart: cart,
        isCartLoading: false,
      ));
    } catch (error) {
      print('❌ Erreur application code promo: $error');
      emit(state.copyWith(
        cartError: 'Code promo invalide: ${error.toString()}',
        isCartLoading: false,
      ));
    }
  }

  // ✅ METTRE À JOUR L'ADRESSE DE LIVRAISON
  Future<void> _onUpdateDeliveryAddress(
    UpdateDeliveryAddressEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) async {
    emit(state.copyWith(isCartLoading: true, cartError: null));

    try {
      print('📍 Mise à jour adresse de livraison: ${event.ville}');

      final response = await _apiClient.updateDeliveryAddress(
        userId: event.userId,
        nom: event.nom,
        telephone: event.telephone,
        adresse: event.adresse,
        ville: event.ville,
        codePostal: event.codePostal,
        pays: event.pays,
        instructions: event.instructions,
      );

      final cart = Cart.fromJson(response['cart']);

      print('✅ Adresse de livraison mise à jour');

      emit(state.copyWith(
        cart: cart,
        isCartLoading: false,
      ));
    } catch (error) {
      print('❌ Erreur mise à jour adresse: $error');
      emit(state.copyWith(
        cartError:
            'Impossible de mettre à jour l\'adresse: ${error.toString()}',
        isCartLoading: false,
      ));
    }
  }

  // ✅ CHECKOUT - FINALISER LA COMMANDE
  Future<void> _onCheckout(
    CheckoutEvent event,
    Emitter<ShoppingPageStateM> emit,
  ) async {
    emit(state.copyWith(isCartLoading: true, cartError: null));

    try {
      print('💳 Finalisation de la commande');

      // Vérifications avant checkout
      if (state.cart == null || state.cart!.isEmpty) {
        throw Exception('Le panier est vide');
      }

      if (!state.cart!.hasDeliveryAddress) {
        throw Exception('Veuillez ajouter une adresse de livraison');
      }

      final response = await _apiClient.checkout(
        userId: event.userId,
        moyenPaiement: event.moyenPaiement,
        notesClient: event.notesClient,
      );

      final commande = response['commande'];
      final cart = Cart.fromJson(response['cart']);

      print('✅ Commande créée avec succès! ID: ${commande['_id']}');

      emit(state.copyWith(
        cart: cart,
        isCartLoading: false,
      ));

      // TODO: Navigation vers la page de confirmation
      // ou émission d'un event de succès pour afficher un message
    } catch (error) {
      print('❌ Erreur checkout: $error');
      emit(state.copyWith(
        cartError: 'Impossible de finaliser la commande: ${error.toString()}',
        isCartLoading: false,
      ));
    }
  }
}
