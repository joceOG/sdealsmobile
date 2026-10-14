import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/screens/provider_main_screen.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/widgets/provider_home_dashboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpNav(
    WidgetTester tester, {
    required Size size,
    required EdgeInsets padding,
    EdgeInsets viewPadding = EdgeInsets.zero,
    EdgeInsets gesture = EdgeInsets.zero,
    double textScale = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              size: size,
              padding: padding,
              viewPadding: viewPadding == EdgeInsets.zero ? padding : viewPadding,
              systemGestureInsets: gesture,
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          );
        },
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: ProviderBottomNavigation(
            currentIndex: 0,
            onTap: (_) {},
          ),
        ),
      ),
    );
  }

  void expectLabelFullyVisible(WidgetTester tester, String label, Size size) {
    final para = tester.renderObject<RenderParagraph>(find.text(label));
    expect(para.didExceedMaxLines, isFalse, reason: label);
    final rect = tester.getRect(find.text(label));
    final inset = SDResponsive.systemBottomInset(
      tester.element(find.text(label)),
    );
    expect(rect.bottom, lessThanOrEqualTo(size.height - inset + 0.5));
    expect(rect.right, lessThanOrEqualTo(size.width + 0.5));
    expect(tester.takeException(), isNull);
  }

  for (final width in [320.0, 360.0, 390.0]) {
    testWidgets('nav pro $width — 3 boutons, texte normal', (tester) async {
      final size = Size(width, 640);
      await pumpNav(
        tester,
        size: size,
        padding: const EdgeInsets.only(bottom: 48),
      );
      expectLabelFullyVisible(tester, 'Messages', size);
      expectLabelFullyVisible(tester, 'Planning', size);
    });

    testWidgets('nav pro $width — geste, texte 1.3', (tester) async {
      final size = Size(width, 520);
      await pumpNav(
        tester,
        size: size,
        padding: EdgeInsets.zero,
        viewPadding: EdgeInsets.zero,
        gesture: const EdgeInsets.only(bottom: 24),
        textScale: 1.3,
      );
      expectLabelFullyVisible(tester, 'Accueil', size);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Mes services tient sur 320 sans être coupé', (tester) async {
    const size = Size(320, 568);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              size: size,
              textScaler: const TextScaler.linear(1.3),
              padding: const EdgeInsets.only(bottom: 48),
              viewPadding: const EdgeInsets.only(bottom: 48),
            ),
            child: child!,
          );
        },
        home: Scaffold(
          body: ProviderHomeDashboard(
            fullName: 'Awa K.',
            metier: 'Soudure',
            location: 'Abidjan',
            isVerified: false,
            isAvailable: true,
            onAvailabilityChanged: (_) {},
            pendingMissions: const [],
            demandesRecues: 0,
            missionsEnCours: 0,
            isLoadingStats: false,
            unreadMessages: 0,
            onRefresh: () {},
            onOpenStats: () {},
            onOpenServices: () {},
            onOpenMessages: () {},
            onOpenPlanning: () {},
            onOpenProfile: () {},
            onOpenMissions: () {},
            onOpenMission: (_) {},
            expertMenuAction: const SizedBox(width: 40, height: 40),
            onOpenNotifications: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    final para = tester.renderObject<RenderParagraph>(find.text('Mes services'));
    expect(para.didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });
}
