import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../alertpageblocm/alertPageBlocM.dart';
import '../alertpageblocm/alertPageEventM.dart';
import '../../../../data/models/alert.dart';

class AlertDetailScreenM extends StatelessWidget {
  final Alert alert;

  const AlertDetailScreenM({
    super.key,
    required this.alert,
  });

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

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'NON_LUE':
        return 'Non lue';
      case 'LUE':
        return 'Lue';
      case 'ARCHIVEE':
        return 'Archivée';
      default:
        return statut;
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

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'NON_LUE':
        return Colors.red;
      case 'LUE':
        return Colors.green;
      case 'ARCHIVEE':
        return Colors.grey;
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de l\'Alerte'),
        backgroundColor: _getTypeColor(alert.type),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'mark_read':
                  _markAsRead(context);
                  break;
                case 'archive':
                  _archiveAlert(context);
                  break;
                case 'delete':
                  _deleteAlert(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              if (alert.estNonLue)
                const PopupMenuItem(
                  value: 'mark_read',
                  child: Row(
                    children: [
                      Icon(Icons.mark_email_read),
                      SizedBox(width: 8),
                      Text('Marquer comme lue'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(Icons.archive),
                    SizedBox(width: 8),
                    Text('Archiver'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _getTypeColor(alert.type),
                          child: Icon(
                            _getTypeIcon(alert.type),
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alert.titre,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getTypeLabel(alert.type),
                                style: TextStyle(
                                  color: _getTypeColor(alert.type),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Chip(
                              label: Text(_getStatutLabel(alert.statut)),
                              backgroundColor: _getStatutColor(alert.statut)
                                  .withOpacity(0.2),
                              labelStyle: TextStyle(
                                  color: _getStatutColor(alert.statut)),
                            ),
                            const SizedBox(height: 4),
                            Chip(
                              label: Text(_getPrioriteLabel(alert.priorite)),
                              backgroundColor: _getPrioriteColor(alert.priorite)
                                  .withOpacity(0.2),
                              labelStyle: TextStyle(
                                  color: _getPrioriteColor(alert.priorite)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Description',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alert.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 📊 INFORMATIONS TECHNIQUES
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations Techniques',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Type', _getTypeLabel(alert.type)),
                    if (alert.sousType != null)
                      _buildInfoRow('Sous-type', alert.sousType!),
                    _buildInfoRow(
                        'Priorité', _getPrioriteLabel(alert.priorite)),
                    _buildInfoRow('Statut', _getStatutLabel(alert.statut)),
                    if (alert.referenceId != null)
                      _buildInfoRow('Référence ID', alert.referenceId!),
                    if (alert.referenceType != null)
                      _buildInfoRow('Type de référence', alert.referenceType!),
                    if (alert.urlAction != null)
                      _buildInfoRow('URL d\'action', alert.urlAction!),
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildChannelCard(
                            'Email',
                            alert.envoiEmail,
                            Icons.email,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildChannelCard(
                            'Push',
                            alert.envoiPush,
                            Icons.phone_android,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildChannelCard(
                            'SMS',
                            alert.envoiSMS,
                            Icons.sms,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 📅 DATES
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dates',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Créée le', _formatDate(alert.createdAt)),
                    _buildInfoRow('Modifiée le', _formatDate(alert.updatedAt)),
                    if (alert.dateLue != null)
                      _buildInfoRow('Lue le', _formatDate(alert.dateLue!)),
                    if (alert.dateArchivage != null)
                      _buildInfoRow(
                          'Archivée le', _formatDate(alert.dateArchivage!)),
                    if (alert.dateExpiration != null)
                      _buildInfoRow(
                          'Expire le', _formatDate(alert.dateExpiration!)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 📊 DONNÉES SUPPLÉMENTAIRES
            if (alert.donnees != null && alert.donnees!.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Données Supplémentaires',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ...alert.donnees!.entries.map((entry) {
                        return _buildInfoRow(
                          entry.key,
                          entry.value.toString(),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // 🎯 ACTIONS
            if (alert.urlAction != null && alert.urlAction!.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Actions Disponibles',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Ouvrir l'URL d'action
                            // TODO: Implémenter l'ouverture de l'URL
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Ouvrir l\'action'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getTypeColor(alert.type),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelCard(
      String title, bool enabled, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: enabled ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              enabled ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: enabled ? color : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: enabled ? color : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            color: enabled ? Colors.green : Colors.red,
            size: 16,
          ),
        ],
      ),
    );
  }

  void _markAsRead(BuildContext context) {
    context.read<AlertPageBlocM>().add(MarkAsReadM(alertId: alert.id!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alerte marquée comme lue')),
    );
  }

  void _archiveAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archiver l\'alerte'),
        content: const Text('Êtes-vous sûr de vouloir archiver cette alerte ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<AlertPageBlocM>()
                  .add(ArchiveAlertM(alertId: alert.id!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alerte archivée avec succès')),
              );
            },
            child: const Text('Archiver'),
          ),
        ],
      ),
    );
  }

  void _deleteAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'alerte'),
        content: const Text(
            'Êtes-vous sûr de vouloir supprimer cette alerte ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<AlertPageBlocM>()
                  .add(DeleteAlertM(alertId: alert.id!));
              Navigator.pop(context); // Retour à la liste
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alerte supprimée avec succès')),
              );
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
