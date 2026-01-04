import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../favorispageblocm/favoritePageBlocM.dart';
import '../favorispageblocm/favoritePageEventM.dart';
import '../favorispageblocm/favoritePageStateM.dart';
import 'package:sdealsmobile/data/models/favorite.dart';
import 'favoriteDetailScreenM.dart';
import 'addFavoriteScreenM.dart';
import '../../common/widgets/empty_state_widget.dart';

class FavoritePageScreenM extends StatefulWidget {
  const FavoritePageScreenM({super.key});

  @override
  State<FavoritePageScreenM> createState() => _FavoritePageScreenMState();
}

class _FavoritePageScreenMState extends State<FavoritePageScreenM>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedObjetType = '';
  String _selectedStatut = 'ACTIF';
  String _selectedCategorie = '';
  String _selectedVille = '';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Charger les favoris au démarrage
    context.read<FavoritePageBlocM>().add(LoadFavoritesM());
    context.read<FavoritePageBlocM>().add(LoadFavoriteStatsM());
    context.read<FavoritePageBlocM>().add(LoadCustomListsM());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Mes Favoris'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<FavoritePageBlocM>().add(RefreshFavoritesM());
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tous', icon: Icon(Icons.favorite)),
            Tab(text: 'Actifs', icon: Icon(Icons.check_circle)),
            Tab(text: 'Archivés', icon: Icon(Icons.archive)),
          ],
        ),
      ),
      body: BlocConsumer<FavoritePageBlocM, FavoritePageStateM>(
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
          return Column(
            children: [
              // 🔍 BARRE DE RECHERCHE ET FILTRES
              _buildSearchAndFilters(),

              // 📊 STATISTIQUES
              if (state.hasStats) _buildStatsCard(state),

              // 📋 LISTE DES FAVORIS
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFavoritesList(state.favorites ?? []),
                    _buildFavoritesList(
                        state.favorites?.where((f) => f.estActif).toList() ??
                            []),
                    _buildFavoritesList(
                        state.favorites?.where((f) => f.estArchive).toList() ??
                            []),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFavoriteDialog(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // 🔍 BARRE DE RECHERCHE ET FILTRES
  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher dans les favoris...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  context
                      .read<FavoritePageBlocM>()
                      .add(SearchFavoritesM(query: ''));
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onSubmitted: (value) {
              context
                  .read<FavoritePageBlocM>()
                  .add(SearchFavoritesM(query: value));
            },
          ),

          const SizedBox(height: 12),

          // Filtres
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterDropdown(
                  'Type',
                  _selectedObjetType,
                  [
                    '',
                    'PRESTATAIRE',
                    'VENDEUR',
                    'FREELANCE',
                    'ARTICLE',
                    'SERVICE',
                    'PRESTATION',
                    'COMMANDE'
                  ],
                  [
                    'Tous',
                    'Prestataire',
                    'Vendeur',
                    'Freelance',
                    'Article',
                    'Service',
                    'Prestation',
                    'Commande'
                  ],
                  (value) {
                    setState(() => _selectedObjetType = value);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterDropdown(
                  'Statut',
                  _selectedStatut,
                  ['ACTIF', 'ARCHIVE', 'SUPPRIME'],
                  ['Actif', 'Archivé', 'Supprimé'],
                  (value) {
                    setState(() => _selectedStatut = value);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterDropdown(
                  'Catégorie',
                  _selectedCategorie,
                  [
                    '',
                    ...(context
                        .read<FavoritePageBlocM>()
                        .state
                        .categoriesDisponibles)
                  ],
                  [
                    'Toutes',
                    ...(context
                        .read<FavoritePageBlocM>()
                        .state
                        .categoriesDisponibles)
                  ],
                  (value) {
                    setState(() => _selectedCategorie = value);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterDropdown(
                  'Ville',
                  _selectedVille,
                  [
                    '',
                    ...(context
                        .read<FavoritePageBlocM>()
                        .state
                        .villesDisponibles)
                  ],
                  [
                    'Toutes',
                    ...(context
                        .read<FavoritePageBlocM>()
                        .state
                        .villesDisponibles)
                  ],
                  (value) {
                    setState(() => _selectedVille = value);
                    _applyFilters();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> values,
    List<String> labels,
    Function(String) onChanged,
  ) {
    return Container(
      width: 120,
      child: DropdownButtonFormField<String>(
        value: value.isEmpty ? null : value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: values.asMap().entries.map((entry) {
          return DropdownMenuItem(
            value: entry.value,
            child: Text(
              labels[entry.key],
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (value) => onChanged(value ?? ''),
      ),
    );
  }

  // 📊 CARTE DE STATISTIQUES
  Widget _buildStatsCard(FavoritePageStateM state) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
              'Total', state.totalFavorites.toString(), Icons.favorite),
          _buildStatItem(
              'Actifs', state.totalActifs.toString(), Icons.check_circle),
          _buildStatItem(
              'Archivés', state.totalArchives.toString(), Icons.archive),
          _buildStatItem(
              'Récents', state.totalRecents.toString(), Icons.schedule),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // 📋 LISTE DES FAVORIS
  Widget _buildFavoritesList(List<Favorite> favorites) {
    if (favorites.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final favorite = favorites[index];
        return _buildFavoriteCard(favorite);
      },
    );
  }

  // 🎴 CARTE DE FAVORI
  Widget _buildFavoriteCard(Favorite favorite) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDetail(favorite),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec titre et type
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          favorite.titre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildTypeChip(favorite.objetType),
                            const SizedBox(width: 8),
                            if (favorite.categorie != null)
                              Chip(
                                label: Text(favorite.categorie!),
                                backgroundColor: Colors.blue[100],
                                labelStyle: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(favorite.statut),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              if (favorite.description != null) ...[
                Text(
                  favorite.description!,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],

              // Informations supplémentaires
              Row(
                children: [
                  if (favorite.prix != null) ...[
                    Icon(Icons.attach_money,
                        size: 16, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      favorite.prixFormate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (favorite.localisation != null) ...[
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      favorite.localisation!.ville,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${favorite.vues} vues',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

              // Tags
              if (favorite.tags != null && favorite.tags!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: favorite.tags!.take(3).map((tag) {
                    return Chip(
                      label: Text(tag),
                      backgroundColor: Colors.grey[200],
                      labelStyle: const TextStyle(fontSize: 10),
                    );
                  }).toList(),
                ),
              ],

              // Actions
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 20),
                    onPressed: () => _navigateToDetail(favorite),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showEditDialog(favorite),
                  ),
                  IconButton(
                    icon: const Icon(Icons.archive, size: 20),
                    onPressed: () => _showArchiveDialog(favorite),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => _showDeleteDialog(favorite),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    Color color;
    switch (type) {
      case 'PRESTATAIRE':
        color = Colors.blue;
        break;
      case 'VENDEUR':
        color = Colors.orange;
        break;
      case 'FREELANCE':
        color = Colors.purple;
        break;
      case 'ARTICLE':
        color = Colors.green;
        break;
      case 'SERVICE':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(type),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(
        fontSize: 12,
        color: color,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'ACTIF':
        color = Colors.green;
        break;
      case 'ARCHIVE':
        color = Colors.orange;
        break;
      case 'SUPPRIME':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(status),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(
        fontSize: 12,
        color: color,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // 🚫 ÉTAT VIDE
  Widget _buildEmptyState() {
    return EmptyStateWidget(
      imagePath: 'assets/favoris_vides.png',
      title: 'Aucun favori',
      message: 'Commencez par ajouter vos premiers favoris en explorant nos services et produits !',
      imageSize: 180,
    );
  }

  // 🔍 APPLIQUER LES FILTRES
  void _applyFilters() {
    context.read<FavoritePageBlocM>().add(LoadFavoritesM(
          objetType: _selectedObjetType.isEmpty ? null : _selectedObjetType,
          statut: _selectedStatut,
          categorie: _selectedCategorie.isEmpty ? null : _selectedCategorie,
          ville: _selectedVille.isEmpty ? null : _selectedVille,
        ));
  }

  // 🔍 NAVIGATION VERS LE DÉTAIL
  void _navigateToDetail(Favorite favorite) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => FavoritePageBlocM(),
          child: FavoriteDetailScreenM(favorite: favorite),
        ),
      ),
    );
  }

  // 📝 DIALOGUE D'AJOUT DE FAVORI
  void _showAddFavoriteDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => FavoritePageBlocM(),
          child: const AddFavoriteScreenM(),
        ),
      ),
    );
  }

  // ✏️ DIALOGUE DE MODIFICATION
  void _showEditDialog(Favorite favorite) {
    // TODO: Implémenter le dialogue de modification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Fonctionnalité de modification en cours de développement'),
      ),
    );
  }

  // 🔄 DIALOGUE D'ARCHIVAGE
  void _showArchiveDialog(Favorite favorite) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archiver le favori'),
        content:
            Text('Êtes-vous sûr de vouloir archiver "${favorite.titre}" ?'),
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
                  .add(ArchiveFavoriteM(favoriteId: favorite.id!));
            },
            child:
                const Text('Archiver', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  // 🗑️ DIALOGUE DE SUPPRESSION
  void _showDeleteDialog(Favorite favorite) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le favori'),
        content:
            Text('Êtes-vous sûr de vouloir supprimer "${favorite.titre}" ?'),
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
                  .add(DeleteFavoriteM(favoriteId: favorite.id!));
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
