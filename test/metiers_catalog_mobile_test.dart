import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/errors/api_exception.dart';
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/models/groupe.dart';
import 'package:sdealsmobile/data/models/prestataire.dart';
import 'package:sdealsmobile/data/models/service.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/utils/metier_catalog.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageEventM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageStateM.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/searchpageblocm/searchPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/searchpageblocm/searchPageEventM.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/searchpageblocm/searchPageStateM.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _prestataireJson({
  required String id,
  required String serviceId,
  String serviceName = 'Plombier',
  String nom = 'Kouassi',
}) {
  return {
    '_id': id,
    'utilisateur': {
      '_id': 'u-$id',
      'nom': nom,
      'prenom': 'A',
      'email': '$id@test.local',
      'password': 'x',
      'telephone': '0700000000',
      'role': 'PRESTATAIRE',
    },
    'service': {
      '_id': serviceId,
      'nomservice': serviceName,
      'imageservice': '',
      'prixmoyen': '0',
    },
    'prixprestataire': 10000,
    'localisation': 'Abidjan',
    'verifier': true,
    'anneeExperience': '3',
  };
}

Service _svc(String id, String nom, {int? rank, String? catId}) {
  return Service(
    idservice: id,
    nomservice: nom,
    imageservice: '',
    prixmoyen: '0',
    shortcutRank: rank,
    categorie: catId == null
        ? null
        : Categorie(
            idcategorie: catId,
            nomcategorie: 'Bâtiment',
            imagecategorie: '',
            groupe: Groupe(idgroupe: 'g1', nomgroupe: 'Métiers'),
          ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_URL=http://127.0.0.1\n');
    SharedPreferences.setMockInitialValues({});
  });

  test('Service.fromJson tolère l’absence d’aliases, needs et shortcutRank', () {
    final s = Service.fromJson({
      '_id': '507f1f77bcf86cd799439011',
      'nomservice': 'Plombier',
      'imageservice': '',
      'prixmoyen': '0',
    });
    expect(s.aliases, isEmpty);
    expect(s.needs, isEmpty);
    expect(s.shortcutRank, isNull);
  });

  test('Service.fromJson lit aliases, needs et shortcutRank', () {
    final s = Service.fromJson({
      '_id': '507f1f77bcf86cd799439011',
      'nomservice': 'Plombier',
      'imageservice': '',
      'prixmoyen': '0',
      'aliases': ['plomberie', 'Bijoutier Artisannal'],
      'needs': ['robinet', 'fuite d’eau'],
      'shortcutRank': 1,
    });
    expect(s.idservice, '507f1f77bcf86cd799439011');
    expect(s.aliases, contains('plomberie'));
    expect(s.needs, contains('robinet'));
    expect(s.shortcutRank, 1);
  });

  test('raccourci → serviceId filtré côté fetch (réponses simulées)', () async {
    final calls = <Map<String, String?>>[];
    final bloc = JobPageBlocM(
      fetchPrestataires: ({
        forceRefresh = false,
        page = 1,
        limit = 20,
        serviceId,
        categorieId,
      }) async {
        calls.add({'serviceId': serviceId, 'categorieId': categorieId, 'page': '$page'});
        expect(serviceId, 'svc-plombier');
        return [
          _prestataireJson(id: 'p1', serviceId: 'svc-plombier'),
        ];
      },
    );
    addTearDown(bloc.close);
    bloc.add(const LoadProviderMatchingM(
      serviceType: 'Plombier',
      location: '',
      serviceId: 'svc-plombier',
    ));
    await bloc.stream.firstWhere((s) => !s.isMatchingLoading);
    expect(bloc.state.selectedServiceId, 'svc-plombier');
    expect(bloc.state.matchedProviders, hasLength(1));
    expect(bloc.state.matchedProviders.first.service.idservice, 'svc-plombier');
    expect(calls.single['serviceId'], 'svc-plombier');
  });

  test('catégorie → fetch avec categorieId, sans serviceId', () async {
    final calls = <Map<String, String?>>[];
    final bloc = JobPageBlocM(
      fetchPrestataires: ({
        forceRefresh = false,
        page = 1,
        limit = 20,
        serviceId,
        categorieId,
      }) async {
        calls.add({'serviceId': serviceId, 'categorieId': categorieId});
        return [
          _prestataireJson(id: 'p1', serviceId: 'svc-macon', serviceName: 'Maçon'),
        ];
      },
    );
    addTearDown(bloc.close);
    bloc.add(const LoadProvidersByCategoryM(
      category: 'Bâtiment & Construction',
      categoryId: 'cat-bat',
    ));
    await bloc.stream.firstWhere((s) => !s.isNearbyLoading);
    expect(bloc.state.selectedCategoryId, 'cat-bat');
    expect(bloc.state.selectedServiceId, isEmpty);
    expect(calls.single['categorieId'], 'cat-bat');
    expect(calls.single['serviceId'], isNull);
  });

  test('Charger plus conserve serviceId et categorieId', () async {
    final pages = <int>[];
    final filters = <Map<String, String?>>[];
    final bloc = JobPageBlocM(
      fetchPrestataires: ({
        forceRefresh = false,
        page = 1,
        limit = 20,
        serviceId,
        categorieId,
      }) async {
        pages.add(page);
        filters.add({'serviceId': serviceId, 'categorieId': categorieId});
        return List.generate(
          20,
          (i) => _prestataireJson(
            id: 'p$page-$i',
            serviceId: serviceId ?? 'x',
          ),
        );
      },
    );
    addTearDown(bloc.close);
    bloc.add(const LoadNearbyProvidersM(
      latitude: 5.3,
      longitude: -4.0,
      serviceId: 'svc-1',
      categoryId: 'cat-1',
    ));
    await bloc.stream.firstWhere((s) => !s.isNearbyLoading && s.nearbyProviders.isNotEmpty);
    bloc.add(const LoadMoreProvidersM());
    await bloc.stream.firstWhere((s) => s.providersPage == 2 && !s.isLoadingMore);
    expect(pages, [1, 2]);
    expect(filters.every((f) => f['serviceId'] == 'svc-1'), isTrue);
    expect(filters.every((f) => f['categorieId'] == 'cat-1'), isTrue);
    expect(bloc.state.selectedServiceId, 'svc-1');
    expect(bloc.state.nearbyProviders.length, greaterThan(20));
  });

  test('changement rapide : ancienne réponse ignorée', () async {
    final bloc = JobPageBlocM(
      fetchPrestataires: ({
        forceRefresh = false,
        page = 1,
        limit = 20,
        serviceId,
        categorieId,
      }) async {
        if (serviceId == 'old') {
          await Future<void>.delayed(const Duration(milliseconds: 80));
          return [_prestataireJson(id: 'old-p', serviceId: 'old')];
        }
        return [_prestataireJson(id: 'new-p', serviceId: 'new')];
      },
    );
    addTearDown(bloc.close);
    bloc.add(const LoadProviderMatchingM(
      serviceType: 'A',
      location: '',
      serviceId: 'old',
    ));
    bloc.add(const LoadProviderMatchingM(
      serviceType: 'B',
      location: '',
      serviceId: 'new',
    ));
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(bloc.state.selectedServiceId, 'new');
    expect(bloc.state.matchedProviders, hasLength(1));
    expect(bloc.state.matchedProviders.first.idprestataire, 'new-p');
  });

  test('retour fictif : la sélection BLoC est conservée (pas de reset)', () async {
    final bloc = JobPageBlocM(
      fetchPrestataires: ({
        forceRefresh = false,
        page = 1,
        limit = 20,
        serviceId,
        categorieId,
      }) async =>
          [_prestataireJson(id: 'p1', serviceId: serviceId ?? '')],
    );
    addTearDown(bloc.close);
    bloc.add(const LoadProviderMatchingM(
      serviceType: 'Plombier',
      location: '',
      serviceId: 'svc-plombier',
    ));
    await bloc.stream.firstWhere((s) => s.selectedServiceId == 'svc-plombier');
    final before = bloc.state.selectedServiceId;
    expect(before, 'svc-plombier');
    expect(bloc.state.copyWith().selectedServiceId, before);
  });

  test('Liste / Carte : même selectedServiceId dans l’état partagé', () {
    const state = JobPageStateM(
      isLoading: false,
      listItems: [],
      error: '',
      isLoading2: false,
      listItems2: [],
      error2: '',
      isPriceLoading: false,
      priceError: '',
      matchedProviders: [],
      isMatchingLoading: false,
      matchError: '',
      nearbyProviders: [],
      isNearbyLoading: false,
      nearbyError: '',
      searchRadius: 5,
      selectedCategory: 'Bâtiment',
      selectedCategoryId: 'cat-1',
      selectedService: 'Plombier',
      selectedServiceId: 'svc-1',
    );
    expect(state.selectedServiceId, 'svc-1');
    expect(state.selectedCategoryId, 'cat-1');
  });

  test('rayon : filtre les résultats seulement avec une position', () {
    final near =
        Prestataire.fromJson(_prestataireJson(id: 'near', serviceId: 's'));
    final far =
        Prestataire.fromJson(_prestataireJson(id: 'far', serviceId: 's'));
    JobPageStateM state({
      double? lat,
      Map<String, double> distances = const {},
      double radius = 5,
    }) {
      return JobPageStateM(
        isLoading: false,
        listItems: const [],
        error: '',
        isLoading2: false,
        listItems2: const [],
        error2: '',
        isPriceLoading: false,
        priceError: '',
        matchedProviders: const [],
        isMatchingLoading: false,
        matchError: '',
        nearbyProviders: [near, far],
        providerDistances: distances,
        isNearbyLoading: false,
        nearbyError: '',
        userLatitude: lat,
        userLongitude: lat == null ? null : -4,
        searchRadius: radius,
        selectedCategory: '',
        selectedService: '',
      );
    }

    final withoutPosition = state();
    expect(withoutPosition.appliesSearchRadius, isFalse);
    expect(withoutPosition.displayProviders, hasLength(2));

    final withinFive = state(
      lat: 5.3,
      distances: const {'near': 1.2, 'far': 12},
    );
    expect(withinFive.appliesSearchRadius, isTrue);
    expect(
      withinFive.displayProviders.map((p) => p.idprestataire),
      ['near'],
    );

    final withinTwenty = state(
      lat: 5.3,
      distances: const {'near': 1.2, 'far': 12},
      radius: 20,
    );
    expect(withinTwenty.displayProviders, hasLength(2));
  });

  test('catalogue Métiers : recherche sur les services réels uniquement', () {
    final services = [
      Service(
        idservice: 'svc-plomb',
        nomservice: 'Plomberie',
        imageservice: '',
        prixmoyen: '0',
        aliases: const ['fuite'],
      ),
      Service(
        idservice: '',
        nomservice: 'Sans identifiant',
        imageservice: '',
        prixmoyen: '0',
      ),
      Service(
        idservice: 'svc-elec',
        nomservice: 'Électricité',
        imageservice: '',
        prixmoyen: '0',
      ),
    ];

    final all = matchingMetierCatalog(services, '');
    expect(all.map((s) => s.idservice), containsAll(['svc-elec', 'svc-plomb']));
    expect(all, hasLength(2));

    final found = matchingMetierCatalog(services, 'fuite');
    expect(found.map((s) => s.idservice), ['svc-plomb']);

    expect(matchingMetierCatalog(services, 'carreleur'), isEmpty);
  });

  test('suggestions : une lettre (r) déclenche FetchSuggestions', () async {
    SharedPreferences.setMockInitialValues({});
    final api = _FakeSearchApi(scopes: []);
    final bloc = SearchPageBlocM(scope: 'global', apiClient: api);
    addTearDown(bloc.close);
    bloc.add(const FetchSuggestions('r'));
    await bloc.stream.firstWhere((s) => s.suggestions.isNotEmpty);
    expect(
      bloc.state.suggestions.every(
        (s) => s.trim().isNotEmpty && s.toLowerCase().startsWith('r'),
      ),
      isTrue,
    );
  });

  test('scope Métiers conservé ; expand conserve la saisie (réponses simulées)',
      () async {
    SharedPreferences.setMockInitialValues({});
    final scopes = <String>[];
    final api = _FakeSearchApi(scopes: scopes);
    final bloc = SearchPageBlocM(scope: 'metiers', apiClient: api);
    addTearDown(bloc.close);
    expect(bloc.state.scope, 'metiers');
    bloc.add(const PerformGlobalSearch('robinet'));
    await bloc.stream.firstWhere((s) => s.hasSearched && !s.isLoading);
    expect(bloc.state.scope, 'metiers');
    expect(bloc.state.query, 'robinet');
    expect(scopes.last, 'metiers');
    bloc.add(const ExpandSearchToGlobal());
    await bloc.stream.firstWhere(
      (s) => s.scope == 'global' && !s.isLoading && scopes.contains('global'),
    );
    expect(bloc.state.query, 'robinet');
    expect(bloc.state.scope, 'global');
    expect(scopes.last, 'global');
  });

  test('zéro raccourci : écran utilisable, catégories et services présents',
      () async {
    final cat = Categorie(
      idcategorie: 'cat-1',
      nomcategorie: 'Bâtiment & Construction',
      imagecategorie: '',
      groupe: Groupe(idgroupe: 'g1', nomgroupe: 'Métiers'),
    );
    final bloc = JobPageBlocM(
      fetchCategories: (_) async => [cat],
      fetchServices: (_) async => [_svc('s1', 'Plombier', catId: 'cat-1')],
      fetchShortcuts: ({scope = 'metiers'}) async => const [],
    );
    addTearDown(bloc.close);
    bloc.add(LoadCategorieDataJobM());
    bloc.add(LoadServiceDataJobM());
    await bloc.stream.firstWhere(
      (s) => !s.isLoading && !s.isLoading2 && s.listItems.isNotEmpty,
    );
    expect(bloc.state.shortcuts, isEmpty);
    expect(bloc.state.shortcutsError, isEmpty);
    expect(bloc.state.listItems, hasLength(1));
    expect(bloc.state.listItems2, hasLength(1));
    expect(bloc.state.error, isEmpty);
    expect(bloc.state.error2, isEmpty);
  });

  test('erreur API distincte d’une liste vide', () async {
    final emptyBloc = JobPageBlocM(
      fetchPrestataires: ({
        forceRefresh = false,
        page = 1,
        limit = 20,
        serviceId,
        categorieId,
      }) async =>
          const [],
    );
    addTearDown(emptyBloc.close);
    emptyBloc.add(const LoadProviderMatchingM(
      serviceType: 'Plombier',
      location: '',
      serviceId: 'svc-1',
    ));
    await emptyBloc.stream.firstWhere((s) => !s.isMatchingLoading);
    expect(emptyBloc.state.matchError, isEmpty);
    expect(emptyBloc.state.matchedProviders, isEmpty);

    final errBloc = JobPageBlocM(
      fetchPrestataires: ({
        forceRefresh = false,
        page = 1,
        limit = 20,
        serviceId,
        categorieId,
      }) async {
        throw const ApiException(message: 'Impossible de charger les prestataires.', statusCode: 500);
      },
    );
    addTearDown(errBloc.close);
    errBloc.add(const LoadProviderMatchingM(
      serviceType: 'Plombier',
      location: '',
      serviceId: 'svc-1',
    ));
    await errBloc.stream.firstWhere((s) => !s.isMatchingLoading);
    expect(errBloc.state.matchError, isNotEmpty);
    expect(errBloc.state.matchedProviders, isEmpty);

    final scBloc = JobPageBlocM(
      fetchServices: (_) async => [_svc('s1', 'Plombier')],
      fetchShortcuts: ({scope = 'metiers'}) async {
        throw const ApiException(message: 'Impossible de charger les raccourcis.', statusCode: 500);
      },
    );
    addTearDown(scBloc.close);
    scBloc.add(LoadServiceDataJobM());
    await scBloc.stream.firstWhere((s) => !s.isLoading2);
    expect(scBloc.state.listItems2, isNotEmpty);
    expect(scBloc.state.shortcuts, isEmpty);
    expect(scBloc.state.shortcutsError, isNotEmpty);
    expect(scBloc.state.error2, isEmpty);
  });

  test('Flutter envoie service et categorie comme le backend (noms de query)', () {
    const serviceId = '6961826fbff072a8b1695dbc';
    const categorieId = 'cat-bat';
    final uri = Uri.parse('http://127.0.0.1/prestataire').replace(queryParameters: {
      'page': '1',
      'limit': '20',
      'service': serviceId,
      'categorie': categorieId,
    });
    expect(uri.queryParameters['service'], serviceId);
    expect(uri.queryParameters['categorie'], categorieId);
  });
}

class _FakeSearchApi extends ApiClient {
  _FakeSearchApi({required this.scopes});
  final List<String> scopes;

  @override
  Future<Map<String, dynamic>> searchGlobal(
    String query, {
    int? minPrice,
    int? maxPrice,
    String? city,
    String scope = 'global',
    bool includeEmarket = true,
  }) async {
    scopes.add(scope);
    return {
      'results': {
        'services': [
          {'_id': 's1', 'nomservice': 'Plombier', 'matchKind': 'contains-need'},
        ],
        'articles': includeEmarket
            ? [
                {'nomArticle': 'Robinet cuisine'},
              ]
            : [],
        'freelances': [],
        'prestataires': [],
        'vendeurs': [],
      },
      'counts': {
        'services': 1,
        'articles': includeEmarket ? 1 : 0,
        'freelances': 0,
        'prestataires': 0,
        'vendeurs': 0,
      },
    };
  }

  @override
  Future<List<String>> getSuggestions(
    String query, {
    String scope = 'global',
    bool includeEmarket = true,
  }) async {
    const catalog = [
      'Redacteur Web SEO',
      'Rédacteur technique',
      'Plombier',
    ];
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return catalog
        .where((name) => name.toLowerCase().startsWith(q))
        .toList();
  }
}
