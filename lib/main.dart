import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sdealsmobile/data/models/article.dart';
import 'data/models/categorie.dart';
import 'data/models/utilisateur.dart';
import 'data/services/authCubit.dart';
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
import 'mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageBlocM.dart';
import 'mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageEventM.dart'
    as shoppingPageEventM;
import 'mobile/view/splashcreenm/screens/splashScreenM.dart';
import 'mobile/view/splashcreenm/splashscreenblocm/splashscreenBlocM.dart';
import 'mobile/view/splashcreenm/splashscreenblocm/splashscreenEventM.dart';
import 'mobile/view/walletpagem/screens/walletPageScreenM.dart';
import 'mobile/view/walletpagem/soutrapayblocm/soutra_wallet_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('fr_FR', null);

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
          return PrestataireFinalizationScreen();
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
          // TODO: Créer ou utiliser ChatScreen existant
          return Scaffold(
            appBar: AppBar(
              title: const Text('Conversation'),
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble, size: 64, color: Color(0xFF2E7D32)),
                  const SizedBox(height: 16),
                  const Text(
                    'Écran Chat à implémenter',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Conversation ID: $conversationId',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'TODO: Utiliser ChatPageScreenM existant',
                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
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
      child: ResponsiveBuilder(builder: (context, sizingInformation) {
        GoRouter router = mobileRouter;

        return MaterialApp.router(
          routerConfig: router,
          title: 'Soutrali Deals',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            useMaterial3: true,
            inputDecorationTheme: const InputDecorationTheme(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    borderSide: BorderSide(
                      color: Colors.grey,
                      width: 1.5,
                    )),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    borderSide: BorderSide(
                      color: Colors.grey,
                      width: 1.5,
                    )),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)),
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14)),
          ),
        );
      }),
    );
  }
}
