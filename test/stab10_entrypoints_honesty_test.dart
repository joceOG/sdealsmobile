import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garde-fous STAB-10 : parcours visibles ne doivent plus mentir.
void main() {
  final root = Directory.current.path.contains('sdealsmobile')
      ? Directory.current.path
      : '${Directory.current.path}${Platform.pathSeparator}sdealsmobile';

  String read(String relative) =>
      File('$root${Platform.pathSeparator}$relative').readAsStringSync();

  test('Inscription vendeur : pas de faux succès déclenchable', () {
    final home = read('lib/mobile/view/home.dart');
    expect(home.contains('SellerRegistrationScreen'), isFalse);
    expect(home.contains('arrive bientôt'), isTrue);
  });

  test('SoutraPay prestataire : pas d’écran simulé ouvert', () {
    final provider = read(
      'lib/mobile/view/provider_dashboard/screens/provider_main_screen.dart',
    );
    expect(provider.contains('ProviderSoutraPayScreen'), isFalse);
    expect(provider.contains('SoutraPay arrive bientôt'), isTrue);
  });

  test('Freelance : aucun fallback getMockFreelancers en prod', () {
    final bloc = read(
      'lib/mobile/view/freelancepagem/freelancepageblocm/freelancePageBlocM.dart',
    );
    expect(bloc.contains('getMockFreelancers'), isFalse);
  });

  test('Matching métiers : pas de MockProviderMatchingService en fallback', () {
    final job = read(
      'lib/mobile/view/jobpagem/jobpageblocm/jobPageBlocM.dart',
    );
    expect(job.contains('MockProviderMatchingService'), isFalse);
  });

  test('Checkout : pas de moyens PSP factices exposés', () {
    final checkout = read(
      'lib/mobile/view/shoppingpagem/screens/confirmationCommandeScreenM.dart',
    );
    expect(checkout.contains('Orange Money'), isFalse);
    expect(checkout.contains('MTN Mobile Money'), isFalse);
    expect(checkout.contains('Wave'), isFalse);
    expect(checkout.contains('reduction: 10.0'), isFalse);
  });
}
