import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart'; // Import pour RangeValues

import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/models/vendeur.dart';
import 'package:sdealsmobile/data/models/cart_model.dart';

// Définition du modèle Product pour éviter l'import cyclique
class Product {
  final String id;
  final String name;
  final String image;
  final String size;
  final String price;
  final String brand;
  final bool isFavorite;
  final double rating;
  final String? vendeurId; // 🛒 ID du vendeur pour ajouter au panier

  const Product({
    required this.name,
    required this.image,
    required this.size,
    required this.price,
    this.id = '',
    this.brand = 'Générique',
    this.isFavorite = false,
    this.rating = 4.5,
    this.vendeurId,
  });
}

class ShoppingPageStateM extends Equatable {
  // États d'origine pour les catégories
  final bool? isLoading;
  final List<Categorie>? listItems;
  final String? error;

  // Nouveaux états pour la gestion des produits
  final List<Product>? products; // Liste de tous les produits
  final List<Product>? filteredProducts; // Liste des produits filtrés
  final List<String>? favoriteProductIds; // IDs des produits favoris
  final List<Product>?
      productsToCompare; // Produits sélectionnés pour comparaison

  // ✅ NOUVEAUX ÉTATS POUR LES VENDEURS
  final bool
      showVendeurs; // true = afficher vendeurs, false = afficher produits
  final List<Vendeur>? vendeurs; // Liste de tous les vendeurs
  final List<Vendeur>? filteredVendeurs; // Liste des vendeurs filtrés
  final List<String>? favoriteVendeurIds; // IDs des vendeurs favoris

  // États pour les filtres
  final String? selectedFilter; // Filtre actuellement sélectionné
  final String? searchQuery; // Texte de recherche
  final String? selectedBrand; // Marque sélectionnée
  final RangeValues? priceRange; // Plage de prix sélectionnée
  final double? minPrice; // Prix minimum
  final double? maxPrice; // Prix maximum
  final String? selectedSize; // Taille sélectionnée
  final bool? onlyInStock; // En stock uniquement
  final String? selectedCondition; // État sélectionné (neuf, bon état, etc.)
  final String? selectedDelivery; // Type de livraison sélectionné
  final String? selectedLocation; // Localisation sélectionnée

  // 🛒 NOUVEAUX ÉTATS POUR LE PANIER
  final Cart? cart; // Panier actuel de l'utilisateur
  final bool isCartLoading; // Chargement du panier
  final String? cartError; // Erreur liée au panier
  final bool isAddingToCart; // Ajout en cours

  const ShoppingPageStateM({
    this.isLoading,
    this.listItems,
    this.error,
    this.products,
    this.filteredProducts,
    this.favoriteProductIds,
    this.productsToCompare,
    // ✅ NOUVEAUX PARAMÈTRES VENDEURS
    this.showVendeurs = false, // Par défaut, afficher les produits
    this.vendeurs,
    this.filteredVendeurs,
    this.favoriteVendeurIds,
    this.selectedFilter,
    this.searchQuery,
    this.selectedBrand,
    this.priceRange,
    this.minPrice,
    this.maxPrice,
    this.selectedSize,
    this.onlyInStock,
    this.selectedCondition,
    this.selectedDelivery,
    this.selectedLocation,
    // 🛒 NOUVEAUX PARAMÈTRES PANIER
    this.cart,
    this.isCartLoading = false,
    this.cartError,
    this.isAddingToCart = false,
  });

  factory ShoppingPageStateM.initial() {
    return const ShoppingPageStateM(
      isLoading: true,
      listItems: null,
      error: '',
      products: null,
      filteredProducts: null,
      favoriteProductIds: [],
      productsToCompare: [],
      selectedFilter: '',
      searchQuery: '',
      selectedBrand: null,
      priceRange: null,
      minPrice: null,
      maxPrice: null,
      selectedSize: null,
      onlyInStock: false,
      selectedCondition: null,
      selectedDelivery: null,
      selectedLocation: null,
    );
  }

  ShoppingPageStateM copyWith({
    bool? isLoading,
    List<Categorie>? listItems,
    String? error,
    List<Product>? products,
    List<Product>? filteredProducts,
    List<String>? favoriteProductIds,
    List<Product>? productsToCompare,
    // ✅ NOUVEAUX PARAMÈTRES VENDEURS
    bool? showVendeurs,
    List<Vendeur>? vendeurs,
    List<Vendeur>? filteredVendeurs,
    List<String>? favoriteVendeurIds,
    String? selectedFilter,
    String? searchQuery,
    String? selectedBrand,
    RangeValues? priceRange,
    double? minPrice,
    double? maxPrice,
    String? selectedSize,
    bool? onlyInStock,
    String? selectedCondition,
    String? selectedDelivery,
    String? selectedLocation,
    // 🛒 NOUVEAUX PARAMÈTRES PANIER
    Cart? cart,
    bool? isCartLoading,
    String? cartError,
    bool? isAddingToCart,
  }) {
    return ShoppingPageStateM(
      isLoading: isLoading ?? this.isLoading,
      listItems: listItems ?? this.listItems,
      error: error ?? this.error,
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      favoriteProductIds: favoriteProductIds ?? this.favoriteProductIds,
      productsToCompare: productsToCompare ?? this.productsToCompare,
      // ✅ NOUVEAUX PARAMÈTRES VENDEURS
      showVendeurs: showVendeurs ?? this.showVendeurs,
      vendeurs: vendeurs ?? this.vendeurs,
      filteredVendeurs: filteredVendeurs ?? this.filteredVendeurs,
      favoriteVendeurIds: favoriteVendeurIds ?? this.favoriteVendeurIds,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedBrand: selectedBrand ?? this.selectedBrand,
      priceRange: priceRange ?? this.priceRange,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      selectedSize: selectedSize ?? this.selectedSize,
      onlyInStock: onlyInStock ?? this.onlyInStock,
      selectedCondition: selectedCondition ?? this.selectedCondition,
      selectedDelivery: selectedDelivery ?? this.selectedDelivery,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      // 🛒 NOUVEAUX PARAMÈTRES PANIER
      cart: cart ?? this.cart,
      isCartLoading: isCartLoading ?? this.isCartLoading,
      cartError: cartError ?? this.cartError,
      isAddingToCart: isAddingToCart ?? this.isAddingToCart,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        listItems,
        error,
        products,
        filteredProducts,
        favoriteProductIds,
        productsToCompare,
        // ✅ NOUVEAUX PROPS VENDEURS
        showVendeurs,
        vendeurs,
        filteredVendeurs,
        favoriteVendeurIds,
        selectedFilter,
        searchQuery,
        selectedBrand,
        priceRange,
        minPrice,
        maxPrice,
        selectedSize,
        onlyInStock,
        selectedCondition,
        selectedDelivery,
        selectedLocation,
        // 🛒 NOUVEAUX PROPS PANIER
        cart,
        isCartLoading,
        cartError,
        isAddingToCart,
      ];
}
