import 'package:flutter/material.dart';

import 'package:sdealsmobile/design_system/design_system.dart';

/// Barre de progression et pied d’action du parcours Prestataire.
class RegistrationStepProgress extends StatelessWidget {
  const RegistrationStepProgress({
    super.key,
    required this.currentStep,
    required this.labels,
  });

  final int currentStep;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(labels.length * 2 - 1, (i) {
            if (i.isOdd) {
              final after = i ~/ 2;
              final done = currentStep > after;
              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: done ? SDColors.primary600 : SDColors.neutral200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }
            final step = i ~/ 2;
            final active = currentStep >= step;
            return Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? SDColors.primary600 : SDColors.neutral100,
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? SDColors.primary600 : SDColors.neutral300,
                ),
              ),
              child: Text(
                '${step + 1}',
                style: SDTypography.labelSmall.copyWith(
                  color: active ? SDColors.white : SDColors.neutral500,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(labels.length, (i) {
            final active = currentStep == i;
            return Expanded(
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: SDTypography.labelSmall.copyWith(
                  color: active ? SDColors.primary700 : SDColors.neutral500,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class RegistrationWizardFooter extends StatelessWidget {
  const RegistrationWizardFooter({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.onBack,
    this.loading = false,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onBack;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottom),
      decoration: BoxDecoration(
        color: SDColors.white,
        boxShadow: [
          BoxShadow(
            color: SDColors.neutral900.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SDButton(
            text: primaryLabel,
            fullWidth: true,
            isLoading: loading,
            onPressed: loading ? null : onPrimary,
          ),
          if (onBack != null) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: loading ? null : onBack,
              child: Text(
                'Retour',
                style: SDTypography.labelMedium.copyWith(
                  color: SDColors.neutral600,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
