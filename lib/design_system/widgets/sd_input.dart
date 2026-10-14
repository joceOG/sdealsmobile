import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../colors.dart';
import '../typography.dart';
import '../spacing.dart';

/// Champ de formulaire standardisé Soutrali Deals
///
/// **Utilisation:**
/// ```dart
/// SDInput(
///   label: 'Email',
///   hint: 'exemple@email.com',
///   keyboardType: TextInput Type.emailAddress,
///   validator: (value) => value?.isEmpty == true ? 'Requis' : null,
/// )
/// ```
class SDInput extends StatefulWidget {
  /// Label du champ
  final String label;

  /// Texte d'aide (hint)
  final String? hint;

  /// Contrôleur de texte
  final TextEditingController? controller;

  /// Masquer le texte (password)
  final bool obscureText;

  /// Type de clavier
  final TextInputType? keyboardType;

  /// Fonction de validation
  final String? Function(String?)? validator;

  /// Icône préfixe
  final IconData? prefixIcon;

  /// Widget suffixe personnalisé
  final Widget? suffixIcon;

  /// Nombre max de lignes
  final int? maxLines;

  /// Callback onChanged
  final ValueChanged<String>? onChanged;

  /// Callback onSubmitted
  final ValueChanged<String>? onSubmitted;

  /// Champ désactivé
  final bool enabled;

  /// Texte initial
  final String? initialValue;

  /// Focus node
  final FocusNode? focusNode;

  /// Erreur serveur / validation (STAB-12A) — affichée sous le champ.
  final String? errorText;

  /// Texte d'aide sous le champ (STAB-13).
  final String? helperText;

  /// Libellé au-dessus du champ (reste visible après saisie).
  final bool labelAbove;

  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  const SDInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.initialValue,
    this.focusNode,
    this.errorText,
    this.helperText,
    this.labelAbove = false,
    this.autofillHints,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLength,
  });

  @override
  State<SDInput> createState() => _SDInputState();
}

class _SDInputState extends State<SDInput> {
  bool _obscureTextVisible = false;

  @override
  Widget build(BuildContext context) {
    Widget? suffixWidget = widget.suffixIcon;

    // Si c'est un champ password, ajouter le toggle visibility
    if (widget.obscureText) {
      suffixWidget = IconButton(
        icon: Icon(
          _obscureTextVisible ? Icons.visibility_off : Icons.visibility,
          color: SDColors.neutral500,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _obscureTextVisible = !_obscureTextVisible;
          });
        },
        tooltip: _obscureTextVisible ? 'Masquer' : 'Afficher',
      );
    }

    final field = TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      initialValue: widget.initialValue,
      obscureText: widget.obscureText && !_obscureTextVisible,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      autofillHints: widget.autofillHints,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      inputFormatters: widget.inputFormatters,
      maxLength: widget.maxLength,
      style: SDTypography.bodyLarge.copyWith(
        color: widget.enabled ? SDColors.neutral900 : SDColors.neutral500,
      ),
      decoration: InputDecoration(
        labelText: widget.labelAbove ? null : widget.label,
        labelStyle: SDTypography.bodyMedium.copyWith(
          color: SDColors.neutral600,
        ),
        hintText: widget.hint,
        hintStyle: SDTypography.bodyMedium.copyWith(
          color: SDColors.neutral400,
        ),
        prefixIcon: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                color: SDColors.neutral500,
                size: 20,
              )
            : null,
        suffixIcon: suffixWidget,

        // ═══════════════════════════════════════
        // BORDERS
        // ═══════════════════════════════════════

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
          borderSide: const BorderSide(
            color: SDColors.neutral300,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
          borderSide: const BorderSide(
            color: SDColors.neutral300,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
          borderSide: const BorderSide(
            color: SDColors.primary600,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
          borderSide: const BorderSide(
            color: SDColors.error500,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
          borderSide: const BorderSide(
            color: SDColors.error500,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
          borderSide: const BorderSide(
            color: SDColors.neutral200,
            width: 1,
          ),
        ),

        // ═══════════════════════════════════════
        // FILL & PADDING
        // ═══════════════════════════════════════

        contentPadding: widget.maxLines == 1
            ? (widget.labelAbove
                ? const EdgeInsets.symmetric(
                    horizontal: SDSpacing.sm,
                    vertical: SDSpacing.sm,
                  )
                : SDSpacing.inputPadding)
            : const EdgeInsets.all(SDSpacing.sm),
        filled: true,
        fillColor: widget.enabled ? SDColors.white : SDColors.neutral100,

        // ═══════════════════════════════════════
        // ERROR STYLE
        // ═══════════════════════════════════════

        errorStyle: SDTypography.fieldError.copyWith(
          color: SDColors.error500,
        ),
        errorMaxLines: 2,
        errorText: widget.errorText,
        counterText: widget.maxLength != null ? '' : null,
        helperText: widget.errorText == null ? widget.helperText : null,
        helperStyle: SDTypography.helper.copyWith(
          color: SDColors.neutral600,
          fontSize: 13,
        ),
        helperMaxLines: 2,
      ),
    );

    if (!widget.labelAbove) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: SDTypography.labelLarge.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: SDColors.neutral800,
          ),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}

/// Input de recherche avec icône
class SDSearchInput extends StatelessWidget {
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final FocusNode? focusNode;

  const SDSearchInput({
    super.key,
    this.hint = 'Rechercher...',
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SDSpacing.inputHeight,
      decoration: BoxDecoration(
        color: SDColors.neutral100,
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        border: Border.all(color: SDColors.neutral300),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: (value) => onSubmitted?.call(),
        style: SDTypography.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: SDTypography.bodyMedium.copyWith(
            color: SDColors.neutral400,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: SDColors.neutral500,
            size: 20,
          ),
          suffixIcon: controller?.text.isNotEmpty == true
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: SDColors.neutral500,
                    size: 20,
                  ),
                  onPressed: () {
                    controller?.clear();
                    onChanged?.call('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: SDSpacing.inputPadding,
        ),
      ),
    );
  }
}
