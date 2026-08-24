import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/models/groupe.dart';
import 'package:sdealsmobile/data/models/service.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/freelancepageblocm/freelancePageBlocM.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/freelancepageblocm/freelancePageEventM.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({
    this.freelancesResponse,
    this.freelancesError,
    this.freelancesDelay = Duration.zero,
  });

  Map<String, dynamic>? freelancesResponse;
  Object? freelancesError;
  final Duration freelancesDelay;
  int freelancesCalls = 0;

  @override
  Future<List<Categorie>> fetchCategorie(String nomGroupe) async => [];

  @override
  Future<List<Service>> fetchServices(String nomGroupe) async => [];

  @override
  Future<Map<String, dynamic>> fetchFreelances({
    int page = 1,
    int limit = 50,
    String sortBy = 'rating',
    String sortOrder = 'desc',
  }) async {
    freelancesCalls++;
    if (freelancesDelay > Duration.zero) {
      await Future<void>.delayed(freelancesDelay);
    }
    if (freelancesError != null) throw freelancesError!;
    return freelancesResponse ??
        {
          'freelances': <Map<String, dynamic>>[],
          'pagination': null,
        };
  }
}

class _SlowCategoriesClient extends ApiClient {
  @override
  Future<List<Categorie>> fetchCategorie(String nomGroupe) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return [
      Categorie(
        idcategorie: 'c1',
        nomcategorie: 'Dev',
        imagecategorie: '',
        groupe: Groupe(idgroupe: 'g1', nomgroupe: 'Freelance'),
      ),
    ];
  }

  @override
  Future<List<Service>> fetchServices(String nomGroupe) async => [];

  @override
  Future<Map<String, dynamic>> fetchFreelances({
    int page = 1,
    int limit = 50,
    String sortBy = 'rating',
    String sortOrder = 'desc',
  }) async =>
      {
        'freelances': [
          {'_id': 'should-not-load', 'name': 'Mock'},
        ],
        'pagination': null,
      };
}

Map<String, dynamic> _sampleFreelance({
  String id = 'f1',
  String name = 'Ada',
}) {
  return {
    '_id': id,
    'name': name,
    'job': 'Dev',
    'category': 'Dev',
    'rating': 4.5,
    'completedJobs': 3,
    'availabilityStatus': 'Disponible',
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:3000/api');
  });

  test('API succès → vraies données, aucun mock', () async {
    final api = _FakeApiClient(
      freelancesResponse: {
        'freelances': [_sampleFreelance()],
        'pagination': null,
      },
    );
    final bloc = FreelancePageBlocM(apiClient: api);
    final done = bloc.stream.firstWhere(
      (s) =>
          s.freelancersLoaded &&
          !s.isLoadingFreelancers &&
          s.freelancersError == null &&
          s.freelancers.length == 1,
    );
    bloc.add(LoadFreelancersEvent());
    final state = await done.timeout(const Duration(seconds: 3));
    expect(state.freelancers.first.name, 'Ada');
    expect(api.freelancesCalls, 1);
    await bloc.close();
  });

  test('API 200 vide → Empty (pas Error, pas mock)', () async {
    final api = _FakeApiClient(
      freelancesResponse: {
        'freelances': <Map<String, dynamic>>[],
        'pagination': null,
      },
    );
    final bloc = FreelancePageBlocM(apiClient: api);
    final done = bloc.stream.firstWhere((s) => s.isFreelancersEmpty);
    bloc.add(LoadFreelancersEvent());
    final state = await done.timeout(const Duration(seconds: 3));
    expect(state.freelancersError, isNull);
    expect(state.freelancers, isEmpty);
    await bloc.close();
  });

  test('API 500 → Error, aucun mock', () async {
    final api = _FakeApiClient(freelancesError: Exception('Échec 500'));
    final bloc = FreelancePageBlocM(apiClient: api);
    final done = bloc.stream.firstWhere(
      (s) =>
          s.freelancersLoaded &&
          !s.isLoadingFreelancers &&
          s.freelancersError != null,
    );
    bloc.add(LoadFreelancersEvent());
    final state = await done.timeout(const Duration(seconds: 3));
    expect(state.freelancers, isEmpty);
    expect(state.freelancersError, contains('Impossible de charger'));
    expect(state.freelancersError!.toLowerCase(), isNot(contains('exception')));
    await bloc.close();
  });

  test('timeout → Error, pas de Loading infini', () async {
    final api = _FakeApiClient(
      freelancesDelay: const Duration(seconds: 5),
      freelancesResponse: {
        'freelances': [_sampleFreelance()],
      },
    );
    final bloc = FreelancePageBlocM(
      apiClient: api,
      requestTimeout: const Duration(milliseconds: 50),
    );
    final done = bloc.stream.firstWhere(
      (s) =>
          s.freelancersLoaded &&
          !s.isLoadingFreelancers &&
          s.freelancersError != null,
    );
    bloc.add(LoadFreelancersEvent());
    final state = await done.timeout(const Duration(seconds: 3));
    expect(state.freelancers, isEmpty);
    expect(state.isLoadingFreelancers, isFalse);
    await bloc.close();
  });

  test('Retry après erreur → Loaded si API répond', () async {
    final api = _FakeApiClient(freelancesError: Exception('boom'));
    final bloc = FreelancePageBlocM(apiClient: api);

    final err = bloc.stream.firstWhere((s) => s.freelancersError != null);
    bloc.add(LoadFreelancersEvent());
    await err.timeout(const Duration(seconds: 3));

    api.freelancesError = null;
    api.freelancesResponse = {
      'freelances': [_sampleFreelance(name: 'Bob')],
    };
    final ok = bloc.stream.firstWhere(
      (s) =>
          s.freelancersError == null &&
          s.freelancers.length == 1 &&
          s.freelancers.first.name == 'Bob',
    );
    bloc.add(LoadFreelancersEvent());
    await ok.timeout(const Duration(seconds: 3));
    expect(api.freelancesCalls, 2);
    await bloc.close();
  });

  test('catégorie timeout → Error, freelancers non mockés', () async {
    final bloc = FreelancePageBlocM(
      apiClient: _SlowCategoriesClient(),
      requestTimeout: const Duration(milliseconds: 40),
    );
    final done = bloc.stream.firstWhere(
      (s) => !s.isLoading && s.error != null,
    );
    bloc.add(LoadCategorieDataM());
    final state = await done.timeout(const Duration(seconds: 3));
    expect(state.error, contains('Impossible de charger'));
    expect(state.freelancers, isEmpty);
    await bloc.close();
  });
}
