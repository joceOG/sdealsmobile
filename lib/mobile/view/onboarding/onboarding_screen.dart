import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../design_system/design_system.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: "Trouvez tout près de vous",
      subtitle:
          "Cartographie intelligente. Découvrez produits et services dans votre zone en temps réel.",
      image: "assets/onboarding/geo.png",
      color: SDColors.primary600, // ✅ Green Soutrali
    ),
    OnboardingContent(
      title: "300+ Métiers à votre service",
      subtitle:
          "Plombiers, menuisiers, designers, développeurs... Trouvez l'expert qu'il vous faut.",
      image: "assets/onboarding/pros.png",
      color: SDColors.warning, // ✅ Orange Pro
    ),
    OnboardingContent(
      title: "Achetez ce que vous voulez",
      subtitle:
          "Des milliers de produits. Électronique, mode, maison. Livraison rapide partout à Abidjan.",
      image: "assets/onboarding/shop.png",
      color: SDColors.secondary, // ✅ Purple Shop
    ),
    OnboardingContent(
      title: "Un compte, tout les possibles",
      subtitle:
          "Client, Prestataire, Freelance, Vendeur. Changez de rôle en un clic selon vos besoins.",
      image: "assets/onboarding/roles.png",
      color: SDColors.info, // ✅ Blue Roles
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      body: Stack(
        children: [
          // Background Animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            color: SDColors.white,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (value) {
                setState(() {
                  _currentPage = value;
                });
              },
              itemCount: _contents.length,
              itemBuilder: (context, index) {
                return OnboardingPage(content: _contents[index]);
              },
            ),
          ),

          // Bottom Navigation Area
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(SDSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    SDColors.white,
                    SDColors.white.withOpacity(0.0),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _contents.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? _contents[_currentPage].color
                              : SDColors.neutral300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: SDSpacing.xl),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Skip Button
                      if (_currentPage != _contents.length - 1)
                        TextButton(
                          onPressed: _completeOnboarding,
                          child: Text(
                            "Passer",
                            style: SDTypography.bodyLarge.copyWith(
                              color: SDColors.neutral600,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 60), // Spacer

                      // Next / Start Button
                      ElevatedButton(
                        onPressed: () {
                          if (_currentPage == _contents.length - 1) {
                            _completeOnboarding();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _contents[_currentPage].color,
                          foregroundColor: SDColors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: SDSpacing.xl,
                            vertical: SDSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          _currentPage == _contents.length - 1
                              ? "C'est parti !"
                              : "Suivant",
                          style: SDTypography.labelLarge.copyWith(
                            color: SDColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SDSpacing.md),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      context.go('/homepage');
    }
  }
}

class OnboardingContent {
  final String title;
  final String subtitle;
  final String image;
  final Color color;

  OnboardingContent({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.color,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingContent content;

  const OnboardingPage({Key? key, required this.content}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(SDSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: content.color.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  content.image,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SizedBox(height: SDSpacing.xxl),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Text(
                  content.title,
                  textAlign: TextAlign.center,
                  style: SDTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: SDColors.neutral900,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: SDSpacing.md),
                Text(
                  content.subtitle,
                  textAlign: TextAlign.center,
                  style: SDTypography.bodyLarge.copyWith(
                    color: SDColors.neutral600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
