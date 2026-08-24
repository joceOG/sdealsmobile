import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// STAB-12A — Erreur API structurée (jamais préfixer avec « Exception: »).
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.fieldErrors = const {},
    this.isNetworkError = false,
    this.isTimeout = false,
  });

  final int? statusCode;
  final String? code;
  final String message;
  /// Champ backend → message utilisateur (telephone, email, password…).
  final Map<String, String> fieldErrors;
  final bool isNetworkError;
  final bool isTimeout;

  /// Texte à afficher à l'utilisateur (snackbar / formulaire).
  String get userMessage => message;

  /// Premier champ en erreur (formulaires).
  String? get primaryField =>
      fieldErrors.isEmpty ? null : fieldErrors.keys.first;

  factory ApiException.network() => const ApiException(
        message: 'Impossible de se connecter. Vérifiez votre connexion internet.',
        isNetworkError: true,
      );

  factory ApiException.timeout() => const ApiException(
        message: 'Le serveur met trop de temps à répondre. Réessayez.',
        isTimeout: true,
      );

  factory ApiException.generic([int? statusCode]) => ApiException(
        statusCode: statusCode,
        message: 'Une erreur est survenue. Veuillez réessayer.',
      );

  /// Convertit n'importe quelle erreur catchée en message UI sûr.
  static String userFacing(Object error) {
    if (error is ApiException) return error.userMessage;
    // Exceptions métier déjà « clean »
    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      final stripped = raw.substring('Exception: '.length);
      if (_looksTechnical(stripped)) {
        return 'Une erreur est survenue. Veuillez réessayer.';
      }
      return stripped;
    }
    if (_looksTechnical(raw)) {
      return 'Une erreur est survenue. Veuillez réessayer.';
    }
    return raw;
  }

  static bool _looksTechnical(String s) {
    final l = s.toLowerCase();
    return l.contains('socketexception') ||
        l.contains('clientexception') ||
        l.contains('formatexception') ||
        l.contains('platformexception') ||
        l.contains('handshake') ||
        l.contains('stack') ||
        l.contains(' at ') ||
        l.contains('<html') ||
        l.contains('nginx') ||
        l.contains('bcrypt') ||
        l.contains('jwt') ||
        s.contains('Exception');
  }

  @override
  String toString() => message;
}

/// Parse les réponses HTTP backend existantes → [ApiException].
class ApiErrorParser {
  const ApiErrorParser._();

  static const _fieldLabels = <String, String>{
    'telephone': 'Numéro de téléphone',
    'phone': 'Numéro de téléphone',
    'identifiant': 'Identifiant',
    'email': 'Email',
    'password': 'Mot de passe',
    'nom': 'Nom',
    'prenom': 'Prénom',
    'fullName': 'Nom complet',
    'code': 'Code OTP',
    'otp': 'Code OTP',
    'phoneCountry': 'Pays',
  };

  /// Construit une [ApiException] depuis une réponse HTTP (corps éventuel).
  static ApiException fromResponse(
    http.Response response, {
    String? fallbackMessage,
  }) {
    final status = response.statusCode;
    Map<String, dynamic>? body;

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      } else if (decoded is Map) {
        body = decoded.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {
      // HTML / non-JSON
      return ApiException(
        statusCode: status,
        message: _messageForStatus(status, fallbackMessage),
      );
    }

    if (body == null) {
      return ApiException(
        statusCode: status,
        message: _messageForStatus(status, fallbackMessage),
      );
    }

    final code = body['code']?.toString();
    final fieldErrors = _parseFieldErrors(body['details']);
    final rawError = (body['error'] ?? body['message'] ?? '').toString().trim();

    // 5xx : jamais exposer le détail serveur
    if (status >= 500) {
      return ApiException(
        statusCode: status,
        code: code,
        message: _messageForStatus(status, fallbackMessage),
        fieldErrors: fieldErrors,
      );
    }

    // Priorité : message du premier champ utile
    String message;
    if (fieldErrors.isNotEmpty) {
      final first = fieldErrors.entries.first;
      message = _humanizeFieldMessage(first.key, first.value);
    } else if (rawError.isNotEmpty && !ApiException._looksTechnical(rawError)) {
      message = _mapKnownPhrases(rawError, status);
    } else {
      message = _messageForStatus(status, fallbackMessage);
    }

    // Si error générique « Données de validation » mais details présents
    if (rawError.toLowerCase().contains('données de validation') &&
        fieldErrors.isNotEmpty) {
      final first = fieldErrors.entries.first;
      message = _humanizeFieldMessage(first.key, first.value);
    }

    // 429 : message fixe même si body autre
    if (status == 429) {
      message = _messageForStatus(429, null);
    }

    return ApiException(
      statusCode: status,
      code: code,
      message: message,
      fieldErrors: fieldErrors,
    );
  }

  /// Réseau / timeout / déjà ApiException.
  static ApiException fromCaught(Object error, [StackTrace? _]) {
    if (error is ApiException) return error;
    if (error is TimeoutException) return ApiException.timeout();
    if (error is SocketException || error is http.ClientException) {
      return ApiException.network();
    }
    if (error is FormatException) return ApiException.generic();
    final msg = ApiException.userFacing(error);
    return ApiException(message: msg);
  }

  static Never throwFromResponse(
    http.Response response, {
    String? fallbackMessage,
  }) {
    throw fromResponse(response, fallbackMessage: fallbackMessage);
  }

  static Map<String, String> _parseFieldErrors(dynamic details) {
    final out = <String, String>{};
    if (details is! List) return out;
    for (final item in details) {
      if (item is! Map) continue;
      final map = item.map((k, v) => MapEntry(k.toString(), v));
      final field = (map['field'] ?? map['path'] ?? map['param'] ?? '')
          .toString()
          .trim();
      final msg = (map['message'] ?? map['msg'] ?? '').toString().trim();
      if (field.isEmpty || msg.isEmpty) continue;
      // Ne pas propager la valeur brute (secrets / PII)
      out[field] = _humanizeFieldMessage(field, msg);
    }
    return out;
  }

  static String _humanizeFieldMessage(String field, String backendMsg) {
    final label = _fieldLabels[field] ?? field;
    final lower = backendMsg.toLowerCase();

    if (field == 'telephone' || field == 'phone') {
      if (lower.contains('déjà') || lower.contains('utilise')) {
        return 'Ce numéro de téléphone est déjà utilisé.';
      }
      if (lower.contains('invalide') || lower.contains('pays')) {
        return 'Numéro de téléphone invalide pour le pays sélectionné.';
      }
      return backendMsg.contains('téléphone') || backendMsg.contains('Numéro')
          ? backendMsg
          : 'Numéro de téléphone invalide.';
    }
    if (field == 'email') {
      if (lower.contains('déjà') || lower.contains('utilise')) {
        return 'Cet email est déjà utilisé.';
      }
      return 'Email invalide.';
    }
    if (field == 'password') {
      return backendMsg.length < 80 ? backendMsg : 'Mot de passe invalide.';
    }
    if (field == 'nom' || field == 'prenom') {
      return '$label invalide.';
    }
    if (field == 'code' || field == 'otp') {
      return backendMsg;
    }

    // Message backend déjà lisible
    if (!ApiException._looksTechnical(backendMsg) && backendMsg.length < 120) {
      return backendMsg;
    }
    return '$label : information invalide.';
  }

  static String _mapKnownPhrases(String raw, int status) {
    final lower = raw.toLowerCase();
    if (lower.contains('déjà utilisé') || lower.contains('deja utilise')) {
      if (lower.contains('email')) return 'Cet email est déjà utilisé.';
      if (lower.contains('téléphone') || lower.contains('telephone')) {
        return 'Ce numéro de téléphone est déjà utilisé.';
      }
      return raw;
    }
    if (lower.contains('identifiants incorrects') ||
        lower.contains('mot de passe')) {
      return raw;
    }
    if (lower.contains('données de validation')) {
      return _messageForStatus(status, null);
    }
    return raw;
  }

  static String _messageForStatus(int status, String? fallback) {
    switch (status) {
      case 400:
      case 422:
        return fallback ??
            'Certaines informations sont invalides. Vérifiez le formulaire.';
      case 401:
        return fallback ?? 'Identifiants incorrects ou session expirée.';
      case 403:
        return fallback ?? 'Action non autorisée.';
      case 404:
        return fallback ?? 'Ressource introuvable.';
      case 409:
        return fallback ?? 'Conflit : cette ressource existe déjà.';
      case 429:
        return 'Trop de tentatives. Réessayez plus tard.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Une erreur est survenue. Veuillez réessayer.';
      default:
        if (status >= 500) {
          return 'Une erreur est survenue. Veuillez réessayer.';
        }
        return fallback ?? 'Une erreur est survenue. Veuillez réessayer.';
    }
  }
}
