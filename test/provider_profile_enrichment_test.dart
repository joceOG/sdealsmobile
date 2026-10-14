import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/screens/provider_profile_enrichment.dart';

void main() {
  group('ProviderProfileEnrichment', () {
    test('split and join bio + description', () {
      const joined = 'Soudeur à Port-Bouët\n\nJe réalise des portails.';
      final parts = ProviderProfileEnrichment.splitDescription(joined);
      expect(parts.bio, 'Soudeur à Port-Bouët');
      expect(parts.description, 'Je réalise des portails.');
      expect(
        ProviderProfileEnrichment.joinDescription(
          bio: parts.bio,
          description: parts.description,
        ),
        joined,
      );
    });

    test('short single line maps to bio only', () {
      final parts = ProviderProfileEnrichment.splitDescription('Soudeur pro');
      expect(parts.bio, 'Soudeur pro');
      expect(parts.description, isEmpty);
    });

    test('missingLabels only real gaps', () {
      expect(
        ProviderProfileEnrichment.missingLabels(
          hasPhotoUrl: false,
          bio: 'Bio ok',
          description: 'Corps détaillé',
        ),
        ['photo'],
      );
      expect(
        ProviderProfileEnrichment.missingLabels(
          hasPhotoUrl: true,
          bio: '',
          description: '',
        ),
        ['description'],
      );
    });
  });
}
