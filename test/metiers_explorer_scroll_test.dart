import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageEventM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/jobPageScreenM.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:9/api\n');
  });

  Future<JobPageBlocM> pumpMetiers(
    WidgetTester tester, {
    required Size size,
    double textScale = 1,
  }) async {
    const channel = MethodChannel('flutter.baseflow.com/geolocator');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => 0,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final gates = <Completer<List<Map<String, dynamic>>>>[];
    final bloc = JobPageBlocM(
      fetchCategories: (_) async => const [],
      fetchServices: (_) async => const [],
      fetchShortcuts: ({scope = 'metiers'}) async => const [],
      fetchPrestataires: ({
        forceRefresh = false,
        page = 1,
        limit = 20,
        serviceId,
        categorieId,
      }) {
        final gate = Completer<List<Map<String, dynamic>>>();
        gates.add(gate);
        return gate.future;
      },
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider<JobPageBlocM>.value(
        value: bloc,
        child: MaterialApp(
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: child!,
            );
          },
          home: const JobPageScreenM(),
        ),
      ),
    );
    await tester.pump();
    if (!bloc.state.isNearbyLoading && !bloc.state.isMatchingLoading) {
      bloc.add(const LoadProviderMatchingM(
        serviceType: 'Plomberie',
        location: '',
        serviceId: 'svc-plomberie',
      ));
      await tester.pump();
    }
    gates.last.complete([
      _provider('p1', 'Kouassi'),
      _provider('p2', 'Aya'),
    ]);
    await tester.pump();
    await tester.pump();
    return bloc;
  }

  testWidgets('un seul scroll vertical, header compact sans overflow',
      (tester) async {
    for (final size in const [Size(320, 568), Size(360, 800)]) {
      await pumpMetiers(tester,
          size: size, textScale: size.width < 340 ? 1.3 : 1);
      expect(tester.takeException(), isNull);
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.text('Métiers'), findsWidgets);
      expect(find.text('De quoi avez-vous besoin ?'), findsOneWidget);

      final lists = tester.widgetList<ListView>(find.byType(ListView));
      for (final list in lists) {
        expect(list.scrollDirection, Axis.horizontal);
      }

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
      await tester.pump();
      expect(find.textContaining('Kouassi'), findsWidgets);
      expect(find.text('Métiers'), findsWidgets);
      expect(tester.takeException(), isNull);
    }
  });
}

Map<String, dynamic> _provider(String id, String prenom) {
  return {
    '_id': id,
    'verifier': true,
    'prixprestataire': 8000,
    'localisation': 'Cocody',
    'utilisateur': {
      '_id': 'u$id',
      'nom': 'Test',
      'prenom': prenom,
      'email': 'a@b.c',
      'telephone': '0700000000',
      'role': 'PRESTATAIRE',
    },
    'service': {
      '_id': 's$id',
      'nomservice': 'Plombier',
      'imageservice': '',
      'prixmoyen': '8000',
    },
  };
}
