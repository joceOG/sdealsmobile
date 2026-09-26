import 'authCubit.dart';
import '../models/professional_capabilities.dart';

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
