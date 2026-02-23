import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/models/security.dart';
import '../securitypageblocm/securityPageBlocM.dart';
import '../securitypageblocm/securityPageEventM.dart';
import '../securitypageblocm/securityPageStateM.dart';

class SecuritySettingsScreenM extends StatefulWidget {
  const SecuritySettingsScreenM({Key? key}) : super(key: key);

  @override
  State<SecuritySettingsScreenM> createState() =>
      _SecuritySettingsScreenMState();
}

class _SecuritySettingsScreenMState extends State<SecuritySettingsScreenM> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  SecuritySettings? _settings;
  bool _isLoading = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    context.read<SecurityPageBlocM>().add(LoadSecuritySettingsEventM());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SecurityPageBlocM(
        apiClient: ApiClient(),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Paramètres de sécurité'),
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
        ),
        body: BlocConsumer<SecurityPageBlocM, SecurityPageStateM>(
          listener: (context, state) {
            if (state is SecurityPageErrorStateM) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is SecurityPageSuccessStateM) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is SecuritySettingsLoadedStateM) {
              setState(() {
                _settings = state.settings;
                _isLoading = false;
              });
            } else if (state is SecuritySettingsUpdatedStateM) {
              setState(() {
                _settings = state.settings;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is PasswordChangedStateM) {
              setState(() {
                _isChangingPassword = false;
              });
              _currentPasswordController.clear();
              _newPasswordController.clear();
              _confirmPasswordController.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is SecurityPageLoadingStateM || _isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Paramètres de sécurité
                  if (_settings != null) ...[
                    _buildSecuritySettingsCard(),
                    const SizedBox(height: 16),
                  ],

                  // Changement de mot de passe
                  _buildPasswordChangeCard(),

                  const SizedBox(height: 16),

                  // Actions de sécurité
                  _buildSecurityActionsCard(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSecuritySettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Paramètres de sécurité',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notifications de connexion
            SwitchListTile(
              title: const Text('Notifications de connexion'),
              subtitle: const Text(
                  'Recevoir des notifications lors de nouvelles connexions'),
              value: _settings!.loginNotifications,
              onChanged: (value) {
                _updateSetting('loginNotifications', value);
              },
              activeColor: Colors.teal,
            ),

            const Divider(),

            // Authentification à deux facteurs requise
            SwitchListTile(
              title: const Text('Authentification à deux facteurs requise'),
              subtitle: const Text(
                  'Forcer l\'utilisation de l\'authentification à deux facteurs'),
              value: _settings!.twoFactorRequired,
              onChanged: (value) {
                _updateSetting('twoFactorRequired', value);
              },
              activeColor: Colors.teal,
            ),

            const Divider(),

            // Délai d'expiration de session
            SwitchListTile(
              title: const Text('Délai d\'expiration de session'),
              subtitle: const Text(
                  'Sessions expirées automatiquement après inactivité'),
              value: _settings!.sessionTimeout,
              onChanged: (value) {
                _updateSetting('sessionTimeout', value);
              },
              activeColor: Colors.teal,
            ),

            if (_settings!.sessionTimeout) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Délai d\'expiration: ${_settings!.sessionTimeoutMinutes} minutes'),
                    Slider(
                      value: _settings!.sessionTimeoutMinutes.toDouble(),
                      min: 5,
                      max: 120,
                      divisions: 23,
                      label: '${_settings!.sessionTimeoutMinutes} min',
                      onChanged: (value) {
                        _updateSetting('sessionTimeoutMinutes', value.round());
                      },
                      activeColor: Colors.teal,
                    ),
                  ],
                ),
              ),
            ],

            const Divider(),

            // Sessions multiples autorisées
            SwitchListTile(
              title: const Text('Sessions multiples autorisées'),
              subtitle: const Text('Permettre plusieurs sessions simultanées'),
              value: _settings!.allowMultipleSessions,
              onChanged: (value) {
                _updateSetting('allowMultipleSessions', value);
              },
              activeColor: Colors.teal,
            ),

            const Divider(),

            // Changement de mot de passe requis
            SwitchListTile(
              title: const Text('Changement de mot de passe requis'),
              subtitle:
                  const Text('Forcer le changement de mot de passe périodique'),
              value: _settings!.requirePasswordChange,
              onChanged: (value) {
                _updateSetting('requirePasswordChange', value);
              },
              activeColor: Colors.teal,
            ),

            if (_settings!.requirePasswordChange) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fréquence: ${_settings!.passwordChangeDays} jours'),
                    Slider(
                      value: _settings!.passwordChangeDays.toDouble(),
                      min: 30,
                      max: 365,
                      divisions: 11,
                      label: '${_settings!.passwordChangeDays} jours',
                      onChanged: (value) {
                        _updateSetting('passwordChangeDays', value.round());
                      },
                      activeColor: Colors.teal,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordChangeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Changer le mot de passe',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe actuel',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmer le nouveau mot de passe',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isChangingPassword ? null : _changePassword,
                icon: _isChangingPassword
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock),
                label: Text(_isChangingPassword
                    ? 'Changement...'
                    : 'Changer le mot de passe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Actions de sécurité',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Terminer toutes les sessions
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Terminer toutes les sessions'),
              subtitle: const Text('Déconnecter tous les appareils'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showTerminateAllSessionsDialog();
              },
            ),

            const Divider(),

            // Vider l'historique de connexion
            ListTile(
              leading: const Icon(Icons.history, color: Colors.orange),
              title: const Text('Vider l\'historique de connexion'),
              subtitle: const Text('Supprimer l\'historique des connexions'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showClearHistoryDialog();
              },
            ),

            const Divider(),

            // Exporter les données de sécurité
            ListTile(
              leading: const Icon(Icons.download, color: Colors.blue),
              title: const Text('Exporter les données de sécurité'),
              subtitle: const Text('Télécharger un rapport de sécurité'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _exportSecurityData();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateSetting(String key, dynamic value) {
    final settings = {key: value};
    context.read<SecurityPageBlocM>().add(
          UpdateSecuritySettingsEventM(settings: settings),
        );
  }

  void _changePassword() {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les mots de passe ne correspondent pas'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le mot de passe doit contenir au moins 6 caractères'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    context.read<SecurityPageBlocM>().add(
          ChangePasswordEventM(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
            confirmPassword: _confirmPasswordController.text,
          ),
        );
  }

  void _showTerminateAllSessionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer toutes les sessions'),
        content: const Text(
          'Êtes-vous sûr de vouloir terminer toutes les sessions actives ? '
          'Vous devrez vous reconnecter sur tous vos appareils.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<SecurityPageBlocM>()
                  .add(TerminateAllOtherSessionsEventM());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Terminer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider l\'historique de connexion'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer l\'historique de connexion ? '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SecurityPageBlocM>().add(ClearLoginHistoryEventM());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _exportSecurityData() {
    // TODO: Implémenter l'exportation des données de sécurité
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Fonctionnalité d\'exportation en cours de développement'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
