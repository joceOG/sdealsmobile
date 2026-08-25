import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/utils/legal_urls.dart';
import '../../../../design_system/design_system.dart';

/// En-tête compact connexion / inscription (logo + titres).
class AuthCompactHeader extends StatelessWidget {
  const AuthCompactHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.logoHeight = 96,
  });

  final String title;
  final String subtitle;
  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Image.asset(
            'assets/logo1.png',
            height: logoHeight,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: SDSpacing.sm),
        Text(
          title,
          textAlign: TextAlign.center,
          style: SDTypography.pageTitle.copyWith(
            fontSize: 30,
            color: SDColors.neutral900,
          ),
        ),
        SizedBox(height: SDSpacing.xxs),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: SDTypography.bodyLarge.copyWith(
            fontSize: 17,
            color: SDColors.neutral600,
          ),
        ),
      ],
    );
  }
}

/// Bouton retour auth (←) — même comportement connexion / inscription.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, size: 24, color: SDColors.neutral900),
      onPressed: onPressed,
      tooltip: 'Retour',
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    );
  }
}

enum AuthLoginMode { phone, email }

/// Segmented Téléphone | Email pour la connexion.
class AuthLoginModeToggle extends StatelessWidget {
  const AuthLoginModeToggle({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final AuthLoginMode mode;
  final ValueChanged<AuthLoginMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SDColors.neutral100,
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: 'Téléphone',
              selected: mode == AuthLoginMode.phone,
              onTap: () => onChanged(AuthLoginMode.phone),
            ),
          ),
          Expanded(
            child: _Segment(
              label: 'Email',
              selected: mode == AuthLoginMode.email,
              onTap: () => onChanged(AuthLoginMode.email),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? SDColors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium - 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium - 2),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: Text(
            label,
            style: SDTypography.labelMedium.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? SDColors.primary700 : SDColors.neutral600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Séparateur « ou … » entre Google et formulaire classique.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key, this.label = 'ou continuer avec email/téléphone'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: SDColors.neutral300, height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SDSpacing.sm),
          child: Text(
            label,
            style: SDTypography.bodySmall.copyWith(
              color: SDColors.neutral500,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(child: Divider(color: SDColors.neutral300, height: 1)),
      ],
    );
  }
}

/// Checkbox conditions avec liens cliquables.
class AuthTermsAcceptance extends StatelessWidget {
  const AuthTermsAcceptance({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = SDTypography.bodyMedium.copyWith(
      color: SDColors.primary700,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: SDColors.primary700,
      fontSize: 15,
    );
    final bodyStyle = SDTypography.bodyMedium.copyWith(
      color: SDColors.neutral800,
      fontSize: 15,
      height: 1.35,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            activeColor: SDColors.primary600,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            onChanged: (v) => onChanged(v ?? false),
          ),
        ),
        SizedBox(width: SDSpacing.xxs),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text.rich(
              TextSpan(
                style: bodyStyle,
                children: [
                  const TextSpan(text: 'J\'accepte les '),
                  TextSpan(
                    text: 'Conditions d\'utilisation',
                    style: linkStyle,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _open(LegalUrls.cgu),
                  ),
                  const TextSpan(text: ' et la '),
                  TextSpan(
                    text: 'Politique de confidentialité',
                    style: linkStyle,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _open(LegalUrls.confidentialite),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Espacement vertical standard entre groupes de champs auth.
class AuthFieldGap extends StatelessWidget {
  const AuthFieldGap({super.key, this.large = false});

  final bool large;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: large ? SDSpacing.md : SDSpacing.sm);
  }
}

/// STAB-13 — Sheet auth invité (Publier, actions protégées).
///
/// Utilise [SDResponsive.systemBottomInset] pour le padding inférieur :
/// fiable sur EMUI/Huawei qui ne remontent pas correctement SafeArea.
/// Le sheet est scrollable sur petits écrans (< 360dp) pour garantir
/// que les deux CTA (Se connecter / Créer un compte) restent accessibles.
Future<void> showGuestAuthSheet(
  BuildContext context, {
  required String title,
  required String description,
  IconData icon = Icons.lock_outline_rounded,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Builder(
      builder: (innerCtx) {
        final double sysBottom = SDResponsive.systemBottomInset(innerCtx);
        // Limite la hauteur max du sheet à 90 % du viewport pour laisser le
        // fond visible et forcer le scroll sur petits écrans.
        final double maxH = MediaQuery.sizeOf(innerCtx).height * 0.90;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Container(
            decoration: const BoxDecoration(
              color: SDColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: SDColors.neutral300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                // Contenu scrollable — protège les CTA sur petits écrans
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(0, 6, 0, sysBottom + 8),
                    child: GuestAuthState(
                      title: title,
                      description: description,
                      icon: icon,
                      centerVertically: false,
                      onPrimary: () {
                        Navigator.pop(sheetContext);
                        context.push('/login');
                      },
                      onSecondary: () {
                        Navigator.pop(sheetContext);
                        context.push('/register');
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
