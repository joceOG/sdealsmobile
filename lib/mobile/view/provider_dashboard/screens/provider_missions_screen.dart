import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
// ✅ Design System
import '../../../../design_system/design_system.dart';

class ProviderMissionsScreen extends StatefulWidget {
  final String? prestataireDocId;
  const ProviderMissionsScreen({Key? key, this.prestataireDocId}) : super(key: key);

  @override
  _ProviderMissionsScreenState createState() => _ProviderMissionsScreenState();
}

class _ProviderMissionsScreenState extends State<ProviderMissionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _apiClient = ApiClient();

  // 🔍 VARIABLES DE RECHERCHE ET FILTRES
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCityFilter;
  String? _selectedDateFilter; // 'today', 'week', 'month', 'all'
  
  // 📊 DONNÉES RÉELLES (remplace les données simulées)
  List<Map<String, dynamic>> _availableMissions = [];
  List<Map<String, dynamic>> _ongoingMissions = [];
  List<Map<String, dynamic>> _completedMissions = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // 🎯 CHARGER LES MISSIONS AU DÉMARRAGE
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMissions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 🚀 CHARGER LES MISSIONS DEPUIS L'API
  Future<void> _loadMissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthCubit>().state;
      if (auth is AuthAuthenticated) {
        final prestataireDocId = widget.prestataireDocId;
        final utilisateurId = auth.utilisateur.idutilisateur;

        if (prestataireDocId != null) {
          // Utiliser l'endpoint direct par prestataireId (plus efficace)
          final available = await _apiClient.getPrestationsByStatus(
            token: auth.token,
            status: 'EN_ATTENTE',
            prestataireId: prestataireDocId,
          );
          final accepted = await _apiClient.getPrestationsByStatus(
            token: auth.token,
            status: 'ACCEPTEE',
            prestataireId: prestataireDocId,
          );
          final ongoing = await _apiClient.getPrestationsByStatus(
            token: auth.token,
            status: 'EN_COURS',
            prestataireId: prestataireDocId,
          );
          final completed = await _apiClient.getPrestationsByStatus(
            token: auth.token,
            status: 'TERMINEE',
            prestataireId: prestataireDocId,
          );
          setState(() {
            _availableMissions = available;
            _ongoingMissions = [...accepted, ...ongoing];
            _completedMissions = completed;
            _isLoading = false;
          });
        } else {
          // Fallback : filtrage client-side par userId
          final available = await _apiClient.getPrestationsByStatus(
            token: auth.token, status: 'EN_ATTENTE');
          final accepted = await _apiClient.getPrestationsByStatus(
            token: auth.token, status: 'ACCEPTEE');
          final ongoing = await _apiClient.getPrestationsByStatus(
            token: auth.token, status: 'EN_COURS');
          final completed = await _apiClient.getPrestationsByStatus(
            token: auth.token, status: 'TERMINEE');

          bool matchUser(m) =>
              m['prestataire']?['utilisateur']?.toString() == utilisateurId ||
              m['prestataire']?.toString() == utilisateurId;

          setState(() {
            _availableMissions = available.where(matchUser).toList();
            _ongoingMissions = [
              ...accepted.where(matchUser),
              ...ongoing.where(matchUser)
            ];
            _completedMissions = completed.where(matchUser).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  // ✅ ACCEPTER UNE MISSION
  Future<void> _acceptMission(Map<String, dynamic> mission) async {
    try {
      final auth = context.read<AuthCubit>().state;
      if (auth is AuthAuthenticated) {
        await _apiClient.updatePrestationStatus(
          token: auth.token,
          prestationId: mission['_id'],
          newStatus: 'ACCEPTEE',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mission acceptée !', style: SDTypography.bodyMedium.copyWith(color: SDColors.white)),
            backgroundColor: SDColors.success500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
            ),
          ),
        );

        // Recharger les missions
        _loadMissions();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ❌ REFUSER UNE MISSION
  Future<void> _rejectMission(Map<String, dynamic> mission) async {
    try {
      final auth = context.read<AuthCubit>().state;
      if (auth is AuthAuthenticated) {
        await _apiClient.updatePrestationStatus(
          token: auth.token,
          prestationId: mission['_id'],
          newStatus: 'REFUSEE',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mission refusée', style: SDTypography.bodyMedium.copyWith(color: SDColors.white)),
            backgroundColor: SDColors.warning500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
            ),
          ),
        );

        // Recharger les missions
        _loadMissions();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ TERMINER UNE MISSION
  Future<void> _completeMission(Map<String, dynamic> mission) async {
    try {
      final auth = context.read<AuthCubit>().state;
      if (auth is AuthAuthenticated) {
        await _apiClient.updatePrestationStatus(
          token: auth.token,
          prestationId: mission['_id'],
          newStatus: 'TERMINEE',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mission terminée !', style: SDTypography.bodyMedium.copyWith(color: SDColors.white)),
            backgroundColor: SDColors.success500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
            ),
          ),
        );

        // Recharger les missions
        _loadMissions();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 🔍 EN-TÊTE DE RECHERCHE
          _buildSearchHeader(),

          // Barre de filtres avec TabBar - AMÉLIORÉ AVEC DESIGN SYSTEM
          Container(
            decoration: BoxDecoration(
              color: SDColors.white,
              boxShadow: [
                BoxShadow(
                  color: SDColors.neutral200.withOpacity(0.3),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: SDColors.primary600,
              unselectedLabelColor: SDColors.neutral500,
              indicatorColor: SDColors.primary600,
              indicatorWeight: 3,
              labelStyle: SDTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
              unselectedLabelStyle: SDTypography.labelMedium,
              tabs: [
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Disponibles',
                          maxLines: 1,
                          style: SDTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (_availableMissions.isNotEmpty)
                          Container(
                            margin: EdgeInsets.only(left: SDSpacing.xxxs),
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: SDColors.warning500,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_availableMissions.length}',
                              style: SDTypography.labelSmall.copyWith(
                                color: SDColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'En cours',
                          maxLines: 1,
                          style: SDTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (_ongoingMissions.isNotEmpty)
                          Container(
                            margin: EdgeInsets.only(left: SDSpacing.xxxs),
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: SDColors.info500,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_ongoingMissions.length}',
                              style: SDTypography.labelSmall.copyWith(
                                color: SDColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Terminées',
                      maxLines: 1,
                      style: SDTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAvailableMissionsTab(),
                _buildOngoingMissionsTab(),
                _buildCompletedMissionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔍 EN-TÊTE DE RECHERCHE - AMÉLIORÉ AVEC DESIGN SYSTEM ET FILTRES
  Widget _buildSearchHeader() {
    return Container(
      padding: EdgeInsets.all(SDSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SDColors.primary50,
            SDColors.success50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: SDColors.primary200.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barre de recherche principale
          Container(
            decoration: BoxDecoration(
              color: SDColors.white,
              borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
              boxShadow: [
                BoxShadow(
                  color: SDColors.neutral200.withOpacity(0.5),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: SDTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Rechercher une mission...',
                hintStyle: SDTypography.bodyMedium.copyWith(color: SDColors.neutral400),
                prefixIcon: Icon(Icons.search, color: SDColors.primary600),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: Icon(Icons.clear, color: SDColors.neutral500),
                      )
                    : IconButton(
                        onPressed: () => _loadMissions(),
                        icon: Icon(Icons.refresh, color: SDColors.primary600),
                      ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: SDSpacing.md, vertical: SDSpacing.sm),
              ),
            ),
          ),
          SizedBox(height: SDSpacing.sm),
          
          // Filtres rapides
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Toutes', _selectedDateFilter == null, () {
                  setState(() => _selectedDateFilter = null);
                }),
                SizedBox(width: SDSpacing.xs),
                _buildFilterChip('Aujourd\'hui', _selectedDateFilter == 'today', () {
                  setState(() => _selectedDateFilter = 'today');
                }),
                SizedBox(width: SDSpacing.xs),
                _buildFilterChip('Cette semaine', _selectedDateFilter == 'week', () {
                  setState(() => _selectedDateFilter = 'week');
                }),
                SizedBox(width: SDSpacing.xs),
                _buildFilterChip('Ce mois', _selectedDateFilter == 'month', () {
                  setState(() => _selectedDateFilter = 'month');
                }),
              ],
            ),
          ),
          
          SizedBox(height: SDSpacing.sm),

          // Compteur et bouton de rafraîchissement
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${_filterMissions(_availableMissions).length} missions trouvées',
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.primary700,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: _loadMissions,
                icon: Icon(Icons.refresh, color: SDColors.primary600, size: 18),
                label: Text(
                  'Actualiser',
                  style: SDTypography.labelMedium.copyWith(color: SDColors.primary600),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: SDSpacing.xs),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: SDSpacing.sm, vertical: SDSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected ? SDColors.primary600 : SDColors.white,
          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
          border: Border.all(
            color: isSelected ? SDColors.primary600 : SDColors.neutral300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: SDTypography.labelSmall.copyWith(
            color: isSelected ? SDColors.white : SDColors.neutral700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // 📋 ONGLET MISSIONS DISPONIBLES
  Widget _buildAvailableMissionsTab() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: SDColors.primary600,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(SDSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: SDColors.error500),
              SizedBox(height: SDSpacing.md),
              Text(
                _errorMessage!,
                style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral700),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: SDSpacing.md),
              ElevatedButton(
                onPressed: _loadMissions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SDColors.primary600,
                  foregroundColor: SDColors.white,
                ),
                child: Text('Réessayer', style: SDTypography.labelMedium),
              ),
            ],
          ),
        ),
      );
    }

    final filteredMissions = _filterMissions(_availableMissions);
    
    if (filteredMissions.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(SDSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined, size: 64, color: SDColors.neutral300),
              SizedBox(height: SDSpacing.md),
              Text(
                _availableMissions.isEmpty 
                    ? 'Aucune mission disponible'
                    : 'Aucune mission ne correspond aux filtres',
                style: SDTypography.titleSmall.copyWith(
                  color: SDColors.neutral600,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: SDSpacing.xs),
              Text(
                _availableMissions.isEmpty
                    ? 'Les nouvelles missions apparaîtront ici'
                    : 'Essayez de modifier vos filtres de recherche',
                style: SDTypography.bodySmall.copyWith(
                  color: SDColors.neutral500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadMissions,
      color: SDColors.primary600,
      child: ListView.builder(
        padding: EdgeInsets.all(SDSpacing.md),
        itemCount: filteredMissions.length,
        itemBuilder: (context, index) {
          final mission = filteredMissions[index];
          return _buildMissionCardWithSwipe(mission, 'available');
        },
      ),
    );
  }
  
  // Filtrer les missions selon les critères
  List<Map<String, dynamic>> _filterMissions(List<Map<String, dynamic>> missions) {
    var filtered = missions;
    
    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((mission) {
        final client = mission['utilisateur'] ?? {};
        final clientName = '${client['nom'] ?? ''} ${client['prenom'] ?? ''}'.trim().toLowerCase();
        final adresse = (mission['adresse'] ?? '').toString().toLowerCase();
        final ville = (mission['ville'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return clientName.contains(query) || adresse.contains(query) || ville.contains(query);
      }).toList();
    }
    
    // Filtre par ville
    if (_selectedCityFilter != null && _selectedCityFilter!.isNotEmpty) {
      filtered = filtered.where((mission) {
        return (mission['ville'] ?? '').toString() == _selectedCityFilter;
      }).toList();
    }
    
    // Filtre par date
    if (_selectedDateFilter != null && _selectedDateFilter != 'all') {
      final now = DateTime.now();
      filtered = filtered.where((mission) {
        final dateStr = mission['datePrestation']?.toString();
        if (dateStr == null || dateStr.isEmpty) return false;
        try {
          final date = DateTime.parse(dateStr);
          switch (_selectedDateFilter) {
            case 'today':
              return date.year == now.year && date.month == now.month && date.day == now.day;
            case 'week':
              final weekStart = now.subtract(Duration(days: now.weekday - 1));
              return date.isAfter(weekStart.subtract(Duration(days: 1)));
            case 'month':
              return date.year == now.year && date.month == now.month;
            default:
              return true;
          }
        } catch (e) {
          return false;
        }
      }).toList();
    }
    
    return filtered;
  }
  
  // Card avec actions swipe
  Widget _buildMissionCardWithSwipe(Map<String, dynamic> mission, String type) {
    if (type == 'available') {
      return Dismissible(
        key: Key(mission['_id']?.toString() ?? UniqueKey().toString()),
        direction: DismissDirection.horizontal,
        background: Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.only(left: SDSpacing.md),
          decoration: BoxDecoration(
            color: SDColors.success500,
            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: SDColors.white, size: 32),
              SizedBox(width: SDSpacing.sm),
              Text(
                'Accepter',
                style: SDTypography.titleSmall.copyWith(
                  color: SDColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: SDSpacing.md),
          decoration: BoxDecoration(
            color: SDColors.error500,
            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Refuser',
                style: SDTypography.titleSmall.copyWith(
                  color: SDColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: SDSpacing.sm),
              Icon(Icons.cancel, color: SDColors.white, size: 32),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Accepter
            await _acceptMission(mission);
            return false; // Ne pas supprimer de la liste, le refresh le fera
          } else {
            // Refuser
            return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Refuser cette mission ?', style: SDTypography.titleMedium),
                content: Text('Cette action est irréversible.', style: SDTypography.bodyMedium),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Annuler', style: SDTypography.labelMedium),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                      _rejectMission(mission);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: SDColors.error500,
                    ),
                    child: Text('Refuser', style: SDTypography.labelMedium.copyWith(color: SDColors.error500)),
                  ),
                ],
              ),
            ) ?? false;
          }
        },
        child: _buildMissionCard(mission, type),
      );
    }
    return _buildMissionCard(mission, type);
  }

  // 🚀 ONGLET MISSIONS EN COURS
  Widget _buildOngoingMissionsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2E7D32),
        ),
      );
    }

    if (_ongoingMissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucune mission en cours',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos missions acceptées apparaîtront ici',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMissions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ongoingMissions.length,
        itemBuilder: (context, index) {
          final mission = _ongoingMissions[index];
          return _buildMissionCard(mission, 'ongoing');
        },
      ),
    );
  }

  // ✅ ONGLET MISSIONS TERMINÉES
  Widget _buildCompletedMissionsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2E7D32),
        ),
      );
    }

    if (_completedMissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucune mission terminée',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos missions terminées apparaîtront ici',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMissions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _completedMissions.length,
        itemBuilder: (context, index) {
          final mission = _completedMissions[index];
          return _buildMissionCard(mission, 'completed');
        },
      ),
    );
  }

  // 🎯 CARTE DE MISSION
  Widget _buildMissionCard(Map<String, dynamic> mission, String type) {
    final client = mission['utilisateur'] ?? {};
    final clientName =
        '${client['nom'] ?? ''} ${client['prenom'] ?? ''}'.trim();
    final adresse = mission['adresse'] ?? 'Adresse non spécifiée';
    final ville = mission['ville'] ?? 'Ville non spécifiée';
    final notes = mission['notesClient'] ?? '';
    final datePrestation = mission['datePrestation'] ?? '';
    final montant = mission['montantTotal'] ?? 0;
    final priorite = mission['priorite']?.toString() ?? 'NORMALE';
    final historiqueStatuts = mission['historiqueStatuts'] as List<dynamic>? ?? [];
    final isNew = historiqueStatuts.isEmpty || historiqueStatuts.length == 1;

    return Container(
      margin: EdgeInsets.only(bottom: SDSpacing.md),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
        border: isNew ? Border.all(color: SDColors.primary200, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: SDColors.neutral200.withOpacity(0.5),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(SDSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec nom client, statut et badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              clientName.isNotEmpty ? clientName : 'Client anonyme',
                              style: SDTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: SDColors.neutral900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isNew)
                            Container(
                              margin: EdgeInsets.only(left: SDSpacing.xs),
                              padding: EdgeInsets.symmetric(horizontal: SDSpacing.xs, vertical: 2),
                              decoration: BoxDecoration(
                                color: SDColors.primary600,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'NOUVEAU',
                                style: SDTypography.labelSmall.copyWith(
                                  color: SDColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: SDSpacing.xxxs),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: SDColors.neutral500),
                          SizedBox(width: SDSpacing.xxxs),
                          Expanded(
                            child: Text(
                              '$ville, $adresse',
                              style: SDTypography.bodySmall.copyWith(
                                color: SDColors.neutral600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: SDSpacing.xs),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.32),
                      padding: EdgeInsets.symmetric(horizontal: SDSpacing.sm, vertical: SDSpacing.xs),
                      decoration: BoxDecoration(
                        color: _getStatusColor(type),
                        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                      ),
                      child: Text(
                        _getStatusText(type),
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (priorite == 'HAUTE')
                      Container(
                        margin: EdgeInsets.only(top: SDSpacing.xxxs),
                        padding: EdgeInsets.symmetric(horizontal: SDSpacing.xs, vertical: 2),
                        decoration: BoxDecoration(
                          color: SDColors.error500,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'URGENT',
                          style: SDTypography.labelSmall.copyWith(
                            color: SDColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            SizedBox(height: SDSpacing.sm),

            // Détails de la mission
            if (datePrestation.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: SDColors.neutral500),
                  SizedBox(width: SDSpacing.xs),
                  Expanded(
                    child: Text(
                      'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(datePrestation))}',
                      style: SDTypography.bodySmall.copyWith(
                        color: SDColors.neutral700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: SDSpacing.xs),
            ],

            // Message GRATUIT au lieu du montant
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(SDSpacing.xs),
              decoration: BoxDecoration(
                color: SDColors.success50,
                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                border: Border.all(color: SDColors.success200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: SDColors.success600),
                  SizedBox(width: SDSpacing.xxxs),
                  Expanded(
                    child: Text(
                      'Service 100% GRATUIT',
                      style: SDTypography.bodySmall.copyWith(
                        color: SDColors.success700,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            if (notes.isNotEmpty) ...[
              SizedBox(height: SDSpacing.sm),
              Container(
                padding: EdgeInsets.all(SDSpacing.xs),
                decoration: BoxDecoration(
                  color: SDColors.neutral50,
                  borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: SDColors.neutral500),
                    SizedBox(width: SDSpacing.xs),
                    Expanded(
                      child: Text(
                        notes,
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.neutral700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: SDSpacing.sm),

            // Boutons d'action selon le type
            _buildActionButtons(mission, type),
          ],
        ),
      ),
    );
  }

  // 🎯 BOUTONS D'ACTION - AMÉLIORÉS AVEC DESIGN SYSTEM
  Widget _buildActionButtons(Map<String, dynamic> mission, String type) {
    switch (type) {
      case 'available':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _acceptMission(mission),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SDColors.success500,
                  foregroundColor: SDColors.white,
                  padding: EdgeInsets.symmetric(vertical: SDSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                  ),
                ),
                icon: Icon(Icons.check, size: 20),
                label: Text('Accepter', style: SDTypography.labelMedium.copyWith(color: SDColors.white)),
              ),
            ),
            SizedBox(width: SDSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _rejectMission(mission),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SDColors.error500,
                  side: BorderSide(color: SDColors.error500),
                  padding: EdgeInsets.symmetric(vertical: SDSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                  ),
                ),
                icon: Icon(Icons.close, size: 20),
                label: Text('Refuser', style: SDTypography.labelMedium.copyWith(color: SDColors.error500)),
              ),
            ),
          ],
        );

      case 'ongoing':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _completeMission(mission),
            style: ElevatedButton.styleFrom(
              backgroundColor: SDColors.info500,
              foregroundColor: SDColors.white,
              padding: EdgeInsets.symmetric(vertical: SDSpacing.sm),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
              ),
            ),
            icon: Icon(Icons.check_circle, size: 20),
            label: Text('Marquer comme terminée', style: SDTypography.labelMedium.copyWith(color: SDColors.white)),
          ),
        );

      case 'completed':
        return Container(
          padding: EdgeInsets.all(SDSpacing.sm),
          decoration: BoxDecoration(
            color: SDColors.success50,
            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
            border: Border.all(color: SDColors.success200),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: SDColors.success600, size: 20),
              SizedBox(width: SDSpacing.xs),
              Expanded(
                child: Text(
                  'Mission terminée avec succès',
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.success700,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );

      default:
        return SizedBox.shrink();
    }
  }

  // 🎨 COULEUR PAR STATUT - AVEC DESIGN SYSTEM
  Color _getStatusColor(String type) {
    switch (type) {
      case 'available':
        return SDColors.warning500;
      case 'ongoing':
        return SDColors.info500;
      case 'completed':
        return SDColors.success500;
      default:
        return SDColors.neutral500;
    }
  }

  // 📝 TEXTE PAR STATUT
  String _getStatusText(String type) {
    switch (type) {
      case 'available':
        return 'Disponible';
      case 'ongoing':
        return 'En cours';
      case 'completed':
        return 'Terminée';
      default:
        return 'Inconnu';
    }
  }
}
