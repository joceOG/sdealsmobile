import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/security.dart';
import '../../../../data/services/api_client.dart';
import '../securitypageblocm/securityPageBlocM.dart';
import '../securitypageblocm/securityPageEventM.dart';
import '../securitypageblocm/securityPageStateM.dart';

class SecurityDetailScreenM extends StatefulWidget {
  final SecurityAlert alert;

  const SecurityDetailScreenM({
    Key? key,
    required this.alert,
  }) : super(key: key);

  @override
  State<SecurityDetailScreenM> createState() => _SecurityDetailScreenMState();
}

class _SecurityDetailScreenMState extends State<SecurityDetailScreenM> {
  @override
  void initState() {
    super.initState();
    // Marquer l'alerte comme lue si elle ne l'est pas déjà
    if (!widget.alert.isRead) {
      context.read<SecurityPageBlocM>().add(
            MarkAlertAsReadEventM(alertId: widget.alert.id!),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SecurityPageBlocM(
        apiClient: ApiClient(),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Détail de l\'alerte'),
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                _showDeleteDialog();
              },
            ),
          ],
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
            } else if (state is AlertDeletedStateM) {
              Navigator.pop(context);
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête de l'alerte
                  _buildAlertHeader(),

                  const SizedBox(height: 16),

                  // Détails de l'alerte
                  _buildAlertDetails(),

                  const SizedBox(height: 16),

                  // Actions
                  _buildActions(),

                  const SizedBox(height: 16),

                  // Métadonnées
                  if (widget.alert.metadata != null) ...[
                    _buildMetadata(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAlertHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getAlertIcon(widget.alert.severity),
                  color: _getAlertColor(widget.alert.severity),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.alert.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getSeverityText(widget.alert.severity),
                        style: TextStyle(
                          color: _getAlertColor(widget.alert.severity),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!widget.alert.isRead)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Nouveau',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.alert.message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Créé le ${_formatDate(widget.alert.createdAt)}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Détails de l\'alerte',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Type', widget.alert.type),
            _buildDetailRow(
                'Sévérité', _getSeverityText(widget.alert.severity)),
            _buildDetailRow('Statut', widget.alert.isRead ? 'Lu' : 'Non lu'),
            _buildDetailRow(
                'Date de création', _formatDate(widget.alert.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<SecurityPageBlocM>().add(
                            MarkAlertAsReadEventM(alertId: widget.alert.id!),
                          );
                    },
                    icon: const Icon(Icons.mark_email_read),
                    label: const Text('Marquer comme lu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showDeleteDialog();
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Supprimer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadata() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations supplémentaires',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.alert.metadata!.entries.map((entry) {
              return _buildDetailRow(
                entry.key,
                entry.value.toString(),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  IconData _getAlertIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  Color _getAlertColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _getSeverityText(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return 'Élevée';
      case 'medium':
        return 'Moyenne';
      case 'low':
        return 'Faible';
      default:
        return severity;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'alerte'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette alerte ? '
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
              context.read<SecurityPageBlocM>().add(
                    DeleteAlertEventM(alertId: widget.alert.id!),
                  );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
