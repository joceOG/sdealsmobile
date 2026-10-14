import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../../design_system/design_system.dart';

/// Parse le texte saisi (espaces FR autorisés) — `null` si vide.
int? parseProviderDailyRateText(String text) {
  final raw = text.replaceAll(RegExp(r'\s'), '');
  if (raw.isEmpty) return null;
  return int.tryParse(raw);
}

/// Étape 3 — tarif jour, description, récap (ordre maquette).
class ProviderPricingStep extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onDataChanged;
  final VoidCallback? onEditService;
  final VoidCallback? onEditZones;

  const ProviderPricingStep({
    Key? key,
    required this.formData,
    required this.onDataChanged,
    this.onEditService,
    this.onEditZones,
  }) : super(key: key);

  @override
  State<ProviderPricingStep> createState() => _ProviderPricingStepState();
}

class _ProviderPricingStepState extends State<ProviderPricingStep> {
  final TextEditingController _dailyRateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final rate = widget.formData['dailyRate'];
    if (rate is num && rate > 0) {
      _dailyRateController.text = _formatInt(rate.round());
    }
    _descriptionController.text = widget.formData['description']?.toString() ?? '';
  }

  @override
  void dispose() {
    _dailyRateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  static String _formatInt(int v) =>
      NumberFormat('#,###', 'fr_FR').format(v).replaceAll(',', ' ');

  void _syncDailyRateToForm() {
    final raw = _dailyRateController.text.replaceAll(RegExp(r'\s'), '');
    if (raw.isEmpty) {
      widget.onDataChanged({
        'dailyRate': null,
        'dailyRateInvalid': false,
        'dailyRateZero': false,
      });
      return;
    }
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      widget.onDataChanged({
        'dailyRate': null,
        'dailyRateInvalid': true,
        'dailyRateZero': false,
      });
      return;
    }
    if (parsed <= 0) {
      widget.onDataChanged({
        'dailyRate': null,
        'dailyRateInvalid': false,
        'dailyRateZero': true,
      });
      return;
    }
    widget.onDataChanged({
      'dailyRate': parsed.toDouble(),
      'dailyRateInvalid': false,
      'dailyRateZero': false,
    });
  }

  void _syncDescription() {
    widget.onDataChanged({
      'description': _descriptionController.text,
    });
  }

  String? _inlineRateError() {
    if (widget.formData['dailyRateInvalid'] == true) {
      return 'Montant invalide';
    }
    if (widget.formData['dailyRateZero'] == true) {
      return 'Le tarif doit être supérieur à 0 FCFA';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final serviceName =
        (widget.formData['serviceName'] as String?)?.trim().isNotEmpty == true
            ? widget.formData['serviceName'] as String
            : '—';
    final categoryName =
        (widget.formData['categoryName'] as String?)?.trim().isNotEmpty == true
            ? widget.formData['categoryName'] as String
            : '—';
    final areas = List<String>.from(widget.formData['serviceAreas'] ?? []);
    final hasPosition = widget.formData['position'] != null;
    final descLen = _descriptionController.text.length;
    final rateError = _inlineRateError();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tarif par jour (FCFA) *',
          style: SDTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: SDColors.neutral900,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _dailyRateController,
          keyboardType: TextInputType.number,
          inputFormatters: [ProviderFcfaDigitsFormatter()],
          onChanged: (_) {
            setState(() {});
            _syncDailyRateToForm();
          },
          style: SDTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w800,
            color: SDColors.neutral900,
          ),
          decoration: InputDecoration(
            hintText: '15 000',
            suffixText: 'FCFA / jour',
            suffixStyle: SDTypography.labelMedium.copyWith(
              color: SDColors.neutral500,
              fontWeight: FontWeight.w700,
            ),
            filled: true,
            fillColor: SDColors.neutral50,
            errorText: rateError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SDColors.neutral200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: rateError != null
                    ? SDColors.error500
                    : SDColors.neutral200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: rateError != null
                    ? SDColors.error500
                    : SDColors.primary600,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SDColors.error500),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SDColors.error500, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        SizedBox(height: SDSpacing.md),
        Text(
          'Description (optionnelle)',
          style: SDTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: SDColors.neutral900,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _descriptionController,
          maxLines: 5,
          maxLength: 500,
          onChanged: (_) {
            setState(() {});
            _syncDescription();
          },
          decoration: InputDecoration(
            hintText: 'Présentez votre expérience, vos atouts…',
            counterText: '$descLen / 500',
            filled: true,
            fillColor: SDColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SDColors.neutral200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SDColors.neutral200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SDColors.primary600),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SDColors.primary50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SDColors.primary100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: SDColors.primary700, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Une bonne description attire plus de clients et inspire confiance.',
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.primary800,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: SDSpacing.lg),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: SDColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SDColors.neutral200),
          ),
          child: Column(
            children: [
              _RecapRow(
                label: 'Service',
                value: serviceName,
                onEdit: widget.onEditService,
              ),
              const Divider(height: 1, thickness: 1, color: SDColors.neutral100),
              _RecapRow(
                label: 'Catégorie',
                value: categoryName,
              ),
              const Divider(height: 1, thickness: 1, color: SDColors.neutral100),
              _RecapRow(
                label: 'Zones',
                value: areas.isEmpty ? '—' : areas.join(', '),
                onEdit: widget.onEditZones,
              ),
              const Divider(height: 1, thickness: 1, color: SDColors.neutral100),
              _RecapRow(
                label: 'Position GPS',
                value: hasPosition ? 'Renseignée' : 'Non renseignée',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Saisie montant FCFA avec espaces milliers (partagé inscription + espace pro).
class ProviderFcfaDigitsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final n = int.tryParse(digits);
    if (n == null) return oldValue;
    final formatted =
        NumberFormat('#,###', 'fr_FR').format(n).replaceAll(',', ' ');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _RecapRow extends StatelessWidget {
  const _RecapRow({
    required this.label,
    required this.value,
    this.onEdit,
  });

  final String label;
  final String value;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: SDTypography.bodyMedium.copyWith(
                color: SDColors.neutral500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: SDTypography.bodyMedium.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
          if (onEdit != null)
            TextButton(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(48, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Modifier',
                style: SDTypography.labelMedium.copyWith(
                  color: SDColors.primary700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
