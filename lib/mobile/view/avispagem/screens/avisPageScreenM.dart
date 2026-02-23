import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../avispageblocm/avisPageBlocM.dart';
import '../avispageblocm/avisPageEventM.dart';
import '../avispageblocm/avisPageStateM.dart';
import 'package:sdealsmobile/data/models/avis.dart';
import 'createAvisScreenM.dart';
import 'avisDetailScreenM.dart';

// ✅ Design System
import '../../../../design_system/design_system.dart';

class AvisPageScreenM extends StatefulWidget {
  const AvisPageScreenM({super.key});

  @override
  State<AvisPageScreenM> createState() => _AvisPageScreenMState();
}

class _AvisPageScreenMState extends State<AvisPageScreenM> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedObjetType = '';
  String _selectedStatut = '';
  int? _selectedNote;

  @override
  void initState() {
    super.initState();
    // Charger les avis au démarrage
    context.read<AvisPageBlocM>().add(LoadAvisDataM());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: SDColors.primary600,
        title: Text(
          'Mes Avis & Évaluations',
          style: SDTypography.titleLarge.copyWith(color: SDColors.white),
        ),
        centerTitle: true,
        leading: const BackButton(color: SDColors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: SDColors.white),
            onPressed: () {
              context.read<AvisPageBlocM>().add(RefreshAvisM());
            },
          ),
        ],
      ),
      body: BlocConsumer<AvisPageBlocM, AvisPageStateM>(
        listener: (context, state) {
          if (state.hasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error ?? 'Erreur inconnue'),
                backgroundColor: SDColors.error500,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // 🔍 BARRE DE RECHERCHE ET FILTRES
              _buildSearchAndFilters(),

              // 📊 STATISTIQUES
              if (state.statsObjet != null) _buildStatsCard(state),

              // 📋 LISTE DES AVIS
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.hasAvis
                        ? _buildAvisList(state.avis!)
                        : _buildEmptyState(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateAvisDialog(),
        backgroundColor: SDColors.primary600,
        child: const Icon(Icons.add, color: SDColors.white),
      ),
    );
  }

  // 🔍 BARRE DE RECHERCHE ET FILTRES
  Widget _buildSearchAndFilters() {
    return Container(
      padding: EdgeInsets.all(SDSpacing.md),
      decoration: BoxDecoration(
        color: SDColors.neutral50,
        border: Border(
          bottom: BorderSide(color: SDColors.neutral200),
        ),
      ),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher dans les avis...',
              hintStyle: SDTypography.bodyMedium.copyWith(color: SDColors.neutral500),
              prefixIcon: const Icon(Icons.search, color: SDColors.neutral500),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: SDColors.neutral500),
                onPressed: () {
                  _searchController.clear();
                  context.read<AvisPageBlocM>().add(SearchAvisM(query: ''));
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                borderSide: BorderSide(color: SDColors.neutral200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                borderSide: BorderSide(color: SDColors.neutral200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                borderSide: BorderSide(color: SDColors.primary600),
              ),
              filled: true,
              fillColor: SDColors.white,
            ),
            onSubmitted: (value) {
              context.read<AvisPageBlocM>().add(SearchAvisM(query: value));
            },
          ),

          const SizedBox(height: 12),

          // Filtres
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedObjetType.isEmpty ? null : _selectedObjetType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Tous')),
                    DropdownMenuItem(
                        value: 'PRESTATAIRE', child: Text('Prestataire')),
                    DropdownMenuItem(value: 'VENDEUR', child: Text('Vendeur')),
                    DropdownMenuItem(
                        value: 'FREELANCE', child: Text('Freelance')),
                    DropdownMenuItem(value: 'ARTICLE', child: Text('Article')),
                    DropdownMenuItem(value: 'SERVICE', child: Text('Service')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedObjetType = value ?? '';
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatut.isEmpty ? null : _selectedStatut,
                  decoration: const InputDecoration(
                    labelText: 'Statut',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Tous')),
                    DropdownMenuItem(value: 'PUBLIE', child: Text('Publié')),
                    DropdownMenuItem(
                        value: 'EN_ATTENTE', child: Text('En attente')),
                    DropdownMenuItem(value: 'MODERE', child: Text('Modéré')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatut = value ?? '';
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedNote,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Toutes')),
                    DropdownMenuItem(value: 5, child: Text('5 étoiles')),
                    DropdownMenuItem(value: 4, child: Text('4 étoiles')),
                    DropdownMenuItem(value: 3, child: Text('3 étoiles')),
                    DropdownMenuItem(value: 2, child: Text('2 étoiles')),
                    DropdownMenuItem(value: 1, child: Text('1 étoile')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedNote = value;
                    });
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 📊 CARTE DE STATISTIQUES
  Widget _buildStatsCard(AvisPageStateM state) {
    return Container(
      margin: EdgeInsets.all(SDSpacing.md),
      padding: EdgeInsets.all(SDSpacing.md),
      decoration: BoxDecoration(
        color: SDColors.primary50,
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        border: Border.all(color: SDColors.primary200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
              'Total', state.totalAvis.toString(), Icons.rate_review),
          _buildStatItem('Moyenne', '${state.moyenneNote.toStringAsFixed(1)}/5',
              Icons.star),
          _buildStatItem(
              'Utiles',
              '${state.avis?.where((a) => a.utile > 0).length ?? 0}',
              Icons.thumb_up),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: SDColors.primary600, size: 24),
        SizedBox(height: SDSpacing.xxs),
        Text(
          value,
          style: SDTypography.titleLarge.copyWith(fontWeight: FontWeight.bold, color: SDColors.neutral900),
        ),
        Text(
          label,
          style: SDTypography.bodySmall.copyWith(color: SDColors.neutral600),
        ),
      ],
    );
  }

  // 📋 LISTE DES AVIS
  Widget _buildAvisList(List<Avis> avisList) {
    return ListView.builder(
      padding: EdgeInsets.all(SDSpacing.md),
      itemCount: avisList.length,
      itemBuilder: (context, index) {
        final avis = avisList[index];
        return _buildAvisCard(avis);
      },
    );
  }

  // 🎴 CARTE D'AVIS
  Widget _buildAvisCard(Avis avis) {
    return Card(
        margin: EdgeInsets.only(bottom: SDSpacing.sm),
        elevation: 2,
        color: SDColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
        child: InkWell(
          onTap: () => _navigateToDetail(avis),
          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
          child: Padding(
            padding: EdgeInsets.all(SDSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec auteur et note
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: avis.auteur.photoProfil != null
                          ? NetworkImage(avis.auteur.photoProfil!)
                          : null,
                      child: avis.auteur.photoProfil == null
                          ? Text(avis.auteur.nom.isNotEmpty
                              ? avis.auteur.nom[0]
                              : '?')
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            avis.anonyme
                                ? 'Anonyme'
                                : '${avis.auteur.nom} ${avis.auteur.prenom}',
                            style: SDTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatDate(avis.createdAt),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    _buildRatingStars(avis.note),
                  ],
                ),

                const SizedBox(height: 12),

                // Titre et commentaire
                Text(
                  avis.titre,
                  style: SDTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  avis.commentaire,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Informations supplémentaires
                Row(
                  children: [
                    Chip(
                      label: Text(avis.objetType),
                      backgroundColor: SDColors.success100,
                      labelStyle: SDTypography.labelSmall.copyWith(color: SDColors.success600),
                      padding: EdgeInsets.zero,
                    ),
                    SizedBox(width: SDSpacing.xs),
                    if (avis.recommande)
                      Chip(
                        label: const Text('Recommande'),
                        backgroundColor: SDColors.info100,
                        labelStyle: SDTypography.labelSmall.copyWith(color: SDColors.info600),
                        padding: EdgeInsets.zero,
                      ),
                    const Spacer(),
                    Text(
                      '${avis.utile} utiles',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),

                // Réponse du professionnel
                if (avis.reponse != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text(
                            'Réponse du professionnel',
                            style: SDTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: SDColors.neutral700,
                            ),
                          ),
                          SizedBox(height: SDSpacing.xxs),
                          Text(
                            avis.reponse!.contenu,
                            style: SDTypography.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                ],

                // Actions
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.thumb_up, size: 20),
                      onPressed: () {
                        context.read<AvisPageBlocM>().add(
                              MarquerUtileM(avisId: avis.id, utile: true),
                            );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.thumb_down, size: 20),
                      onPressed: () {
                        context.read<AvisPageBlocM>().add(
                              MarquerUtileM(avisId: avis.id, utile: false),
                            );
                      },
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.reply, size: 20),
                      onPressed: () => _showReplyDialog(avis),
                    ),
                    IconButton(
                      icon: const Icon(Icons.report, size: 20),
                      onPressed: () => _showReportDialog(avis),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () => _showDeleteDialog(avis),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  // ⭐ AFFICHAGE DES ÉTOILES
  Widget _buildRatingStars(int note) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < note ? Icons.star : Icons.star_border,
          color: SDColors.warning500,
          size: 20,
        );
      }),
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

  // 🚫 ÉTAT VIDE
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 64,
            color: SDColors.neutral400,
          ),
          SizedBox(height: SDSpacing.md),
          Text(
            'Aucun avis trouvé',
            style: SDTypography.titleMedium.copyWith(
              color: SDColors.neutral600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: SDSpacing.sm),
          Text(
            'Commencez par donner votre premier avis !',
            style: SDTypography.bodyMedium.copyWith(
              color: SDColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  // 🔍 APPLIQUER LES FILTRES
  void _applyFilters() {
    context.read<AvisPageBlocM>().add(LoadAvisDataM(
          objetType: _selectedObjetType.isEmpty ? null : _selectedObjetType,
          statut: _selectedStatut.isEmpty ? null : _selectedStatut,
          note: _selectedNote,
          searchTerm:
              _searchController.text.isEmpty ? null : _searchController.text,
        ));
  }

  // 🔍 NAVIGATION VERS LE DÉTAIL
  void _navigateToDetail(Avis avis) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => AvisPageBlocM(),
          child: AvisDetailScreenM(avis: avis),
        ),
      ),
    );
  }

  // 📝 DIALOGUE DE CRÉATION D'AVIS
  void _showCreateAvisDialog() {
    // Pour l'instant, on utilise des valeurs par défaut
    // Dans une vraie app, ces valeurs viendraient de la navigation
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => AvisPageBlocM(),
          child: const CreateAvisScreenM(
            objetType: 'PRESTATAIRE',
            objetId: 'default_id',
            objetNom: 'Service par défaut',
          ),
        ),
      ),
    );
  }

  // 💬 DIALOGUE DE RÉPONSE
  void _showReplyDialog(Avis avis) {
    // TODO: Implémenter le dialogue de réponse
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de réponse en cours de développement'),
      ),
    );
  }

  // 🚨 DIALOGUE DE SIGNALEMENT
  void _showReportDialog(Avis avis) {
    // TODO: Implémenter le dialogue de signalement
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Fonctionnalité de signalement en cours de développement'),
      ),
    );
  }

  // 🗑️ DIALOGUE DE SUPPRESSION
  void _showDeleteDialog(Avis avis) {
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
              context.read<AvisPageBlocM>().add(DeleteAvisM(avisId: avis.id));
            },
            child: Text('Supprimer', style: SDTypography.labelLarge.copyWith(color: SDColors.error500)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
