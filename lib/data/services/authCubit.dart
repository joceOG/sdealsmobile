import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/utilisateur.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String token;
  final Utilisateur utilisateur;
  final List<String> roles; // CLIENT, PRESTATAIRE, VENDEUR, FREELANCE, ADMIN
  final String? activeRole; // rôle actif pour l'UI
  final Map<String, dynamic>? roleDetails; // détails (verifier/accountStatus)
  AuthAuthenticated(
      {required this.token,
      required this.utilisateur,
      this.roles = const ['CLIENT'],
      this.activeRole,
      this.roleDetails});
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial()) {
    _loadAuthFromStorage();
  }

  // ✅ CHARGER L'AUTHENTIFICATION AU DÉMARRAGE
  Future<void> _loadAuthFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userJson = prefs.getString('auth_user');
      final rolesJson = prefs.getString('auth_roles');
      final activeRole = prefs.getString('auth_active_role');

      if (token != null && userJson != null) {
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
        ));
      }
    } catch (e) {
      // En cas d'erreur, rester en AuthInitial
      print('Erreur lors du chargement de l\'authentification: $e');
    }
  }

  void setAuthenticated(
      {required String token,
      required Utilisateur utilisateur,
      List<String> roles = const ['CLIENT'],
      String? activeRole,
      Map<String, dynamic>? roleDetails}) {
    // ✅ SAUVEGARDER DANS LE STOCKAGE LOCAL
    _saveAuthToStorage(token, utilisateur, roles, activeRole);

    emit(AuthAuthenticated(
      token: token,
      utilisateur: utilisateur,
      roles: roles,
      activeRole: activeRole ?? (roles.isNotEmpty ? roles.first : 'CLIENT'),
      roleDetails: roleDetails,
    ));
  }

  // ✅ SAUVEGARDER L'AUTHENTIFICATION
  Future<void> _saveAuthToStorage(String token, Utilisateur utilisateur,
      List<String> roles, String? activeRole) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('auth_user', jsonEncode(utilisateur.toJson()));
      await prefs.setString('auth_roles', jsonEncode(roles));
      if (activeRole != null) {
        await prefs.setString('auth_active_role', activeRole);
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'authentification: $e');
    }
  }

  void setRoles(
      {required List<String> roles,
      String? activeRole,
      Map<String, dynamic>? roleDetails}) {
    final current = state;
    if (current is AuthAuthenticated) {
      emit(AuthAuthenticated(
        token: current.token,
        utilisateur: current.utilisateur,
        roles: roles.isNotEmpty ? roles : current.roles,
        activeRole: activeRole ?? current.activeRole,
        roleDetails: roleDetails ?? current.roleDetails,
      ));
    }
  }

  void switchActiveRole(String role) {
    final current = state;
    if (current is AuthAuthenticated && current.roles.contains(role)) {
      // ✅ PROTECTION : Ne pas émettre si le rôle est déjà actif
      if (current.activeRole == role) {
        print('Rôle $role déjà actif, pas de changement');
        return;
      }

      // ✅ PROTECTION : Vérifier que l'état a vraiment changé
      final newState = AuthAuthenticated(
        token: current.token,
        utilisateur: current.utilisateur,
        roles: current.roles,
        activeRole: role,
        roleDetails: current.roleDetails,
      );

      // Émettre seulement si l'état est différent
      emit(newState);
    }
  }

  void logout() {
    _clearAuthFromStorage();
    emit(AuthInitial());
  }

  // ✅ SUPPRIMER L'AUTHENTIFICATION DU STOCKAGE
  Future<void> _clearAuthFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('auth_user');
      await prefs.remove('auth_roles');
      await prefs.remove('auth_active_role');
    } catch (e) {
      print('Erreur lors de la suppression de l\'authentification: $e');
    }
  }
}
