import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/utilisateur.dart';
import '../models/professional_capabilities.dart';
import 'api_client.dart';
import 'token_store.dart';
import 'fcm_service.dart';
import 'protected_action_intent.dart';
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
  final UserProfessionalCapabilities? professional;
  final String? refreshToken;

  AuthAuthenticated({
    required this.token,
    required this.utilisateur,
    this.roles = const ['CLIENT'],
    this.activeRole,
    this.roleDetails,
    this.professional,
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
        professional: current.professional,
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
      final capsJson = prefs.getString('auth_professional_caps');
      final refreshToken = await TokenStore.getRefreshToken();
      UserProfessionalCapabilities? restoredCaps;
      if (capsJson != null && capsJson.isNotEmpty) {
        try {
          restoredCaps = UserProfessionalCapabilities.fromJson(
            Map<String, dynamic>.from(jsonDecode(capsJson) as Map),
          );
        } catch (_) {}
      }

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

        final rawUser = Map<String, dynamic>.from(jsonDecode(userJson) as Map);
        final hadSecrets = rawUser.containsKey('password') ||
            rawUser.containsKey('token') ||
            rawUser.containsKey('tokens');
        final userData = Utilisateur.sanitizePersistedJson(rawUser);
        final utilisateur = Utilisateur.fromJson(userData);
        if (hadSecrets) {
          // Migration : réécrire sans secrets, session conservée.
          await prefs.setString('auth_user', jsonEncode(utilisateur.toJson()));
        }
        final roles = rolesJson != null
            ? List<String>.from(jsonDecode(rolesJson))
            : ['CLIENT'];

        emit(AuthAuthenticated(
          token: token,
          utilisateur: utilisateur,
          roles: roles,
          activeRole: activeRole ?? (roles.isNotEmpty ? roles.first : 'CLIENT'),
          professional: restoredCaps,
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
    UserProfessionalCapabilities? professional,
    String? refreshToken,
  }) {
    _saveAuthToStorage(
      token,
      utilisateur,
      roles,
      activeRole,
      refreshToken,
      professional: professional,
    );

    emit(AuthAuthenticated(
      token: token,
      utilisateur: utilisateur,
      roles: roles,
      activeRole: activeRole ?? (roles.isNotEmpty ? roles.first : 'CLIENT'),
      roleDetails: roleDetails,
      professional: professional,
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
    String? refreshToken, {
    UserProfessionalCapabilities? professional,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_user', jsonEncode(utilisateur.toJson()));
      await prefs.setString('auth_roles', jsonEncode(roles));
      if (professional != null) {
        await prefs.setString(
          'auth_professional_caps',
          jsonEncode(professional.toJson()),
        );
      } else {
        await prefs.remove('auth_professional_caps');
      }
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
    UserProfessionalCapabilities? professional,
  }) {
    final current = state;
    if (current is AuthAuthenticated) {
      final newRoles = roles.isNotEmpty ? roles : current.roles;
      final newActiveRole = activeRole ?? current.activeRole;
      final newProfessional = professional ?? current.professional;
      _saveAuthToStorage(
        current.token,
        current.utilisateur,
        newRoles,
        newActiveRole,
        current.refreshToken,
        professional: newProfessional,
      );
      emit(AuthAuthenticated(
        token: current.token,
        utilisateur: current.utilisateur,
        roles: newRoles,
        activeRole: newActiveRole,
        roleDetails: roleDetails ?? current.roleDetails,
        professional: newProfessional,
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
      final professional =
          UserProfessionalCapabilities.fromRolesApiResponse(data);
      final raw = data['roles'];
      final roles = raw is List
          ? raw.map((e) => e.toString().toUpperCase()).toList()
          : professional.toLegacyRolesList();
      if (!roles.contains('CLIENT')) {
        roles.insert(0, 'CLIENT');
      }
      final details = data['details'] is Map
          ? Map<String, dynamic>.from(data['details'] as Map)
          : null;
      setRoles(
        roles: roles,
        roleDetails: details,
        professional: professional,
      );
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
      professional: current.professional,
    );
    emit(AuthAuthenticated(
      token: current.token,
      utilisateur: utilisateur,
      roles: current.roles,
      activeRole: current.activeRole,
      roleDetails: current.roleDetails,
      professional: current.professional,
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
        professional: current.professional,
      );

      emit(AuthAuthenticated(
        token: current.token,
        utilisateur: current.utilisateur,
        roles: current.roles,
        activeRole: role,
        roleDetails: current.roleDetails,
        professional: current.professional,
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
    SessionExit.clearPending();
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
      await prefs.remove('auth_professional_caps');
      await TokenStore.clear();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la suppression de l\'authentification: $e');
      }
    }
  }
}
