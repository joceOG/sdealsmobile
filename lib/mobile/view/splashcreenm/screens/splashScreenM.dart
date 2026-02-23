import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../design_system/design_system.dart';
import '../splashscreenblocm/splashscreenBlocM.dart';
import '../splashscreenblocm/splashscreenStateM.dart';

class SplashScreenM extends StatefulWidget {
  const SplashScreenM({super.key});

  @override
  State<SplashScreenM> createState() => _SplashScreenMState();
}

class _SplashScreenMState extends State<SplashScreenM> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashscreenBlocM, SplashscreenStateM>(
      listener: (context, state) async {
        if (state is SplashLoadedM) {
          final prefs = await SharedPreferences.getInstance();
          final bool onboardingCompleted =
              prefs.getBool('onboarding_completed') ?? false;

          // Petit délai pour laisser l'animation se terminer
          await Future.delayed(const Duration(milliseconds: 1500));
          
          if (mounted) {
            if (onboardingCompleted) {
              context.go('/homepage');
            } else {
              context.go('/onboarding');
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: SDColors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _animation,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/logo1.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              SizedBox(height: SDSpacing.xl),
              // Optionnel: Petit loader discret
              SizedBox(
                width: 24, 
                height: 24, 
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(SDColors.primary600),
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}
