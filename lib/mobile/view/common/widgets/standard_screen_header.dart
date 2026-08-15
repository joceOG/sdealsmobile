import 'package:flutter/material.dart';
import '../../../../design_system/design_system.dart';

/// Bouton circulaire bordé (style Freelance / Messagerie).
class SdCircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? iconColor;

  const SdCircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SDColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: SDColors.neutral200),
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        icon: Icon(
          icon,
          color: iconColor ?? SDColors.neutral900,
          size: 22,
        ),
      ),
    );
  }
}

/// Ligne titre à gauche + actions à droite (Freelance / Marketplace / Messages).
class StandardScreenHeader extends StatelessWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;

  const StandardScreenHeader({
    super.key,
    required this.title,
    this.leading,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading!,
          SizedBox(width: SDSpacing.sm),
        ],
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SDTypography.displayMedium.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (actions != null)
          ...actions!.map(
            (w) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: w,
            ),
          ),
      ],
    );
  }
}

/// Barre de recherche type Freelance / Messagerie (pill blanche, primary100, tune).
class FreelanceStyleSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final VoidCallback? onTunePressed;
  final bool readOnly;
  final VoidCallback? onTap;

  const FreelanceStyleSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.hintText = 'Rechercher…',
    this.onTunePressed,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SDSpacing.sm,
        vertical: SDSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: SDColors.primary100, width: 1),
        boxShadow: [
          BoxShadow(
            color: SDColors.neutral900.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: SDColors.primary600, size: 20),
          SizedBox(width: SDSpacing.xs),
          Expanded(
            child: readOnly
                ? GestureDetector(
                    onTap: onTap,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        hintText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SDTypography.bodyMedium.copyWith(
                          color: SDColors.neutral400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                : TextField(
                    controller: controller,
                    onChanged: onChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: SDTypography.bodyMedium.copyWith(
                        color: SDColors.neutral400,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: SDTypography.bodyMedium.copyWith(
                      color: SDColors.neutral900,
                      fontSize: 13,
                    ),
                  ),
          ),
          if (onTunePressed != null)
            GestureDetector(
              onTap: onTunePressed,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: SDColors.primary600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tune, color: SDColors.white, size: 17),
              ),
            ),
        ],
      ),
    );
  }
}
