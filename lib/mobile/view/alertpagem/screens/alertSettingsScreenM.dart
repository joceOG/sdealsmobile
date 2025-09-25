import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../alertpageblocm/alertPageBlocM.dart';
import '../alertpageblocm/alertPageEventM.dart';
import '../alertpageblocm/alertPageStateM.dart';

class AlertSettingsScreenM extends StatefulWidget {
  const AlertSettingsScreenM({super.key});

  @override
  State<AlertSettingsScreenM> createState() => _AlertSettingsScreenMState();
}

class _AlertSettingsScreenMState extends State<AlertSettingsScreenM> {
  bool _emailEnabled = true;
  bool _pushEnabled = true;
  bool _smsEnabled = false;
  List<String> _typesEnabled = [];
  List<String> _prioritesEnabled = [];

  final List<String> _allTypes = [
    'COMMANDE',
    'PRESTATION',
    'PAIEMENT',
    'VERIFICATION',
    'MESSAGE',
    'SYSTEME',
    'PROMOTION',
    'RAPPEL'
  ];

  final List<String> _allPriorites = ['BASSE', 'NORMALE', 'HAUTE', 'CRITIQUE'];

  @override
  void initState() {
    super.initState();
    // Charger les préférences actuelles
    context.read<AlertPageBlocM>().add(const LoadAlertPreferencesM());
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'COMMANDE':
        return 'Commande';
      case 'PRESTATION':
        return 'Prestation';
      case 'PAIEMENT':
        return 'Paiement';
      case 'VERIFICATION':
        return 'Vérification';
      case 'MESSAGE':
        return 'Message';
      case 'SYSTEME':
        return 'Système';
      case 'PROMOTION':
        return 'Promotion';
      case 'RAPPEL':
        return 'Rappel';
      default:
        return type;
    }
  }

  String _getPrioriteLabel(String priorite) {
    switch (priorite) {
      case 'BASSE':
        return 'Basse';
      case 'NORMALE':
        return 'Normale';
      case 'HAUTE':
        return 'Haute';
      case 'CRITIQUE':
        return 'Critique';
      default:
        return priorite;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'COMMANDE':
        return Colors.blue;
      case 'PRESTATION':
        return Colors.green;
      case 'PAIEMENT':
        return Colors.orange;
      case 'VERIFICATION':
        return Colors.purple;
      case 'MESSAGE':
        return Colors.teal;
      case 'SYSTEME':
        return Colors.grey;
      case 'PROMOTION':
        return Colors.pink;
      case 'RAPPEL':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Color _getPrioriteColor(String priorite) {
    switch (priorite) {
      case 'BASSE':
        return Colors.green;
      case 'NORMALE':
        return Colors.blue;
      case 'HAUTE':
        return Colors.orange;
      case 'CRITIQUE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'COMMANDE':
        return Icons.shopping_cart;
      case 'PRESTATION':
        return Icons.work;
      case 'PAIEMENT':
        return Icons.payment;
      case 'VERIFICATION':
        return Icons.verified;
      case 'MESSAGE':
        return Icons.message;
      case 'SYSTEME':
        return Icons.settings;
      case 'PROMOTION':
        return Icons.local_offer;
      case 'RAPPEL':
        return Icons.schedule;
      default:
        return Icons.notifications;
    }
  }

  void _savePreferences() {
    context.read<AlertPageBlocM>().add(UpdateAlertPreferencesM(
          emailEnabled: _emailEnabled,
          pushEnabled: _pushEnabled,
          smsEnabled: _smsEnabled,
          typesEnabled: _typesEnabled,
          prioritesEnabled: _prioritesEnabled,
        ));
  }

  void _resetToDefaults() {
    setState(() {
      _emailEnabled = true;
      _pushEnabled = true;
      _smsEnabled = false;
      _typesEnabled = List.from(_allTypes);
      _prioritesEnabled = List.from(_allPriorites);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres des Alertes'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _savePreferences,
            child: const Text(
              'Sauvegarder',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: BlocListener<AlertPageBlocM, AlertPageStateM>(
        listener: (context, state) {
          if (state is AlertPreferencesLoadedM) {
            setState(() {
              _emailEnabled = state.emailEnabled;
              _pushEnabled = state.pushEnabled;
              _smsEnabled = state.smsEnabled;
              _typesEnabled = List.from(state.typesEnabled);
              _prioritesEnabled = List.from(state.prioritesEnabled);
            });
          } else if (state is AlertPreferencesUpdatedM) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Préférences sauvegardées avec succès')),
            );
          } else if (state is AlertPageErrorM) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur: ${state.message}')),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔔 CANAUX DE NOTIFICATION
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Canaux de Notification',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Email'),
                        subtitle: const Text('Recevoir les alertes par email'),
                        value: _emailEnabled,
                        onChanged: (value) {
                          setState(() {
                            _emailEnabled = value;
                          });
                        },
                        secondary: const Icon(Icons.email),
                      ),
                      SwitchListTile(
                        title: const Text('Notifications Push'),
                        subtitle: const Text('Recevoir les notifications push'),
                        value: _pushEnabled,
                        onChanged: (value) {
                          setState(() {
                            _pushEnabled = value;
                          });
                        },
                        secondary: const Icon(Icons.phone_android),
                      ),
                      SwitchListTile(
                        title: const Text('SMS'),
                        subtitle: const Text('Recevoir les alertes par SMS'),
                        value: _smsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _smsEnabled = value;
                          });
                        },
                        secondary: const Icon(Icons.sms),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 🏷️ TYPES D'ALERTES
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Types d\'Alertes',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sélectionnez les types d\'alertes que vous souhaitez recevoir',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ..._allTypes.map((type) {
                        final isEnabled = _typesEnabled.contains(type);
                        return CheckboxListTile(
                          title: Row(
                            children: [
                              Icon(
                                _getTypeIcon(type),
                                color: _getTypeColor(type),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(_getTypeLabel(type)),
                            ],
                          ),
                          value: isEnabled,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _typesEnabled.add(type);
                              } else {
                                _typesEnabled.remove(type);
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.trailing,
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 🎯 PRIORITÉS
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Priorités',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sélectionnez les priorités d\'alertes que vous souhaitez recevoir',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ..._allPriorites.map((priorite) {
                        final isEnabled = _prioritesEnabled.contains(priorite);
                        return CheckboxListTile(
                          title: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                color: _getPrioriteColor(priorite),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(_getPrioriteLabel(priorite)),
                            ],
                          ),
                          value: isEnabled,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _prioritesEnabled.add(priorite);
                              } else {
                                _prioritesEnabled.remove(priorite);
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.trailing,
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 📊 RÉSUMÉ DES PRÉFÉRENCES
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Résumé des Préférences',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Canaux activés: ${_getActiveChannels()}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Types activés: ${_typesEnabled.length}/${_allTypes.length}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Priorités activées: ${_prioritesEnabled.length}/${_allPriorites.length}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 🎯 ACTIONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _resetToDefaults,
                      icon: const Icon(Icons.restore),
                      label: const Text('Réinitialiser'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _savePreferences,
                      icon: const Icon(Icons.save),
                      label: const Text('Sauvegarder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ℹ️ INFORMATIONS
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Informations',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Les paramètres sont sauvegardés automatiquement\n'
                        '• Vous pouvez modifier vos préférences à tout moment\n'
                        '• Les alertes critiques sont toujours envoyées\n'
                        '• Les notifications push nécessitent l\'autorisation de l\'appareil',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getActiveChannels() {
    final channels = <String>[];
    if (_emailEnabled) channels.add('Email');
    if (_pushEnabled) channels.add('Push');
    if (_smsEnabled) channels.add('SMS');
    return channels.isEmpty ? 'Aucun' : channels.join(', ');
  }
}
