import 'package:flutter/material.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import '../../../../design_system/design_system.dart';

/// Pays proposés à l'inscription / login téléphone (indicatif explicite).
class PhoneCountryOption {
  const PhoneCountryOption({
    required this.isoCode,
    required this.dialCode,
    required this.label,
    required this.flag,
  });

  final IsoCode isoCode;
  final String dialCode;
  final String label;
  final String flag;
}

const kDefaultPhoneCountries = <PhoneCountryOption>[
  PhoneCountryOption(
    isoCode: IsoCode.CI,
    dialCode: '+225',
    label: "Côte d'Ivoire",
    flag: '🇨🇮',
  ),
  PhoneCountryOption(
    isoCode: IsoCode.TN,
    dialCode: '+216',
    label: 'Tunisie',
    flag: '🇹🇳',
  ),
  PhoneCountryOption(
    isoCode: IsoCode.SN,
    dialCode: '+221',
    label: 'Sénégal',
    flag: '🇸🇳',
  ),
  PhoneCountryOption(
    isoCode: IsoCode.BF,
    dialCode: '+226',
    label: 'Burkina Faso',
    flag: '🇧🇫',
  ),
  PhoneCountryOption(
    isoCode: IsoCode.ML,
    dialCode: '+223',
    label: 'Mali',
    flag: '🇲🇱',
  ),
  PhoneCountryOption(
    isoCode: IsoCode.FR,
    dialCode: '+33',
    label: 'France',
    flag: '🇫🇷',
  ),
];

/// Champ téléphone avec pays / indicatif explicite (STAB-07).
class PhoneCountryField extends StatelessWidget {
  const PhoneCountryField({
    super.key,
    required this.controller,
    required this.selectedCountry,
    required this.onCountryChanged,
    this.label = 'Numéro de téléphone',
    this.hint = 'Numéro national',
    this.enabled = true,
  });

  final TextEditingController controller;
  final PhoneCountryOption selectedCountry;
  final ValueChanged<PhoneCountryOption> onCountryChanged;
  final String label;
  final String hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: SDTypography.labelLarge.copyWith(color: SDColors.neutral800),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(color: SDColors.neutral300),
                borderRadius: BorderRadius.circular(12),
                color: SDColors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<PhoneCountryOption>(
                  value: selectedCountry,
                  isDense: true,
                  items: kDefaultPhoneCountries
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text('${c.flag} ${c.dialCode}'),
                        ),
                      )
                      .toList(),
                  onChanged: enabled
                      ? (v) {
                          if (v != null) onCountryChanged(v);
                        }
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: hint,
                  prefixIcon: const Icon(Icons.phone_android),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Pays sélectionné : ${selectedCountry.label}',
          style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
        ),
      ],
    );
  }
}
