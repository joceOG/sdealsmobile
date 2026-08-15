abstract class SplashscreenStateM {}

class SplashInitialM extends SplashscreenStateM {}

class SplashLoadingM extends SplashscreenStateM {}

/// App prête à naviguer — l’animation peut être interrompue.
class SplashReadyM extends SplashscreenStateM {
  final bool showFullIntro;
  final String destination;
  final Object? destinationExtra;

  SplashReadyM({
    required this.showFullIntro,
    required this.destination,
    this.destinationExtra,
  });
}
