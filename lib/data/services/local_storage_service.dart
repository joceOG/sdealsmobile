import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Recherche récente persistée localement.
///
/// [at] et [scope] sont absents pour les anciennes chaînes brutes :
/// on n’invente ni date ni univers.
class SearchHistoryEntry {
  final String query;
  final DateTime? at;
  final String? scope;

  const SearchHistoryEntry({
    required this.query,
    this.at,
    this.scope,
  });
}

class LocalStorageService {
  static const String _searchHistoryKey = 'search_history';
  static const int _maxEntries = 10;

  Future<List<String>> getSearchHistory() async {
    final entries = await getSearchHistoryEntries();
    return entries.map((e) => e.query).toList();
  }

  Future<List<SearchHistoryEntry>> getSearchHistoryEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_searchHistoryKey) ?? [];
    final seen = <String>{};
    final cleaned = <SearchHistoryEntry>[];
    final encoded = <String>[];

    for (final item in raw) {
      final entry = _parseEntry(item);
      if (entry == null) continue;
      final key = entry.query.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      cleaned.add(entry);
      encoded.add(_encodeEntry(entry));
    }

    if (encoded.length != raw.length || !_sameList(encoded, raw)) {
      await prefs.setStringList(_searchHistoryKey, encoded);
    }
    return cleaned;
  }

  Future<void> addToHistory(String query, {String? scope}) async {
    final q = query.trim();
    if (q.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_searchHistoryKey) ?? [];
    final entries = <SearchHistoryEntry>[];
    for (final item in raw) {
      final entry = _parseEntry(item);
      if (entry == null) continue;
      if (entry.query.toLowerCase() == q.toLowerCase()) continue;
      entries.add(entry);
    }

    final resolvedScope =
        (scope == null || scope.trim().isEmpty) ? null : scope.trim();
    entries.insert(
      0,
      SearchHistoryEntry(
        query: q,
        at: DateTime.now().toUtc(),
        scope: resolvedScope,
      ),
    );

    final kept = entries.length > _maxEntries
        ? entries.sublist(0, _maxEntries)
        : entries;
    await prefs.setStringList(
      _searchHistoryKey,
      kept.map(_encodeEntry).toList(),
    );
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchHistoryKey);
  }

  Future<void> removeFromHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_searchHistoryKey) ?? [];
    final target = query.trim().toLowerCase();
    final kept = <String>[];
    for (final item in raw) {
      final entry = _parseEntry(item);
      if (entry == null) continue;
      if (entry.query.toLowerCase() == target) continue;
      kept.add(_encodeEntry(entry));
    }
    await prefs.setStringList(_searchHistoryKey, kept);
  }

  SearchHistoryEntry? _parseEntry(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    if (t.startsWith('{')) {
      try {
        final decoded = jsonDecode(t);
        if (decoded is Map) {
          final q = (decoded['q'] ?? decoded['query'] ?? '').toString().trim();
          if (q.isEmpty) return null;
          DateTime? at;
          final atRaw = decoded['at'];
          if (atRaw is String && atRaw.isNotEmpty) {
            at = DateTime.tryParse(atRaw);
          }
          String? scope = decoded['scope']?.toString().trim();
          if (scope != null && scope.isEmpty) scope = null;
          return SearchHistoryEntry(query: q, at: at, scope: scope);
        }
      } catch (_) {
        // Ancienne chaîne non JSON.
      }
    }
    return SearchHistoryEntry(query: t);
  }

  String _encodeEntry(SearchHistoryEntry entry) {
    return jsonEncode({
      'q': entry.query,
      if (entry.at != null) 'at': entry.at!.toUtc().toIso8601String(),
      if (entry.scope != null && entry.scope!.isNotEmpty) 'scope': entry.scope,
    });
  }

  bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
