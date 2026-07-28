import 'package:flutter/material.dart';

import '../colors.dart';
import '../spacing.dart';

/// Bouton fermer (X) dans un cercle gris clair — pattern type app grand public.
class SDCircleCloseButton extends StatelessWidget {
  const SDCircleCloseButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Fermer',
  });

  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: SDSpacing.xs),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: SDColors.neutral100,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                Icons.close,
                size: 22,
                color: SDColors.neutral900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
