import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/mobile/view/chatpagem/chatpageblocm/chatPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/chatpagem/chatpageblocm/chatPageEventM.dart';
import 'package:sdealsmobile/mobile/view/chatpagem/chatpageblocm/chatPageStateM.dart';

void main() {
  const notConnected = 'Utilisateur non connecté';

  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost\n');
  });

  ChatPageBlocM buildBloc({
    String? userId,
    Future<List<Map<String, dynamic>>> Function(String userId)? loader,
  }) {
    return ChatPageBlocM(
      userId: userId,
      conversationsLoader: loader ??
          (id) async {
            expect(id, isNotEmpty);
            return <Map<String, dynamic>>[];
          },
    );
  }

  test(
    'LoadConversations sans userId → loading, jamais « Utilisateur non connecté »',
    () async {
      final bloc = buildBloc();
      addTearDown(bloc.close);

      final future = expectLater(
        bloc.stream,
        emits(predicate<ChatPageStateM>((s) {
          return s.status == ChatPageStatus.loading && s.error != notConnected;
        })),
      );

      bloc.add(const LoadConversations());
      await future;

      expect(bloc.state.error, isNot(equals(notConnected)));
      expect(bloc.debugPendingLoadConversations, isTrue);
      expect(bloc.debugCurrentUserId, isEmpty);
    },
  );

  test(
    'AuthAuthenticated : userId présent → loaded sans « non connecté »',
    () async {
      final bloc = buildBloc(userId: 'user-abc-123');
      addTearDown(bloc.close);

      final future = expectLater(
        bloc.stream,
        emitsThrough(predicate<ChatPageStateM>((s) {
          return s.status == ChatPageStatus.loaded && s.error != notConnected;
        })),
      );

      bloc.add(const LoadConversations());
      await future;

      expect(bloc.state.status, ChatPageStatus.loaded);
      expect(bloc.state.error, isNot(equals(notConnected)));
    },
  );

  test(
    'Race : LoadConversations avant setUserId → pending puis loaded',
    () async {
      final seenIds = <String>[];
      final bloc = buildBloc(
        loader: (id) async {
          seenIds.add(id);
          return [];
        },
      );
      addTearDown(bloc.close);

      bloc.add(const LoadConversations());
      await bloc.stream.firstWhere((s) => s.status == ChatPageStatus.loading);
      expect(bloc.state.error, isNot(equals(notConnected)));
      expect(bloc.debugPendingLoadConversations, isTrue);

      final future = expectLater(
        bloc.stream,
        emitsThrough(predicate<ChatPageStateM>(
          (s) => s.status == ChatPageStatus.loaded,
        )),
      );

      bloc.setUserId('user-after-auth');
      await future;

      expect(seenIds, ['user-after-auth']);
      expect(bloc.state.error, isNot(equals(notConnected)));
      expect(bloc.debugPendingLoadConversations, isFalse);
    },
  );
}
