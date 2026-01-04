import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../data/models/prestataire.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart';
import '../../loginpagem/screens/loginPageScreenM.dart';
import '../widgets/mini_map_widget.dart';
import '../../orderpagem/screens/service_request_summary_screen.dart';
import '../../common/widgets/app_image.dart';

/// 🎯 Page de profil complète d'un prestataire
/// Affiche toutes les informations détaillées, services, avis, portfolio
class ProviderProfileScreen extends StatefulWidget {
  final String providerId;
  final Map<String, dynamic>? providerData; // Cache optionnel

  const ProviderProfileScreen({
    required this.providerId,
    this.providerData,
    super.key,
  });

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  
  Prestataire? _provider;
  bool _isLoading = true;
  String? _error;
  bool _isFavorited = false;
  LatLng? _userLocation;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProviderData();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      // Position par défaut (Abidjan)
      if (mounted) {
        setState(() {
          _userLocation = const LatLng(5.3599, -4.0083);
        });
      }
    }
  }

  Future<void> _loadProviderData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Si on a des données en cache, les utiliser temporairement
      if (widget.providerData != null) {
        _provider = Prestataire.fromBackend(widget.providerData!);
        setState(() {
          _isLoading = false;
        });
        // Puis recharger en background pour avoir les données fraîches
        _reloadProviderData();
      } else {
        // Charger depuis l'API
        await _reloadProviderData();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur lors du chargement du profil: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _reloadProviderData() async {
    try {
      final data = await _api.fetchPrestataireById(widget.providerId);
      if (mounted) {
        setState(() {
          _provider = Prestataire.fromBackend(data);
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('Erreur rechargement prestataire: $e');
      if (_provider == null && mounted) {
        setState(() {
          _error = 'Impossible de charger le profil';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : _error != null
              ? _buildErrorState()
              : _buildProfileContent(),
      bottomNavigationBar: _provider != null ? _buildBottomActions() : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Erreur',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Une erreur est survenue',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProviderData,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    if (_provider == null) return const SizedBox.shrink();

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderInfo(),
              const SizedBox(height: 16),
              _buildTabBar(),
              const SizedBox(height: 16),
            ],
          ),
        ),
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAboutTab(),
              _buildServicesTab(),
              _buildReviewsTab(),
              _buildPortfolioTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    final photoUrl = _provider?.utilisateur.photoProfil ?? '';
    final isUrl = photoUrl.isNotEmpty && photoUrl.startsWith('http');

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF2E7D32),
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF2E7D32),
                    const Color(0xFF4CAF50).withOpacity(0.8),
                  ],
                ),
              ),
            ),
            // Profile photo
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: isUrl
                      ? AppImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                        )
                      : _buildDefaultAvatar(),
                ),
              ),
            ),
            // Verified badge
            if (_provider!.verifier)
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(left: 80),
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.ios_share_rounded),
          onPressed: _onShareProfile,
        ),
        IconButton(
          icon: Icon(_isFavorited ? Icons.favorite : Icons.favorite_border),
          onPressed: _onToggleFavorite,
        ),
        IconButton(
          icon: const Icon(Icons.flag_outlined),
          onPressed: _onReportProfile,
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFF2E7D32).withOpacity(0.2),
      child: const Icon(
        Icons.person,
        color: Color(0xFF2E7D32),
        size: 60,
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Nom et profession
          Text(
            _provider!.utilisateur.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _provider!.service.nomservice,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                Icons.star,
                _provider!.note ?? '4.5',
                'Note',
                Colors.amber,
              ),
              _buildStatItem(
                Icons.work_outline,
                _provider!.anneeExperience ?? '5+',
                'Années',
                const Color(0xFF2E7D32),
              ),
              _buildStatItem(
                Icons.location_on,
                _calculateDistance(),
                'Distance',
                Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Price range
          if (_provider!.tarifHoraireMin != null || _provider!.tarifHoraireMax != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2E7D32).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payments_outlined, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Text(
                    _formatPriceRange(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _calculateDistance() {
    if (_userLocation == null || _provider!.localisationMaps == null) {
      return 'N/A';
    }
    
    final distance = Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      _provider!.localisationMaps!.latitude,
      _provider!.localisationMaps!.longitude,
    );
    
    if (distance < 1000) {
      return '${distance.toInt()}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }

  String _formatPriceRange() {
    final min = _provider!.tarifHoraireMin;
    final max = _provider!.tarifHoraireMax;
    
    if (min != null && max != null) {
      return '${min.toInt()} - ${max.toInt()} FCFA/h';
    } else if (min != null) {
      return 'À partir de ${min.toInt()} FCFA/h';
    } else if (max != null) {
      return "Jusqu'à ${max.toInt()} FCFA/h";
    } else {
      return '${_provider!.prixprestataire.toInt()} FCFA/h';
    }
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF2E7D32),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF2E7D32),
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'À propos'),
          Tab(text: 'Services'),
          Tab(text: 'Avis'),
          Tab(text: 'Portfolio'),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          _buildSection(
            'Description',
            Icons.description,
            child: Text(
              _provider!.description ?? 'Prestataire professionnel et expérimenté.',
              style: const TextStyle(fontSize: 15, height: 1.5),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 24),
          
          // Spécialités
          if (_provider!.specialite != null && _provider!.specialite!.isNotEmpty)
            _buildSection(
              'Spécialités',
              Icons.stars,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _provider!.specialite!
                    .map((s) => Chip(
                          label: Text(
                            s,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
                          labelStyle: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 13,
                          ),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ),
          const SizedBox(height: 24),
          
          // Zones d'intervention
          if (_provider!.zoneIntervention != null && _provider!.zoneIntervention!.isNotEmpty)
            _buildSection(
              'Zones d\'intervention',
              Icons.location_city,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _provider!.zoneIntervention!
                    .map((z) => Chip(
                          label: Text(
                            z,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                          avatar: const Icon(Icons.location_on, size: 14),
                          backgroundColor: Colors.blue.shade50,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ),
          const SizedBox(height: 24),
          
          // Diplômes et certifications
          if (_provider!.diplomeCertificat != null && _provider!.diplomeCertificat!.isNotEmpty)
            _buildSection(
              'Diplômes & Certifications',
              Icons.school,
              child: Column(
                children: _provider!.diplomeCertificat!
                    .map((d) => ListTile(
                          leading: const Icon(Icons.verified, color: Color(0xFF2E7D32), size: 20),
                          title: Text(
                            d,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ))
                    .toList(),
              ),
            ),
          const SizedBox(height: 24),
          
          // Carte de localisation
          _buildSection(
            'Localisation',
            Icons.map,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _provider!.localisation,
                  style: const TextStyle(fontSize: 15),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (_userLocation != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 100,
                      maxHeight: 200,
                    ),
                    child: MiniMapWidget(
                      provider: _provider!.toJson(),
                      userLocation: _userLocation,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            'Service Principal',
            Icons.work,
            child: Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.build, color: Color(0xFF2E7D32), size: 20),
                ),
                title: Text(
                  _provider!.service.nomservice,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  _provider!.service.categorie?.nomcategorie ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: Text(
                  '${_provider!.prixprestataire.toInt()} FCFA',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ce prestataire propose des services de qualité avec une expertise reconnue.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Note moyenne
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Column(
                    children: [
                      Text(
                        _provider!.note ?? '4.5',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < double.parse(_provider!.note ?? '4.5').floor()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Basé sur 42 avis',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        _buildRatingBar('5', 0.75),
                        _buildRatingBar('4', 0.15),
                        _buildRatingBar('3', 0.07),
                        _buildRatingBar('2', 0.02),
                        _buildRatingBar('1', 0.01),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Liste des avis (simulés)
          const Text(
            'Avis récents',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._buildMockReviews(),
        ],
      ),
    );
  }

  Widget _buildRatingBar(String stars, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(stars, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(percentage * 100).toInt()}%',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMockReviews() {
    final reviews = [
      {
        'name': 'Marie Koné',
        'rating': 5,
        'date': '2 jours',
        'comment': 'Excellent travail ! Très professionnel et ponctuel. Je recommande vivement.',
      },
      {
        'name': 'Kouassi Jean',
        'rating': 5,
        'date': '1 semaine',
        'comment': 'Super prestataire, travail de qualité et prix raisonnable.',
      },
      {
        'name': 'Aminata Diallo',
        'rating': 4,
        'date': '2 semaines',
        'comment': 'Bon service dans l\'ensemble. Quelques petits détails à revoir mais satisfaite.',
      },
    ];

    return reviews.map((review) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(review['name'].toString()[0]),
                    backgroundColor: const Color(0xFF2E7D32).withOpacity(0.2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            ...List.generate(
                              review['rating'] as int,
                              (i) => const Icon(Icons.star, size: 14, color: Colors.amber),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Il y a ${review['date']}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(review['comment'] as String),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildPortfolioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Galerie de travaux',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 48, color: Colors.grey),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Les photos du portfolio seront bientôt disponibles',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF2E7D32), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildBottomActions() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _onContactProvider,
                icon: const Icon(Icons.phone),
                label: const Text('Appeler'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _onRequestService,
                icon: const Icon(Icons.send),
                label: const Text('Demander un devis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Actions
  void _onShareProfile() async {
    final text = 'Découvrez ${_provider!.utilisateur.fullName} - ${_provider!.service.nomservice} sur Soutrali Deals';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lien copié dans le presse-papiers')),
      );
    }
  }

  void _onToggleFavorite() {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour ajouter en favoris.')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPageScreenM()),
      );
      return;
    }

    setState(() => _isFavorited = !_isFavorited);
    final msg = _isFavorited ? 'Ajouté aux favoris' : 'Retiré des favoris';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _onReportProfile() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Signaler ce prestataire'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Décrivez le problème...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Signaler'),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signalement envoyé. Merci.')),
      );
    }
  }

  void _onContactProvider() async {
    final phone = _provider?.utilisateur.telephone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro de téléphone non disponible')),
      );
      return;
    }

    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'appeler ce numéro')),
        );
      }
    }
  }

  void _onRequestService() {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter pour demander un devis.')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPageScreenM()),
      );
      return;
    }

    // Ouvrir le formulaire de demande de devis
    _openRequestQuoteSheet(auth);
  }

  void _openRequestQuoteSheet(AuthAuthenticated auth) {
    final adresseCtrl = TextEditingController();
    final villeCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime? selectedDateTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête moderne
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.request_quote_rounded,
                            color: Color(0xFF2E7D32),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Demander un devis',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                _provider!.utilisateur.fullName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Badge du service
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.build_circle, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Service demandé',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  _provider!.service.nomservice,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (_provider!.prixprestataire > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_provider!.prixprestataire.toInt()} F',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Adresse
                    TextField(
                      controller: adresseCtrl,
                      decoration: InputDecoration(
                        labelText: 'Adresse *',
                        hintText: 'Ex: Rue 12, Cocody',
                        prefixIcon: const Icon(Icons.home, color: Color(0xFF2E7D32)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Ville
                    TextField(
                      controller: villeCtrl,
                      decoration: InputDecoration(
                        labelText: 'Ville',
                        hintText: 'Ex: Abidjan',
                        prefixIcon: const Icon(Icons.location_city, color: Color(0xFF2E7D32)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Date et heure moderne
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedDateTime == null
                                  ? 'Choisir une date et heure (optionnel)'
                                  : '${selectedDateTime!.day}/${selectedDateTime!.month}/${selectedDateTime!.year} à ${selectedDateTime!.hour}:${selectedDateTime!.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: selectedDateTime == null ? Colors.grey.shade500 : Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().add(const Duration(days: 1)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (time != null) {
                                  setSheetState(() {
                                    selectedDateTime = DateTime(
                                      date.year,
                                      date.month,
                                      date.day,
                                      time.hour,
                                      time.minute,
                                    );
                                  });
                                }
                              }
                            },
                            child: const Text('Choisir', style: TextStyle(color: Color(0xFF2E7D32))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Notes
                    TextField(
                      controller: notesCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Notes / Instructions (optionnel)',
                        hintText: 'Ajoutez des détails supplémentaires...',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 40),
                          child: Icon(Icons.note_alt, color: Color(0xFF2E7D32)),
                        ),
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Info système gratuit
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Service 100% GRATUIT - Aucun paiement requis',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  
                  // Bouton de soumission moderne
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Validation
                        if (adresseCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: const [
                                  Icon(Icons.warning_amber_rounded, color: Colors.white),
                                  SizedBox(width: 8),
                                  Expanded(child: Text('Veuillez saisir une adresse')),
                                ],
                              ),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                          return;
                        }
                        
                        // Montrer un loader
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(
                            child: Card(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(color: Color(0xFF2E7D32)),
                                    SizedBox(height: 16),
                                    Text('Envoi en cours...'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                        
                        // Créer la demande
                        try {
                          final created = await _api.createPrestation(
                            token: auth.token,
                            utilisateurId: auth.utilisateur.idutilisateur,
                            prestataireId: _provider!.idprestataire,
                            serviceId: _provider!.service.idservice,
                            adresse: adresseCtrl.text.trim(),
                            ville: villeCtrl.text.trim(),
                            dateHeure: selectedDateTime,
                            notesClient: notesCtrl.text.trim(),
                            montant: _provider!.prixprestataire,
                          );
                          
                          if (mounted) {
                            Navigator.pop(context); // Fermer le loader
                            Navigator.pop(context); // Fermer le modal
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: const [
                                    Icon(Icons.check_circle, color: Colors.white),
                                    SizedBox(width: 8),
                                    Expanded(child: Text('Demande envoyée avec succès ! 🎉')),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF2E7D32),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            
                            // Navigation vers l'écran de suivi
                            final requestId = created['_id']?.toString();
                            if (requestId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ServiceRequestSummaryScreen(
                                    requestId: requestId,
                                    token: auth.token,
                                  ),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            Navigator.pop(context); // Fermer le loader
                            Navigator.pop(context); // Fermer le modal
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text('Erreur: ${e.toString()}')),
                                  ],
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: const Color(0xFF2E7D32).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.send_rounded, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Envoyer la demande',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

