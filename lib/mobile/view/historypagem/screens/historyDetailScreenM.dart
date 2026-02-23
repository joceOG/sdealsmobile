import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../historypageblocm/historyPageBlocM.dart';
import '../historypageblocm/historyPageEventM.dart';
import '../historypageblocm/historyPageStateM.dart';
import '../../../../data/models/history.dart';

class HistoryDetailScreenM extends StatelessWidget {
  final History history;

  const HistoryDetailScreenM({
    super.key,
    required this.history,
  });

  String _getTypeLabel(String type) {
    switch (type) {
      case 'PRESTATAIRE':
        return 'Prestataire';
      case 'VENDEUR':
        return 'Vendeur';
      case 'FREELANCE':
        return 'Freelance';
      case 'ARTICLE':
        return 'Article';
      case 'SERVICE':
        return 'Service';
      case 'PRESTATION':
        return 'Prestation';
      case 'COMMANDE':
        return 'Commande';
      case 'PAGE':
        return 'Page';
      case 'CATEGORIE':
        return 'Catégorie';
      default:
        return type;
    }
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'ACTIVE':
        return 'Active';
      case 'ARCHIVE':
        return 'Archivée';
      case 'SUPPRIME':
        return 'Supprimée';
      default:
        return statut;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'PRESTATAIRE':
        return Colors.blue;
      case 'VENDEUR':
        return Colors.green;
      case 'FREELANCE':
        return Colors.orange;
      case 'ARTICLE':
        return Colors.purple;
      case 'SERVICE':
        return Colors.red;
      case 'PRESTATION':
        return Colors.teal;
      case 'COMMANDE':
        return Colors.brown;
      case 'PAGE':
        return Colors.grey;
      case 'CATEGORIE':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'ACTIVE':
        return Colors.green;
      case 'ARCHIVE':
        return Colors.orange;
      case 'SUPPRIME':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la Consultation'),
        backgroundColor: _getTypeColor(history.objetType),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'archive':
                  _archiveHistory(context);
                  break;
                case 'delete':
                  _deleteHistory(context);
                  break;
              }
            },
            itemBuilder: (context) => [
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
                          backgroundColor: _getTypeColor(history.objetType),
                          child: Text(
                            history.objetType[0],
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                history.titre,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getTypeLabel(history.objetType),
                                style: TextStyle(
                                  color: _getTypeColor(history.objetType),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(_getStatutLabel(history.statut)),
                          backgroundColor:
                              _getStatutColor(history.statut).withOpacity(0.2),
                          labelStyle:
                              TextStyle(color: _getStatutColor(history.statut)),
                        ),
                      ],
                    ),
                    if (history.description != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Description',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        history.description!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                    if (history.prix != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.attach_money, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            '${history.prix} ${history.devise ?? 'FCFA'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 📊 MÉTRIQUES DE CONSULTATION
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Métriques de Consultation',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Durée',
                            history.dureeFormatee,
                            Icons.timer,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricCard(
                            'Vues',
                            '${history.nombreVues}',
                            Icons.visibility,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if (history.interactions != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Interactions',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              'Clics',
                              '${history.interactions!.clics}',
                              Icons.mouse,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricCard(
                              'Scrolls',
                              '${history.interactions!.scrolls}',
                              Icons.swap_vert,
                              Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 📱 INFORMATIONS TECHNIQUES
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
                    _buildInfoRow('Session ID', history.sessionId),
                    if (history.ipAddress != null)
                      _buildInfoRow('Adresse IP', history.ipAddress!),
                    if (history.userAgent != null)
                      _buildInfoRow('User Agent', history.userAgent!),
                    if (history.deviceInfo != null) ...[
                      _buildInfoRow(
                          'Type d\'appareil', history.deviceInfo!.type),
                      if (history.deviceInfo!.os != null)
                        _buildInfoRow('Système', history.deviceInfo!.os!),
                      if (history.deviceInfo!.browser != null)
                        _buildInfoRow(
                            'Navigateur', history.deviceInfo!.browser!),
                    ],
                    if (history.url != null) _buildInfoRow('URL', history.url!),
                    if (history.referrer != null)
                      _buildInfoRow('Référent', history.referrer!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 📍 LOCALISATION
            if (history.localisation != null ||
                history.localisationUtilisateur != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Localisation',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (history.localisation != null) ...[
                        if (history.localisation!.ville != null)
                          _buildInfoRow('Ville', history.localisation!.ville!),
                        if (history.localisation!.pays != null)
                          _buildInfoRow('Pays', history.localisation!.pays!),
                      ],
                      if (history.localisationUtilisateur != null) ...[
                        if (history.localisationUtilisateur!.ville != null)
                          _buildInfoRow('Ville utilisateur',
                              history.localisationUtilisateur!.ville!),
                        if (history.localisationUtilisateur!.latitude != null &&
                            history.localisationUtilisateur!.longitude != null)
                          _buildInfoRow(
                            'Coordonnées',
                            '${history.localisationUtilisateur!.latitude}, ${history.localisationUtilisateur!.longitude}',
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // 🎯 ACTIONS EFFECTUÉES
            if (history.actions != null && history.actions!.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Actions Effectuées',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ...history.actions!.map((action) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getActionIcon(action.type),
                                color: _getActionColor(action.type),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      action.type,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    if (action.details != null)
                                      Text(
                                        action.details!,
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatDate(action.timestamp),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
                    _buildInfoRow('Date de consultation',
                        _formatDate(history.dateConsultation)),
                    _buildInfoRow('Dernière consultation',
                        _formatDate(history.dateDerniereConsultation)),
                    _buildInfoRow('Créé le', _formatDate(history.createdAt)),
                    _buildInfoRow('Modifié le', _formatDate(history.updatedAt)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
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

  IconData _getActionIcon(String type) {
    switch (type) {
      case 'VIEW':
        return Icons.visibility;
      case 'CLICK':
        return Icons.mouse;
      case 'SCROLL':
        return Icons.swap_vert;
      case 'SEARCH':
        return Icons.search;
      case 'FILTER':
        return Icons.filter_list;
      case 'SORT':
        return Icons.sort;
      case 'SHARE':
        return Icons.share;
      case 'FAVORITE':
        return Icons.favorite;
      case 'CONTACT':
        return Icons.contact_mail;
      case 'BOOKMARK':
        return Icons.bookmark;
      default:
        return Icons.info;
    }
  }

  Color _getActionColor(String type) {
    switch (type) {
      case 'VIEW':
        return Colors.blue;
      case 'CLICK':
        return Colors.green;
      case 'SCROLL':
        return Colors.orange;
      case 'SEARCH':
        return Colors.purple;
      case 'FILTER':
        return Colors.teal;
      case 'SORT':
        return Colors.brown;
      case 'SHARE':
        return Colors.pink;
      case 'FAVORITE':
        return Colors.red;
      case 'CONTACT':
        return Colors.indigo;
      case 'BOOKMARK':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  void _archiveHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archiver la consultation'),
        content: const Text(
            'Êtes-vous sûr de vouloir archiver cette consultation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<HistoryPageBlocM>()
                  .add(ArchiveHistoryM(historyId: history.id!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Consultation archivée avec succès')),
              );
            },
            child: const Text('Archiver'),
          ),
        ],
      ),
    );
  }

  void _deleteHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la consultation'),
        content: const Text(
            'Êtes-vous sûr de vouloir supprimer cette consultation ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<HistoryPageBlocM>()
                  .add(DeleteHistoryM(historyId: history.id!));
              Navigator.pop(context); // Retour à la liste
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Consultation supprimée avec succès')),
              );
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}



