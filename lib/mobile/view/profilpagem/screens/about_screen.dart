import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../design_system/design_system.dart';

/// À propos — liens = vitrine soutrali-deals
/// (https://soutralideals-web.onrender.com — routes App.tsx).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const double _hPad = 20;

  /// Aligné sur `pubspec.yaml`.
  static const String appVersion = '1.2.2';
  static const String buildNumber = '8';

  /// Base marketing (soutrali-deals sur Render), pas www.
  static const String _site = 'https://soutralideals-web.onrender.com';
  static const String _cguUrl = '$_site/cgu';
  static const String _privacyUrl = '$_site/confidentialite';
  static const String _cgvUrl = '$_site/cgv';
  static const String _mentionsUrl = '$_site/mentions-legales';
  static const String _cookiesUrl = '$_site/cookies';
  static const String _aboutUrl = '$_site/a-propos';
  static const String _contactUrl = '$_site/contact';
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.sdealsmobile.app';

  /// Vision alignée sur soutrali-deals / aboutContent.
  static const String _mission =
      'Soutrali Deals est une plateforme pensée pour structurer, connecter '
      'et faire grandir l’économie informelle en Côte d’Ivoire — et au-delà. '
      'Une marketplace web et mobile pour découvrir services, freelances et '
      'produits de qualité à proximité, en toute confiance.';

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lien indisponible pour le moment')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lien indisponible pour le moment')),
        );
      }
    }
  }

  Future<void> _rateApp(BuildContext context) async {
    final market = Uri.parse('market://details?id=com.sdealsmobile.app');
    try {
      if (await canLaunchUrl(market)) {
        await launchUrl(market, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    await _openUrl(context, _playStoreUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.neutral50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, _hPad, 0),
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, color: SDColors.neutral900),
                tooltip: 'Retour',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(_hPad, 4, _hPad, 12),
              child: Text(
                'À propos',
                style: SDTypography.displayMedium.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 28),
                children: [
                  _card(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/soutra_splash.png',
                            width: 56,
                            height: 56,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              width: 56,
                              height: 56,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: SDColors.primary600,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'S',
                                style: SDTypography.titleLarge.copyWith(
                                  color: SDColors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Soutrali Deals',
                                style: SDTypography.titleLarge.copyWith(
                                  color: SDColors.neutral900,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Marketplace locale pour services, freelances et vente & achat',
                                style: SDTypography.bodyMedium.copyWith(
                                  color: SDColors.neutral600,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Version $appVersion ($buildNumber)',
                                style: SDTypography.labelMedium.copyWith(
                                  color: SDColors.primary700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notre mission',
                          style: SDTypography.titleMedium.copyWith(
                            color: SDColors.primary700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _mission,
                          style: SDTypography.bodyMedium.copyWith(
                            color: SDColors.neutral800,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _linkRow(
                          icon: Icons.description_outlined,
                          title: 'Conditions d’utilisation',
                          onTap: () => _openUrl(context, _cguUrl),
                        ),
                        _thinDivider(),
                        _linkRow(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Politique de confidentialité',
                          onTap: () => _openUrl(context, _privacyUrl),
                        ),
                        _thinDivider(),
                        _linkRow(
                          icon: Icons.receipt_long_outlined,
                          title: 'Conditions de vente (CGV)',
                          onTap: () => _openUrl(context, _cgvUrl),
                        ),
                        _thinDivider(),
                        _linkRow(
                          icon: Icons.gavel_outlined,
                          title: 'Mentions légales',
                          onTap: () => _openUrl(context, _mentionsUrl),
                        ),
                        _thinDivider(),
                        _linkRow(
                          icon: Icons.cookie_outlined,
                          title: 'Politique cookies',
                          onTap: () => _openUrl(context, _cookiesUrl),
                        ),
                        _thinDivider(),
                        _linkRow(
                          icon: Icons.info_outline,
                          title: 'En savoir plus',
                          onTap: () => _openUrl(context, _aboutUrl),
                        ),
                        _thinDivider(),
                        _linkRow(
                          icon: Icons.mail_outline,
                          title: 'Nous contacter',
                          onTap: () => _openUrl(context, _contactUrl),
                        ),
                        _thinDivider(),
                        _linkRow(
                          icon: Icons.language_outlined,
                          title: 'Site web',
                          onTap: () => _openUrl(context, _site),
                        ),
                        _thinDivider(),
                        _linkRow(
                          icon: Icons.copyright_outlined,
                          title: 'Licences open source',
                          onTap: () => showLicensePage(
                            context: context,
                            applicationName: 'Soutrali Deals',
                            applicationVersion: '$appVersion+$buildNumber',
                          ),
                        ),
                        _thinDivider(),
                        _linkRow(
                          icon: Icons.star_border,
                          title: 'Évaluer l’application',
                          onTap: () => _rateApp(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Text(
                      '© ${DateTime.now().year} Soutrali Deals',
                      style: SDTypography.bodySmall.copyWith(
                        color: SDColors.neutral400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: child,
    );
  }

  Widget _thinDivider() =>
      const Divider(height: 1, color: SDColors.neutral200, indent: 52);

  Widget _linkRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: SDColors.neutral800, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: SDTypography.bodyLarge.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: SDColors.neutral400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
