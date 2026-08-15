/// Config splash de marque Soutrali Deals.
///
/// Pipeline :
/// 1) Native Android : fond blanc + [soutra_splash] centré (ratio conservé)
/// 2) Flutter SplashShell : même fond + même logo (zéro vide)
/// 3) Lottie FULL/SHORT en overlay
class BrandIntroConfig {
  BrandIntroConfig._();

  /// Incrémenter seulement pour refonte marque / expérience de lancement.
  /// v4 : soutra_splash.png + ratio strict (largeur max seule).
  static const int brandIntroVersion = 4;

  static const String prefSeenVersion = 'brand_intro_seen_version';

  /// FULL — storytelling (plafond absolu).
  static const Duration fullMax = Duration(milliseconds: 1700);

  /// SHORT — ouvertures normales (plafond absolu).
  static const Duration shortMax = Duration(milliseconds: 900);

  /// Cible motion design (idéale, sous le plafond).
  static const Duration fullTarget = Duration(milliseconds: 1500);
  static const Duration shortTarget = Duration(milliseconds: 700);

  /// Sécurité : ne jamais rester bloqué si auth/prefs trainent.
  static const Duration absoluteReadyTimeout = Duration(seconds: 5);

  /// Logo statique splash — fond fourni par Flutter/Android (= blanc).
  /// Matcher `android/.../drawable/soutra_splash.png`.
  static const String splashMarkAsset = 'assets/soutra_splash.png';

  /// Vrais JSON Bodymovin.
  static const String lottieFull = 'assets/lottie/soutrali_splash_full.json';
  static const String lottieShort = 'assets/lottie/soutrali_splash_short.json';

  static String lottiePath({required bool full}) =>
      full ? lottieFull : lottieShort;

  /// Largeur max uniquement (jamais hauteur forcée — ratio original).
  static const double logoMaxWidth = 220;
  static const double logoWidthFraction = 0.52;
  static const double logoHorizontalPadding = 40;
}
