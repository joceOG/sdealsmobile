/// STAB-12D — configuration publique backend (autorité serveur).
class PhoneVerificationConfig {
  const PhoneVerificationConfig({
    required this.mode,
    required this.signupRequiresOtp,
    required this.googleRequiresPhone,
  });

  final String mode;
  final bool signupRequiresOtp;
  final bool googleRequiresPhone;

  bool get isDeferred => mode == 'deferred';

  factory PhoneVerificationConfig.fromJson(Map<String, dynamic> json) {
    return PhoneVerificationConfig(
      mode: json['mode']?.toString() ?? 'legacy',
      signupRequiresOtp: json['signupRequiresOtp'] == true,
      googleRequiresPhone: json['googleRequiresPhone'] == true,
    );
  }

  static const legacy = PhoneVerificationConfig(
    mode: 'legacy',
    signupRequiresOtp: false,
    googleRequiresPhone: true,
  );
}
