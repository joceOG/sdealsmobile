import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sdealsmobile/data/models/utilisateur.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/services/websocket_service.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/chatpagem/chatpageblocm/chatPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/chatpagem/chatpageblocm/chatPageEventM.dart';
import 'package:sdealsmobile/mobile/view/chatpagem/screens/chatPageScreenM.dart';

class _TestAuthCubit extends AuthCubit {
  void asClient() {
    emit(
      AuthAuthenticated(
        token: 'token-test',
        utilisateur: Utilisateur(
          idutilisateur: 'user-test',
          nom: 'Kouassi',
          prenom: 'Awa',
          email: 'hidden@example.com',
          password: 'secret',
          telephone: '00000000',
          role: 'CLIENT',
        ),
      ),
    );
  }

  void asGuest() => emit(AuthInitial());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:9/api\n');
    final dir = await Directory.systemTemp.createTemp('sd-ill-003');
    Hive.init(dir.path);
    WebSocketService.debugSkipRealSocket = true;
    WebSocketService.debugSocketTokenFetcher = () async => 'socket-test';
  });

  tearDown(WebSocketService.debugReset);

  Future<void> pumpChat(
    WidgetTester tester, {
    required AuthCubit auth,
    required ChatPageBlocM chat,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: auth),
          BlocProvider<ChatPageBlocM>.value(value: chat),
        ],
        child: const MaterialApp(home: ChatPageScreenM()),
      ),
    );
    await tester.pump();
  }

  String? shownAsset(WidgetTester tester) {
    final found = find.byType(SDIllustration);
    if (found.evaluate().isEmpty) return null;
    return tester.widget<SDIllustration>(found).asset;
  }

  Map<String, dynamic> conversation() => {
        '_id': 'conv-1',
        'updatedAt': '2026-01-01T00:00:00.000Z',
        'interlocuteur': {
          '_id': 'p1',
          'prenom': 'Awa',
          'nom': 'Kouassi',
        },
      };

  testWidgets('connecté sans conversation affiche SD-ILL-003', (tester) async {
    final auth = _TestAuthCubit()..asClient();
    final chat = ChatPageBlocM(
      userId: 'user-test',
      conversationsLoader: (_) async => [],
    );
    addTearDown(auth.close);
    addTearDown(chat.close);

    await pumpChat(tester, auth: auth, chat: chat);
    await tester.pump();

    expect(shownAsset(tester), SDIllustrations.messagesEmptyConnected);
    expect(find.text('Aucune conversation pour le moment'), findsOneWidget);
    expect(
        find.text('Connectez-vous pour accéder à vos messages'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le chargement ne montre pas SD-ILL-003', (tester) async {
    final gate = Completer<List<Map<String, dynamic>>>();
    final auth = _TestAuthCubit()..asClient();
    final chat = ChatPageBlocM(
      userId: 'user-test',
      conversationsLoader: (_) => gate.future,
    );
    addTearDown(auth.close);
    addTearDown(chat.close);

    await pumpChat(tester, auth: auth, chat: chat);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(shownAsset(tester), isNull);

    gate.complete([]);
    await tester.pump();
    await tester.pump();

    expect(shownAsset(tester), SDIllustrations.messagesEmptyConnected);
  });

  testWidgets('une erreur de chargement ne montre pas SD-ILL-003',
      (tester) async {
    final auth = _TestAuthCubit()..asClient();
    final chat = ChatPageBlocM(
      userId: 'user-test',
      conversationsLoader: (_) async => throw Exception('réseau'),
    );
    addTearDown(auth.close);
    addTearDown(chat.close);

    await pumpChat(tester, auth: auth, chat: chat);
    await tester.pump();

    expect(shownAsset(tester), isNull);
    expect(find.text('Aucune conversation pour le moment'), findsNothing);
  });

  testWidgets('une conversation retire SD-ILL-003', (tester) async {
    var calls = 0;
    final auth = _TestAuthCubit()..asClient();
    final chat = ChatPageBlocM(
      userId: 'user-test',
      conversationsLoader: (_) async {
        calls += 1;
        if (calls == 1) return [];
        return [conversation()];
      },
    );
    addTearDown(auth.close);
    addTearDown(chat.close);

    await pumpChat(tester, auth: auth, chat: chat);
    await tester.pump();
    expect(shownAsset(tester), SDIllustrations.messagesEmptyConnected);

    chat.add(const LoadConversations());
    await tester.pump();
    await tester.pump();

    expect(shownAsset(tester), isNull);
    expect(find.text('Awa Kouassi'), findsWidgets);
  });

  testWidgets('déconnexion revient à SD-ILL-002', (tester) async {
    final auth = _TestAuthCubit()..asClient();
    final chat = ChatPageBlocM(
      userId: 'user-test',
      conversationsLoader: (_) async => [],
    );
    addTearDown(auth.close);
    addTearDown(chat.close);

    await pumpChat(tester, auth: auth, chat: chat);
    await tester.pump();
    expect(shownAsset(tester), SDIllustrations.messagesEmptyConnected);

    auth.asGuest();
    await tester.pump();

    expect(shownAsset(tester), SDIllustrations.messagesGuest);
  });

  testWidgets('petit écran sans overflow', (tester) async {
    final auth = _TestAuthCubit()..asClient();
    final chat = ChatPageBlocM(
      userId: 'user-test',
      conversationsLoader: (_) async => [],
    );
    addTearDown(auth.close);
    addTearDown(chat.close);

    await pumpChat(
      tester,
      auth: auth,
      chat: chat,
      size: const Size(320, 568),
    );
    await tester.pump();

    expect(shownAsset(tester), SDIllustrations.messagesEmptyConnected);
    expect(tester.takeException(), isNull);
  });
}
