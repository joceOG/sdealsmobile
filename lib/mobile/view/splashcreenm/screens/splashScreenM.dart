import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../splashscreenblocm/splashscreenBlocM.dart';
import '../splashscreenblocm/splashscreenStateM.dart';

class SplashScreenM extends StatelessWidget {
  const SplashScreenM({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashscreenBlocM, SplashscreenStateM>(
      listener: (context, state) async {
        if (state is SplashLoadedM) {
          final prefs = await SharedPreferences.getInstance();
          final bool onboardingCompleted =
              prefs.getBool('onboarding_completed') ?? false;

          if (onboardingCompleted) {
            context.go('/homepage');
          } else {
            context.go('/onboarding');
          }
        }
      },
      child: Scaffold(
        body: Center(
          child: BlocBuilder<SplashscreenBlocM, SplashscreenStateM>(
            builder: (context, state) {
              if (state is SplashLoadingM) {
                return Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Container(
                        width: 400,
                        height: 400,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/logo1.png'),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const Text('Welcome');
            },
          ),
        ),
      ),
    );
  }
}
