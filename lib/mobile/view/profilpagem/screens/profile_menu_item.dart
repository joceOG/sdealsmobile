import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

/// Ligne de menu profil / hubs (Airbnb : icône + titre gauche + chevron).
class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isLogout;
  final VoidCallback onTap;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.isLogout = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLogout ? SDColors.error500 : SDColors.neutral900;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: SDTypography.bodyLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
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
    );
  }
}

/// Alias historique — même widget.
typedef MenuItem = ProfileMenuItem;
