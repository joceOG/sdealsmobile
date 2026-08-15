import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../design_system/design_system.dart';

/// Étape 3 Figma — récap + tarif jour + description.
class ProviderPricingStep extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onDataChanged;
  final VoidCallback? onEditSummary;

  const ProviderPricingStep({
    Key? key,
    required this.formData,
    required this.onDataChanged,
    this.onEditSummary,
  }) : super(key: key);

  @override
  State<ProviderPricingStep> createState() => _ProviderPricingStepState();
}

class _ProviderPricingStepState extends State<ProviderPricingStep> {
  final TextEditingController _dailyRateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  static const _presets = [10000, 15000, 20000];

  @override
  void initState() {
    super.initState();
    final rate = widget.formData['dailyRate'];
    if (rate != null && rate != 0.0 && rate != 0) {
      _dailyRateController.text = _formatInt((rate as num).round());
    }
    _descriptionController.text = widget.formData['description'] ?? '';
  }

  @override
  void dispose() {
    _dailyRateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatInt(int v) =>
      NumberFormat('#,###', 'fr_FR').format(v).replaceAll(',', ' ');

  int? get _parsedRate {
    final raw = _dailyRateController.text.replaceAll(RegExp(r'\s'), '');
    return int.tryParse(raw);
  }

  void _updateFormData() {
    widget.onDataChanged({
      'dailyRate': (_parsedRate ?? 0).toDouble(),
      'description': _descriptionController.text,
    });
  }

  void _applyPreset(int value) {
    setState(() => _dailyRateController.text = _formatInt(value));
    _updateFormData();
  }

  @override
  Widget build(BuildContext context) {
    final serviceName =
        (widget.formData['serviceName'] as String?)?.trim().isNotEmpty == true
            ? widget.formData['serviceName']
            : '—';
    final categoryName =
        (widget.formData['categoryName'] as String?)?.trim().isNotEmpty == true
            ? widget.formData['categoryName']
            : '—';
    final areas = List<String>.from(widget.formData['serviceAreas'] ?? []);
    final hasPosition = widget.formData['position'] != null;
    final descLen = _descriptionController.text.length;
    final current = _parsedRate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SDColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SDColors.neutral200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Récapitulatif',
                    style: SDTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: SDColors.neutral900,
                    ),
                  ),
                  const Spacer(),
                  if (widget.onEditSummary != null)
                    IconButton(
                      tooltip: 'Modifier',
                      onPressed: widget.onEditSummary,
                      icon: const Icon(Icons.edit_outlined,
                          color: SDColors.primary600, size: 20),
                    ),
                ],
              ),
              _RecapLine(label: 'Service', value: '$serviceName'),
              _RecapLine(label: 'Catégorie', value: '$categoryName'),
              _RecapLine(
                label: 'Zones',
                value: areas.isEmpty ? '—' : areas.join(', '),
              ),
              _RecapLine(
                label: 'Position',
                value: hasPosition ? 'Renseignée' : 'Non renseignée',
              ),
            ],
          ),
        ),
        SizedBox(height: SDSpacing.md),
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
          onChanged: (_) {
            setState(() {});
            _updateFormData();
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
              borderSide: const BorderSide(color: SDColors.primary600, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._presets.map((p) {
              final selected = current == p;
              return ChoiceChip(
                label: Text(_formatInt(p)),
                selected: selected,
                onSelected: (_) => _applyPreset(p),
                selectedColor: SDColors.primary50,
                labelStyle: SDTypography.labelMedium.copyWith(
                  color: selected ? SDColors.primary800 : SDColors.neutral700,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(
                  color: selected ? SDColors.primary600 : SDColors.neutral300,
                ),
              );
            }),
            ChoiceChip(
              label: const Text('Autre'),
              selected: current != null && !_presets.contains(current),
              onSelected: (_) {},
              selectedColor: SDColors.primary50,
              labelStyle: SDTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: SDColors.neutral700,
              ),
              side: const BorderSide(color: SDColors.neutral300),
            ),
          ],
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
            _updateFormData();
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
      ],
    );
  }
}

class _RecapLine extends StatelessWidget {
  final String label;
  final String value;

  const _RecapLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: SDTypography.labelSmall.copyWith(
                color: SDColors.neutral500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: SDTypography.bodySmall.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
