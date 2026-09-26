import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/config/client_feature_flags.dart';
import 'package:sdealsmobile/data/services/local_storage_service.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/client_provider_list_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PHASE 10D-3 flags É-marché off', () {
    test('pas de Plus ni Shop dans les listes actives', () {
      expect(ClientFeatureFlags.emarketEnabled, isFalse);
      expect(ClientFeatureFlags.explorerChipLabels, ['Métiers', 'Freelance']);
      expect(ClientFeatureFlags.searchTabLabels, isNot(contains('Shop')));
      expect(ClientFeatureFlags.searchTabLabels, isNot(contains('Boutiques')));
      expect(ClientFeatureFlags.searchTabLabels, contains('Professionnels'));
    });
  });

  group('PHASE 10D-3 vérité affichage', () {
    test('note nulle masquée', () {
      expect(formatOptionalRating(0), isNull);
      expect(formatOptionalRating(null), isNull);
    });

    test('prix formaté avec espaces', () {
      final label = formatOptionalPrice(12000, suffix: 'FCFA');
      expect(label, isNotNull);
      expect(label!, contains('12'));
      expect(label, contains('FCFA'));
    });

    test('expérience sans double unité', () {
      expect(formatExperienceLabel('3 ans'), '3 ans d’expérience');
      expect(formatExperienceLabel('1'), '1 an d’expérience');
      expect(formatExperienceLabel(''), isNull);
    });
  });

  group('PHASE 10D-3 historique recherche', () {
    test('trim et déduplication', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorageService();
      await storage.addToHistory('  plombier  ');
      await storage.addToHistory('');
      await storage.addToHistory('m');
      await storage.addToHistory('Plombier');
      final history = await storage.getSearchHistory();
      expect(history, isNot(contains('')));
      expect(history.where((e) => e.toLowerCase() == 'plombier').length, 1);
      expect(history.first.toLowerCase(), 'plombier');
    });
  });
}
