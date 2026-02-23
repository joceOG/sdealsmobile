import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _searchHistoryKey = 'search_history';

  // Récupérer l'historique
  Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_searchHistoryKey) ?? [];
  }

  // Ajouter une recherche (LIFO + Limite 10)
  Future<void> addToHistory(String query) async {
    if (query.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_searchHistoryKey) ?? [];
    
    // Déduplication : Supprimer si existe déjà pour le remettre en haut
    history.removeWhere((item) => item.toLowerCase() == query.toLowerCase());
    
    // Ajouter en haut de liste
    history.insert(0, query.trim());
    
    // Garder seulement les 10 derniers
    if (history.length > 10) {
      history = history.sublist(0, 10);
    }
    
    await prefs.setStringList(_searchHistoryKey, history);
  }

  // Effacer tout l'historique
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchHistoryKey);
  }

  // Supprimer un élément spécifique
  Future<void> removeFromHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_searchHistoryKey) ?? [];
    
    history.removeWhere((item) => item == query);
    
    await prefs.setStringList(_searchHistoryKey, history);
  }
}
