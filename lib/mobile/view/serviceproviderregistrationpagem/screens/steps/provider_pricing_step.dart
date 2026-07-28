import 'package:flutter/material.dart';
import '../../../../../design_system/design_system.dart';

class ProviderPricingStep extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onDataChanged;

  const ProviderPricingStep({
    Key? key,
    required this.formData,
    required this.onDataChanged,
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
    _dailyRateController.text = (rate != null && rate != 0.0) ? rate.toString() : '';
    _descriptionController.text = widget.formData['description'] ?? '';
  }

  @override
  void dispose() {
    _dailyRateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateFormData() {
    widget.onDataChanged({
      'dailyRate': double.tryParse(_dailyRateController.text) ?? 0.0,
      'description': _descriptionController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tarification',
            style: SDTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
        SizedBox(height: SDSpacing.xs),
        Text('Définissez votre tarif pour une journée de travail',
            style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral500)),
        SizedBox(height: SDSpacing.md),

        // Tarif par jour
        SDInput(
          label: 'Tarif par jour (FCFA) *',
          hint: 'Ex: 15000',
          controller: _dailyRateController,
          prefixIcon: Icons.monetization_on_outlined,
          keyboardType: TextInputType.number,
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text('FCFA',
                style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral500, fontWeight: FontWeight.w600)),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Veuillez entrer votre tarif';
            final rate = double.tryParse(v);
            if (rate == null || rate <= 0) return 'Montant invalide';
            return null;
          },
          onChanged: (_) => _updateFormData(),
        ),
        SizedBox(height: SDSpacing.sm),

        // Description optionnelle
        SDInput(
          label: 'Description (optionnelle)',
          hint: 'Décrivez brièvement vos services...',
          controller: _descriptionController,
          prefixIcon: Icons.description_outlined,
          maxLines: 3,
          onChanged: (_) => _updateFormData(),
        ),
        SizedBox(height: SDSpacing.md),

        // Exemples de tarifs
        Container(
          padding: EdgeInsets.all(SDSpacing.sm),
          decoration: BoxDecoration(
            color: SDColors.info50,
            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
            border: Border.all(color: SDColors.info200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: SDColors.info600, size: 18),
                  SizedBox(width: SDSpacing.xs),
                  Text('Exemples de tarifs',
                      style: SDTypography.labelLarge.copyWith(
                          color: SDColors.info600, fontWeight: FontWeight.w600)),
                ],
              ),
              SizedBox(height: SDSpacing.xs),
              ...[
                '• Plombier : 15 000 – 25 000 FCFA/jour',
                '• Électricien : 20 000 – 30 000 FCFA/jour',
                '• Peintre : 10 000 – 20 000 FCFA/jour',
                '• Menuisier : 25 000 – 40 000 FCFA/jour',
              ].map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(t,
                        style: SDTypography.bodySmall.copyWith(
                            color: SDColors.info700)),
                  )),
              SizedBox(height: SDSpacing.xs),
              Text('Vous pourrez ajuster vos tarifs plus tard.',
                  style: SDTypography.bodySmall.copyWith(
                      fontStyle: FontStyle.italic, color: SDColors.neutral500)),
            ],
          ),
        ),
        SizedBox(height: SDSpacing.sm),

        // Note finale
        Container(
          padding: EdgeInsets.all(SDSpacing.sm),
          decoration: BoxDecoration(
            color: SDColors.success50,
            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
            border: Border.all(color: SDColors.success200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_outline, color: SDColors.success600, size: 18),
              SizedBox(width: SDSpacing.xs),
              Expanded(
                child: Text(
                  'Parfait ! Votre profil prestataire sera créé. Vous pourrez recevoir des demandes clients.',
                  style: SDTypography.bodySmall.copyWith(color: SDColors.success700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
