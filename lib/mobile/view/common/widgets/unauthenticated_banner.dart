import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../design_system/design_system.dart';

/// Widget bannière "non connecté" — réutilisable sur tous les écrans.
/// Affiche une illustration, un titre, une description et les boutons Se connecter / Créer un compte.
class UnauthenticatedBanner extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? appBarTitle;

  const UnauthenticatedBanner({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.lock_outline_rounded,
    this.appBarTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: appBarTitle != null
          ? SDAppBarIconThemed(
              style: SDAppBarIconStyles.onLightSurface,
              bar: AppBar(
              backgroundColor: SDColors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: SDColors.neutral900,
              iconTheme: const IconThemeData(
                color: SDColors.neutral900,
                size: 22,
              ),
              title: Text(
                appBarTitle!,
                style: SDTypography.titleLarge.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône dans un cercle
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: SDColors.primary50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 56,
                    color: SDColors.primary600,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  title,
                  style: SDTypography.titleLarge.copyWith(
                    color: SDColors.neutral900,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: SDTypography.bodyMedium.copyWith(
                    color: SDColors.neutral500,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                // Bouton Se connecter
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SDColors.primary600,
                      foregroundColor: SDColors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: SDSpacing.lg,
                        vertical: SDSpacing.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            SDSpacing.borderRadiusMedium),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Se connecter',
                      style: SDTypography.labelMedium.copyWith(
                        color: SDColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: SDSpacing.sm),
                // Bouton Créer un compte
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.push('/register'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SDColors.primary700,
                      side: const BorderSide(
                          color: SDColors.primary600, width: 1.5),
                      padding: EdgeInsets.symmetric(
                        horizontal: SDSpacing.lg,
                        vertical: SDSpacing.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            SDSpacing.borderRadiusMedium),
                      ),
                    ),
                    child: Text(
                      'Créer un compte',
                      style: SDTypography.labelMedium.copyWith(
                        color: SDColors.primary700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
