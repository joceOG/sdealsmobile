import 'package:phone_numbers_parser/phone_numbers_parser.dart';

/// STAB-07 — Canonisation E.164 côté mobile.
///
/// Règle : jamais déduire le pays d'un numéro national seul.
class PhoneCanonicalizationException implements Exception {
  const PhoneCanonicalizationException([
    this.message =
        'Numéro de téléphone invalide pour le pays sélectionné.',
  ]);
  final String message;

  @override
  String toString() => message;
}

class PhoneCanonicalizer {
  const PhoneCanonicalizer._();

  static bool isInternationalInput(String raw) {
    final s = raw.trim();
    return s.startsWith('+') || s.startsWith('00');
  }

  static String _preprocess(String raw) {
    var s = raw.trim().replaceAll(RegExp(r'[\s\-().]'), '');
    if (s.startsWith('00')) s = '+${s.substring(2)}';
    return s;
  }

  /// [isoCode] requis si [raw] est national (ex: IsoCode.TN, IsoCode.CI).
  static String toE164(String raw, {IsoCode? isoCode}) {
    final cleaned = _preprocess(raw);
    if (cleaned.isEmpty) {
      throw const PhoneCanonicalizationException();
    }

    final international = cleaned.startsWith('+');
    if (!international && isoCode == null) {
      throw const PhoneCanonicalizationException();
    }

    try {
      final PhoneNumber phone;
      if (international) {
        phone = PhoneNumber.parse(cleaned);
      } else {
        phone = PhoneNumber.parse(
          cleaned,
          destinationCountry: isoCode,
        );
      }

      if (!phone.isValid()) {
        throw const PhoneCanonicalizationException();
      }

      final e164 = phone.international.replaceAll(' ', '');
      if (!RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(e164)) {
        throw const PhoneCanonicalizationException();
      }
      return e164;
    } on PhoneCanonicalizationException {
      rethrow;
    } catch (_) {
      throw const PhoneCanonicalizationException();
    }
  }

  /// Login : email inchangé ; téléphone → E.164 si possible.
  static String normalizeLoginIdentifiant(
    String identifiant, {
    IsoCode? isoCode,
  }) {
    final id = identifiant.trim();
    if (id.isEmpty) return '';
    if (id.contains('@')) return id.toLowerCase();
    try {
      return toE164(id, isoCode: isoCode);
    } catch (_) {
      return id;
    }
  }
}
