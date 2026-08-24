import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/utilisateur.dart';
import 'api_client.dart';
import 'token_store.dart';
import 'fcm_service.dart';
import 'websocket_service.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String token;
  final Utilisateur utilisateur;
  final List<String> roles;
  final String? activeRole;
  final Map<String, dynamic>? roleDetails;
  final String? refreshToken;

  AuthAuthenticated({
    required this.token,
    required this.utilisateur,
    this.roles = const ['CLIENT'],
    this.activeRole,
    this.roleDetails,
    this.refreshToken,
  });
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial()) {
    ApiClient.onUnauthorized = () {
      logout();
    };
    ApiClient.onTokenRefreshed = (newToken, newRefresh) {
      final current = state;
      if (current is! AuthAuthenticated) return;
      final refresh = (newRefresh != null && newRefresh.isNotEmpty)
          ? newRefresh
          : current.refreshToken;
      if (current.token == newToken && current.refreshToken == refresh) return;
      emit(AuthAuthenticated(
        token: newToken,
        utilisateur: current.utilisateur,
        roles: current.roles,
        activeRole: current.activeRole,
        roleDetails: current.roleDetails,
        refreshToken: refresh,
      ));
    };
    _loadAuthFromStorage();
  }

  Future<void> _loadAuthFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await TokenStore.getAccessToken();
      final userJson = prefs.getString('auth_user');
      final rolesJson = prefs.getString('auth_roles');
      final activeRole = prefs.getString('auth_active_role');
      final refreshToken = await TokenStore.getRefreshToken();

      if (token != null && userJson != null) {
        try {
          // Vérif session via ApiClient (AUTH-REFRESH unique).
          await ApiClient()
              .get('/utilisateur/profile')
              .timeout(const Duration(seconds: 5));
        } on UnauthorizedException {
          await _clearAuthFromStorage();
          emit(AuthInitial());
          return;
        } catch (_) {
          // Offline / timeout : accepter le token local
        }

        final userData = jsonDecode(userJson);
        final utilisateur = Utilisateur.fromJson(userData);
        final roles = rolesJson != null
            ? List<String>.from(jsonDecode(rolesJson))
            : ['CLIENT'];

        emit(AuthAuthenticated(
          token: token,
          utilisateur: utilisateur,
          roles: roles,
          activeRole: activeRole ?? (roles.isNotEmpty ? roles.first : 'CLIENT'),
          refreshToken: refreshToken,
        ));
        // Met à jour PRESTATAIRE / FREELANCE / VENDEUR si le doc existe
        unawaited(refreshRoles());
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chargement de l\'authentification: $e');
      }
    }
  }

  void setAuthenticated({
    required String token,
    required Utilisateur utilisateur,
    List<String> roles = const ['CLIENT'],
    String? activeRole,
    Map<String, dynamic>? roleDetails,
    String? refreshToken,
  }) {
    _saveAuthToStorage(token, utilisateur, roles, activeRole, refreshToken);

    emit(AuthAuthenticated(
      token: token,
      utilisateur: utilisateur,
      roles: roles,
      activeRole: activeRole ?? (roles.isNotEmpty ? roles.first : 'CLIENT'),
      roleDetails: roleDetails,
      refreshToken: refreshToken,
    ));

    // Enregistrer le token FCM maintenant que la session est active
    Future.microtask(() => FcmService.instance.syncTokenWithBackend());
  }

  Future<void> _saveAuthToStorage(
    String token,
    Utilisateur utilisateur,
    List<String> roles,
    String? activeRole,
    String? refreshToken,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_user', jsonEncode(utilisateur.toJson()));
      await prefs.setString('auth_roles', jsonEncode(roles));
      if (activeRole != null) {
        await prefs.setString('auth_active_role', activeRole);
      }
      await TokenStore.saveTokens(
        accessToken: token,
        refreshToken: refreshToken,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la sauvegarde de l\'authentification: $e');
      }
    }
  }

  void setRoles({
    required List<String> roles,
    String? activeRole,
    Map<String, dynamic>? roleDetails,
  }) {
    final current = state;
    if (current is AuthAuthenticated) {
      final newRoles = roles.isNotEmpty ? roles : current.roles;
      final newActiveRole = activeRole ?? current.activeRole;
      _saveAuthToStorage(
        current.token,
        current.utilisateur,
        newRoles,
        newActiveRole,
        current.refreshToken,
      );
      emit(AuthAuthenticated(
        token: current.token,
        utilisateur: current.utilisateur,
        roles: newRoles,
        activeRole: newActiveRole,
        roleDetails: roleDetails ?? current.roleDetails,
        refreshToken: current.refreshToken,
      ));
    }
  }

  /// Recharge CLIENT + PRESTATAIRE / FREELANCE / VENDEUR depuis l’API.
  Future<void> refreshRoles() async {
    final current = state;
    if (current is! AuthAuthenticated) return;
    final userId = current.utilisateur.idutilisateur;
    if (userId.isEmpty) return;

    try {
      final data = await ApiClient().getUserRoles(userId, token: current.token);
      final raw = data['roles'];
      final roles = raw is List
          ? raw.map((e) => e.toString().toUpperCase()).toList()
          : <String>['CLIENT'];
      if (!roles.contains('CLIENT')) {
        roles.insert(0, 'CLIENT');
      }
      final details = data['details'] is Map
          ? Map<String, dynamic>.from(data['details'] as Map)
          : null;
      setRoles(roles: roles, roleDetails: details);
    } catch (e) {
      if (kDebugMode) {
        print('refreshRoles: $e');
      }
    }
  }

  /// Met à jour l'utilisateur en session (ex. après édition profil).
  void updateUtilisateur(Utilisateur utilisateur) {
    final current = state;
    if (current is! AuthAuthenticated) return;
    _saveAuthToStorage(
      current.token,
      utilisateur,
      current.roles,
      current.activeRole,
      current.refreshToken,
    );
    emit(AuthAuthenticated(
      token: current.token,
      utilisateur: utilisateur,
      roles: current.roles,
      activeRole: current.activeRole,
      roleDetails: current.roleDetails,
      refreshToken: current.refreshToken,
    ));
  }

  void switchActiveRole(String role) {
    final current = state;
    if (current is AuthAuthenticated && current.roles.contains(role)) {
      if (current.activeRole == role) return;

      _saveAuthToStorage(
        current.token,
        current.utilisateur,
        current.roles,
        role,
        current.refreshToken,
      );

      emit(AuthAuthenticated(
        token: current.token,
        utilisateur: current.utilisateur,
        roles: current.roles,
        activeRole: role,
        roleDetails: current.roleDetails,
        refreshToken: current.refreshToken,
      ));
    }
  }

  Future<void> logout() async {
    final current = state;
    if (current is AuthAuthenticated) {
      try {
        await FcmService.instance.unregisterFromBackend();
      } catch (_) {}
      try {
        await ApiClient().post(
          '/logout',
          body: {
            if (current.refreshToken != null)
              'refreshToken': current.refreshToken,
          },
        ).timeout(const Duration(seconds: 10));
      } catch (_) {}
    }
    WebSocketService().disconnectForLogout();
    await _clearAuthFromStorage();
    emit(AuthInitial());
  }

  Future<void> _clearAuthFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('auth_user');
      await prefs.remove('auth_roles');
      await prefs.remove('auth_active_role');
      await TokenStore.clear();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la suppression de l\'authentification: $e');
      }
    }
  }
}
