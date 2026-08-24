import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sdealsmobile/data/models/vendeur.dart' hide Utilisateur;
import 'data/models/utilisateur.dart';
import 'data/services/authCubit.dart';
import 'data/services/crashlytics_service.dart';
import 'data/services/fcm_service.dart';
import 'data/services/token_store.dart';
import 'data/utils/go_router_refresh_stream.dart';
import 'mobile/view/locationpagem/locationpageblocm/locationPageBlocM.dart';
import 'mobile/view/home.dart';
import 'mobile/view/loginpagem/screens/loginPageScreenM.dart';
import 'mobile/view/provider_dashboard/screens/provider_main_screen.dart';
import 'mobile/view/provider_dashboard/screens/prestataire_finalization_screen.dart';
import 'mobile/view/onboarding/onboarding_screen.dart';
import 'mobile/view/registerpagem/registerpageblocm/registerPageBlocM.dart';
import 'mobile/view/registerpagem/screens/registerPageScreenM.dart';
import 'mobile/view/serviceproviderregistrationpagem/screens/serviceProviderRegistrationScreenM.dart';
import 'mobile/view/serviceproviderregistrationpagem/serviceproviderregistrationoageblocm/serviceProviderRegistrationPageBlocM.dart';
import 'mobile/view/serviceproviderwelcomepagem/screens/serviceProviderWelcomeScreenM.dart';
import 'mobile/view/shoppingpagem/screens/vendorDetailsScreenM.dart';
import 'mobile/view/splashcreenm/screens/splashScreenM.dart';
import 'mobile/view/splashcreenm/splashscreenblocm/splashscreenBlocM.dart';
import 'mobile/view/splashcreenm/splashscreenblocm/splashscreenEventM.dart';
import 'mobile/view/walletpagem/screens/walletPageScreenM.dart';
import 'mobile/view/chatpagem/screens/chatPageScreenM.dart';
import 'mobile/view/chatpagem/chatpageblocm/chatPageBlocM.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:hive_flutter/hive_flutter.dart';

// Design System
import 'design_system/design_system.dart';

/// AuthCubit racine — partagé par GoRouter.redirect et MultiBlocProvider.
late final AuthCubit appAuthCubit;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Photo Picker système (Android) — pas de READ_MEDIA_IMAGES / galerie large.
  final imagePickerImplementation = ImagePickerPlatform.instance;
  if (imagePickerImplementation is ImagePickerAndroid) {
    imagePickerImplementation.useAndroidPhotoPicker = true;
  }

  // Barre de statut + navigation Android en blanc
  // contrastEnforced: false → obligatoire Android 10+ / edge-to-edge (sinon reste noire)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    ),
  );

  await Hive.initFlutter();
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    try {
      await dotenv.load(fileName: ".env.example");
    } catch (_) {}
  }
  const apiUrlDefine = String.fromEnvironment('API_URL');
  const mapsKeyDefine = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  if (apiUrlDefine.isNotEmpty) dotenv.env['API_URL'] = apiUrlDefine;
  if (mapsKeyDefine.isNotEmpty) {
    dotenv.env['GOOGLE_MAPS_API_KEY'] = mapsKeyDefine;
  }
  await initializeDateFormatting('fr_FR', null);

  // Firebase + Crashlytics (no-op si non configuré)
  await CrashlyticsService.initialize();
  // FCM local (permissions + token) — sans await réseau backend (voir FcmService).
  await FcmService.instance.initialize();

  // AUTH-REFRESH : hydrater TokenStore avant AuthCubit / premières requêtes.
  await TokenStore.hydrate();

  appAuthCubit = AuthCubit();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static const _authRequiredPrefixes = [
    '/wallet',
    '/providermain',
    '/prestataire-finalization',
    '/mission-details',
    '/chat',
  ];

  final GoRouter mobileRouter = GoRouter(
    refreshListenable: GoRouterRefreshStream(appAuthCubit.stream),
    redirect: (context, state) {
      final loggedIn = appAuthCubit.state is AuthAuthenticated;
      final loc = state.matchedLocation;
      if (loggedIn && (loc == '/login' || loc == '/register')) {
        return '/homepage';
      }
      final needsAuth =
          _authRequiredPrefixes.any((p) => loc == p || loc.startsWith('$p/'));
      if (needsAuth && !loggedIn) return '/login';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          return BlocProvider(
            create: (_) => SplashscreenBlocM(authCubit: appAuthCubit)
              ..add(LoadSplashM()),
            child: const SplashScreenM(),
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
        builder: (context, state) => const LoginPageScreenM(),
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
          return const WalletPageScreenM();
        },
      ),
      GoRoute(
        path: '/wallet/profile',
        builder: (context, state) {
          return const WalletPageScreenM();
        },
      ),
      // Deep-link mission → écran d'aiguillage (plus de TODO placeholder)
      GoRoute(
        path: '/mission-details/:missionId',
        name: 'mission-details',
        builder: (context, state) {
          final missionId = state.pathParameters['missionId'] ?? '';
          return Scaffold(
            backgroundColor: SDColors.white,
            appBar: SDWhiteAppBar.appBar(
              title: 'Mission',
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.assignment,
                        size: 64, color: SDColors.primary600),
                    const SizedBox(height: 16),
                    Text(
                      'Mission #$missionId',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ouvrez le tableau prestataire pour gérer cette mission.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.go('/providermain'),
                      child: const Text('Voir mes missions'),
                    ),
                  ],
                ),
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
              ? authState.utilisateur.idutilisateur
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
        BlocProvider<AuthCubit>.value(
          value: appAuthCubit,
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

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.dark,
            systemNavigationBarContrastEnforced: false,
            systemStatusBarContrastEnforced: false,
          ),
          child: MaterialApp.router(
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
              error: SDColors.error500,
              onPrimary: SDColors.white,
              onSecondary: SDColors.white,
              onSurface: SDColors.neutral900,
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
              backgroundColor: SDColors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              surfaceTintColor: Colors.transparent,
              foregroundColor: SDColors.neutral900,
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
                systemNavigationBarColor: Colors.white,
                systemNavigationBarIconBrightness: Brightness.dark,
                systemNavigationBarContrastEnforced: false,
                systemStatusBarContrastEnforced: false,
              ),
              titleTextStyle: SDTypography.displayMedium.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w700,
              ),
              iconTheme: const IconThemeData(
                color: SDColors.neutral900,
                size: 22,
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
              shadowColor: SDColors.neutral900.withValues(alpha: 0.1),
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
        ),
        );
      });
      }),
    );
  }
}
