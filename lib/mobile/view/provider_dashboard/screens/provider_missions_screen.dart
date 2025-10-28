import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';

class ProviderMissionsScreen extends StatefulWidget {
  const ProviderMissionsScreen({Key? key}) : super(key: key);

  @override
  _ProviderMissionsScreenState createState() => _ProviderMissionsScreenState();
}

class _ProviderMissionsScreenState extends State<ProviderMissionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _apiClient = ApiClient();

  // 🔍 VARIABLES DE RECHERCHE
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
        // Récupérer l'ID de l'utilisateur pour filtrer les missions
        final utilisateurId = auth.utilisateur.idutilisateur;

        // Charger les missions disponibles (EN_ATTENTE) pour ce prestataire
        final available = await _apiClient.getPrestationsByStatus(
          token: auth.token,
          status: 'EN_ATTENTE',
        );

        // Charger les missions acceptées (ACCEPTEE) pour ce prestataire
        final accepted = await _apiClient.getPrestationsByStatus(
          token: auth.token,
          status: 'ACCEPTEE',
        );

        // Charger les missions en cours (EN_COURS) pour ce prestataire
        final ongoing = await _apiClient.getPrestationsByStatus(
          token: auth.token,
          status: 'EN_COURS',
        );

        // Charger les missions terminées (TERMINEE) pour ce prestataire
        final completed = await _apiClient.getPrestationsByStatus(
          token: auth.token,
          status: 'TERMINEE',
        );

        // Filtrer les missions par utilisateur (via le champ prestataire.utilisateur)
        final filteredAvailable = available
            .where((mission) =>
                mission['prestataire']?['utilisateur']?.toString() ==
                    utilisateurId ||
                mission['prestataire']?.toString() == utilisateurId)
            .toList();

        final filteredAccepted = accepted
            .where((mission) =>
                mission['prestataire']?['utilisateur']?.toString() ==
                    utilisateurId ||
                mission['prestataire']?.toString() == utilisateurId)
            .toList();

        final filteredOngoing = ongoing
            .where((mission) =>
                mission['prestataire']?['utilisateur']?.toString() ==
                    utilisateurId ||
                mission['prestataire']?.toString() == utilisateurId)
            .toList();

        final filteredCompleted = completed
            .where((mission) =>
                mission['prestataire']?['utilisateur']?.toString() ==
                    utilisateurId ||
                mission['prestataire']?.toString() == utilisateurId)
            .toList();

        setState(() {
          _availableMissions = filteredAvailable;
          _ongoingMissions = [
            ...filteredAccepted,
            ...filteredOngoing
          ]; // Accepter + En cours
          _completedMissions = filteredCompleted;
          _isLoading = false;
        });
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
          const SnackBar(
            content: Text('Mission acceptée !'),
            backgroundColor: Colors.green,
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
          const SnackBar(
            content: Text('Mission refusée'),
            backgroundColor: Colors.orange,
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
          const SnackBar(
            content: Text('Mission terminée !'),
            backgroundColor: Colors.green,
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

          // Barre de filtres avec TabBar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2E7D32),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF2E7D32),
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Disponibles'),
                Tab(text: 'En cours'),
                Tab(text: 'Terminées'),
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

  // 🔍 EN-TÊTE DE RECHERCHE
  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade50,
            Colors.green.shade100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barre de recherche principale
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
              decoration: InputDecoration(
                hintText: '🔍 Rechercher une mission...',
                prefixIcon: Icon(Icons.search, color: Colors.green.shade600),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                      )
                    : IconButton(
                        onPressed: () => _loadMissions(),
                        icon: Icon(Icons.refresh, color: Colors.green.shade600),
                      ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Bouton de rafraîchissement
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_availableMissions.length} missions disponibles',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _loadMissions,
                icon: Icon(Icons.refresh, color: Colors.green.shade600),
                label: Text(
                  'Actualiser',
                  style: TextStyle(color: Colors.green.shade600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 📋 ONGLET MISSIONS DISPONIBLES
  Widget _buildAvailableMissionsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2E7D32),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMissions,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_availableMissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucune mission disponible',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les nouvelles missions apparaîtront ici',
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
        itemCount: _availableMissions.length,
        itemBuilder: (context, index) {
          final mission = _availableMissions[index];
          return _buildMissionCard(mission, 'available');
        },
      ),
    );
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec nom client et statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName.isNotEmpty ? clientName : 'Client anonyme',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '$ville, $adresse',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(type),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(type),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Détails de la mission
            if (datePrestation.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Date: ${DateTime.parse(datePrestation).toLocal().toString().split(' ')[0]}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            if (montant > 0) ...[
              Row(
                children: [
                  Icon(Icons.monetization_on,
                      size: 16, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Montant: ${montant.toString()} FCFA',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            if (notes.isNotEmpty) ...[
              Text(
                'Notes: $notes',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Boutons d'action selon le type
            _buildActionButtons(mission, type),
          ],
        ),
      ),
    );
  }

  // 🎯 BOUTONS D'ACTION
  Widget _buildActionButtons(Map<String, dynamic> mission, String type) {
    switch (type) {
      case 'available':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _acceptMission(mission),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.check),
                label: const Text('Accepter'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _rejectMission(mission),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close),
                label: const Text('Refuser'),
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
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check_circle),
            label: const Text('Marquer comme terminée'),
          ),
        );

      case 'completed':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600),
              const SizedBox(width: 8),
              Text(
                'Mission terminée avec succès',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // 🎨 COULEUR PAR STATUT
  Color _getStatusColor(String type) {
    switch (type) {
      case 'available':
        return Colors.orange;
      case 'ongoing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
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
