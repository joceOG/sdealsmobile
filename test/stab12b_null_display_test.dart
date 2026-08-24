import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/models/prestataire.dart';
import 'package:sdealsmobile/data/models/utilisateur.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';
import 'package:sdealsmobile/mobile/data/models/conversation_model.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/models/freelance_model.dart';

void main() {
  group('STAB-12B display_text helpers', () {
    test('prénom + nom → Prénom Nom', () {
      expect(
        joinPersonName(prenom: 'Alice', nom: 'Dupont'),
        'Alice Dupont',
      );
    });

    test('BUG HISTORIQUE: prenom null + nom alice → alice (jamais null alice)', () {
      final ui = joinPersonName(prenom: null, nom: 'alice', fallback: 'Prestataire');
      expect(ui, 'alice');
      expect(ui.toLowerCase(), isNot(contains('null')));
      expect(containsLiteralNull(ui), isFalse);
    });

    test('prénom + nom null → prénom uniquement', () {
      expect(joinPersonName(prenom: 'Alice', nom: null), 'Alice');
    });

    test('prénom null + nom null → fallback', () {
      expect(
        joinPersonName(prenom: null, nom: null, fallback: 'Prestataire'),
        'Prestataire',
      );
    });

    test('splitPersonNameInput — mononyme → nom seul', () {
      final split = splitPersonNameInput('Aaron');
      expect(split.nom, 'Aaron');
      expect(split.prenom, isNull);
    });

    test('splitPersonNameInput — prénom puis nom', () {
      final split = splitPersonNameInput('Aaron Rusker');
      expect(split.prenom, 'Aaron');
      expect(split.nom, 'Rusker');
      expect(
        joinPersonName(prenom: split.prenom, nom: split.nom),
        'Aaron Rusker',
      );
    });

    test('chaînes vides → fallback', () {
      expect(
        joinPersonName(prenom: '', nom: '  ', fallback: 'Utilisateur'),
        'Utilisateur',
      );
    });

    test('espaces uniquement → fallback', () {
      expect(
        joinPersonName(prenom: '   ', nom: '\t', fallback: 'Freelance'),
        'Freelance',
      );
    });

    test('littéral "null" / "undefined" ignorés', () {
      expect(
        joinPersonName(prenom: 'null', nom: 'alice', fallback: 'X'),
        'alice',
      );
      expect(
        joinPersonName(prenom: 'Alice', nom: 'undefined', fallback: 'X'),
        'Alice',
      );
    });

    test('avatar null / vide / "null" → safeImageUrl null', () {
      expect(safeImageUrl(null), isNull);
      expect(safeImageUrl(''), isNull);
      expect(safeImageUrl('null'), isNull);
      expect(safeImageUrl('NULL'), isNull);
      expect(safeImageUrl('https://cdn.example/a.jpg'), isNotNull);
    });

    test('prix / note absents → pas de faux 0', () {
      expect(formatOptionalPrice(null), isNull);
      expect(formatOptionalPrice(0), isNull);
      expect(formatOptionalRating(null), isNull);
      expect(formatOptionalRating(0), isNull);
      expect(formatOptionalPrice(1500), contains('1500'));
      expect(formatOptionalRating(4.5), '4.5');
    });
  });

  group('STAB-12B Utilisateur / Prestataire partiels', () {
    test('fromJson prenom null + nom alice → fullName alice', () {
      final u = Utilisateur.fromJson({
        '_id': '1',
        'prenom': null,
        'nom': 'alice',
        'email': '',
        'password': '',
        'telephone': '',
        'role': 'PRESTATAIRE',
      });
      expect(u.fullName, 'alice');
      expect(containsLiteralNull(u.fullName), isFalse);
    });

    test('fromJson prenom littéral null string', () {
      final u = Utilisateur.fromJson({
        '_id': '1',
        'prenom': 'null',
        'nom': 'alice',
        'email': '',
        'password': '',
        'telephone': '',
        'role': 'CLIENT',
      });
      expect(u.fullName, 'alice');
    });

    test('photoProfil "null" → null (placeholder)', () {
      final u = Utilisateur.fromJson({
        '_id': '1',
        'nom': 'Bob',
        'photoProfil': 'null',
        'email': '',
        'password': '',
        'telephone': '',
        'role': 'CLIENT',
      });
      expect(u.photoProfil, isNull);
    });

    test('card prestataire partielle — nested utilisateur absent', () {
      final p = Prestataire.fromJson({
        '_id': 'p1',
        'prixprestataire': 1000,
        'localisation': null,
        'utilisateur': null,
        'service': null,
      });
      final name = joinPersonName(
        prenom: p.utilisateur.prenom,
        nom: p.utilisateur.nom,
        fallback: 'Prestataire',
      );
      expect(name, 'Prestataire');
      expect(containsLiteralNull(name), isFalse);
      expect(containsLiteralNull(p.localisation), isFalse);
    });

    test('card prestataire — bug null alice via map API', () {
      final name = personNameFromMap({
        'prenom': null,
        'nom': 'alice',
      }, fallback: 'Prestataire');
      expect(name, 'alice');
      expect(name, isNot(contains('null')));
    });
  });

  group('STAB-12B Freelance partiel', () {
    test('fromBackend partiel — aucun littéral null', () {
      final f = FreelanceModel.fromBackend({
        '_id': 'f1',
        'name': null,
        'job': null,
        'category': '',
        'imagePath': 'null',
        'description': '   ',
        'utilisateur': {'prenom': null, 'nom': 'Koné'},
        'hourlyRate': null,
        'rating': null,
      });
      expect(f.name, 'Koné');
      expect(containsLiteralNull(f.name), isFalse);
      expect(containsLiteralNull(f.job), isFalse);
      expect(containsLiteralNull(f.category), isFalse);
      expect(containsLiteralNull(f.description), isFalse);
      expect(f.imagePath, isEmpty);
      expect(f.hourlyRate, 0.0); // modèle interne ; UI = Sur devis
      expect(f.rating, 0.0); // modèle interne ; UI = Pas encore noté
    });
  });

  group('STAB-12B Conversation utilisateur partiel', () {
    test('fromBackend interlocuteur partiel — pas de crash, pas de null', () {
      final c = ConversationModel.fromBackend({
        'conversationId': 'c1',
        'interlocuteur': {
          '_id': 'u1',
          'prenom': null,
          'nom': 'alice',
          'photoProfil': 'null',
          'role': 'CLIENT',
        },
        'nonLus': 0,
      }, 'me');
      expect(c.participantName, 'alice');
      expect(containsLiteralNull(c.participantName), isFalse);
      expect(c.participantImage, isEmpty);
    });

    test('interlocuteur absent → Utilisateur', () {
      final c = ConversationModel.fromBackend({
        'conversationId': 'c2',
        'interlocuteur': null,
      }, 'me');
      expect(c.participantName, 'Utilisateur');
      expect(containsLiteralNull(c.participantName), isFalse);
    });
  });
}
