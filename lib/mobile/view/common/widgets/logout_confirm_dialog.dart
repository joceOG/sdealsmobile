import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/services/authCubit.dart';
import '../../../../design_system/design_system.dart';
import '../auth_completion.dart';

/// Dialogue de déconnexion — appelle [AuthCubit.logout], sans second mécanisme.
class LogoutConfirmDialog extends StatefulWidget {
  const LogoutConfirmDialog({
    super.key,
    required this.onLogout,
    this.onLoggedOut,
  });

  final Future<void> Function() onLogout;
  final VoidCallback? onLoggedOut;

  static Future<void> show(BuildContext origin) {
    return showDialog<void>(
      context: origin,
      barrierDismissible: true,
      builder: (dialogContext) => LogoutConfirmDialog(
        onLogout: () => origin.read<AuthCubit>().logout(),
        onLoggedOut: () {
          if (origin.mounted) exitToGuestHome(origin);
        },
      ),
    );
  }

  @override
  State<LogoutConfirmDialog> createState() => _LogoutConfirmDialogState();
}

class _LogoutConfirmDialogState extends State<LogoutConfirmDialog> {
  bool _busy = false;

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onLogout();
    } finally {
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onLoggedOut?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Dialog(
        backgroundColor: SDColors.white,
        surfaceTintColor: SDColors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SDSpacing.radiusSheet),
        ),
        child: Padding(
          padding: const EdgeInsets.all(SDSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: SDColors.error50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: SDColors.error600,
                  size: 24,
                ),
              ),
              const SizedBox(height: SDSpacing.sm),
              Text(
                'Se déconnecter ?',
                style: SDTypography.displaySmall.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: SDSpacing.xxs),
              Text(
                'Vous devrez vous reconnecter pour accéder à votre compte.',
                style: SDTypography.bodyLarge.copyWith(
                  color: SDColors.neutral600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: SDSpacing.md),
              _LogoutActions(
                busy: _busy,
                onCancel: _busy ? null : () => Navigator.of(context).pop(),
                onConfirm: _busy ? null : _confirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutActions extends StatelessWidget {
  const _LogoutActions({
    required this.busy,
    required this.onCancel,
    required this.onConfirm,
  });

  final bool busy;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  static const double _minH = 48;

  @override
  Widget build(BuildContext context) {
    final scaled = MediaQuery.textScalerOf(context).scale(16);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 280 || scaled > 18;
        final cancel = _actionButton(
          label: 'Annuler',
          filled: false,
          onPressed: onCancel,
        );
        final confirm = _actionButton(
          label: 'Se déconnecter',
          filled: true,
          onPressed: onConfirm,
          loading: busy,
        );
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              confirm,
              const SizedBox(height: 8),
              cancel,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: cancel),
            const SizedBox(width: 12),
            Expanded(child: confirm),
          ],
        );
      },
    );
  }

  Widget _actionButton({
    required String label,
    required bool filled,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    final child = loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(SDColors.white),
            ),
          )
        : Text(
            label,
            textAlign: TextAlign.center,
            softWrap: true,
            style: SDTypography.labelLarge.copyWith(
              color: filled ? SDColors.white : SDColors.neutral900,
              fontWeight: FontWeight.w600,
            ),
          );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(SDSpacing.radiusButton),
    );

    if (filled) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: SDColors.error600,
          foregroundColor: SDColors.white,
          disabledBackgroundColor: SDColors.error600,
          disabledForegroundColor: SDColors.white,
          elevation: 0,
          minimumSize: const Size(48, _minH),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: shape,
        ),
        child: child,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: SDColors.neutral900,
        backgroundColor: SDColors.white,
        minimumSize: const Size(48, _minH),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        tapTargetSize: MaterialTapTargetSize.padded,
        side: const BorderSide(color: SDColors.neutral300, width: 1),
        shape: shape,
      ),
      child: child,
    );
  }
}
