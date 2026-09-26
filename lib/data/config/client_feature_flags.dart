/// Activation temporaire des univers client.
/// Une seule source de vérité : passer [emarketEnabled] à true réaffiche
/// les entrées sans recréer les écrans, routes ou modèles.
class ClientFeatureFlags {
  static const bool emarketEnabled = false;

  static const List<String> homeUniversesWhenEnabled = [
    'Métiers',
    'Freelance',
    'É-marché',
  ];

  static const List<String> homeUniversesWhenHidden = [
    'Métiers',
    'Freelance',
  ];

  static List<String> get homeUniverseTitles =>
      emarketEnabled ? homeUniversesWhenEnabled : homeUniversesWhenHidden;

  static const List<String> publishWhenEnabled = [
    'Métiers',
    'Freelance',
    'Boutique',
  ];

  static const List<String> publishWhenHidden = [
    'Métiers',
    'Freelance',
  ];

  static List<String> get publishTitles =>
      emarketEnabled ? publishWhenEnabled : publishWhenHidden;

  static const List<String> explorerWhenEnabled = [
    'Métiers',
    'Freelance',
    'Vente & Achat',
    'Plus',
  ];

  /// Sans É-marché : pas de « Plus » (aucune destination active utile).
  static const List<String> explorerWhenHidden = [
    'Métiers',
    'Freelance',
  ];

  static List<String> get explorerChipLabels =>
      emarketEnabled ? explorerWhenEnabled : explorerWhenHidden;

  static const List<String> searchTabsWhenEnabled = [
    'Tout',
    'Services',
    'Freelances',
    'Professionnels',
    'Shop',
    'Boutiques',
  ];

  static const List<String> searchTabsWhenHidden = [
    'Tout',
    'Services',
    'Freelances',
    'Professionnels',
  ];

  static List<String> get searchTabLabels =>
      emarketEnabled ? searchTabsWhenEnabled : searchTabsWhenHidden;

  static int clampSearchTabIndex(int index) {
    final max = searchTabLabels.length - 1;
    if (index < 0) return 0;
    if (index > max) return 0;
    return index;
  }
}
