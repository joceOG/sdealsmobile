import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/errors/api_exception.dart';
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/models/groupe.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/utils/network_user_message.dart';
import 'package:sdealsmobile/mobile/view/homepagem/homepageblocm/homePageBlocM.dart';
import 'package:sdealsmobile/mobile/view/homepagem/homepageblocm/homePageEventM.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:9/api\n');
  });

  test('reprise seulement pour timeout, coupure ou 5xx', () {
    expect(isTransientReadFailure(TimeoutException('slow')), isTrue);
    expect(isTransientReadFailure(ApiException.timeout()), isTrue);
    expect(isTransientReadFailure(ApiException.network()), isTrue);
    expect(
      isTransientReadFailure(
        const ApiException(message: 'down', statusCode: 503),
      ),
      isTrue,
    );
    expect(
      isTransientReadFailure(
        Exception('Échec de chargement des catégories: TimeoutException'),
      ),
      isTrue,
    );
    expect(
      isTransientReadFailure(
        const ApiException(message: 'interdit', statusCode: 401),
      ),
      isFalse,
    );
    expect(
      isTransientReadFailure(
        const ApiException(message: 'interdit', statusCode: 403),
      ),
      isFalse,
    );
    expect(
      isTransientReadFailure(
        const ApiException(message: 'invalide', statusCode: 400),
      ),
      isFalse,
    );
  });

  test('un timeout puis un succès affiche les catégories', () async {
    final api = _FakeCategories()
      ..steps.add(TimeoutException('slow'))
      ..steps.add(<Categorie>[_category('Plomberie')]);
    final bloc = HomePageBlocM(apiClient: api, retryDelay: Duration.zero);
    addTearDown(bloc.close);

    bloc.add(LoadCategorieDataM());
    await bloc.stream.firstWhere((state) => !state.isLoading);

    expect(api.fetchCalls, 2);
    expect(bloc.state.error, isEmpty);
    expect(bloc.state.listItems, hasLength(1));
    expect(bloc.state.listItems!.single.nomcategorie, 'Plomberie');
  });

  test('un 401 ne relance pas la lecture et reste une erreur', () async {
    final api = _FakeCategories()
      ..steps.add(const ApiException(message: 'interdit', statusCode: 401));
    final bloc = HomePageBlocM(apiClient: api, retryDelay: Duration.zero);
    addTearDown(bloc.close);

    bloc.add(LoadCategorieDataM());
    await bloc.stream.firstWhere((state) => !state.isLoading);

    expect(api.fetchCalls, 1);
    expect(bloc.state.listItems ?? [], isEmpty);
    expect(bloc.state.error, genericUserMessage);
  });

  test('un échec avec cache garde les catégories et masque le bandeau', () async {
    final api = _FakeCategories()
      ..cache.add(_category('Menuiserie'))
      ..steps.add(TimeoutException('slow'))
      ..steps.add(TimeoutException('still'));
    final bloc = HomePageBlocM(apiClient: api, retryDelay: Duration.zero);
    addTearDown(bloc.close);

    bloc.add(LoadCategorieDataM());
    await bloc.stream.firstWhere((state) => !state.isLoading);

    expect(api.fetchCalls, 2);
    expect(bloc.state.error, isEmpty);
    expect(bloc.state.listItems, hasLength(1));
    expect(bloc.state.listItems!.single.nomcategorie, 'Menuiserie');
  });

  test('une liste vide est un succès, pas une erreur', () async {
    final api = _FakeCategories()..steps.add(<Categorie>[]);
    final bloc = HomePageBlocM(apiClient: api, retryDelay: Duration.zero);
    addTearDown(bloc.close);

    bloc.add(LoadCategorieDataM());
    await bloc.stream.firstWhere((state) => !state.isLoading);

    expect(api.fetchCalls, 1);
    expect(bloc.state.error, isEmpty);
    expect(bloc.state.listItems, isEmpty);
  });
}

Categorie _category(String name) {
  return Categorie(
    idcategorie: name,
    nomcategorie: name,
    imagecategorie: '',
    groupe: Groupe(idgroupe: 'g', nomgroupe: 'Métiers'),
  );
}

class _FakeCategories extends ApiClient {
  final List<Object> steps = [];
  final List<Categorie> cache = [];
  int fetchCalls = 0;

  @override
  Future<List<Categorie>> readCachedCategorie(String nomGroupe) async {
    return List<Categorie>.from(cache);
  }

  @override
  Future<List<Categorie>> fetchCategorie(
    String nomGroupe, {
    bool skipCache = false,
    bool settleLateResponse = false,
  }) async {
    fetchCalls++;
    final step = steps[fetchCalls - 1];
    if (step is List<Categorie>) return step;
    throw step;
  }
}
