import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:sdealsmobile/data/models/categorie.dart';

import 'shoppingPageStateM.dart';

abstract class ShoppingPageEventM extends Equatable {
  const ShoppingPageEventM();

  @override
  List<Object> get props => [];
}

// Événements d'origine
class LoadCategorieDataM extends ShoppingPageEventM {}

// Nouveaux événements pour la gestion des produits
class LoadProductsEvent extends ShoppingPageEventM {}

// Événements pour le filtrage des produits
class ApplyFilterEvent extends ShoppingPageEventM {
  final String filterName;

  const ApplyFilterEvent(this.filterName);

  @override
  List<Object> get props => [filterName];
}

class SearchProductsEvent extends ShoppingPageEventM {
  final String query;

  const SearchProductsEvent(this.query);

  @override
  List<Object> get props => [query];
}

class ApplyPriceRangeEvent extends ShoppingPageEventM {
  final RangeValues priceRange;

  const ApplyPriceRangeEvent(this.priceRange);

  @override
  List<Object> get props => [priceRange];
}

class SelectBrandEvent extends ShoppingPageEventM {
  final String brand;

  const SelectBrandEvent(this.brand);

  @override
  List<Object> get props => [brand];
}

class SelectConditionEvent extends ShoppingPageEventM {
  final String condition;

  const SelectConditionEvent(this.condition);

  @override
  List<Object> get props => [condition];
}

class SelectDeliveryEvent extends ShoppingPageEventM {
  final String delivery;

  const SelectDeliveryEvent(this.delivery);

  @override
  List<Object> get props => [delivery];
}

class SelectLocationEvent extends ShoppingPageEventM {
  final String location;

  const SelectLocationEvent(this.location);

  @override
  List<Object> get props => [location];
}

class ResetFiltersEvent extends ShoppingPageEventM {}

// Événements pour la gestion des favoris
class ToggleFavoriteEvent extends ShoppingPageEventM {
  final String productId;

  const ToggleFavoriteEvent(this.productId);

  @override
  List<Object> get props => [productId];
}

// Événements pour la comparaison de produits
class AddToCompareEvent extends ShoppingPageEventM {
  final Product product;

  const AddToCompareEvent(this.product);

  @override
  List<Object> get props => [product];
}

class RemoveFromCompareEvent extends ShoppingPageEventM {
  final String productId;

  const RemoveFromCompareEvent(this.productId);

  @override
  List<Object> get props => [productId];
}

class ClearCompareListEvent extends ShoppingPageEventM {}

// Événement pour les filtres avancés
class ApplyAdvancedFiltersEvent extends ShoppingPageEventM {
  final double minPrice;
  final double maxPrice;
  final String? brand;
  final String? size;
  final bool onlyInStock;

  const ApplyAdvancedFiltersEvent({
    required this.minPrice,
    required this.maxPrice,
    this.brand,
    this.size,
    this.onlyInStock = false,
  });

  @override
  List<Object> get props => [
        minPrice,
        maxPrice,
        brand ?? '',
        size ?? '',
        onlyInStock,
      ];
}

// ✅ NOUVEAUX ÉVÉNEMENTS POUR LES VENDEURS

// Événement pour charger les vendeurs
class LoadVendeursEvent extends ShoppingPageEventM {}

// Événement pour basculer entre produits et vendeurs
class ToggleViewEvent extends ShoppingPageEventM {
  final bool showVendeurs;

  const ToggleViewEvent({required this.showVendeurs});

  @override
  List<Object> get props => [showVendeurs];
}

// Événement pour filtrer les vendeurs
class FilterVendeursEvent extends ShoppingPageEventM {
  final String? searchQuery;
  final String? businessType;
  final String? category;
  final double? minRating;

  const FilterVendeursEvent({
    this.searchQuery,
    this.businessType,
    this.category,
    this.minRating,
  });

  @override
  List<Object> get props => [
        searchQuery ?? '',
        businessType ?? '',
        category ?? '',
        minRating ?? 0.0,
      ];
}

// Événement pour ajouter/supprimer un vendeur des favoris
class ToggleVendeurFavoriteEvent extends ShoppingPageEventM {
  final String vendeurId;

  const ToggleVendeurFavoriteEvent({required this.vendeurId});

  @override
  List<Object> get props => [vendeurId];
}

// 🛒 NOUVEAUX ÉVÉNEMENTS POUR LE PANIER

// Événement pour charger le panier
class LoadCartEvent extends ShoppingPageEventM {
  final String userId;

  const LoadCartEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

// Événement pour ajouter un article au panier
class AddToCartEvent extends ShoppingPageEventM {
  final String userId;
  final String articleId;
  final String vendeurId;
  final int quantite;
  final Map<String, String>? variantes;

  const AddToCartEvent({
    required this.userId,
    required this.articleId,
    required this.vendeurId,
    this.quantite = 1,
    this.variantes,
  });

  @override
  List<Object> get props =>
      [userId, articleId, vendeurId, quantite, variantes ?? {}];
}

// Événement pour modifier la quantité d'un article
class UpdateCartItemQuantityEvent extends ShoppingPageEventM {
  final String userId;
  final String itemId;
  final int quantite;

  const UpdateCartItemQuantityEvent({
    required this.userId,
    required this.itemId,
    required this.quantite,
  });

  @override
  List<Object> get props => [userId, itemId, quantite];
}

// Événement pour retirer un article du panier
class RemoveFromCartEvent extends ShoppingPageEventM {
  final String userId;
  final String itemId;

  const RemoveFromCartEvent({
    required this.userId,
    required this.itemId,
  });

  @override
  List<Object> get props => [userId, itemId];
}

// Événement pour vider le panier
class ClearCartEvent extends ShoppingPageEventM {
  final String userId;

  const ClearCartEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

// Événement pour appliquer un code promo
class ApplyPromoCodeEvent extends ShoppingPageEventM {
  final String userId;
  final String code;
  final double reduction;
  final String typeReduction;

  const ApplyPromoCodeEvent({
    required this.userId,
    required this.code,
    required this.reduction,
    this.typeReduction = 'MONTANT_FIXE',
  });

  @override
  List<Object> get props => [userId, code, reduction, typeReduction];
}

// Événement pour mettre à jour l'adresse de livraison
class UpdateDeliveryAddressEvent extends ShoppingPageEventM {
  final String userId;
  final String nom;
  final String telephone;
  final String adresse;
  final String ville;
  final String codePostal;
  final String pays;
  final String? instructions;

  const UpdateDeliveryAddressEvent({
    required this.userId,
    required this.nom,
    required this.telephone,
    required this.adresse,
    required this.ville,
    required this.codePostal,
    this.pays = 'Côte d\'Ivoire',
    this.instructions,
  });

  @override
  List<Object> get props => [
        userId,
        nom,
        telephone,
        adresse,
        ville,
        codePostal,
        pays,
        instructions ?? ''
      ];
}

// Événement pour finaliser la commande (checkout)
class CheckoutEvent extends ShoppingPageEventM {
  final String userId;
  final String? moyenPaiement;
  final String? notesClient;

  const CheckoutEvent({
    required this.userId,
    this.moyenPaiement,
    this.notesClient,
  });

  @override
  List<Object> get props => [userId, moyenPaiement ?? '', notesClient ?? ''];
}
