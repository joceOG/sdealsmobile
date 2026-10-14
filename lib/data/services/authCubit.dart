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
import 'freelance_hub_cache.dart';
import 'cache_service.dart';
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

/// État de la lecture locale de la session au démarrage.
///
/// [AuthInitial] ne suffit pas : il vaut aussi bien « restauration en cours »
/// qu'« aucune session ». Confondre les deux faisait traiter un utilisateur
/// connecté comme invité dès que la restauration dépassait le délai du splash.
enum SessionRestoreStatus {
  /// Lecture du stockage en cours : on ne sait pas encore.
  restoring,

  /// Session locale lue et appliquée ([AuthAuthenticated]).
  restored,

  /// Lecture terminée, aucune session enregistrée : invité.
  absent,

  /// Lecture en erreur ou trop longue : session non appliquée, mais NON
  /// supprimée (elle peut être restaurée plus tard). Jamais un accès pro.
  failed,
}

class AuthCubit extends Cubit<AuthState> {
  /// Plafond d'attente quand l'interface est déjà affichée alors que la
  /// restauration n'est pas finie. Au-delà : [SessionRestoreStatus.failed].
  /// (Aucun minuteur dans le cas courant : restauration terminée avant l'UI.)
  @visibleForTesting
  static Duration restoreHardCap = const Duration(seconds: 6);

  /// Observable par les écrans invités et le routeur.
  final ValueNotifier<SessionRestoreStatus> restoreStatus =
      ValueNotifier<SessionRestoreStatus>(SessionRestoreStatus.restoring);

  bool _interfaceShownBeforeRestore = false;
  Timer? _pendingCap;

  /// Vrai si l'interface a été ouverte avant la fin de la restauration
  /// (le splash a dépassé son délai). Seul cas où les murs « invité » doivent
  /// patienter : sinon la restauration est finie avant tout écran.
  bool get interfaceShownBeforeRestore => _interfaceShownBeforeRestore;

  /// Appelé par le splash quand il ouvre l'interface alors que la
  /// restauration est encore en cours. Borne l'attente (pas de spinner infini).
  void markInterfaceShownBeforeRestore() {
    if (restoreStatus.value != SessionRestoreStatus.restoring ||
        _interfaceShownBeforeRestore) {
      return;
    }
    _interfaceShownBeforeRestore = true;
    _pendingCap = Timer(restoreHardCap, () {
      _pendingCap = null;
      if (restoreStatus.value == SessionRestoreStatus.restoring) {
        _setRestoreStatus(SessionRestoreStatus.failed);
      }
    });
  }

  void _setRestoreStatus(SessionRestoreStatus status) {
    if (status != SessionRestoreStatus.restoring) {
      _pendingCap?.cancel();
      _pendingCap = null;
    }
    if (restoreStatus.value != status) restoreStatus.value = status;
  }

  @override
  Future<void> close() {
    _pendingCap?.cancel();
    _pendingCap = null;
    return super.close();
  }

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

  final Completer<void> _sessionRestore = Completer<void>();

  /// Terminé quand la lecture locale de session est finie : connecté,
  /// invité (aucune session) ou erreur. Le splash l'attend au lieu de sonder
  /// l'état : un invité reste [AuthInitial] et payait tout le délai de sondage.
  Future<void> get sessionRestored => _sessionRestore.future;

  Future<void> _loadAuthFromStorage() async {
    try {
      await _restoreFromStorage();
    } finally {
      if (!_sessionRestore.isCompleted) _sessionRestore.complete();
    }
  }

  Future<void> _restoreFromStorage() async {
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
        _setRestoreStatus(SessionRestoreStatus.restored);
        // Réseau hors chemin splash : invalide la session seulement si 401.
        unawaited(_confirmStoredSession());
        unawaited(refreshRoles());
      } else {
        // Keystore abandonné (trop lent) ≠ aucune session enregistrée.
        _setRestoreStatus(TokenStore.storageAbandoned
            ? SessionRestoreStatus.failed
            : SessionRestoreStatus.absent);
      }
    } catch (e) {
      _setRestoreStatus(SessionRestoreStatus.failed);
      if (kDebugMode) {
        print('Erreur lors du chargement de l\'authentification: $e');
      }
    }
  }

  Future<void> _confirmStoredSession() async {
    try {
      await ApiClient()
          .get('/utilisateur/profile')
          .timeout(const Duration(seconds: 5));
    } on UnauthorizedException {
      await _clearAuthFromStorage();
      if (state is AuthAuthenticated) emit(AuthInitial());
      _setRestoreStatus(SessionRestoreStatus.absent);
    } catch (_) {
      // Hors-ligne / timeout : la session locale reste valide.
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
    _setRestoreStatus(SessionRestoreStatus.restored);

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
    _setRestoreStatus(SessionRestoreStatus.absent);
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
      // Plus aucune donnée de listing associée à ce compte.
      await FreelanceHubCache.shared.clearAll();
      await CacheService().removeByPrefix('private_');
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la suppression de l\'authentification: $e');
      }
    }
  }
}
