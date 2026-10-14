import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/chatpagem/chatpageblocm/chatPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/chatpagem/screens/chatPageScreenM.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:9/api\n');
    final dir = await Directory.systemTemp.createTemp('sd-ill-002');
    Hive.init(dir.path);
  });

  testWidgets('messagerie invité affiche SD-ILL-002', (tester) async {
    final auth = AuthCubit();
    final chat = ChatPageBlocM(conversationsLoader: (_) async => []);
    addTearDown(auth.close);
    addTearDown(chat.close);

    tester.view.physicalSize = const Size(390, 844);
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

    final illustration = tester.widget<SDIllustration>(
      find.byType(SDIllustration),
    );
    expect(illustration.asset, SDIllustrations.messagesGuest);
    expect(illustration.loop, isTrue);
    expect(
      find.text('Connectez-vous pour accéder à vos messages'),
      findsOneWidget,
    );
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
    expect(find.byIcon(Icons.forum_outlined), findsNothing);
    expect(find.text('Aucune conversation pour le moment'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
