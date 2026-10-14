import 'package:sdealsmobile/data/models/service.dart';

/// Services du groupe Métiers réellement chargés, filtrés par la recherche.
/// N’ajoute aucun métier absent du catalogue.
List<Service> matchingMetierCatalog(List<Service> services, String query) {
  final named = services.where((s) {
    return s.idservice.trim().isNotEmpty && s.nomservice.trim().isNotEmpty;
  }).toList();
  named.sort(
    (a, b) => a.nomservice.toLowerCase().compareTo(b.nomservice.toLowerCase()),
  );
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return named;
  return named.where((s) {
    if (s.nomservice.toLowerCase().contains(q)) return true;
    for (final alias in s.aliases) {
      if (alias.toLowerCase().contains(q)) return true;
    }
    for (final need in s.needs) {
      if (need.toLowerCase().contains(q)) return true;
    }
    return false;
  }).toList();
}
