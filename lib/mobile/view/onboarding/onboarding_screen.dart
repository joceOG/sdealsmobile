import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../design_system/design_system.dart';

/// Accent onboarding — vert Soutrali
const Color _kOnboardingAccent = SDColors.primary600;
const Color _kOnboardingTitle = Color(0xFF0A1931);

const SystemUiOverlayStyle _kOnboardingSystemUi = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: Colors.white,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarContrastEnforced: false,
  systemStatusBarContrastEnforced: false,
);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: 'Trouvez tout\nprès de vous',
      subtitle:
          'Cartographie intelligente. Découvrez produits et services dans votre zone en temps réel.',
      image: 'assets/onboarding/geo.png',
    ),
    OnboardingContent(
      title: '300+ Métiers\nà votre service',
      subtitle:
          'Plombiers, menuisiers, designers, développeurs... Trouvez l\'expert qu\'il vous faut.',
      image: 'assets/onboarding/pros.png',
    ),
    OnboardingContent(
      title: 'Achetez ce\nque vous voulez',
      subtitle:
          'Des milliers de produits. Électronique, mode, maison. Livraison rapide partout à Abidjan.',
      image: 'assets/onboarding/shop.png',
    ),
    OnboardingContent(
      title: 'Un compte,\ntout les possibles',
      subtitle:
          'Client, Prestataire, Freelance, Vendeur. Changez de rôle en un clic selon vos besoins.',
      image: 'assets/onboarding/roles.png',
    ),
  ];

  bool get _isLastPage => _currentPage == _contents.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_isLastPage) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      context.go('/homepage');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _kOnboardingSystemUi,
      child: Scaffold(
      backgroundColor: SDColors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (value) => setState(() => _currentPage = value),
            itemCount: _contents.length,
            itemBuilder: (context, index) {
              return _OnboardingSlide(content: _contents[index]);
            },
          ),

          // Passer (haut droite)
          if (!_isLastPage)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 8,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  'Passer',
                  style: SDTypography.labelLarge.copyWith(
                    color: SDColors.neutral500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Indicateurs + bouton rond flèche
          Positioned(
            left: 24,
            right: 24,
            bottom: bottomInset + 20,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: List.generate(_contents.length, (index) {
                      final active = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(right: 6),
                        height: 6,
                        width: active ? 28 : 8,
                        decoration: BoxDecoration(
                          color: active
                              ? _kOnboardingAccent
                              : SDColors.neutral200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
                _RoundArrowButton(
                  color: _kOnboardingAccent,
                  onTap: _goNext,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class OnboardingContent {
  final String title;
  final String subtitle;
  final String image;

  const OnboardingContent({
    required this.title,
    required this.subtitle,
    required this.image,
  });
}

class _OnboardingSlide extends StatelessWidget {
  final OnboardingContent content;

  const _OnboardingSlide({required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Grande image + flou / fondu bas (style capture 01)
        Expanded(
          flex: 58,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                content.image,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => Container(
                  color: SDColors.neutral100,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_outlined,
                    size: 64,
                    color: SDColors.neutral300,
                  ),
                ),
              ),
              // Léger soft-blur sur le bas de l'image
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 120,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              // Fondu blanc vers le texte
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 180,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        SDColors.white.withOpacity(0),
                        SDColors.white.withOpacity(0.75),
                        SDColors.white,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Texte bas, aligné à gauche (style capture 01)
        Expanded(
          flex: 42,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.title,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontSize: 34,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                    color: _kOnboardingTitle,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  content.subtitle,
                  textAlign: TextAlign.left,
                  style: SDTypography.bodyLarge.copyWith(
                    color: SDColors.neutral500,
                    height: 1.45,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Bouton rond + flèche (capture 02)
class _RoundArrowButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _RoundArrowButton({
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 58,
          height: 58,
          child: Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}
