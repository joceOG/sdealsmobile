import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

/// SnackBars alignés sur la charte Soutrali (vert primaire, typo Inter).
class AppSnackBar {
  AppSnackBar._();

  static EdgeInsets _floatingMargin(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottom = mq.padding.bottom + 72;
    return EdgeInsets.fromLTRB(SDSpacing.sm, 0, SDSpacing.sm, bottom);
  }

  /// Succès : dégradé vert marque, icône Material (pas d’emoji).
  static void success(
    BuildContext context,
    String message, {
    String? subtitle,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: _floatingMargin(context),
        duration: duration,
        content: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [SDColors.primary600, SDColors.primary800],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: SDColors.primary900.withOpacity(0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SDSpacing.sm,
              vertical: SDSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: SDColors.white.withOpacity(0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.check_rounded,
                      color: SDColors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: SDSpacing.xs),
                Expanded(
                  child: subtitle != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message,
                              style: SDTypography.titleSmall.copyWith(
                                color: SDColors.white,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: SDTypography.bodySmall.copyWith(
                                color: SDColors.white.withOpacity(0.92),
                                height: 1.35,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          message,
                          style: SDTypography.bodyMedium.copyWith(
                            color: SDColors.white,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
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

  /// Erreur : rouge charte.
  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: _floatingMargin(context),
        duration: duration,
        content: DecoratedBox(
          decoration: BoxDecoration(
            color: SDColors.error500,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: SDColors.error500.withOpacity(0.28),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SDSpacing.sm,
              vertical: SDSpacing.sm,
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: SDColors.white, size: 22),
                const SizedBox(width: SDSpacing.xs),
                Expanded(
                  child: Text(
                    message,
                    style: SDTypography.bodyMedium.copyWith(
                      color: SDColors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
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

  /// Information neutre (gris foncé).
  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: _floatingMargin(context),
        duration: duration,
        content: DecoratedBox(
          decoration: BoxDecoration(
            color: SDColors.neutral800,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: SDColors.neutral900.withOpacity(0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SDSpacing.sm,
              vertical: SDSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: SDColors.white.withOpacity(0.95), size: 22),
                const SizedBox(width: SDSpacing.xs),
                Expanded(
                  child: Text(
                    message,
                    style: SDTypography.bodyMedium.copyWith(
                      color: SDColors.white,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
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

  /// Avertissement : accent secondaire.
  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: _floatingMargin(context),
        duration: duration,
        content: DecoratedBox(
          decoration: BoxDecoration(
            color: SDColors.secondary600,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: SDColors.secondary700.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SDSpacing.sm,
              vertical: SDSpacing.sm,
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: SDColors.white, size: 22),
                const SizedBox(width: SDSpacing.xs),
                Expanded(
                  child: Text(
                    message,
                    style: SDTypography.bodyMedium.copyWith(
                      color: SDColors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
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
