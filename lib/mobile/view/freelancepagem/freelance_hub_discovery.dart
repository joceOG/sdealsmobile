import 'package:flutter/material.dart';
import 'package:sdealsmobile/data/models/service.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';

/// Sélection éditoriale du hub Freelance — 6 services catalogue réels (images API).
class _DiscoveryIntent {
  final List<String> preferredNames;
  final List<String> keywords;
  final String shortLabel;

  const _DiscoveryIntent({
    required this.preferredNames,
    required this.keywords,
    required this.shortLabel,
  });
}

/// Ordre grille hub Freelance (noms affichés = [shortLabel]).
const _discoveryIntents = <_DiscoveryIntent>[
  _DiscoveryIntent(
    preferredNames: [
      'Monteur Vidéo',
      'Monteur Video',
      'Monteur Video YouTube',
      'Monteur de Reels et TikTok',
    ],
    keywords: ['monteur video', 'montage video', 'montage'],
    shortLabel: 'Monteur Vidéo',
  ),
  _DiscoveryIntent(
    preferredNames: [
      'Producteur de Podcasts',
      'Producteur de Podcast',
    ],
    keywords: ['podcast', 'producteur de podcast'],
    shortLabel: 'Producteur de Podcasts',
  ),
  _DiscoveryIntent(
    preferredNames: [
      'Développeur Front-End',
      'Developpeur Front-End',
      'Developpeur Frontend',
    ],
    keywords: ['frontend', 'front end', 'react'],
    shortLabel: 'Développeur Front-End',
  ),
  _DiscoveryIntent(
    preferredNames: [
      'Rédacteur Web',
      'Redacteur Web',
      'Redacteur Web SEO',
    ],
    keywords: ['redacteur web', 'redaction web', 'seo'],
    shortLabel: 'Rédacteur Web',
  ),
  _DiscoveryIntent(
    preferredNames: ['Developpeur Android', 'Développeur Android'],
    keywords: ['android', 'kotlin', 'mobile'],
    shortLabel: 'Developpeur Android',
  ),
  _DiscoveryIntent(
    preferredNames: ['Analyste SOC'],
    keywords: ['analyste soc', 'soc', 'securite'],
    shortLabel: 'Analyste SOC',
  ),
];

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll(RegExp('[éèêë]'), 'e')
    .replaceAll(RegExp('[àâä]'), 'a')
    .replaceAll(RegExp('[îï]'), 'i')
    .replaceAll(RegExp('[ôö]'), 'o')
    .replaceAll(RegExp('[ùûü]'), 'u')
    .replaceAll('ç', 'c')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim();

bool _hasPreferredName(Service service, _DiscoveryIntent intent) {
  final normalizedName = _normalize(service.nomservice);
  return intent.preferredNames
      .map(_normalize)
      .any((name) => normalizedName == name);
}

bool _serviceMatches(Service service, _DiscoveryIntent intent) {
  if (_hasPreferredName(service, intent)) return true;
  final haystack = _normalize(
    '${service.nomservice} ${service.aliases.join(' ')} '
    '${service.categorie?.nomcategorie ?? ''}',
  );
  for (final kw in intent.keywords) {
    if (haystack.contains(_normalize(kw))) return true;
  }
  return false;
}

bool _hasDisplayableImage(Service service) {
  final url = cleanDisplayPart(service.imageservice);
  return url != null && url.isNotEmpty;
}

Service? _bestMatchForIntent(List<Service> all, Set<String> used, _DiscoveryIntent intent) {
  Service? exactWithImage;
  Service? exactAny;
  Service? fuzzyWithImage;
  Service? fuzzyAny;

  for (final s in all) {
    if (used.contains(s.idservice)) continue;
    final preferred = _hasPreferredName(s, intent);
    final fuzzy = !preferred && _serviceMatches(s, intent);
    if (!preferred && !fuzzy) continue;

    final withImg = _hasDisplayableImage(s);
    if (preferred) {
      if (withImg) {
        exactWithImage ??= s;
      } else {
        exactAny ??= s;
      }
    } else {
      if (withImg) {
        fuzzyWithImage ??= s;
      } else {
        fuzzyAny ??= s;
      }
    }
  }

  return exactWithImage ??
      exactAny ??
      fuzzyWithImage ??
      fuzzyAny;
}

/// Libellé court pour tuiles / raccourcis (accessibilité : garder [Service.nomservice]).
String freelanceServiceShortLabel(Service service) {
  for (final intent in _discoveryIntents) {
    if (_hasPreferredName(service, intent)) return intent.shortLabel;
  }
  for (final intent in _discoveryIntents) {
    if (_serviceMatches(service, intent)) return intent.shortLabel;
  }
  final name = service.nomservice.trim();
  if (name.length <= 18) return name;
  final cut = name.substring(0, 18);
  final lastSpace = cut.lastIndexOf(' ');
  if (lastSpace > 8) return '${cut.substring(0, lastSpace)}…';
  return '$cut…';
}

IconData freelanceServiceFallbackIcon(Service service) {
  final shortLabel = freelanceServiceShortLabel(service);
  switch (shortLabel) {
    case 'Monteur Vidéo':
      return Icons.movie_outlined;
    case 'Producteur de Podcasts':
      return Icons.mic_outlined;
    case 'Développeur Front-End':
      return Icons.code_outlined;
    case 'Rédacteur Web':
      return Icons.article_outlined;
    case 'Developpeur Android':
      return Icons.android_outlined;
    case 'Analyste SOC':
      return Icons.security_outlined;
  }
  return Icons.work_outline_rounded;
}

/// Jusqu'à [max] services pour la grille hub / raccourcis Explorer.
List<Service> pickFreelanceHubDiscoveryServices(
  List<Service> all, {
  int max = 6,
}) {
  if (all.isEmpty) return const [];

  final used = <String>{};
  final picked = <Service>[];

  void add(Service s) {
    if (picked.length >= max) return;
    if (s.idservice.isEmpty || used.contains(s.idservice)) return;
    used.add(s.idservice);
    picked.add(s);
  }

  for (final intent in _discoveryIntents) {
    if (picked.length >= max) break;
    final match = _bestMatchForIntent(all, used, intent);
    if (match != null) add(match);
  }

  if (picked.isEmpty) {
    final fallback = List<Service>.from(all)
      ..sort((a, b) {
        final ai = _hasDisplayableImage(a) ? 0 : 1;
        final bi = _hasDisplayableImage(b) ? 0 : 1;
        if (ai != bi) return ai.compareTo(bi);
        return a.nomservice.compareTo(b.nomservice);
      });
    for (final s in fallback) {
      if (picked.length >= max) break;
      add(s);
    }
  }

  return picked;
}
