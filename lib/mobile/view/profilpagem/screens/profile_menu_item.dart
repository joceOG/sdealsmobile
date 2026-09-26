import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

/// Ligne de menu profil / hubs (Airbnb : icône + titre gauche + chevron).
class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final bool isLogout;
  final FontWeight titleFontWeight;
  final EdgeInsetsGeometry padding;
  final VoidCallback onTap;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    this.isLogout = false,
    this.titleFontWeight = FontWeight.w500,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLogout ? SDColors.error500 : SDColors.neutral900;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: SDSpacing.minTouchTarget),
        child: Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              leading ?? Icon(icon, color: color, size: SDSpacing.iconStandard),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: SDTypography.bodyLarge.copyWith(
                        color: color,
                        fontWeight: titleFontWeight,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: SDTypography.caption
                            .copyWith(color: SDColors.neutral600),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isLogout)
                const Icon(
                  Icons.chevron_right,
                  color: SDColors.neutral400,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alias historique — même widget.
typedef MenuItem = ProfileMenuItem;
