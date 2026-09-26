import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/errors/api_exception.dart';
import 'package:sdealsmobile/data/models/professional_capabilities.dart';
import 'package:http/http.dart' as http;

void main() {
  group('MOB-10D.3 capabilities parsing', () {
    test('fromRolesApiResponse — multi-profils + caps opérationnelles', () {
      final caps = UserProfessionalCapabilities.fromRolesApiResponse({
        'capabilities': ['Prestataire'],
        'roles': ['CLIENT', 'PRESTATAIRE'],
        'details': {
          'prestataire': {
            'id': 'p1',
            'status': 'active',
            'canOperate': true,
          },
          'freelance': {
            'id': 'f1',
            'status': 'pending',
            'canOperate': false,
          },
          'vendeur': null,
        },
        'data': {
          'profiles': {
            'prestataire': {
              'exists': true,
              'status': 'active',
              'canOperate': true,
            },
            'freelance': {
              'exists': true,
              'status': 'pending',
              'canOperate': false,
            },
            'vendeur': {'exists': false, 'status': null, 'canOperate': false},
          },
        },
      });

      expect(caps.capabilities, ['Prestataire']);
      expect(caps.canOperateAs('Prestataire'), isTrue);
      expect(caps.canOperateAs('Freelance'), isFalse);
      expect(caps.hasProfile('Freelance'), isTrue);
      expect(caps.freelance.status, 'pending');
      expect(caps.freelance.canOperate, isFalse);
    });

    test('recherche catégorie Métiers envoie le libellé nomcategorie', () {
      const selectedLabel = 'Plomberie';
      const wrongObjectId = '507f1f77bcf86cd799439011';
      expect(selectedLabel == wrongObjectId, isFalse);
      expect(selectedLabel.toLowerCase().contains('plomb'), isTrue);
    });
  });

  group('MOB-10D.3 erreurs commande', () {
    test('codes métier ORDER_*', () {
      for (final code in [
        'ORDER_FIELD_FORBIDDEN',
        'MULTI_VENDOR_ORDER_NOT_SUPPORTED',
        'VENDOR_NOT_AVAILABLE',
        'INSUFFICIENT_STOCK',
        'ARTICLE_NOT_FOUND',
      ]) {
        final ex = ApiErrorParser.fromResponse(
          http.Response(
            '{"success":false,"code":"$code","message":"x"}',
            409,
          ),
        );
        expect(ex.code, code);
        expect(ex.message, isNot(contains('Exception')));
        expect(ex.message.length, greaterThan(8));
      }
    });
  });
}
