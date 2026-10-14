import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../errors/api_exception.dart';
import '../models/professional_capabilities.dart';
import 'authCubit.dart';

extension AuthProfessionalAccess on AuthState {
  UserProfessionalCapabilities? get professionalCaps {
    if (this is AuthAuthenticated) {
      return (this as AuthAuthenticated).professional;
    }
    return null;
  }

  bool get canOperatePrestataire =>
      professionalCaps?.canOperateAs('Prestataire') ?? false;

  bool get canOperateFreelance =>
      professionalCaps?.canOperateAs('Freelance') ?? false;

  bool get canOperateVendeur =>
      professionalCaps?.canOperateAs('Vendeur') ?? false;

  bool get hasPrestataireProfile =>
      professionalCaps?.hasProfile('Prestataire') ?? false;

  bool get hasFreelanceProfile =>
      professionalCaps?.hasProfile('Freelance') ?? false;

  bool get hasVendeurProfile =>
      professionalCaps?.hasProfile('Vendeur') ?? false;
}

/// Après un refus métier lié au dossier pro, resynchroniser `capabilities` en session.
Future<void> refreshProfessionalCapabilitiesAfterBlock(
  BuildContext context,
  Object error,
) async {
  if (error is! ApiException) return;
  if (error.code != 'PROFESSIONAL_PROFILE_NOT_OPERATIONAL') return;
  await context.read<AuthCubit>().refreshRoles();
}
