import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/utils/legal_urls.dart';
import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';

/// Liens juridiques / conformité — ouvrent les pages web Soutrali Deals.
class SDLegalFooterLinks extends StatelessWidget {
  const SDLegalFooterLinks({super.key});

  static final List<({String label, String url})> _links = [
    (label: 'Conditions générales d\'utilisation', url: LegalUrls.cgu),
    (label: 'Politique de confidentialité', url: LegalUrls.confidentialite),
    (label: 'Politique des cookies', url: LegalUrls.cookies),
    (label: 'Mentions légales', url: LegalUrls.mentions),
  ];

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir : $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = SDTypography.bodySmall.copyWith(
      color: SDColors.primary700,
      decoration: TextDecoration.underline,
      decorationColor: SDColors.primary700,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Conformité et documents légaux',
          textAlign: TextAlign.center,
          style: SDTypography.labelMedium.copyWith(
            color: SDColors.neutral600,
          ),
        ),
        SDSpacing.verticalTinyGap,
        ..._links.map(
          (item) => Padding(
            padding: EdgeInsets.only(bottom: SDSpacing.xxs),
            child: Center(
              child: GestureDetector(
                onTap: () => _open(context, item.url),
                behavior: HitTestBehavior.opaque,
                child: Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: baseStyle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
