/// Contrat OTP téléphone (backend : 6 chiffres, canal SMS, TTL 10 min).
const int kPhoneOtpCodeLength = 6;

bool isPhoneOtpCode(String code) =>
    RegExp('^\\d{$kPhoneOtpCodeLength}\$').hasMatch(code.trim());
