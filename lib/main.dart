import 'dart:async';
import 'package:flutter/foundation.dart';
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
import 'data/services/fcm_route_policy.dart';
import 'data/services/fcm_service.dart';
import 'data/services/protected_action_intent.dart';
import 'mobile/view/common/auth_completion.dart';
import 'config/startup_api.dart';
import 'data/services/startup_trace.dart';
import 'data/services/token_store.dart';
import 'data/utils/go_router_refresh_stream.dart';
import 'mobile/view/locationpagem/locationpageblocm/locationPageBlocM.dart';
import 'mobile/view/home.dart';
import 'mobile/view/loginpagem/screens/loginPageScreenM.dart';
import 'mobile/view/provider_dashboard/screens/provider_main_screen.dart';
import 'mobile/view/provider_dashboard/screens/provider_mission_detail_screen.dart';
import 'mobile/view/provider_dashboard/screens/prestataire_finalization_screen.dart';
import 'mobile/view/onboarding/onboarding_screen.dart';
import 'mobile/view/registerpagem/registerpageblocm/registerPageBlocM.dart';
import 'mobile/view/registerpagem/screens/registerPageScreenM.dart';
import 'mobile/view/serviceproviderregistrationpagem/screens/serviceProviderRegistrationScreenM.dart';
import 'mobile/view/serviceproviderregistrationpagem/serviceproviderregistrationoageblocm/serviceProviderRegistrationPageBlocM.dart';
import 'mobile/view/serviceproviderwelcomepagem/screens/serviceProviderWelcomeScreenM.dart';
import 'mobile/view/freelance_registration/screens/freelance_welcome_screen.dart';
import 'mobile/view/seller_registration/screens/emarket_welcome_screen.dart';
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
import 'design_system/design_system.dart';

/// AuthCubit racine — partagé par GoRouter.redirect et MultiBlocProvider.
late final AuthCubit appAuthCubit;

/// Icônes sombres, sans couleur de barre : Android 15 ignore et signale
/// setStatusBarColor / setNavigationBarColor / setNavigationBarDividerColor.
const SystemUiOverlayStyle _lightSystemBars = SystemUiOverlayStyle(
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarContrastEnforced: false,
  systemStatusBarContrastEnforced: false,
);

void main() async {
  StartupTrace.mark('main');
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await _startApp();
  } on StateError {
    StartupTrace.mark('bootstrap abort StateError');
    runApp(const _StartupFailureApp());
  } catch (e) {
    StartupTrace.mark('bootstrap abort ${e.runtimeType}');
    runApp(const _StartupFailureApp(configuration: false));
  }
}

Future<void> _startApp() async {

  // Photo Picker système (Android) — pas de READ_MEDIA_IMAGES / galerie large.
  final imagePickerImplementation = ImagePickerPlatform.instance;
  if (imagePickerImplementation is ImagePickerAndroid) {
    imagePickerImplementation.useAndroidPhotoPicker = true;
  }

  // Barre de statut + navigation Android en blanc
  // contrastEnforced: false → obligatoire Android 10+ / edge-to-edge (sinon reste noire)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(_lightSystemBars);

  const apiUrlDefine = String.fromEnvironment('API_URL');
  const mapsKeyDefine = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  const legalBaseDefine = String.fromEnvironment('LEGAL_BASE_URL');

  // flutter_dotenv : tout accès à dotenv.env AVANT load/testLoad → NotInitializedError.
  // Ne jamais embarquer un vrai .env (secrets) dans les assets Flutter (extractible).
  // Les defines / valeurs publiques passent par mergeWith après init.
  final mergeWith = <String, String>{
    if (apiUrlDefine.isNotEmpty) 'API_URL': apiUrlDefine,
    if (mapsKeyDefine.isNotEmpty) 'GOOGLE_MAPS_API_KEY': mapsKeyDefine,
    if (legalBaseDefine.isNotEmpty) 'LEGAL_BASE_URL': legalBaseDefine,
  };

  dotenv.testLoad(mergeWith: mergeWith);
  if ((dotenv.env['LEGAL_BASE_URL'] ?? '').trim().isEmpty) {
    dotenv.env['LEGAL_BASE_URL'] = publicLegalBaseUrl;
  }
  dotenv.env['API_URL'] = resolveStartupApiUrl(
    fromEnvironment: dotenv.env['API_URL'] ?? '',
    releaseMode: kReleaseMode,
  );

  StartupTrace.mark('env ok');
  try {
    await TokenStore.hydrate();
    StartupTrace.mark('token hydrate end');
  } catch (e) {
    StartupTrace.mark('token hydrate error ${e.runtimeType}');
  }

  appAuthCubit = AuthCubit();
  StartupTrace.mark('before runApp');
  runApp(MyApp());
}

/// Écran visible si le démarrage release ne peut pas continuer.
/// Remplace un splash natif laissé affiché par une exception avant runApp.
class _StartupFailureApp extends StatelessWidget {
  const _StartupFailureApp({this.configuration = true});

  /// Vrai seulement pour un [StateError] de configuration (URL d’API).
  /// Un délai ou un service secondaire ne doit pas afficher ce texte.
  final bool configuration;

  @override
  Widget build(BuildContext context) {
    final message = configuration
        ? 'Soutrali Deals n’a pas pu démarrer.\n'
            'La configuration du service est incomplète.'
        : 'Soutrali Deals n’a pas pu démarrer.\n'
            'Réessayez dans un instant.';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

bool _deferredBootstrapStarted = false;

bool _sessionResolverAttached = false;

/// Quand la restauration de session se termine APRÈS l'ouverture de
/// l'interface : ouvre la destination conservée (session appliquée) ou mène
/// au login (destination protégée, pas de session). Aucun effet si rien
/// n'est en attente. Une seule installation.
void _attachSessionRestoreResolver(GoRouter router) {
  if (_sessionResolverAttached) return;
  _sessionResolverAttached = true;
  void onStatus() {
    final status = appAuthCubit.restoreStatus.value;
    final action = FcmRoutePolicy.afterSessionRestore(
      settled: status != SessionRestoreStatus.restoring,
      authenticated: appAuthCubit.state is AuthAuthenticated,
      pending: FcmService.instance.peekPendingDestination(),
    );
    switch (action) {
      case PostRestoreAction.openPending:
        final dest = FcmService.instance.consumePendingDestination();
        if (dest != null) router.go(dest);
      case PostRestoreAction.openLogin:
        // La destination reste en attente : le login la consomme.
        router.go('/login');
      case PostRestoreAction.none:
        break;
    }
  }

  appAuthCubit.restoreStatus.addListener(onStatus);
}

Future<void> _deferredBootstrap() async {
  StartupTrace.mark('deferred start');
  try {
    await Hive.initFlutter();
  } catch (e) {
    if (kDebugMode) debugPrint('[startup] Hive: $e');
  }
  try {
    await initializeDateFormatting('fr_FR', null);
  } catch (e) {
    if (kDebugMode) debugPrint('[startup] dates: $e');
  }
  await CrashlyticsService.initialize();
  StartupTrace.mark('fcm deferred start');
  await FcmService.instance.initialize();
  StartupTrace.mark('fcm deferred end');
}

Page<void> _fadeInPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    opaque: false,
    child: child,
    transitionDuration: const Duration(milliseconds: 240),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
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
      if (shouldRedirectAuthedAuthRouteToHome(
        loggedIn: loggedIn,
        location: loc,
        hasPending: ProtectedActionStore.instance.hasPending,
        hasFcmDestination: FcmService.instance.peekPendingDestination() != null,
        routeExtra: state.extra,
      )) {
        ClientShellSelection.showHome();
        return '/homepage';
      }
      final needsAuth =
          _authRequiredPrefixes.any((p) => loc == p || loc.startsWith('$p/'));
      if (needsAuth && !loggedIn) {
        // Restauration encore en cours : on ne sait pas si c'est un invité.
        // Pas de /login (l'utilisateur connecté s'y retrouverait bloqué) :
        // la destination est gardée et rouverte par le résolveur.
        if (appAuthCubit.restoreStatus.value ==
            SessionRestoreStatus.restoring) {
          FcmService.instance.holdDestination(loc);
          return '/homepage';
        }
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            child: BlocProvider(
              create: (_) => SplashscreenBlocM(authCubit: appAuthCubit)
                ..add(LoadSplashM()),
              child: const SplashScreenM(),
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return child;
            },
          );
        },
      ),
      GoRoute(
        path: '/homepage',
        pageBuilder: (context, state) => _fadeInPage(state, const Home()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _fadeInPage(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _fadeInPage(state, const LoginPageScreenM()),
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
        path: '/serviceProviderWelcome',
        builder: (context, state) {
          final categories = state.extra as List<dynamic>; // cast to your type
          return ServiceProviderWelcomeScreenM(categories: categories);
        },
      ),
      GoRoute(
        path: '/freelanceWelcome',
        builder: (context, state) => const FreelanceWelcomeScreen(),
      ),
      GoRoute(
        path: '/emarketWelcome',
        builder: (context, state) => const EmarketWelcomeScreen(),
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
        pageBuilder: (context, state) {
          final utilisateur = state.extra as Utilisateur?;
          return _fadeInPage(
            state,
            ProviderMainScreen(utilisateur: utilisateur),
          );
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
      GoRoute(
        path: '/mission-details/:missionId',
        name: 'mission-details',
        builder: (context, state) {
          final missionId = state.pathParameters['missionId'] ?? '';
          String? prestataireDocId;
          final extra = state.extra;
          if (extra is Map) {
            prestataireDocId = extra['prestataireDocId']?.toString();
          } else if (extra is String && extra.isNotEmpty) {
            prestataireDocId = extra;
          }
          return ProviderMissionDetailScreen(
            missionId: missionId,
            prestataireDocId: prestataireDocId,
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
        if (!_deferredBootstrapStarted) {
          _deferredBootstrapStarted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            StartupTrace.mark('first frame');
            unawaited(_deferredBootstrap());
          });
        }
        _attachSessionRestoreResolver(mobileRouter);
        // Deep-links FCM → GoRouter
        FcmService.instance.onNavigate = (data) {
          final decision = FcmRoutePolicy.decide(
            data,
            loggedIn: appAuthCubit.state is AuthAuthenticated,
          );
          if (decision.resumeAfterAuth != null) {
            FcmService.instance.holdDestination(decision.resumeAfterAuth!);
          }
          if (FcmRoutePolicy.isAllowedPath(decision.route) ||
              decision.route == '/login') {
            mobileRouter.go(decision.route);
          } else {
            mobileRouter.go('/homepage');
          }
        };
        final auth = context.read<AuthCubit>().state;
        if (auth is AuthAuthenticated) {
          Future.microtask(() => FcmService.instance.syncTokenWithBackend());
        }

        return ResponsiveBuilder(builder: (context, sizingInformation) {
          GoRouter router = mobileRouter;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: _lightSystemBars,
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
                  systemOverlayStyle: _lightSystemBars,
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
                      borderRadius:
                          BorderRadius.circular(SDSpacing.borderRadiusMedium),
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
                    side:
                        const BorderSide(color: SDColors.primary600, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(SDSpacing.borderRadiusMedium),
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
                    borderRadius:
                        BorderRadius.circular(SDSpacing.borderRadiusMedium),
                    borderSide:
                        const BorderSide(color: SDColors.neutral300, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(SDSpacing.borderRadiusMedium),
                    borderSide:
                        const BorderSide(color: SDColors.neutral300, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(SDSpacing.borderRadiusMedium),
                    borderSide:
                        const BorderSide(color: SDColors.primary600, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(SDSpacing.borderRadiusMedium),
                    borderSide:
                        const BorderSide(color: SDColors.error500, width: 1),
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
                    borderRadius:
                        BorderRadius.circular(SDSpacing.borderRadiusLarge),
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
