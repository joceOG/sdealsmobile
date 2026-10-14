import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

/// Langue de l’application — Français confirmé, sans choix non déployé.
class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  static const double _hPad = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back,
                        color: SDColors.neutral900),
                    tooltip: 'Retour',
                  ),
                  Expanded(
                    child: Text(
                      'Langue de l’application',
                      style: SDTypography.titleLarge.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(_hPad, 12, _hPad, 32),
                children: [
                  Text(
                    'L’application est disponible en français.',
                    style: SDTypography.bodyMedium.copyWith(
                      color: SDColors.neutral600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: SDColors.primary50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SDColors.primary100),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: SDColors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.language,
                            color: SDColors.primary700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Français',
                                style: SDTypography.bodyLarge.copyWith(
                                  color: SDColors.neutral900,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Langue actuelle',
                                style: SDTypography.bodySmall.copyWith(
                                  color: SDColors.neutral600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.check_circle,
                          color: SDColors.primary600,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'D’autres langues seront proposées ici lorsqu’elles seront disponibles.',
                    style: SDTypography.bodySmall.copyWith(
                      color: SDColors.neutral500,
                      height: 1.4,
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
}
