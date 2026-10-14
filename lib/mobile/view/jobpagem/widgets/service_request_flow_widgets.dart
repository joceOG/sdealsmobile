import 'package:flutter/material.dart';
import '../../../../data/utils/display_text.dart';
import '../../../../design_system/design_system.dart';
import 'service_request_draft.dart';

class ServiceRequestProviderPreview extends StatelessWidget {
  final ServiceRequestContext context;

  const ServiceRequestProviderPreview({super.key, required this.context});

  @override
  Widget build(BuildContext buildContext) {
    final name = displayOrFallback(context.providerName, 'Professionnel');
    final metier =
        displayOrFallback(context.providerMetier, context.serviceName);
    final photo = safeImageUrl(context.providerPhotoUrl);
    final initial =
        name.isNotEmpty ? name[0].toUpperCase() : '?';

    Widget avatar;
    if (photo != null) {
      avatar = ClipOval(
        child: Image.network(
          photo,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initials(initial),
        ),
      );
    } else {
      avatar = _initials(initial);
    }

    return Row(
      children: [
        avatar,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SDTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: SDColors.neutral900,
                ),
              ),
              Text(
                metier,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SDTypography.labelSmall.copyWith(
                  color: SDColors.neutral600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _initials(String initial) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: SDColors.primary50,
      child: Text(
        initial,
        style: SDTypography.titleSmall.copyWith(
          color: SDColors.primary700,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class ServiceRequestInfoBanner extends StatelessWidget {
  final String message;

  const ServiceRequestInfoBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Icon(Icons.info_outline, color: SDColors.primary700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: SDTypography.bodySmall.copyWith(
                color: SDColors.neutral800,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration serviceRequestFieldDecoration({
  required String label,
  required String hint,
  IconData? icon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: SDTypography.labelMedium.copyWith(
      color: SDColors.neutral700,
      fontWeight: FontWeight.w700,
    ),
    hintStyle: SDTypography.bodyMedium.copyWith(color: SDColors.neutral400),
    prefixIcon: icon != null
        ? Icon(icon, color: SDColors.primary700, size: 22)
        : null,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: SDColors.neutral200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: SDColors.primary700, width: 2),
    ),
    filled: true,
    fillColor: SDColors.white,
    alignLabelWithHint: true,
  );
}

Widget serviceRequestPrimaryButton({
  required String label,
  required VoidCallback? onPressed,
  IconData? trailingIcon,
  String? subtitle,
}) {
  return SizedBox(
    width: double.infinity,
    height: subtitle != null ? 56 : 52,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: SDColors.primary700,
        foregroundColor: SDColors.white,
        disabledBackgroundColor: SDColors.primary700.withValues(alpha: 0.45),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: subtitle != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: SDTypography.titleSmall.copyWith(
                        color: SDColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 8),
                      Icon(trailingIcon, size: 20, color: SDColors.white),
                    ],
                  ],
                ),
                Text(
                  subtitle,
                  style: SDTypography.labelSmall.copyWith(
                    color: SDColors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: SDTypography.titleSmall.copyWith(
                    color: SDColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(trailingIcon, size: 20, color: SDColors.white),
                ],
              ],
            ),
    ),
  );
}

Widget serviceRequestOutlineButton({
  required String label,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    width: double.infinity,
    height: 52,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: SDColors.primary700,
        side: const BorderSide(color: SDColors.primary700, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        label,
        style: SDTypography.titleSmall.copyWith(
          fontWeight: FontWeight.w800,
          color: SDColors.primary700,
        ),
      ),
    ),
  );
}

class ServiceRequestRecapSection extends StatelessWidget {
  final String title;
  final String value;

  const ServiceRequestRecapSection({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: SDTypography.labelSmall.copyWith(
            color: SDColors.neutral500,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: SDTypography.bodyMedium.copyWith(
            color: SDColors.neutral900,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
