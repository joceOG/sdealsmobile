import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../alertpageblocm/alertPageBlocM.dart';
import '../alertpageblocm/alertPageEventM.dart';
import '../alertpageblocm/alertPageStateM.dart';

class CreateAlertScreenM extends StatefulWidget {
  const CreateAlertScreenM({super.key});

  @override
  State<CreateAlertScreenM> createState() => _CreateAlertScreenMState();
}

class _CreateAlertScreenMState extends State<CreateAlertScreenM> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _referenceIdController = TextEditingController();
  final _urlActionController = TextEditingController();
  final _sousTypeController = TextEditingController();

  String _selectedType = 'SYSTEME';
  String _selectedPriorite = 'NORMALE';
  String _selectedReferenceType = 'Commande';
  bool _envoiEmail = false;
  bool _envoiPush = true;
  bool _envoiSMS = false;
  DateTime? _dateExpiration;
  Map<String, dynamic> _donnees = {};

  final List<String> _typeOptions = [
    'COMMANDE',
    'PRESTATION',
    'PAIEMENT',
    'VERIFICATION',
    'MESSAGE',
    'SYSTEME',
    'PROMOTION',
    'RAPPEL'
  ];

  final List<String> _prioriteOptions = [
    'BASSE',
    'NORMALE',
    'HAUTE',
    'CRITIQUE'
  ];

  final List<String> _referenceTypeOptions = [
    'Commande',
    'Prestation',
    'Paiement',
    'Message',
    'Verification'
  ];

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _referenceIdController.dispose();
    _urlActionController.dispose();
    _sousTypeController.dispose();
    super.dispose();
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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      context.read<AlertPageBlocM>().add(CreateAlertM(
            titre: _titreController.text,
            description: _descriptionController.text,
            type: _selectedType,
            sousType: _sousTypeController.text.isEmpty
                ? null
                : _sousTypeController.text,
            referenceId: _referenceIdController.text.isEmpty
                ? null
                : _referenceIdController.text,
            referenceType: _referenceIdController.text.isEmpty
                ? null
                : _selectedReferenceType,
            priorite: _selectedPriorite,
            envoiEmail: _envoiEmail,
            envoiPush: _envoiPush,
            envoiSMS: _envoiSMS,
            donnees: _donnees.isEmpty ? null : _donnees,
            urlAction: _urlActionController.text.isEmpty
                ? null
                : _urlActionController.text,
            dateExpiration: _dateExpiration,
          ));
    }
  }

  Future<void> _selectDateExpiration() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _dateExpiration ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _dateExpiration = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une Alerte'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _submitForm,
            child: const Text(
              'Créer',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: BlocListener<AlertPageBlocM, AlertPageStateM>(
        listener: (context, state) {
          if (state is AlertCreatedM) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Alerte créée avec succès')),
            );
            Navigator.pop(context);
          } else if (state is AlertPageErrorM) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur: ${state.message}')),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🎯 INFORMATIONS GÉNÉRALES
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informations Générales',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titreController,
                          decoration: const InputDecoration(
                            labelText: 'Titre *',
                            hintText: 'Entrez le titre de l\'alerte',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Le titre est requis';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description *',
                            hintText: 'Entrez la description de l\'alerte',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'La description est requise';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedType,
                                decoration: const InputDecoration(
                                  labelText: 'Type *',
                                  border: OutlineInputBorder(),
                                ),
                                items: _typeOptions.map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Row(
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
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedType = value!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedPriorite,
                                decoration: const InputDecoration(
                                  labelText: 'Priorité *',
                                  border: OutlineInputBorder(),
                                ),
                                items: _prioriteOptions.map((priorite) {
                                  return DropdownMenuItem<String>(
                                    value: priorite,
                                    child: Row(
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
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPriorite = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _sousTypeController,
                          decoration: const InputDecoration(
                            labelText: 'Sous-type (optionnel)',
                            hintText: 'Entrez le sous-type',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 🔗 RÉFÉRENCES
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Références (optionnel)',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _referenceIdController,
                          decoration: const InputDecoration(
                            labelText: 'ID de référence',
                            hintText: 'Entrez l\'ID de l\'objet référencé',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedReferenceType,
                          decoration: const InputDecoration(
                            labelText: 'Type de référence',
                            border: OutlineInputBorder(),
                          ),
                          items: _referenceTypeOptions.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedReferenceType = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _urlActionController,
                          decoration: const InputDecoration(
                            labelText: 'URL d\'action (optionnel)',
                            hintText: 'Entrez l\'URL d\'action',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 🔔 CANAUX D'ENVOI
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Canaux d\'Envoi',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Email'),
                          subtitle: const Text('Envoyer par email'),
                          value: _envoiEmail,
                          onChanged: (value) {
                            setState(() {
                              _envoiEmail = value;
                            });
                          },
                          secondary: const Icon(Icons.email),
                        ),
                        SwitchListTile(
                          title: const Text('Push'),
                          subtitle: const Text('Notification push'),
                          value: _envoiPush,
                          onChanged: (value) {
                            setState(() {
                              _envoiPush = value;
                            });
                          },
                          secondary: const Icon(Icons.phone_android),
                        ),
                        SwitchListTile(
                          title: const Text('SMS'),
                          subtitle: const Text('Envoyer par SMS'),
                          value: _envoiSMS,
                          onChanged: (value) {
                            setState(() {
                              _envoiSMS = value;
                            });
                          },
                          secondary: const Icon(Icons.sms),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 📅 DATE D'EXPIRATION
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Date d\'Expiration (optionnel)',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: Text(
                            _dateExpiration != null
                                ? 'Expire le ${_dateExpiration!.day}/${_dateExpiration!.month}/${_dateExpiration!.year} à ${_dateExpiration!.hour}:${_dateExpiration!.minute.toString().padLeft(2, '0')}'
                                : 'Aucune date d\'expiration',
                          ),
                          subtitle:
                              const Text('Sélectionnez une date d\'expiration'),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: _selectDateExpiration,
                        ),
                        if (_dateExpiration != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _selectDateExpiration,
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Modifier'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _dateExpiration = null;
                                      });
                                    },
                                    icon: const Icon(Icons.clear),
                                    label: const Text('Supprimer'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 📊 DONNÉES SUPPLÉMENTAIRES
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Données Supplémentaires (optionnel)',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Les données supplémentaires seront ajoutées automatiquement selon le type d\'alerte sélectionné.',
                          style: TextStyle(color: Colors.grey),
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
                                'Données actuelles:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_donnees.isEmpty)
                                const Text(
                                  'Aucune donnée supplémentaire',
                                  style: TextStyle(color: Colors.grey),
                                )
                              else
                                ..._donnees.entries.map((entry) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    child: Text(
                                      '${entry.key}: ${entry.value}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                }).toList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 🎯 BOUTON DE CRÉATION
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: const Icon(Icons.add),
                    label: const Text('Créer l\'Alerte'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getTypeColor(_selectedType),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
