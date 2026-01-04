
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

import 'package:sdealsmobile/data/models/categorie.dart';


class SearchPageStateM extends Equatable {
  final bool isLoading;
  final String error;
  
  // 🔍 État de la recherche
  final String query;
  final List<String> suggestions;
  final List<String> history; // ✅ Ajout
  
  // 📊 Résultats groupés
  final List<dynamic> services;
  final List<dynamic> articles;
  final List<dynamic> freelances;
  final List<dynamic> prestataires;
  final List<dynamic> vendeurs;
  
  // 🎛️ Filtres
  final double minPrice;
  final double maxPrice;
  final String city;

  // 🔢 Compteurs
  final Map<String, int> counts;

  const SearchPageStateM({
    this.isLoading = false,
    this.error = '',
    this.query = '',
    this.suggestions = const [],
    this.history = const [], // ✅ Ajout
    this.services = const [],
    this.articles = const [],
    this.freelances = const [],
    this.prestataires = const [], // ✅ Ajout
    this.vendeurs = const [],
    this.minPrice = 0, // 🎛️ Filtres par défaut
    this.maxPrice = 1000000,
    this.city = '',
    this.counts = const {
      'services': 0, 
      'articles': 0, 
      'freelances': 0, 
      'prestataires': 0, // ✅ Ajout
      'vendeurs': 0
    },
  });

  factory SearchPageStateM.initial() {
    return const SearchPageStateM();
  }

  SearchPageStateM copyWith({
    bool? isLoading,
    String? error,
    String? query,
    List<String>? suggestions,
    List<String>? history, // ✅ Ajout Historique
    List<dynamic>? services,
    List<dynamic>? articles,
    List<dynamic>? freelances,
    List<dynamic>? prestataires,
    List<dynamic>? vendeurs,
    Map<String, int>? counts,
    // 🎛️ Filtres
    double? minPrice,
    double? maxPrice,
    String? city,
  }) {
    return SearchPageStateM(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      history: history ?? this.history, // ✅ Ajout
      services: services ?? this.services,
      minPrice: minPrice ?? this.minPrice, // 🎛️ Filtres
      maxPrice: maxPrice ?? this.maxPrice,
      city: city ?? this.city,
      articles: articles ?? this.articles,
      freelances: freelances ?? this.freelances,
      prestataires: prestataires ?? this.prestataires, // ✅ Ajout
      vendeurs: vendeurs ?? this.vendeurs,
      counts: counts ?? this.counts,
    );
  }

  @override
  List<Object?> get props => [
    isLoading, error, query, suggestions, history, // ✅ Ajout
    services, articles, freelances, prestataires, vendeurs, counts,
    minPrice, maxPrice, city // 🎛️ Filtres
  ];
}









