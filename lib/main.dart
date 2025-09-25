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
          final utilisateur = state.extra as Utilisateur;
          return ProviderMainScreen(utilisateur: utilisateur);
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
