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
    this.hint = '07 00 00 00 00',
    this.helperText,
    this.enabled = true,
    this.errorText,
    this.compact = true,
  });

  final TextEditingController controller;
  final PhoneCountryOption selectedCountry;
  final ValueChanged<PhoneCountryOption> onCountryChanged;
  final String label;
  final String hint;
  final String? helperText;
  final bool enabled;
  final String? errorText;
  final bool compact;

  static const double _fieldHeight = 52;

  @override
  Widget build(BuildContext context) {
    final dialStyle = SDTypography.labelMedium.copyWith(
      fontSize: compact ? 14 : 16,
      fontWeight: FontWeight.w600,
      color: SDColors.neutral800,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: SDTypography.labelLarge.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: SDColors.neutral800,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: compact ? 34 : 40,
              child: Container(
                height: _fieldHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: SDColors.neutral300),
                  borderRadius:
                      BorderRadius.circular(SDSpacing.borderRadiusMedium),
                  color: SDColors.white,
                ),
                padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PhoneCountryOption>(
                    value: selectedCountry,
                    isExpanded: true,
                    isDense: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: compact ? 18 : 22,
                      color: SDColors.neutral600,
                    ),
                    items: kDefaultPhoneCountries
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              '${c.flag} ${c.dialCode}',
                              style: dialStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
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
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: compact ? 66 : 60,
              child: TextField(
                controller: controller,
                enabled: enabled,
                keyboardType: TextInputType.phone,
                style: SDTypography.bodyLarge.copyWith(
                  fontSize: 16,
                  color: SDColors.neutral900,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: SDTypography.bodyMedium.copyWith(
                    color: SDColors.neutral400,
                    fontSize: 16,
                  ),
                  errorText: errorText,
                  errorMaxLines: 2,
                  errorStyle: SDTypography.fieldError,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(SDSpacing.borderRadiusMedium),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(SDSpacing.borderRadiusMedium),
                    borderSide: const BorderSide(color: SDColors.neutral300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(SDSpacing.borderRadiusMedium),
                    borderSide: const BorderSide(
                      color: SDColors.primary600,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        if (errorText == null && helperText != null && helperText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              helperText!,
              style: SDTypography.helper.copyWith(
                color: SDColors.neutral600,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}
