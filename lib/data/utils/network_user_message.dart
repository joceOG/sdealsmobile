import 'dart:async';
import 'dart:io';

import 'package:sdealsmobile/data/errors/api_exception.dart';

enum UserNetworkKind { offline, timeout, server, auth, other }

const String offlineUserMessage =
    'Vous êtes hors connexion. Vérifiez votre réseau.';
const String timeoutUserMessage =
    'Le service met plus de temps à répondre. Réessayez.';
const String serverUserMessage =
    'Service momentanément indisponible. Réessayez dans un instant.';
const String genericUserMessage =
    'Impossible de charger les données. Réessayez.';

UserNetworkKind classifyUserNetworkFailure(
  Object error, {
  bool? deviceOnline,
}) {
  if (error is ApiException) {
    final code = error.statusCode;
    if (code == 401 || code == 403) return UserNetworkKind.auth;
    if (error.isTimeout) return UserNetworkKind.timeout;
    if (code != null && code >= 500 && code <= 599)
      return UserNetworkKind.server;
    if (error.isNetworkError) {
      return deviceOnline == true
          ? UserNetworkKind.server
          : UserNetworkKind.offline;
    }
  }
  if (error is TimeoutException) return UserNetworkKind.timeout;
  final text = error.toString().toLowerCase();
  if (text.contains('401') ||
      text.contains('403') ||
      text.contains('unauthorized')) {
    return UserNetworkKind.auth;
  }
  if (text.contains('timed out') || text.contains('timeout')) {
    return UserNetworkKind.timeout;
  }
  if (RegExp(r'\b5\d\d\b').hasMatch(text) ||
      text.contains('502') ||
      text.contains('503') ||
      text.contains('504')) {
    return UserNetworkKind.server;
  }
  if (error is SocketException ||
      text.contains('socket') ||
      text.contains('failed host') ||
      text.contains('connection refused') ||
      text.contains('clientexception') ||
      text.contains('handshake')) {
    return deviceOnline == true
        ? UserNetworkKind.server
        : UserNetworkKind.offline;
  }
  return UserNetworkKind.other;
}

/// Message visible. Un 401/403 renvoie une chaîne vide : ce n'est pas du hors-ligne.
String userFacingNetworkMessage(Object error, {bool? deviceOnline}) {
  switch (classifyUserNetworkFailure(error, deviceOnline: deviceOnline)) {
    case UserNetworkKind.offline:
      return offlineUserMessage;
    case UserNetworkKind.timeout:
      return timeoutUserMessage;
    case UserNetworkKind.server:
      return serverUserMessage;
    case UserNetworkKind.auth:
      return '';
    case UserNetworkKind.other:
      return genericUserMessage;
  }
}

/// Timeout, coupure ou 5xx : une lecture peut être rejouée une fois.
/// 401/403 et les autres erreurs (validation, 4xx) ne sont pas rejouées.
bool isTransientReadFailure(Object error) {
  switch (classifyUserNetworkFailure(error)) {
    case UserNetworkKind.timeout:
    case UserNetworkKind.server:
    case UserNetworkKind.offline:
      return true;
    case UserNetworkKind.auth:
    case UserNetworkKind.other:
      return false;
  }
}

/// La bannière d'accueil affiche le message déjà classé, sans le réécrire en hors-ligne.
String homeBannerDisplayMessage(String message) => message;

bool homeBannerLooksOffline(String message) => message == offlineUserMessage;
