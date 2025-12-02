import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/mobile/view/loginpagem/screens/loginPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/serviceproviderwelcomepagem/screens/serviceProviderWelcomeScreenM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/detailPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/fullMapScreenM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/categories_list_screen.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/services_list_screen.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/providers_list_screen.dart';
import 'package:sdealsmobile/mobile/view/common/screens/ai_assistant_chat_screen.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/ai_price_estimator_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../services/custom_marker_service.dart';
import '../utils/navigation_helper.dart';

import '../../../../data/models/service.dart';
// import '../../../../data/models/prestataire.dart'; // ✅ Import manquant - supprimé car non utilisé
import '../jobpageblocm/jobPageBlocM.dart';
import '../jobpageblocm/jobPageStateM.dart';
import '../jobpageblocm/jobPageEventM.dart';

class JobPageScreenM extends StatefulWidget {
  final List<dynamic> categories;

  const JobPageScreenM({super.key, this.categories = const []});

  @override
  State<JobPageScreenM> createState() => _JobPageScreenMState();
}

class _JobPageScreenMState extends State<JobPageScreenM> {
  // GoogleMapController? _mapController; // Supprimé car non utilisé
  Set<Marker> _markers = {};
  LatLng? _userLocation;
  double _searchRadius = 5.0;
  String _selectedCategory = '';
  String _selectedService = '';
  bool _showWelcomeBanner = true; // ✅ Contrôle l'affichage du banner

  // Catégories par défaut si pas de données API
  final List<Map<String, dynamic>> defaultCategories = const [
    {'name': 'Auto & Moto', 'icon': Icons.directions_car, 'badge': ''},
    {'name': 'Immobilier', 'icon': Icons.house, 'badge': 'Promo'},
    {'name': 'Électronique', 'icon': Icons.electrical_services, 'badge': ''},
    {'name': 'Mode', 'icon': Icons.style, 'badge': 'Nouveau'},
    {'name': 'Maison', 'icon': Icons.chair, 'badge': ''},
    {'name': 'Sport', 'icon': Icons.sports_soccer, 'badge': 'Top'},
    {'name': 'Jeux', 'icon': Icons.videogame_asset, 'badge': ''},
    {'name': 'Santé', 'icon': Icons.health_and_safety, 'badge': ''},
  ];

  // Quick Actions modernes (remplace les anciennes stories)
  static const List<Map<String, dynamic>> quickActions = [
    {
      "icon": Icons.flash_on,
      "title": "Urgence",
      "subtitle": "24h/24",
      "color": Colors.red,
      "action": "urgent"
    },
    {
      "icon": Icons.star,
      "title": "Top Rated",
      "subtitle": "Les meilleurs",
      "color": Colors.amber,
      "action": "toprated"
    },
    {
      "icon": Icons.location_on,
      "title": "Proche",
      "subtitle": "À proximité",
      "color": Colors.blue,
      "action": "nearby"
    },
    {
      "icon": Icons.savings,
      "title": "Promo",
      "subtitle": "Économisez",
      "color": const Color(0xFF2E7D32),
      "action": "promo"
    },
    {
      "icon": Icons.smart_toy,
      "title": "IA Conseil",
      "subtitle": "Assistant",
      "color": Colors.purple,
      "action": "ai"
    },
  ];

  // Messages promotionnels pour la bannière (supprimé car non utilisé)
  // static const List<String> bannerMessages = [
  //   "✨ Obtenez 10% de réduction sur votre première commande !",
  //   "🎯 Trouvez le prestataire idéal à proximité",
  //   "🛠️ Des services de qualité à portée de main",
  //   "💼 Rejoignez notre communauté de prestataires",
  // ];

  // Données fictives pour les carrousels (à remplacer par API)
  static const List<Map<String, String>> topServices = [
    {
      "image": "assets/categories/Image1.png",
      "title": "Plombier",
      "price": "5000"
    },
    {
      "image": "assets/categories/Image2.png",
      "title": "Coiffeur",
      "price": "3500"
    },
    {
      "image": "assets/categories/Image3.png",
      "title": "Photographe",
      "price": "10000"
    },
    {
      "image": "assets/categories/Image4.png",
      "title": "Nettoyage",
      "price": "2500"
    },
    {
      "image": "assets/categories/Image5.png",
      "title": "Menuiserie",
      "price": "7000"
    },
  ];

  // Données fictives pour les prestataires (supprimé car non utilisé)
  // static const List<Map<String, dynamic>> topPrestataires = [
  //   {
  //     "image": "assets/categories/Image1.png",
  //     "title": "Électricien",
  //     "subtitle": "Disponible 24h/24",
  //     "location": "Abidjan",
  //     "rating": "4.8",
  //     "verified": true,
  //     "online": true
  //   },
  //   // ... autres prestataires
  // ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    // ✅ NOUVEAU : Charger les prestataires par défaut (fallback)
    // Utiliser addPostFrameCallback pour s'assurer que le contexte est prêt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDefaultProviders();
      }
    });
  }

  // ✅ NOUVEAU : Charger les prestataires même sans géolocalisation
  void _loadDefaultProviders() {
    print('📍 Chargement des prestataires par défaut (sans géolocalisation)');
    context.read<JobPageBlocM>().add(const LoadProviderMatchingM(
          serviceType: '',
          location: '',
        ));
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('❌ Permission de localisation refusée - utilisation des prestataires par défaut');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });

      // Charger les prestataires à proximité (remplace les prestataires par défaut)
      if (_userLocation != null) {
        print('📍 Position obtenue - chargement des prestataires à proximité');
        context.read<JobPageBlocM>().add(LoadNearbyProvidersM(
              latitude: _userLocation!.latitude,
              longitude: _userLocation!.longitude,
              radius: _searchRadius,
              category: _selectedCategory.isNotEmpty ? _selectedCategory : null,
              service: _selectedService.isNotEmpty ? _selectedService : null,
            ));
      }
    } catch (e) {
      print('❌ Erreur géolocalisation: $e - utilisation des prestataires par défaut');
    }
  }

  void _updateMapMarkers(List<dynamic> providers) async {
    Set<Marker> markers = {};

    // Marqueur de l'utilisateur avec forme humaine
    if (_userLocation != null) {
      final userIcon = await CustomMarkerService.createUserMarker();
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userLocation!,
          icon: userIcon,
          infoWindow: const InfoWindow(
            title: 'Ma position',
            snippet: 'Vous êtes ici',
          ),
        ),
      );
    }

    // Marqueurs des prestataires avec formes humaines personnalisées
    for (int i = 0; i < providers.length && i < 20; i++) {
      final provider = providers[i];
      // Simulation de position (à remplacer par les vraies coordonnées)
      double lat = _userLocation != null
          ? _userLocation!.latitude + (0.01 * (i - 2))
          : 5.3599; // Abidjan par défaut
      double lng = _userLocation != null
          ? _userLocation!.longitude + (0.01 * (i - 2))
          : -4.0083;

      // Déterminer le type de marqueur selon le service (simplifié)
      // serviceName supprimé car non utilisé

      // Créer le marqueur personnalisé avec couleur intelligente
      final providerIcon = await CustomMarkerService.createSmartProviderMarker(
        name: provider.utilisateur?.fullName ?? 'Prestataire',
        category: provider.service.categorie?.nomcategorie ?? '',
        service: provider.service?.nomservice ?? '',
        isVerified: provider.verifier == true,
        isUrgent:
            false, // Simplification - pas de données de disponibilité dans le modèle
      );

      markers.add(
        Marker(
          markerId: MarkerId('provider_$i'),
          position: LatLng(lat, lng),
          icon: providerIcon,
          infoWindow: InfoWindow(
            title: provider.utilisateur?.fullName ?? 'Prestataire',
            snippet:
                'Note: ${provider.note ?? 'N/A'}/5 • ${provider.service?.nomservice ?? 'Service'}',
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (_) => JobPageBlocM()
          ..add(LoadCategorieDataJobM())
          ..add(LoadServiceDataJobM()),
        child: Scaffold(
          backgroundColor: Colors.white,
          // ✅ CTA Flottant
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              final authState = context.read<AuthCubit>().state;
              if (authState is! AuthAuthenticated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Veuillez vous connecter pour continuer')),
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPageScreenM()),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const ServiceProviderWelcomeScreenM(categories: []),
                ),
              );
            },
            backgroundColor: const Color(0xFF2E7D32), // Vert SoutraLi principal
            icon: const Icon(Icons.handyman, color: Colors.white),
            label: const Text(
              '🔧 Devenir Prestataire',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          // ✅ NOUVEAU : CustomScrollView pour performance optimale
          body: BlocListener<JobPageBlocM, JobPageStateM>(
            listener: (context, state) {
              // Mettre à jour les marqueurs de la carte quand les prestataires changent
              if (state.nearbyProviders.isNotEmpty) {
                _updateMapMarkers(state.nearbyProviders);
              }
            },
            child: CustomScrollView(
              slivers: [
                // AppBar slim moderne
                _buildModernSliverAppBar(),

                // Banner promo sticky (si newbie)
                _buildPromoStickyBanner(context),

                // Chips SoutraPay + IA
                _buildToolChipsSliver(context),

                // Contenu principal
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        
                        // 🎯 SECTION 1 : HERO SEARCH BAR (Nouveau)
                        _buildHeroSearchBar(),
                        const SizedBox(height: 24),
                        
                        // 🚀 SECTION 2 : Quick Actions (optimisé)
                        _buildQuickActionsSection(),
                        const SizedBox(height: 32),
                        
                        // 🎯 SECTION 3 : RECOMMANDATIONS IA (Remonté - prioritaire)
                        _buildPersonalizedRecommendationsSection(),
                        const SizedBox(height: 32),
                        
                        // 🔥 SECTION 4 : PROMOTIONS ACTIVES (Remonté - urgent)
                        _buildActivePromotionsSection(),
                        const SizedBox(height: 32), // Standardisé

                        // 📂 SECTION 5 : TOP CATÉGORIES
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '📂 Catégories',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CategoriesListScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.arrow_forward, size: 14),
                              label: const Text('Tout', style: TextStyle(fontSize: 13)),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF2E7D32),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                minimumSize: const Size(0, 32),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        BlocBuilder<JobPageBlocM, JobPageStateM>(
                          builder: (context, state) {
                            if (state.isLoading) {
                              return _buildSkeletonLoader(height: 120, count: 4);
                            }
                            if (state.error.isNotEmpty) {
                              return _buildErrorCard(state.error);
                            }
                            if (state.listItems.isEmpty) {
                              return _buildEmptyState('Aucune catégorie disponible');
                            }

                            return SizedBox(
                              height: 120,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: state.listItems.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 16),
                                itemBuilder: (context, index) {
                                  final cat = state.listItems[index];
                                  return _buildCategoryCardWithImage(
                                    cat.nomcategorie,
                                    cat.imagecategorie,
                                    _getCategoryIcon(cat.nomcategorie),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        
                        // 🛠️ SECTION 6 : TOP SERVICES
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '🛠️ Services populaires',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ServicesListScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.arrow_forward, size: 14),
                              label: const Text('Tout', style: TextStyle(fontSize: 13)),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF2E7D32),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                minimumSize: const Size(0, 32),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Carrousel Services
                        BlocBuilder<JobPageBlocM, JobPageStateM>(
                          builder: (context, state) {
                            if (state.isLoading2) {
                              return _buildSkeletonLoader(height: 150, count: 3);
                            }
                            if (state.listItems2.isEmpty) {
                              return _buildEmptyState('Aucun service disponible');
                            }

                            return SizedBox(
                              height: 150,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: state.listItems2.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 16),
                                itemBuilder: (context, index) {
                                  final service = state.listItems2[index];
                                  
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DetailPage(
                                            title: service.nomservice,
                                            image: service.imageservice,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 280,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Card(
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        color: const Color(0xFF2E7D32).withOpacity(0.05),
                                        child: Row(
                                          children: [
                                            // Image
                                            ClipRRect(
                                              borderRadius: const BorderRadius.horizontal(
                                                left: Radius.circular(16),
                                              ),
                                              child: service.imageservice.isNotEmpty
                                                  ? Image.network(
                                                      service.imageservice,
                                                      width: 110,
                                                      height: 150,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) =>
                                                          Container(
                                                            width: 110,
                                                            height: 150,
                                                            color: const Color(0xFF2E7D32).withOpacity(0.1),
                                                            child: const Icon(
                                                              Icons.image,
                                                              size: 40,
                                                              color: const Color(0xFF2E7D32),
                                                            ),
                                                          ),
                                                    )
                                                  : Container(
                                                      width: 110,
                                                      height: 150,
                                                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                                                      child: const Icon(
                                                        Icons.handyman,
                                                        size: 40,
                                                        color: const Color(0xFF2E7D32),
                                                      ),
                                                    ),
                                            ),
                                            // Contenu
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.all(10),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      service.nomservice,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                        color: Colors.black87,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    if (service.categorie?.nomcategorie != null)
                                                      Text(
                                                        service.categorie!.nomcategorie,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    const Spacer(),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            '${service.prixmoyen} FCFA/h',
                                                            style: const TextStyle(
                                                              color: const Color(0xFF2E7D32),
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF2E7D32),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: const Icon(
                                                            Icons.arrow_forward,
                                                            color: Colors.white,
                                                            size: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        // ⭐ SECTION 7 : TOP PRESTATAIRES
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '⭐ Prestataires',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProvidersListScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.arrow_forward, size: 14),
                              label: const Text('Tout', style: TextStyle(fontSize: 13)),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF2E7D32),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                minimumSize: const Size(0, 32),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Carrousel Top Prestataires (vraies données)
                        BlocBuilder<JobPageBlocM, JobPageStateM>(
                          builder: (context, state) {
                            // ✅ AMÉLIORÉ : Utiliser nearbyProviders si disponible, sinon matchedProviders
                            List<dynamic> topPrestatairesReal;
                            
                            if (state.nearbyProviders.isNotEmpty) {
                              // Prestataires à proximité (avec géolocalisation)
                              topPrestatairesReal = state.nearbyProviders.take(5).toList();
                              print('✅ Affichage de ${topPrestatairesReal.length} prestataires à proximité');
                            } else if (state.matchedProviders.isNotEmpty) {
                              // Prestataires par défaut (sans géolocalisation)
                              topPrestatairesReal = state.matchedProviders.take(5).toList();
                              print('✅ Affichage de ${topPrestatairesReal.length} prestataires par défaut');
                            } else {
                              // Aucun prestataire
                              topPrestatairesReal = [];
                            }

                          if (topPrestatairesReal.isEmpty) {
                            // Afficher un loader si en cours de chargement
                            if (state.isNearbyLoading || state.isMatchingLoading) {
                              return SizedBox(
                                height: 150,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      CircularProgressIndicator(color: Color(0xFF2E7D32)),
                                      SizedBox(height: 8),
                                      Text('Chargement des prestataires...'),
                                    ],
                                  ),
                                ),
                              );
                            }
                            
                            return const SizedBox(
                              height: 150,
                              child: Center(
                                child: Text('Aucun prestataire trouvé',
                                    style: TextStyle(color: Colors.grey)),
                              ),
                            );
                          }

                          return CarouselSlider.builder(
                            itemCount: topPrestatairesReal.length,
                            options: CarouselOptions(
                              height: 150.0, // Réduit de 170 à 150 pour meilleur UX
                              autoPlay: true,
                              autoPlayInterval: const Duration(seconds: 5), // Plus lent
                              enlargeCenterPage: true,
                              viewportFraction: 0.88, // Montre plus de contexte
                            ),
                            itemBuilder: (context, index, realIndex) {
                              final prestataire = topPrestatairesReal[index];
                              // Extraire les données du prestataire réel
                              String providerName = 'Prestataire';
                              String serviceName = 'Service';
                              String location = 'Localisation';
                              String rating = 'N/A';
                              bool isVerified = false;
                              String imageUrl = '';

                              // Extraction sécurisée des données depuis objet Prestataire
                              try {
                                // Les données viennent maintenant sous forme d'objets Prestataire convertis
                                providerName = prestataire.utilisateur.fullName;
                                if (providerName.isEmpty)
                                  providerName = 'Prestataire';
                                imageUrl =
                                    prestataire.utilisateur.photoProfil ?? '';
                                serviceName = prestataire.service.nomservice;
                                location = prestataire.localisation;
                                rating = prestataire.note ?? 'N/A';
                                isVerified = prestataire.verifier;
                              } catch (e) {
                                print(
                                    'Erreur extraction données prestataire: $e');
                              }

                              return GestureDetector(
                                onTap: () {
                                  // ✅ Navigation vers le profil complet du prestataire
                                  NavigationHelper.navigateToProviderProfile(
                                    context,
                                    providerId: prestataire.idprestataire,
                                    providerData: prestataire.toJson(),
                                  );
                                },
                                child: Card(
                                  elevation: 4, // Standardisé
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        16), // Standardisé
                                  ),
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        // Image du prestataire
                                        Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(14.0),
                                              child: imageUrl.isNotEmpty
                                                  ? Image.network(
                                                      imageUrl,
                                                      fit: BoxFit.cover,
                                                      width: 90,
                                                      height: 130,
                                                      errorBuilder: (context,
                                                              error,
                                                              stackTrace) =>
                                                          Image.asset(
                                                        'assets/profil.png',
                                                        fit: BoxFit.cover,
                                                        width: 90,
                                                        height: 130,
                                                      ),
                                                    )
                                                  : Image.asset(
                                                      'assets/profil.png',
                                                      fit: BoxFit.cover,
                                                      width: 90,
                                                      height: 130,
                                                    ),
                                            ),
                                            // Indicateur vérification
                                            if (isVerified)
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(2),
                                                  decoration:
                                                      const BoxDecoration(
                                                    color:
                                                        const Color(0xFF2E7D32),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.verified,
                                                    color: Colors.white,
                                                    size: 12,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 16),
                                        // Infos du prestataire
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      providerName,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15.0,
                                                        color: Colors.black87,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                serviceName,
                                                style: const TextStyle(
                                                  fontSize: 12.0,
                                                  color: Colors.black54,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  const Icon(Icons.location_on,
                                                      size: 14,
                                                      color: Colors.green),
                                                  const SizedBox(width: 3),
                                                  Expanded(
                                                    flex: 3,
                                                    child: Text(
                                                      location,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: const Color(
                                                            0xFF2E7D32),
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Icon(Icons.star,
                                                      size: 14,
                                                      color: Colors.amber),
                                                  const SizedBox(width: 2),
                                                  Flexible(
                                                    flex: 1,
                                                    child: Text(
                                                      rating,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.amber,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              SizedBox(
                                                height: 28,
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    // Action contacter
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFF2E7D32),
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              14),
                                                    ),
                                                  ),
                                                  child: const Text('Contacter',
                                                      style: TextStyle(
                                                          fontSize: 11)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                        const SizedBox(height: 32),
                        
                        // 📍 SECTION 8 : AUTOUR DE MOI (Carte interactive + liste)
                        _buildAroundMeSection(),
                        
                        const SizedBox(height: 60), // Espacement final pour FAB
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  // ✅ NOUVEAU : AppBar slim moderne avec Sliver
  Widget _buildModernSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 60,
      floating: true,
      pinned: false,
      snap: true,
      backgroundColor: const Color(0xFF2E7D32),
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF2E7D32), const Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Métiers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.search, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ NOUVEAU : Banner promo sticky pour newbies
  Widget _buildPromoStickyBanner(BuildContext context) {
    // Si le banner est masqué, retourner un widget vide
    if (!_showWelcomeBanner) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // Affichage du banner promo pour tous les utilisateurs (peut être conditionné plus tard)
    return SliverPersistentHeader(
      pinned: true,
      delegate: _PromoStickyDelegate(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF2E7D32)
                    .withOpacity(0.1), // Vert Soutrali transparent
                const Color(0xFF2E7D32).withOpacity(0.15),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border(
              bottom: BorderSide(
                  color: const Color(0xFF2E7D32).withOpacity(0.3), width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.verified_user,
                    color: const Color(0xFF2E7D32), size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '✨ Bienvenue ! Découvre nos prestataires vérifiés',
                  style: TextStyle(
                    color: const Color(0xFF2E7D32).withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showWelcomeBanner = false;
                    });
                  },
                  child: Icon(
                    Icons.close,
                    color: const Color(0xFF2E7D32),
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NOUVEAU : Chips horizontales SoutraPay + IA
  Widget _buildToolChipsSliver(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Chip SoutraPay
            InkWell(
              onTap: () => Navigator.pushNamed(context, '/wallet'),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.1),
                      Colors.green.withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.green.withOpacity(0.4), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet,
                        color: const Color(0xFF2E7D32), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '💳 SoutraPay',
                      style: TextStyle(
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Chip IA Assistant
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AIAssistantChatScreen()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade300, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.smart_toy,
                        color: Colors.blue.shade700, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '🤖 IA Assistant',
                      style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
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

  // ✅ NOUVEAU : Section Quick Actions modernes
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Actions rapides',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () {
                // TODO: Navigation vers la page complète des actions rapides
              },
              child: const Text(
                'Voir tout',
                style: TextStyle(
                  color: const Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 95, // Augmenté de 90 à 95 pour éviter l'overflow
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: quickActions.length,
            itemBuilder: (context, index) {
              final action = quickActions[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16), // Standardisé
                child: _buildQuickActionCard(
                  icon: action['icon'],
                  title: action['title'],
                  subtitle: action['subtitle'],
                  color: action['color'],
                  onTap: () => _handleQuickAction(action['action']),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ✅ NOUVEAU : Carte d'action rapide moderne
  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NOUVEAU : Gestionnaire des actions rapides
  void _handleQuickAction(String action) {
    switch (action) {
      case 'urgent':
        // Charger les prestataires d'urgence
        if (_userLocation != null) {
          context.read<JobPageBlocM>().add(LoadUrgentProvidersM(
                latitude: _userLocation!.latitude,
                longitude: _userLocation!.longitude,
                radius: 10.0,
              ));
        }
        break;
      case 'toprated':
        // Charger les prestataires les mieux notés
        if (_userLocation != null) {
          context.read<JobPageBlocM>().add(LoadNearbyProvidersM(
                latitude: _userLocation!.latitude,
                longitude: _userLocation!.longitude,
                radius: _searchRadius,
              ));
        }
        break;
      case 'nearby':
        // Afficher la section "Autour de moi"
        _showAroundMeSection();
        break;
      case 'promo':
        // TODO: Afficher promotions actives
        print('💰 Affichage promotions');
        break;
      case 'ai':
        // TODO: Ouvrir assistant IA
        print('🤖 Ouverture assistant IA');
        break;
    }
  }

  // 🎯 NOUVEAU : Hero Search Bar
  Widget _buildHeroSearchBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2E7D32),
            const Color(0xFF4CAF50),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👋 Bonjour !',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'De quoi avez-vous besoin ?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un service, prestataire...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.tune, color: Colors.white, size: 20),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onTap: () {
                // TODO: Navigation vers page de recherche
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonction de recherche bientôt disponible'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Stats rapides
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  icon: Icons.person,
                  label: '${_markers.length} prestataires',
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatChip(
                  icon: Icons.location_on,
                  label: 'À proximité',
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // 📦 NOUVEAU : Skeleton Loader
  Widget _buildSkeletonLoader({required double height, int count = 3}) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, __) => Container(
          width: 160,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: CircularProgressIndicator(
              color: const Color(0xFF2E7D32),
              strokeWidth: 2,
            ),
          ),
        ),
      ),
    );
  }

  // ⚠️ NOUVEAU : Error Card
  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  // 🔍 NOUVEAU : Empty State
  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ✅ NOUVEAU : Afficher la section "Autour de moi"
  void _showAroundMeSection() {
    // Scroll vers la section "Autour de moi"
    // Cette fonctionnalité sera implémentée avec ScrollController
  }

  // ✅ NOUVEAU : Section "Autour de moi" avec carte et prestataires
  Widget _buildAroundMeSection() {
    return BlocBuilder<JobPageBlocM, JobPageStateM>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre de la section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📍 Autour de moi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18, // Standardisé
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                // Contrôles sur une ligne séparée
                Row(
                  children: [
                    // Slider de rayon plus compact
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          const Icon(Icons.radio_button_unchecked, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Slider(
                              value: _searchRadius,
                              min: 1.0,
                              max: 20.0,
                              divisions: 19,
                              activeColor: Colors.green,
                              onChanged: (value) {
                                setState(() {
                                  _searchRadius = value;
                                });
                                if (_userLocation != null) {
                                  context
                                      .read<JobPageBlocM>()
                                      .add(LoadNearbyProvidersM(
                                        latitude: _userLocation!.latitude,
                                        longitude: _userLocation!.longitude,
                                        radius: _searchRadius,
                                        category: _selectedCategory.isNotEmpty
                                            ? _selectedCategory
                                            : null,
                                        service: _selectedService.isNotEmpty
                                            ? _selectedService
                                            : null,
                                      ));
                                }
                              },
                            ),
                          ),
                          Text('${_searchRadius.toInt()}km',
                              style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                    // Boutons plus compacts
                    IconButton(
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        if (_userLocation != null) {
                          context.read<JobPageBlocM>().add(LoadNearbyProvidersM(
                                latitude: _userLocation!.latitude,
                                longitude: _userLocation!.longitude,
                                radius: _searchRadius,
                                category: _selectedCategory.isNotEmpty
                                    ? _selectedCategory
                                    : null,
                                service: _selectedService.isNotEmpty
                                    ? _selectedService
                                    : null,
                              ));
                        }
                      },
                      icon: const Icon(Icons.refresh,
                          color: Colors.green, size: 20),
                    ),
                    IconButton(
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        if (_userLocation != null) {
                          print(
                              '🗺️ Navigation vers FullMap avec ${state.nearbyProviders.length} prestataires');
                          print(
                              '🗺️ Type des nearbyProviders: ${state.nearbyProviders.map((p) => p.runtimeType).toList()}');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullMapScreenM(
                                initialPosition: _userLocation,
                                providers: state.nearbyProviders,
                                searchRadius: _searchRadius,
                                selectedCategory: _selectedCategory,
                                selectedService: _selectedService,
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.zoom_out_map,
                          color: Colors.blue, size: 20),
                      tooltip: 'Voir carte complète',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Carte Google Maps
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _userLocation != null
                    ? Builder(
                        builder: (context) {
                          // Désactiver Google Maps sur le Web pour éviter l'erreur
                          if (kIsWeb) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.map,
                                        size: 48, color: Colors.green),
                                    SizedBox(height: 8),
                                    Text('Carte disponible sur mobile',
                                        style: TextStyle(
                                          color: const Color(0xFF2E7D32),
                                          fontWeight: FontWeight.bold,
                                        )),
                                    SizedBox(height: 4),
                                    Text(
                                        'Utilisez l\'application mobile pour voir la carte',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        )),
                                  ],
                                ),
                              ),
                            );
                          }

                          try {
                            return GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _userLocation!,
                                zoom: 13.0,
                              ),
                              markers: _markers,
                              onMapCreated: (GoogleMapController controller) {
                                // _mapController supprimé car non utilisé
                              },
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                            );
                          } catch (e) {
                            print('Erreur Google Maps: $e');
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 48, color: Colors.red),
                                  SizedBox(height: 8),
                                  Text('Erreur de chargement de la carte',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            );
                          }
                        },
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_off,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Position non disponible',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Filtres de catégorie et service
            _buildFiltersRow(state),
            const SizedBox(height: 16),

            // Compteur de prestataires trouvés
            if (state.nearbyProviders.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${state.nearbyProviders.length} prestataire(s) trouvé(s)',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedCategory.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _selectedCategory,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Liste des prestataires à proximité
            if (state.isNearbyLoading)
              const Center(
                  child: CircularProgressIndicator(color: Colors.green))
            else if (state.nearbyError.isNotEmpty)
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 8),
                    Text('Erreur: ${state.nearbyError}',
                        style: const TextStyle(color: Colors.red)),
                  ],
                ),
              )
            else if (state.nearbyProviders.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.location_searching,
                        size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Aucun prestataire à proximité',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else
              _buildNearbyProvidersList(state.nearbyProviders),
          ],
        );
      },
    );
  }

  // ✅ NOUVEAU : Filtres de catégorie et service
  Widget _buildFiltersRow(JobPageStateM state) {
    return Column(
      children: [
        // Filtres en colonne pour éviter l'overflow
        Row(
          children: [
            // Filtre par catégorie
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _selectedCategory.isEmpty ? null : _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  isDense: true,
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(
                      value: '', child: Text('Toutes les catégories')),
                  ...state.listItems.map((category) => DropdownMenuItem(
                        value: category.nomcategorie,
                        child: Text(
                          category.nomcategorie,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? '';
                  });
                  if (_userLocation != null) {
                    context.read<JobPageBlocM>().add(LoadNearbyProvidersM(
                          latitude: _userLocation!.latitude,
                          longitude: _userLocation!.longitude,
                          radius: _searchRadius,
                          category: _selectedCategory.isNotEmpty
                              ? _selectedCategory
                              : null,
                          service: _selectedService.isNotEmpty
                              ? _selectedService
                              : null,
                        ));
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            // Filtre par service
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _selectedService.isEmpty ? null : _selectedService,
                decoration: const InputDecoration(
                  labelText: 'Service',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  isDense: true,
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(
                      value: '', child: Text('Tous les services')),
                  ...state.listItems2.map((service) => DropdownMenuItem(
                        value: service.nomservice,
                        child: Text(
                          service.nomservice,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedService = value ?? '';
                  });
                  if (_userLocation != null) {
                    context.read<JobPageBlocM>().add(LoadNearbyProvidersM(
                          latitude: _userLocation!.latitude,
                          longitude: _userLocation!.longitude,
                          radius: _searchRadius,
                          category: _selectedCategory.isNotEmpty
                              ? _selectedCategory
                              : null,
                          service: _selectedService.isNotEmpty
                              ? _selectedService
                              : null,
                        ));
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ✅ NOUVEAU : Liste des prestataires à proximité
  Widget _buildNearbyProvidersList(List<dynamic> providers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prestataires à proximité (${providers.length})',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              return _buildNearbyProviderCard(provider, index);
            },
          ),
        ),
      ],
    );
  }

  // ✅ NOUVEAU : Carte de prestataire à proximité
  Widget _buildNearbyProviderCard(dynamic provider, int index) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 4, // Standardisé
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)), // Standardisé
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // ✅ Navigation vers le profil complet du prestataire
            NavigationHelper.navigateToProviderProfile(
              context,
              providerId: provider.idprestataire,
              providerData: provider.toJson(),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec avatar et statut
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage(
                          'assets/categories/Image${(index % 5) + 1}.png'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.utilisateur?.fullName ?? 'Prestataire',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            provider.service?.nomservice ?? 'Service',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (provider.verifier)
                      const Icon(Icons.verified, color: Colors.green, size: 16),
                  ],
                ),
                const SizedBox(height: 8),

                // Note et distance
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 3),
                    Flexible(
                      flex: 2,
                      child: Text(
                        provider.note ?? 'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.location_on,
                        color: const Color(0xFF2E7D32), size: 14),
                    const SizedBox(width: 3),
                    Flexible(
                      flex: 3,
                      child: Text(
                        '${(index + 1) * 0.5} km',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  provider.description ?? 'Prestataire professionnel',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Bouton d'action
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Action contacter
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        const Text('Contacter', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Méthode pour attribuer une icône selon le nom de la catégorie
  IconData _getCategoryIcon(String name) {
    // Par défaut
    IconData icon = Icons.category;

    final lowerName = name.toLowerCase();

    if (lowerName.contains('auto') || lowerName.contains('moto')) {
      return Icons.directions_car;
    } else if (lowerName.contains('immobilier') ||
        lowerName.contains('maison')) {
      return Icons.house;
    } else if (lowerName.contains('électronique') ||
        lowerName.contains('electronique')) {
      return Icons.devices;
    } else if (lowerName.contains('tech')) {
      return Icons.electrical_services;
    } else if (lowerName.contains('mode') || lowerName.contains('vêtement')) {
      return Icons.style;
    } else if (lowerName.contains('meuble')) {
      return Icons.chair;
    } else if (lowerName.contains('sport')) {
      return Icons.sports_soccer;
    } else if (lowerName.contains('jeu')) {
      return Icons.videogame_asset;
    } else if (lowerName.contains('santé') || lowerName.contains('sante')) {
      return Icons.health_and_safety;
    } else if (lowerName.contains('coiff') || lowerName.contains('beauté')) {
      return Icons.face;
    } else if (lowerName.contains('plomb') || lowerName.contains('eau')) {
      return Icons.plumbing;
    } else if (lowerName.contains('électricité') ||
        lowerName.contains('electricité')) {
      return Icons.electrical_services;
    } else if (lowerName.contains('livraison') ||
        lowerName.contains('transport')) {
      return Icons.delivery_dining;
    } else if (lowerName.contains('menuis') || lowerName.contains('bois')) {
      return Icons.carpenter;
    }

    return icon;
  }

  // Section À la une cette semaine
  Widget _buildFeaturedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.star_border, color: Colors.amber),
                SizedBox(width: 6),
                Text(
                  'À la une cette semaine',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18, // Standardisé
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                // TODO: Navigation vers la page complète des featured
              },
              child: const Text(
                'Voir plus',
                style: TextStyle(
                  color: const Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            image: const DecorationImage(
              image: AssetImage('assets/categories/Image3.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'POPULAIRE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Amadou K. - Plombier Professionnel',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '15 ans d\'expérience - Disponible 24/7',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ Carte Catégorie avec Image API
  Widget _buildCategoryCardWithImage(
      String name, String? imageUrl, IconData fallbackIcon) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipOval(
              child: Image.network(
                imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(fallbackIcon, color: Colors.green, size: 32),
              ),
            )
          else
            Icon(fallbackIcon, color: Colors.green, size: 40),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 🥇 PRIORITÉ 1 : Section Promotions actives
  Widget _buildActivePromotionsSection() {
    // Données simulées des promotions (à remplacer par API)
    final List<Map<String, dynamic>> activePromotions = [
      {
        'title': '🎉 Première commande',
        'discount': '20%',
        'description': 'Économisez sur votre premier service',
        'code': 'FIRST20',
        'expiry': '31 Dec 2024',
        'color': Colors.red,
        'services': ['Ménage', 'Plomberie', 'Électricité']
      },
      {
        'title': '⚡ Service Express',
        'discount': '15%',
        'description': 'Réduction sur interventions urgentes',
        'code': 'EXPRESS15',
        'expiry': '15 Jan 2025',
        'color': Colors.orange,
        'services': ['Urgence', 'Dépannage']
      },
      {
        'title': '🏠 Pack Maison',
        'discount': '25%',
        'description': 'Combiné ménage + jardinage',
        'code': 'PACK25',
        'expiry': '28 Feb 2025',
        'color': Colors.green,
        'services': ['Ménage', 'Jardinage', 'Rénovation']
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Supprime spaceBetween
            const Expanded(
              // Wrap avec Expanded
              child: Row(
                children: [
                  Icon(Icons.local_offer,
                      color: Colors.red, size: 22), // Réduit de 24 à 22
                  SizedBox(width: 6), // Réduit de 8 à 6
                  Flexible(
                    // Wrap text avec Flexible
                    child: Text(
                      '🎁 Promotions du moment',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18, // Réduit de 20 à 18
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigation vers la page complète des promotions
              },
              child: const Text(
                'Voir toutes',
                style: TextStyle(
                  color: const Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180, // Augmenté de 160 à 180
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: activePromotions.length,
            itemBuilder: (context, index) {
              final promo = activePromotions[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                child: Card(
                  elevation: 4, // Standardisé
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // Standardisé
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          promo['color'].withOpacity(0.1),
                          promo['color'].withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                promo['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: promo['color'],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                promo['discount'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          promo['description'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.code, size: 14, color: promo['color']),
                            const SizedBox(width: 4),
                            Text(
                              promo['code'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: promo['color'],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Expire le ${promo['expiry']}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () {
                                  // TODO: Appliquer la promotion
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Code ${promo['code']} copié !'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: promo['color'],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  minimumSize: const Size(0, 24),
                                ),
                                child: const Text(
                                  'Utiliser',
                                  style: TextStyle(fontSize: 9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 🥈 PRIORITÉ 2 : Témoignages clients
  Widget _buildRecentReviewsSection() {
    // Données simulées des témoignages (à remplacer par API)
    final List<Map<String, dynamic>> reviews = [
      {
        'name': 'Marie K.',
        'service': 'Ménage à domicile',
        'rating': 5,
        'comment':
            'Service exceptionnel ! Très professionnel et ponctuel. Je recommande vivement.',
        'date': '3 jours',
        'avatar':
            'https://images.unsplash.com/photo-1494790108755-2616b612727a?w=150',
        'provider': 'Fatou Diallo'
      },
      {
        'name': 'Jean-Claude D.',
        'service': 'Plomberie',
        'rating': 5,
        'comment':
            'Problème résolu rapidement. Prix honnête et travail de qualité.',
        'date': '1 semaine',
        'avatar':
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
        'provider': 'Moussa Traoré'
      },
      {
        'name': 'Aicha B.',
        'service': 'Coiffure à domicile',
        'rating': 4,
        'comment':
            'Très satisfaite du résultat. Coiffeuse très à l\'écoute de mes souhaits.',
        'date': '2 semaines',
        'avatar':
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
        'provider': 'Aminata Keita'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Supprime spaceBetween
            const Expanded(
              // Wrap avec Expanded
              child: Row(
                children: [
                  Icon(Icons.star,
                      color: Colors.amber, size: 22), // Réduit de 24 à 22
                  SizedBox(width: 6), // Réduit de 8 à 6
                  Flexible(
                    // Wrap text avec Flexible
                    child: Text(
                      '💬 Ils nous font confiance',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18, // Réduit de 20 à 18
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigation vers la page complète des témoignages
              },
              child: const Text(
                'Voir tous',
                style: TextStyle(
                  color: const Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Container(
                width: 280, // Réduit de 300 à 280
                margin: const EdgeInsets.only(right: 12), // Réduit de 16 à 12
                child: Card(
                  elevation: 4, // Standardisé
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // Standardisé
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: NetworkImage(review['avatar']),
                              onBackgroundImageError: (_, __) {},
                              child: review['avatar'] == null
                                  ? const Icon(Icons.person, size: 18)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    review['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    review['service'],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (starIndex) {
                                return Icon(
                                  starIndex < review['rating']
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 14,
                                );
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Flexible(
                          child: Text(
                            review['comment'],
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black87,
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Par ${review['provider']}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: const Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              review['date'],
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 🥉 PRIORITÉ 3 : Recommandations personnalisées
  Widget _buildPersonalizedRecommendationsSection() {
    return BlocBuilder<JobPageBlocM, JobPageStateM>(
      builder: (context, state) {
        // Données simulées des recommandations (à remplacer par vraie IA)
        final List<Map<String, dynamic>> recommendations = [
          {
            'title': 'Ménage hebdomadaire',
            'reason': 'Basé sur vos recherches récentes',
            'provider': 'Aminata Services',
            'rating': 4.8,
            'price': '15 000 FCFA',
            'image': null, // Utilise l'icône par défaut au lieu d'URL cassée
            'category': 'Ménage',
            'discount': '10%',
            'urgent': false,
            'icon': Icons.cleaning_services,
          },
          {
            'title': 'Réparation électrique',
            'reason': 'Prestataires populaires près de chez vous',
            'provider': 'Électro Pro',
            'rating': 4.9,
            'price': '25 000 FCFA',
            'image': null, // Utilise l'icône par défaut au lieu d'URL cassée
            'category': 'Électricité',
            'discount': null,
            'urgent': true,
            'icon': Icons.electrical_services,
          },
          {
            'title': 'Jardinage & Taille',
            'reason': 'Saison recommandée pour vos plantes',
            'provider': 'Vert Jardin',
            'rating': 4.7,
            'price': '20 000 FCFA',
            'image': null, // Utilise l'icône par défaut au lieu d'URL cassée
            'category': 'Jardinage',
            'discount': '15%',
            'urgent': false,
            'icon': Icons.local_florist,
          },
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Supprime spaceBetween
                const Expanded(
                  // Wrap avec Expanded
                  child: Row(
                    children: [
                      Icon(Icons.recommend,
                          color: Colors.blue, size: 22), // Réduit de 24 à 22
                      SizedBox(width: 6), // Réduit de 8 à 6
                      Flexible(
                        // Wrap text avec Flexible
                        child: Text(
                          '🎯 Recommandé pour vous',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18, // Réduit de 20 à 18
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigation vers la page complète des recommandations
                  },
                  child: const Text(
                    'Tout voir',
                    style: TextStyle(
                      color: const Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220, // Optimisé pour meilleur UX
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recommendations.length,
                itemBuilder: (context, index) {
                  final rec = recommendations[index];
                  return Container(
                    width: 300, // Réduit de 320 à 300
                    margin:
                        const EdgeInsets.only(right: 12), // Réduit de 16 à 12
                    child: Card(
                      elevation: 4, // Standardisé
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), // Standardisé
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // Évite l'overflow
                        children: [
                          // Header avec image et badges
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: Container(
                                  height: 100,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(0xFF2E7D32).withOpacity(0.1),
                                        const Color(0xFF2E7D32).withOpacity(0.05),
                                      ],
                                    ),
                                  ),
                                  child: rec['image'] != null && rec['image'].toString().isNotEmpty
                                      ? Image.network(
                                          rec['image'],
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                                strokeWidth: 2,
                                                color: const Color(0xFF2E7D32),
                                              ),
                                            );
                                          },
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Icon(
                                              rec['icon'] ?? Icons.home_repair_service,
                                              size: 50,
                                              color: const Color(0xFF2E7D32),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Icon(
                                            rec['icon'] ?? Icons.handyman,
                                            size: 50,
                                            color: const Color(0xFF2E7D32),
                                          ),
                                        ),
                                ),
                              ),
                              // Badges
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Row(
                                  children: [
                                    if (rec['urgent'] == true)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'URGENT',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 4),
                                    if (rec['discount'] != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2E7D32),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '-${rec['discount']}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Contenu
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    rec['title'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    rec['reason'],
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.blue,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          rec['provider'],
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        rec['rating'].toString(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          rec['price'],
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF2E7D32),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        flex: 2,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            // TODO: Navigation vers les détails du service
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF2E7D32),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            minimumSize: const Size(0, 24),
                                          ),
                                          child: const Text(
                                            'Voir',
                                            style: TextStyle(fontSize: 9),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ✅ NOUVEAU : Delegate pour banner sticky
class _PromoStickyDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _PromoStickyDelegate({required this.child});

  @override
  double get minExtent => 45.0;

  @override
  double get maxExtent => 45.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_PromoStickyDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
