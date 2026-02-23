import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../favorispageblocm/favoritePageBlocM.dart';
import '../favorispageblocm/favoritePageEventM.dart';
import 'package:sdealsmobile/data/models/favorite.dart';
import '../../../../design_system/design_system.dart'; // ✅ Import DS

class FavoriteDetailScreenM extends StatefulWidget {
  final Favorite favorite;

  const FavoriteDetailScreenM({super.key, required this.favorite});

  @override
  State<FavoriteDetailScreenM> createState() => _FavoriteDetailScreenMState();
}

class _FavoriteDetailScreenMState extends State<FavoriteDetailScreenM> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: SDColors.primary600,
        title: Text('Détail du Favori', style: SDTypography.titleMedium.copyWith(color: SDColors.white)),
        centerTitle: true,
        iconTheme: IconThemeData(color: SDColors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareFavorite(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ IMAGE (si disponible)
            if (widget.favorite.image != null) ...[
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(widget.favorite.image!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 📝 TITRE ET TYPE
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.favorite.titre,
                    style: SDTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                _buildTypeChip(widget.favorite.objetType),
              ],
            ),

            const SizedBox(height: 8),

            // 🏷️ CATÉGORIE ET STATUT
            Row(
              children: [
                if (widget.favorite.categorie != null) ...[
                  Chip(
                    label: Text(widget.favorite.categorie!),
                    backgroundColor: Colors.blue[100],
                  ),
                  const SizedBox(width: 8),
                ],
                _buildStatusChip(widget.favorite.statut),
              ],
            ),

            const SizedBox(height: 16),

            // 📄 DESCRIPTION
            if (widget.favorite.description != null) ...[
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.favorite.description!,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
            ],

            // 💰 PRIX ET LOCALISATION
            Row(
              children: [
                if (widget.favorite.prix != null) ...[
                  Expanded(
                    child: _buildInfoCard(
                      'Prix',
                      widget.favorite.prixFormate,
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (widget.favorite.localisation != null) ...[
                  Expanded(
                    child: _buildInfoCard(
                      'Localisation',
                      widget.favorite.localisationFormatee,
                      Icons.location_on,
                      Colors.blue,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // ⭐ NOTE ET MÉTRIQUES
            Row(
              children: [
                if (widget.favorite.note != null) ...[
                  Expanded(
                    child: _buildInfoCard(
                      'Note',
                      '${widget.favorite.note!.toStringAsFixed(1)}/5',
                      Icons.star,
                      Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: _buildInfoCard(
                    'Vues',
                    '${widget.favorite.vues}',
                    Icons.visibility,
                    SDColors.neutral600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 🏷️ TAGS
            if (widget.favorite.tags != null &&
                widget.favorite.tags!.isNotEmpty) ...[
              const Text(
                'Tags',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.favorite.tags!.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: Colors.grey[200],
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // 📝 NOTES PERSONNELLES
            if (widget.favorite.notesPersonnelles != null) ...[
              const Text(
                'Notes personnelles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SDColors.neutral100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.favorite.notesPersonnelles!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 🔔 ALERTES
            if (widget.favorite.alertePrix ||
                widget.favorite.alerteDisponibilite) ...[
              const Text(
                'Alertes activées',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (widget.favorite.alertePrix) ...[
                    Icon(Icons.attach_money, color: Colors.green, size: 20),
                    const SizedBox(width: 4),
                    const Text('Alerte prix'),
                    const SizedBox(width: 16),
                  ],
                  if (widget.favorite.alerteDisponibilite) ...[
                    Icon(Icons.notifications, color: Colors.blue, size: 20),
                    const SizedBox(width: 4),
                    const Text('Alerte disponibilité'),
                  ],
                ],
              ),
              const SizedBox(height: 16),
            ],

            // 📅 INFORMATIONS DE DATE
            _buildInfoCard(
              'Ajouté le',
              _formatDate(widget.favorite.dateAjout),
              Icons.calendar_today,
              Colors.grey,
            ),

            const SizedBox(height: 8),

            _buildInfoCard(
              'Dernière consultation',
              _formatDate(widget.favorite.dateDerniereConsultation),
              Icons.schedule,
              Colors.grey,
            ),

            const SizedBox(height: 24),

            // 🎯 ACTIONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditDialog(),
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SDColors.info,
                      foregroundColor: SDColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showArchiveDialog(),
                    icon: const Icon(Icons.archive),
                    label: const Text('Archiver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SDColors.warning,
                      foregroundColor: SDColors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareFavorite(),
                    icon: const Icon(Icons.share),
                    label: const Text('Partager'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDeleteDialog(),
                    icon: const Icon(Icons.delete),
                    label: const Text('Supprimer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SDColors.error,
                      side: BorderSide(color: SDColors.error),
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

  Widget _buildInfoCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: SDTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    Color color;
    switch (type) {
      case 'PRESTATAIRE':
        color = SDColors.info;
        break;
      case 'VENDEUR':
        color = SDColors.warning;
        break;
      case 'FREELANCE':
        color = SDColors.secondary;
        break;
      case 'ARTICLE':
        color = SDColors.success;
        break;
      case 'SERVICE':
        color = SDColors.error;
        break;
      default:
        color = SDColors.neutral500;
    }

    return Chip(
      label: Text(type),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: SDTypography.bodySmall.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
      side: BorderSide.none,
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'ACTIF':
        color = SDColors.success;
        break;
      case 'ARCHIVE':
        color = SDColors.warning;
        break;
      case 'SUPPRIME':
        color = SDColors.error;
        break;
      default:
        color = SDColors.neutral500;
    }

    return Chip(
      label: Text(status),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: SDTypography.bodySmall.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
      side: BorderSide.none,
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

  // 🔄 DIALOGUE D'ARCHIVAGE
  void _showArchiveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archiver le favori'),
        content: Text(
            'Êtes-vous sûr de vouloir archiver "${widget.favorite.titre}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<FavoritePageBlocM>()
                  .add(ArchiveFavoriteM(favoriteId: widget.favorite.id!));
              Navigator.pop(context); // Retour à la liste
            },
            child:
                const Text('Archiver', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  // 🗑️ DIALOGUE DE SUPPRESSION
  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le favori'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer "${widget.favorite.titre}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<FavoritePageBlocM>()
                  .add(DeleteFavoriteM(favoriteId: widget.favorite.id!));
              Navigator.pop(context); // Retour à la liste
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 📤 PARTAGER LE FAVORI
  void _shareFavorite() {
    // TODO: Implémenter le partage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de partage en cours de développement'),
      ),
    );
  }
}
