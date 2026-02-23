import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../avispageblocm/avisPageBlocM.dart';
import '../avispageblocm/avisPageEventM.dart';
import '../avispageblocm/avisPageStateM.dart';
import 'package:sdealsmobile/data/models/avis.dart';

class AvisDetailScreenM extends StatefulWidget {
  final Avis avis;

  const AvisDetailScreenM({
    super.key,
    required this.avis,
  });

  @override
  State<AvisDetailScreenM> createState() => _AvisDetailScreenMState();
}

class _AvisDetailScreenMState extends State<AvisDetailScreenM> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Détail de l\'avis'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _showEditDialog();
                  break;
                case 'delete':
                  _showDeleteDialog();
                  break;
                case 'report':
                  _showReportDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Modifier'),
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
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Signaler', style: TextStyle(color: Colors.orange)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocConsumer<AvisPageBlocM, AvisPageStateM>(
        listener: (context, state) {
          if (state.hasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error ?? 'Erreur inconnue'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec auteur
                _buildHeader(),

                const SizedBox(height: 20),

                // Note et titre
                _buildRatingAndTitle(),

                const SizedBox(height: 16),

                // Commentaire
                _buildCommentaire(),

                const SizedBox(height: 20),

                // Tags
                if (widget.avis.tags != null && widget.avis.tags!.isNotEmpty)
                  _buildTags(),

                // Localisation
                if (widget.avis.localisation?.ville != null) _buildLocation(),

                const SizedBox(height: 20),

                // Statistiques
                _buildStats(),

                const SizedBox(height: 20),

                // Réponse du professionnel
                if (widget.avis.reponse != null) _buildReponse(),

                const SizedBox(height: 20),

                // Actions
                _buildActions(),
              ],
            ),
          );
        },
      ),
    );
  }

  // 📋 EN-TÊTE AVEC AUTEUR
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: widget.avis.auteur.photoProfil != null
                ? NetworkImage(widget.avis.auteur.photoProfil!)
                : null,
            child: widget.avis.auteur.photoProfil == null
                ? Text(
                    widget.avis.auteur.nom.isNotEmpty
                        ? widget.avis.auteur.nom[0]
                        : '?',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.avis.anonyme
                      ? 'Anonyme'
                      : '${widget.avis.auteur.nom} ${widget.avis.auteur.prenom}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(widget.avis.createdAt),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (widget.avis.auteur.verifie)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Vérifié',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildStatusChip(),
        ],
      ),
    );
  }

  // 🏷️ CHIP DE STATUT
  Widget _buildStatusChip() {
    Color color;
    String text;

    switch (widget.avis.statut) {
      case 'PUBLIE':
        color = Colors.green;
        text = 'Publié';
        break;
      case 'EN_ATTENTE':
        color = Colors.orange;
        text = 'En attente';
        break;
      case 'MODERE':
        color = Colors.red;
        text = 'Modéré';
        break;
      case 'SUPPRIME':
        color = Colors.grey;
        text = 'Supprimé';
        break;
      default:
        color = Colors.grey;
        text = 'Inconnu';
    }

    return Chip(
      label: Text(text),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  // ⭐ NOTE ET TITRE
  Widget _buildRatingAndTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Note
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < widget.avis.note ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 28,
                );
              }),
            ),
            const SizedBox(width: 8),
            Text(
              '${widget.avis.note}/5',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          widget.avis.titre,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // 💬 COMMENTAIRE
  Widget _buildCommentaire() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Commentaire',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.avis.commentaire,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }

  // 🏷️ TAGS
  Widget _buildTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.avis.tags!.map((tag) {
            return Chip(
              label: Text(tag),
              backgroundColor: Colors.green[100],
              labelStyle: const TextStyle(color: Colors.green),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 📍 LOCALISATION
  Widget _buildLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Localisation',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.location_on, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Text(
              '${widget.avis.localisation!.ville}, ${widget.avis.localisation!.pays}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 📊 STATISTIQUES
  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Vues', widget.avis.vues.toString(), Icons.visibility),
          _buildStatItem(
              'Utiles', widget.avis.utile.toString(), Icons.thumb_up),
          _buildStatItem(
              'Partages', widget.avis.partages.toString(), Icons.share),
          _buildStatItem(
              'Score',
              '${widget.avis.scoreUtilite.toStringAsFixed(0)}%',
              Icons.trending_up),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // 💬 RÉPONSE DU PROFESSIONNEL
  Widget _buildReponse() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.reply, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Text(
                'Réponse du professionnel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.avis.reponse!.contenu,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Répondu le ${_formatDate(widget.avis.reponse!.date)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 ACTIONS
  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              context.read<AvisPageBlocM>().add(
                    MarquerUtileM(avisId: widget.avis.id, utile: true),
                  );
            },
            icon: const Icon(Icons.thumb_up),
            label: const Text('Utile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              context.read<AvisPageBlocM>().add(
                    MarquerUtileM(avisId: widget.avis.id, utile: false),
                  );
            },
            icon: const Icon(Icons.thumb_down),
            label: const Text('Pas utile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showReplyDialog,
            icon: const Icon(Icons.reply),
            label: const Text('Répondre'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // 📅 FORMATAGE DE DATE
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // ✏️ DIALOGUE DE MODIFICATION
  void _showEditDialog() {
    // TODO: Implémenter le dialogue de modification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Fonctionnalité de modification en cours de développement'),
      ),
    );
  }

  // 🗑️ DIALOGUE DE SUPPRESSION
  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'avis'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cet avis ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<AvisPageBlocM>()
                  .add(DeleteAvisM(avisId: widget.avis.id));
              Navigator.pop(context); // Retour à la liste
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 🚨 DIALOGUE DE SIGNALEMENT
  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler cet avis'),
        content: const Text('Pourquoi souhaitez-vous signaler cet avis ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AvisPageBlocM>().add(
                    SignalerAvisM(
                      avisId: widget.avis.id,
                      motifs: ['CONTENU_INAPPROPRIE'],
                    ),
                  );
            },
            child:
                const Text('Signaler', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  // 💬 DIALOGUE DE RÉPONSE
  void _showReplyDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Répondre à l\'avis'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Votre réponse...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                context.read<AvisPageBlocM>().add(
                      RepondreAvisM(
                        avisId: widget.avis.id,
                        contenu: controller.text.trim(),
                      ),
                    );
              }
            },
            child: const Text('Répondre'),
          ),
        ],
      ),
    );
  }
}



