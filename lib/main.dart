import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sdealsmobile/data/models/article.dart';
import 'package:sdealsmobile/data/models/vendeur.dart' hide Utilisateur;
import 'data/models/categorie.dart';
import 'data/models/utilisateur.dart';
import 'data/services/authCubit.dart';
import 'data/services/fcm_service.dart';
import 'mobile/view/locationpagem/locationpageblocm/locationPageBlocM.dart';
import 'mobile/view/home.dart';
import 'mobile/view/loginpagem/loginpageblocm/loginPageBlocM.dart';
import 'mobile/view/loginpagem/screens/loginPageScreenM.dart';
import 'mobile/view/provider_dashboard/screens/provider_main_screen.dart';
import 'mobile/view/provider_dashboard/screens/prestataire_finalization_screen.dart';
import 'mobile/view/onboarding/onboarding_screen.dart';
import 'mobile/view/registerpagem/registerpageblocm/registerPageBlocM.dart';
import 'mobile/view/registerpagem/screens/registerPageScreenM.dart';
import 'mobile/view/serviceproviderregistrationpagem/screens/serviceProviderRegistrationScreenM.dart';
import 'mobile/view/serviceproviderregistrationpagem/serviceproviderregistrationoageblocm/serviceProviderRegistrationPageBlocM.dart';
import 'mobile/view/serviceproviderwelcomepagem/screens/serviceProviderWelcomeScreenM.dart';
import 'mobile/view/shoppingpagem/screens/productDetailsScreenM.dart';
import 'mobile/view/shoppingpagem/screens/vendorDetailsScreenM.dart';
import 'mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageBlocM.dart';
import 'mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageEventM.dart'
    as shoppingPageEventM;
import 'mobile/view/splashcreenm/screens/splashScreenM.dart';
import 'mobile/view/splashcreenm/splashscreenblocm/splashscreenBlocM.dart';
import 'mobile/view/splashcreenm/splashscreenblocm/splashscreenEventM.dart';
import 'mobile/view/walletpagem/screens/walletPageScreenM.dart';
import 'mobile/view/walletpagem/soutrapayblocm/soutra_wallet_bloc.dart';
import 'mobile/view/chatpagem/screens/chatPageScreenM.dart';
import 'mobile/view/chatpagem/chatpageblocm/chatPageBlocM.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:hive_flutter/hive_flutter.dart';

// Design System
import 'design_system/design_system.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('fr_FR', null);

  // FCM : no-op si Firebase non configuré (pas de google-services.json)
  await FcmService.instance.initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final GoRouter mobileRouter = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          return BlocProvider(
            create: (_) => SplashscreenBlocM()..add(LoadSplashM()),
            child: SplashScreenM(),
          );
        },
      ),
      GoRoute(
        path: '/homepage',
        builder: (context, state) => const Home(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          return BlocProvider(
            create: (context) => RegisterPageBlocM(),
            child: RegisterPageScreenM(),
          );
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          return BlocProvider(
            create: (context) => LoginPageBlocM(),
            child: LoginPageScreenM(),
          );
        },
      ),
      GoRoute(
        path: '/serviceProviderWelcome',
        builder: (context, state) {
          final categories = state.extra as List<dynamic>; // cast to your type
          return ServiceProviderWelcomeScreenM(categories: categories);
        },
      ),
      GoRoute(
        path: '/serviceProviderRegistration',
        builder: (context, state) {
          return BlocProvider(
            create: (_) => ServiceProviderRegistrationBlocM(),
            child: const ServiceProviderRegistrationScreenM(),
          );
        },
      ),
      GoRoute(
        path: '/providermain',
        name: 'providermain',
        builder: (context, state) {
          final utilisateur = state.extra as Utilisateur?;
          return ProviderMainScreen(utilisateur: utilisateur);
        },
      ),
      GoRoute(
        path: '/prestataire-finalization',
        name: 'prestataire-finalization',
        builder: (context, state) {
          return PrestataireFinalizationScreen(
            prestataireId: state.extra as String?,
          );
        },
      ),
      GoRoute(
        path: '/vendeurDetails',
        name: 'vendeurDetails',
        builder: (context, state) {
          final vendeur = state.extra as Vendeur;
          return VendorDetailsScreenM(vendeur: vendeur);
        },
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) {
          return BlocProvider(
            create: (context) => SoutraWalletBloc(),
            child: const WalletPageScreenM(),
          );
        },
      ),
      GoRoute(
        path: '/wallet/profile',
        builder: (context, state) {
          return BlocProvider(
            create: (context) => SoutraWalletBloc(),
            child: const WalletPageScreenM(), // Ou créer un ProfileScreen dédié
          );
        },
      ),
      // 🎯 Route pour les détails de mission (depuis notifications)
      GoRoute(
        path: '/mission-details/:missionId',
        name: 'mission-details',
        builder: (context, state) {
          final missionId = state.pathParameters['missionId'] ?? '';
          // TODO: Créer MissionDetailsScreen
          return Scaffold(
            appBar: AppBar(
              title: const Text('Détails Mission'),
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment, size: 64, color: Color(0xFF2E7D32)),
                  const SizedBox(height: 16),
                  const Text(
                    'Écran Mission à implémenter',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mission ID: $missionId',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'TODO: Créer MissionDetailsScreen',
                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      // 💬 Route pour le chat (depuis notifications)
      GoRoute(
        path: '/chat/:conversationId',
        name: 'chat',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId'] ?? '';
          final authState = context.read<AuthCubit>().state;
          final userId = authState is AuthAuthenticated
              ? (authState.utilisateur.idutilisateur ?? '')
              : '';
          return BlocProvider(
            create: (_) => ChatPageBlocM(userId: userId),
            child: ChatPageScreenM(conversationId: conversationId),
          );
        },
      ),
    ],
  );

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // 👇 AuthCubit global pour toute l'application
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(),
        ),
        // 👇 LocationPageBlocM pour la géolocalisation
        BlocProvider<LocationPageBlocM>(
          create: (_) => LocationPageBlocM(),
        ),
      ],
      child: Builder(builder: (context) {
        // Deep-links FCM → GoRouter
        FcmService.instance.onNavigate = (data) {
          final route = FcmService.resolveRoute(data);
          if (route != null && route.isNotEmpty) {
            mobileRouter.go(route);
          }
        };
        final auth = context.read<AuthCubit>().state;
        if (auth is AuthAuthenticated) {
          Future.microtask(() => FcmService.instance.syncTokenWithBackend());
        }

        return ResponsiveBuilder(builder: (context, sizingInformation) {
        GoRouter router = mobileRouter;

        return MaterialApp.router(
          routerConfig: router,
          title: 'Soutrali Deals',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            // ═══════════════════════════════════════
            // COLORS
            // ═══════════════════════════════════════
            useMaterial3: true,
            primaryColor: SDColors.primary500,
            scaffoldBackgroundColor: SDColors.neutral50,
            cardColor: SDColors.white,
            dividerColor: SDColors.neutral300,
            
            colorScheme: ColorScheme.light(
              primary: SDColors.primary600,
              secondary: SDColors.secondary500,
              surface: SDColors.white,
              background: SDColors.neutral50,
              error: SDColors.error500,
              onPrimary: SDColors.white,
              onSecondary: SDColors.white,
              onSurface: SDColors.neutral900,
              onBackground: SDColors.neutral900,
              onError: SDColors.white,
            ),
            
            // ═══════════════════════════════════════
            // TYPOGRAPHY
            // ═══════════════════════════════════════
            fontFamily: SDTypography.fontFamily,
            textTheme: TextTheme(
              displayLarge: SDTypography.displayLarge,
              displayMedium: SDTypography.displayMedium,
              displaySmall: SDTypography.displaySmall,
              titleLarge: SDTypography.titleLarge,
              titleMedium: SDTypography.titleMedium,
              titleSmall: SDTypography.titleSmall,
              bodyLarge: SDTypography.bodyLarge,
              bodyMedium: SDTypography.bodyMedium,
              bodySmall: SDTypography.bodySmall,
              labelLarge: SDTypography.labelLarge,
              labelMedium: SDTypography.labelMedium,
              labelSmall: SDTypography.labelSmall,
            ),
            
            // ═══════════════════════════════════════
            // APPBAR
            // ═══════════════════════════════════════
            appBarTheme: AppBarTheme(
              backgroundColor: SDColors.primary500,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: SDTypography.titleLarge.copyWith(
                color: SDColors.white,
              ),
              iconTheme: const IconThemeData(
                color: SDColors.white,
                size: 24,
              ),
            ),
            
            // ═══════════════════════════════════════
            // BUTTONS
            // ═══════════════════════════════════════
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: SDColors.primary600,
                foregroundColor: SDColors.white,
                textStyle: SDTypography.labelLarge,
                padding: SDSpacing.buttonPadding,
                minimumSize: const Size(120, SDSpacing.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                ),
                elevation: 2,
              ),
            ),
            
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: SDColors.primary600,
                textStyle: SDTypography.labelLarge,
                padding: SDSpacing.buttonPadding,
                minimumSize: const Size(120, SDSpacing.buttonHeight),
                side: const BorderSide(color: SDColors.primary600, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                ),
              ),
            ),
            
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: SDColors.primary600,
                textStyle: SDTypography.labelLarge,
                padding: SDSpacing.buttonPadding,
              ),
            ),
            
            // ═══════════════════════════════════════
            // INPUT FIELDS
            // ═══════════════════════════════════════
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: SDColors.white,
              contentPadding: SDSpacing.inputPadding,
              
              labelStyle: SDTypography.bodyMedium.copyWith(
                color: SDColors.neutral600,
              ),
              hintStyle: SDTypography.bodyMedium.copyWith(
                color: SDColors.neutral400,
              ),
              errorStyle: SDTypography.bodySmall.copyWith(
                color: SDColors.error500,
              ),
              
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                borderSide: const BorderSide(color: SDColors.neutral300, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                borderSide: const BorderSide(color: SDColors.neutral300, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                borderSide: const BorderSide(color: SDColors.primary600, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                borderSide: const BorderSide(color: SDColors.error500, width: 1),
              ),
            ),
            
            // ═══════════════════════════════════════
            // CARDS
            // ═══════════════════════════════════════
            cardTheme: CardThemeData(
              color: SDColors.white,
              elevation: 2,
              shadowColor: SDColors.neutral900.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
              ),
            ),
            
            // ═══════════════════════════════════════
            // LIST TILES
            // ═══════════════════════════════════════
            listTileTheme: ListTileThemeData(
              contentPadding: const EdgeInsets.all(SDSpacing.sm),
              titleTextStyle: SDTypography.titleMedium,
              subtitleTextStyle: SDTypography.bodyMedium.copyWith(
                color: SDColors.neutral600,
              ),
            ),
            
            // ═══════════════════════════════════════
            // FLOATING ACTION BUTTON
            // ═══════════════════════════════════════
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: SDColors.primary600,
              foregroundColor: SDColors.white,
              elevation: 4,
            ),
            
            // ═══════════════════════════════════════
            // BOTTOM NAVIGATION BAR
            // ═══════════════════════════════════════
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: SDColors.white,
              selectedItemColor: SDColors.primary600,
              unselectedItemColor: SDColors.neutral500,
              selectedLabelStyle: SDTypography.labelSmall,
              unselectedLabelStyle: SDTypography.labelSmall,
              type: BottomNavigationBarType.fixed,
            ),

            // SnackBars bruts (sans AppSnackBar) : couleur marque + coins arrondis
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              elevation: 2,
              backgroundColor: SDColors.primary700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentTextStyle: SDTypography.bodyMedium.copyWith(
                color: SDColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      });
      }),
    );
  }
}
