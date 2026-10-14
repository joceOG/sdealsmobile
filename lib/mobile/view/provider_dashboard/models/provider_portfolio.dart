import '../../../../data/utils/display_text.dart';

/// Actions portfolio prestataire — activer uniquement quand l’API le permet.
class ProviderPortfolioCapabilities {
  const ProviderPortfolioCapabilities({
    required this.canAdd,
    required this.canEdit,
    required this.canDelete,
  });

  /// Lecture via GET prestataire (champs portfolio* s’ils existent).
  static const ProviderPortfolioCapabilities readOnlyPrestataire =
      ProviderPortfolioCapabilities(
    canAdd: false,
    canEdit: false,
    canDelete: false,
  );

  final bool canAdd;
  final bool canEdit;
  final bool canDelete;

  bool get canMutate => canAdd || canEdit || canDelete;
}

/// Une réalisation ou une photo du portfolio prestataire.
class ProviderPortfolioEntry {
  const ProviderPortfolioEntry({
    required this.id,
    required this.imageUrls,
    this.title,
    this.description,
  });

  final String id;
  final List<String> imageUrls;
  final String? title;
  final String? description;

  bool get hasDisplayTitle {
    final t = title?.trim() ?? '';
    return t.isNotEmpty;
  }

  int get photoCount => imageUrls.length;

  String? get primaryImageUrl {
    for (final u in imageUrls) {
      final resolved = safeImageUrl(u);
      if (resolved != null) return resolved;
    }
    return null;
  }
}

class ProviderPortfolioData {
  const ProviderPortfolioData({
    required this.entries,
    required this.capabilities,
    this.photosOnly = false,
  });

  final List<ProviderPortfolioEntry> entries;
  final ProviderPortfolioCapabilities capabilities;
  /// Vrai si la source API est une simple liste d’URLs (pas de projets structurés).
  final bool photosOnly;

  bool get isEmpty => entries.isEmpty;
}

/// Parse le JSON prestataire (ou sous-objet) — sans inventer de contenu.
ProviderPortfolioData parseProviderPortfolioFromPrestataireJson(
  Map<String, dynamic> data, {
  ProviderPortfolioCapabilities capabilities =
      ProviderPortfolioCapabilities.readOnlyPrestataire,
}) {
  final structured = _parsePortfolioItems(data['portfolioItems']);
  if (structured.isNotEmpty) {
    return ProviderPortfolioData(
      entries: structured,
      capabilities: capabilities,
      photosOnly: false,
    );
  }

  final fromList = _parseUrlList(data['portfolioPhotos'] ?? data['portfolio']);
  if (fromList.isNotEmpty) {
    return ProviderPortfolioData(
      entries: fromList,
      capabilities: capabilities,
      photosOnly: true,
    );
  }

  final fromString = data['portfolio'];
  if (fromString is String && fromString.trim().isNotEmpty) {
    final urls = fromString
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final entries = _entriesFromFlatUrls(urls);
    if (entries.isNotEmpty) {
      return ProviderPortfolioData(
        entries: entries,
        capabilities: capabilities,
        photosOnly: true,
      );
    }
  }

  return ProviderPortfolioData(
    entries: const [],
    capabilities: capabilities,
    photosOnly: false,
  );
}

List<ProviderPortfolioEntry> _parsePortfolioItems(dynamic raw) {
  if (raw is! List) return const [];
  final out = <ProviderPortfolioEntry>[];
  for (var i = 0; i < raw.length; i++) {
    final item = raw[i];
    if (item is! Map) continue;
    final map = Map<String, dynamic>.from(item);
    final title = cleanDisplayPart(map['title'] ?? map['titre']);
    final description =
        cleanDisplayPart(map['description'] ?? map['descriptionProjet']);
    final urls = <String>[];
    void addUrl(dynamic u) {
      final resolved = safeImageUrl(u?.toString());
      if (resolved != null && !urls.contains(resolved)) urls.add(resolved);
    }

    addUrl(map['imageUrl'] ?? map['image'] ?? map['url']);
    final imgs = map['images'];
    if (imgs is List) {
      for (final u in imgs) {
        addUrl(u);
      }
    }
    if (urls.isEmpty) continue;
    out.add(
      ProviderPortfolioEntry(
        id: map['_id']?.toString() ?? map['id']?.toString() ?? 'item_$i',
        imageUrls: urls,
        title: title,
        description: description,
      ),
    );
  }
  return out;
}

List<ProviderPortfolioEntry> _parseUrlList(dynamic raw) {
  if (raw is! List) return const [];
  final urls = <String>[];
  for (final e in raw) {
    final resolved = safeImageUrl(e?.toString());
    if (resolved != null && !urls.contains(resolved)) urls.add(resolved);
  }
  return _entriesFromFlatUrls(urls);
}

List<ProviderPortfolioEntry> _entriesFromFlatUrls(List<String> urls) {
  return List.generate(urls.length, (i) {
    return ProviderPortfolioEntry(
      id: 'photo_$i',
      imageUrls: [urls[i]],
    );
  });
}
