import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/screens/searchPageScreenM.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/mobile/view/loginpagem/screens/loginPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/serviceproviderwelcomepagem/screens/serviceProviderWelcomeScreenM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/detailPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/fullMapScreenM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/categories_list_screen.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/services_list_screen.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/providers_list_screen.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/ai_price_estimator_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../services/custom_marker_service.dart';
import '../utils/navigation_helper.dart';
import '../../common/widgets/app_image.dart';

import '../../../../data/models/service.dart';
// import '../../../../data/models/prestataire.dart'; // ✅ Import manquant - supprimé car non utilisé
import '../jobpageblocm/jobPageBlocM.dart';
import '../jobpageblocm/jobPageStateM.dart';
import '../jobpageblocm/jobPageEventM.dart';

// Design System
import '../../../../design_system/colors.dart';
import '../../../../design_system/typography.dart';
import '../../../../design_system/spacing.dart';

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
      "color": SDColors.error500,
      "action": "urgent"
    },
    {
      "icon": Icons.star,
      "title": "Top Rated",
      "subtitle": "Les meilleurs",
      "color": SDColors.warning500,
      "action": "toprated"
    },
    {
      "icon": Icons.location_on,
      "title": "Proche",
      "subtitle": "À proximité",
      "color": SDColors.info500,
      "action": "nearby"
    },
    {
      "icon": Icons.savings,
      "title": "Promo",
      "subtitle": "Économisez",
      "color": SDColors.primary600,
      "action": "promo"
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
          backgroundColor: SDColors.white,
          floatingActionButton: FloatingActionButton(
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
            backgroundColor: SDColors.primary600,
            child: const Icon(Icons.handyman, color: SDColors.white),
            tooltip: 'Devenir Prestataire',
          ),
          body: BlocListener<JobPageBlocM, JobPageStateM>(
            listener: (context, state) {
              if (state.nearbyProviders.isNotEmpty) {
                _updateMapMarkers(state.nearbyProviders);
              }
            },
            child: CustomScrollView(
              slivers: [
                // Banner promo sticky (si newbie)
                _buildPromoStickyBanner(context),

                // Bannière (remplace SoutraPay + IA)
                _buildHomeBannerSliver(context),

                // Contenu principal
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: SDSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: SDSpacing.lg),
                        
                        // 🎯 SECTION 1 : HERO SEARCH BAR
                        _buildHeroSearchBar(),
                        SizedBox(height: SDSpacing.md),

                        // Catégories (en avant)
                        Row(
                          children: [
                            Icon(Icons.category, color: SDColors.primary600, size: 22),
                            SizedBox(width: SDSpacing.xs),
                            Expanded(
                              child: Text(
                                'Catégories',
                                style: SDTypography.titleLarge.copyWith(color: SDColors.neutral900),
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
                              label: Text('Tout', style: SDTypography.labelSmall),
                              style: TextButton.styleFrom(
                                foregroundColor: SDColors.primary600,
                                padding: SDSpacing.chipPadding,
                                minimumSize: const Size(0, 32),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: SDSpacing.sm),
                        
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
                                separatorBuilder: (_, __) => SizedBox(width: SDSpacing.sm),
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
                        SizedBox(height: SDSpacing.lg),
                        
                        // Services populaires
                        Row(
                          children: [
                            Icon(Icons.build, color: SDColors.primary600, size: 22),
                            SizedBox(width: SDSpacing.xs),
                            Expanded(
                              child: Text(
                                'Services populaires',
                                style: SDTypography.titleLarge.copyWith(color: SDColors.neutral900),
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
                              label: Text('Tout', style: SDTypography.labelSmall),
                              style: TextButton.styleFrom(
                                foregroundColor: SDColors.primary600,
                                padding: SDSpacing.chipPadding,
                                minimumSize: const Size(0, 32),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: SDSpacing.sm),
                        
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
                                separatorBuilder: (_, __) => SizedBox(width: SDSpacing.sm),
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
                                                  ? AppImage(
                                                      imageUrl: service.imageservice,
                                                      width: 110,
                                                      height: 150,
                                                      fit: BoxFit.cover,
                                                      placeholderAsset: 'assets/products/default.png',
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
                                                padding: SDSpacing.cardPadding,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      service.nomservice,
                                                      style: SDTypography.titleSmall.copyWith(
                                                        color: SDColors.neutral900,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    SizedBox(height: SDSpacing.xxxs),
                                                    if (service.categorie?.nomcategorie != null)
                                                      Text(
                                                        service.categorie!.nomcategorie,
                                                        style: SDTypography.bodySmall.copyWith(
                                                          color: SDColors.neutral500,
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
                                                            style: SDTypography.labelMedium.copyWith(
                                                              color: SDColors.primary600,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        Container(
                                                          padding: EdgeInsets.symmetric(
                                                            horizontal: SDSpacing.xxxs,
                                                            vertical: SDSpacing.xxxs,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: SDColors.primary600,
                                                            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                                                          ),
                                                          child: Icon(
                                                            Icons.arrow_forward,
                                                            color: SDColors.white,
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
                        SizedBox(height: SDSpacing.lg),

                        // Prestataires
                        Row(
                          children: [
                            Icon(Icons.people, color: SDColors.primary600, size: 22),
                            SizedBox(width: SDSpacing.xs),
                            Expanded(
                              child: Text(
                                'Prestataires',
                                style: SDTypography.titleLarge.copyWith(color: SDColors.neutral900),
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
                              label: Text('Tout', style: SDTypography.labelSmall),
                              style: TextButton.styleFrom(
                                foregroundColor: SDColors.primary600,
                                padding: SDSpacing.chipPadding,
                                minimumSize: const Size(0, 32),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: SDSpacing.sm),

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
                            
                            return SizedBox(
                              height: 150,
                              child: Center(
                                child: Text('Aucun prestataire trouvé',
                                    style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral500)),
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
                                    padding: SDSpacing.cardPadding,
                                    child: Row(
                                      children: [
                                        // Image du prestataire
                                        Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(14.0),
                                              child: imageUrl.isNotEmpty
                                                  ? AppImage(
                                                      imageUrl: imageUrl,
                                                      fit: BoxFit.cover,
                                                      width: 90,
                                                      height: 130,
                                                      placeholderAsset: 'assets/profil.png',
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
                                                      EdgeInsets.all(SDSpacing.xxxs),
                                                  decoration:
                                                      BoxDecoration(
                                                    color:
                                                        SDColors.primary600,
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
                                        SizedBox(width: SDSpacing.sm),
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
                                                      style: SDTypography.titleSmall.copyWith(
                                                        color: SDColors.neutral900,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: SDSpacing.xxxs),
                                              Text(
                                                serviceName,
                                                style: SDTypography.bodySmall.copyWith(
                                                  color: SDColors.neutral600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: SDSpacing.xxs),
                                              Row(
                                                children: [
                                                  Icon(Icons.location_on,
                                                      size: 14,
                                                      color: SDColors.primary600),
                                                  SizedBox(width: SDSpacing.xxxs),
                                                  Expanded(
                                                    flex: 3,
                                                    child: Text(
                                                      location,
                                                      style: SDTypography.bodySmall.copyWith(
                                                        color: SDColors.primary600,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  SizedBox(width: SDSpacing.xxxs),
                                                  Icon(Icons.star,
                                                      size: 14,
                                                      color: SDColors.warning500),
                                                  SizedBox(width: SDSpacing.xxxs),
                                                  Flexible(
                                                    flex: 1,
                                                    child: Text(
                                                      rating,
                                                      style: SDTypography.labelSmall.copyWith(
                                                        color: SDColors.warning500,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: SDSpacing.xxxs),
                                              SizedBox(
                                                height: 28,
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    // Action contacter
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        SDColors.primary600,
                                                    foregroundColor:
                                                        SDColors.white,
                                                    padding: SDSpacing.chipPadding,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              SDSpacing.borderRadiusMedium),
                                                    ),
                                                  ),
                                                  child: Text('Contacter',
                                                      style: SDTypography.labelSmall),
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
                        SizedBox(height: SDSpacing.lg),
                        
                        // 📍 AUTOUR DE MOI (Carte interactive + liste)
                        _buildAroundMeSection(),
                        SizedBox(height: SDSpacing.xl),

                        // 🔥 Promotions
                        _buildActivePromotionsSection(),
                        SizedBox(height: SDSpacing.xl),

                        // Actions rapides (en dernier)
                        _buildQuickActionsSection(),
                        
                        SizedBox(height: SDSpacing.xxl), // Espacement final pour FAB
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }



  // ✅ NOUVEAU : Banner promo sticky pour newbies
  Widget _buildPromoStickyBanner(BuildContext context) {
    // Si le banner est masqué, retourner un widget vide
    if (!_showWelcomeBanner) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // Affichage du banner promo pour tous les utilisateurs (peut être conditionné plus tard)
    return SliverPersistentHeader(
      floating: true,
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
          padding: EdgeInsets.symmetric(horizontal: SDSpacing.sm, vertical: SDSpacing.xs),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(SDSpacing.xxxs),
                decoration: BoxDecoration(
                  color: SDColors.primary600.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                ),
                child: Icon(Icons.verified_user,
                    color: SDColors.primary600, size: 16),
              ),
              SizedBox(width: SDSpacing.xs),
              Expanded(
                child: Text(
                  '✨ Bienvenue ! Découvre nos prestataires vérifiés',
                  style: SDTypography.labelSmall.copyWith(
                    color: SDColors.primary600.withOpacity(0.9),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(SDSpacing.xxxs),
                decoration: BoxDecoration(
                  color: SDColors.primary600.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
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

  // Bannière Métiers : carousel avec 3 bannières PNG (~25% de l'écran pour plus d'espace)
  Widget _buildHomeBannerSliver(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bannerHeight = screenHeight * 0.25; // ~25% de la hauteur de l'écran (réduit de 40%)
    
    final List<String> bannerImages = [
      'assets/banner/metiers/banner1.png',
      'assets/banner/metiers/banner2.png',
      'assets/banner/metiers/banner3.png',
    ];
    
    return SliverToBoxAdapter(
      child: SizedBox(
        height: bannerHeight,
        width: double.infinity,
        child: CarouselSlider.builder(
          itemCount: bannerImages.length,
          options: CarouselOptions(
            height: bannerHeight,
            viewportFraction: 1.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: false,
            scrollDirection: Axis.horizontal,
          ),
          itemBuilder: (context, index, realIndex) {
            return Image.asset(
              bannerImages[index],
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                color: SDColors.primary50,
                alignment: Alignment.center,
                child: Icon(Icons.image_not_supported, color: SDColors.primary600, size: 40),
              ),
            );
          },
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
            Expanded(
              child: Text(
                'Actions rapides',
                style: SDTypography.titleMedium.copyWith(
                  color: SDColors.neutral900,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () {
                // TODO: Navigation vers la page complète des actions rapides
              },
              child: Text(
                'Voir tout',
                style: SDTypography.labelMedium.copyWith(
                  color: SDColors.primary600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: SDSpacing.sm),
        SizedBox(
          height: 95, // Augmenté de 90 à 95 pour éviter l'overflow
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: quickActions.length,
            itemBuilder: (context, index) {
              final action = quickActions[index];
              return Padding(
                padding: EdgeInsets.only(right: SDSpacing.sm),
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

  // ✅ NOUVEAU : Carte d'action rapide moderne (Optimisée Compact)
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
        width: 80,
        padding: EdgeInsets.symmetric(vertical: SDSpacing.xxxs, horizontal: SDSpacing.xxs),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              SDColors.white,
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(SDSpacing.xxxs),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
              ),
              child: Icon(
                icon,
                color: color,
                size: 16,
              ),
            ),
            SizedBox(height: SDSpacing.xxxs),
            Text(
              title,
              style: SDTypography.labelSmall.copyWith(
                color: SDColors.neutral900,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: SDSpacing.xxxs),
            Text(
              subtitle,
              style: SDTypography.bodySmall.copyWith(
                color: SDColors.neutral500,
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
    }
  }

  // 🎯 Hero Search Bar — réduit pour laisser place à la bannière
  Widget _buildHeroSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: SDSpacing.md, vertical: SDSpacing.sm),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(SDSpacing.lg),
        border: Border.all(color: SDColors.primary100, width: 1),
        boxShadow: [
          BoxShadow(
            color: SDColors.neutral900.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: SDColors.primary600, size: 22),
          SizedBox(width: SDSpacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SearchPageScreenM()),
                );
              },
              child: Text(
                'Rechercher un service, prestataire...',
                style: SDTypography.bodyMedium.copyWith(
                  color: SDColors.neutral400,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SearchPageScreenM()),
              );
            },
            child: Container(
              padding: EdgeInsets.all(SDSpacing.xs),
              decoration: BoxDecoration(
                color: SDColors.primary600,
                borderRadius: BorderRadius.circular(SDSpacing.sm),
              ),
              child: Icon(Icons.tune, color: SDColors.white, size: 20),
            ),
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
      padding: EdgeInsets.symmetric(horizontal: SDSpacing.sm, vertical: SDSpacing.sm),
      decoration: BoxDecoration(
        color: SDColors.primary50,
        borderRadius: BorderRadius.circular(SDSpacing.sm),
        border: Border.all(color: SDColors.primary100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: SDTypography.labelSmall.copyWith(
                color: color,
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
        separatorBuilder: (_, __) => SizedBox(width: SDSpacing.sm),
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
      padding: SDSpacing.cardPadding,
      decoration: BoxDecoration(
        color: SDColors.error50,
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        border: Border.all(color: SDColors.error200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: SDColors.error600),
          SizedBox(width: SDSpacing.sm),
          Expanded(
            child: Text(
              error,
              style: SDTypography.bodyMedium.copyWith(color: SDColors.error600),
            ),
          ),
        ],
      ),
    );
  }

  // 🔍 NOUVEAU : Empty State
  Widget _buildEmptyState(String message) {
    return Container(
      padding: EdgeInsets.all(SDSpacing.lg),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: SDColors.neutral300),
          SizedBox(height: SDSpacing.sm),
          Text(
            message,
            style: SDTypography.bodyLarge.copyWith(
              color: SDColors.neutral500,
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
                Row(
                  children: [
                    Icon(Icons.location_on, color: SDColors.primary600, size: 22),
                    SizedBox(width: SDSpacing.xs),
                    Text(
                      'Autour de moi',
                      style: SDTypography.titleLarge.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SDSpacing.xxs),
                // Contrôles sur une ligne séparée
                Row(
                  children: [
                    // Slider de rayon plus compact
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Icon(Icons.radio_button_unchecked, size: 14, color: SDColors.primary600),
                          SizedBox(width: SDSpacing.xxxs),
                          Expanded(
                            child: Slider(
                              value: _searchRadius,
                              min: 1.0,
                              max: 20.0,
                              divisions: 19,
                              activeColor: SDColors.primary600,
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
                              style: SDTypography.labelSmall),
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
                      icon: Icon(Icons.refresh,
                          color: SDColors.primary600, size: 20),
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
                      icon: Icon(Icons.zoom_out_map,
                          color: SDColors.info500, size: 20),
                      tooltip: 'Voir carte complète',
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: SDSpacing.sm),

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
                                color: SDColors.neutral100,
                                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.map,
                                        size: 48, color: SDColors.primary600),
                                    SizedBox(height: SDSpacing.xxs),
                                    Text('Carte disponible sur mobile',
                                        style: SDTypography.titleSmall.copyWith(
                                          color: SDColors.primary600,
                                        )),
                                    SizedBox(height: SDSpacing.xxxs),
                                    Text(
                                        'Utilisez l\'application mobile pour voir la carte',
                                        style: SDTypography.bodySmall.copyWith(
                                          color: SDColors.neutral500,
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
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 48, color: SDColors.error500),
                                  SizedBox(height: 8),
                                  Text('Erreur de chargement de la carte',
                                      style: SDTypography.bodyMedium.copyWith(color: SDColors.error500)),
                                ],
                              ),
                            );
                          }
                        },
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_off,
                                size: 48, color: SDColors.neutral400),
                            SizedBox(height: SDSpacing.xxs),
                            Text('Position non disponible',
                                style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral500)),
                          ],
                        ),
                      ),
              ),
            ),
            SizedBox(height: SDSpacing.sm),

            // Filtres de catégorie et service
            _buildFiltersRow(state),
            SizedBox(height: SDSpacing.sm),

            // Compteur de prestataires trouvés
            if (state.nearbyProviders.isNotEmpty)
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: SDSpacing.sm, vertical: SDSpacing.xxs),
                margin: EdgeInsets.only(bottom: SDSpacing.xxs),
                decoration: BoxDecoration(
                  color: SDColors.success50,
                  borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                  border: Border.all(color: SDColors.success200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: SDColors.primary600, size: 16),
                    SizedBox(width: SDSpacing.xxs),
                    Text(
                      '${state.nearbyProviders.length} prestataire(s) trouvé(s)',
                      style: SDTypography.bodyMedium.copyWith(
                        color: SDColors.success700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedCategory.isNotEmpty)
                      Container(
                        padding: SDSpacing.chipPadding,
                        decoration: BoxDecoration(
                          color: SDColors.primary600,
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                        ),
                        child: Text(
                          _selectedCategory,
                          style: SDTypography.labelSmall.copyWith(
                            color: SDColors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Liste des prestataires à proximité
            if (state.isNearbyLoading)
              Center(
                  child: CircularProgressIndicator(color: SDColors.primary600))
            else if (state.nearbyError.isNotEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: SDColors.error500),
                    SizedBox(height: SDSpacing.xxs),
                    Text('Erreur: ${state.nearbyError}',
                        style: SDTypography.bodyMedium.copyWith(color: SDColors.error500)),
                  ],
                ),
              )
            else if (state.nearbyProviders.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.location_searching,
                        size: 48, color: SDColors.neutral400),
                    SizedBox(height: SDSpacing.xxs),
                    Text('Aucun prestataire à proximité',
                        style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral500)),
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
                decoration: InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                  contentPadding: SDSpacing.inputPadding,
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
            SizedBox(width: SDSpacing.xxs),
            // Filtre par service
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _selectedService.isEmpty ? null : _selectedService,
                decoration: InputDecoration(
                  labelText: 'Service',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: SDSpacing.xxs, vertical: SDSpacing.xxxs),
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
          style: SDTypography.titleSmall.copyWith(
            color: SDColors.neutral900,
          ),
        ),
        SizedBox(height: SDSpacing.sm),
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
      margin: EdgeInsets.only(right: SDSpacing.sm),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge)),
        child: InkWell(
          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
          onTap: () {
            // ✅ Navigation vers le profil complet du prestataire
            NavigationHelper.navigateToProviderProfile(
              context,
              providerId: provider.idprestataire,
              providerData: provider.toJson(),
            );
          },
          child: Padding(
            padding: SDSpacing.cardPadding,
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
                    SizedBox(width: SDSpacing.xxs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.utilisateur?.fullName ?? 'Prestataire',
                            style: SDTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: SDColors.neutral900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            provider.service?.nomservice ?? 'Service',
                            style: SDTypography.bodySmall.copyWith(
                              color: SDColors.neutral500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (provider.verifier)
                      Icon(Icons.verified, color: SDColors.primary600, size: 16),
                  ],
                ),
                SizedBox(height: SDSpacing.xxs),

                // Note et distance
                Row(
                  children: [
                    Icon(Icons.star, color: SDColors.warning500, size: 14),
                    SizedBox(width: SDSpacing.xxxs),
                    Flexible(
                      flex: 2,
                      child: Text(
                        provider.note ?? 'N/A',
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.warning500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: SDSpacing.xxs),
                    Icon(Icons.location_on,
                        color: SDColors.primary600, size: 14),
                    SizedBox(width: SDSpacing.xxxs),
                    Flexible(
                      flex: 3,
                      child: Text(
                        '${(index + 1) * 0.5} km',
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.primary600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SDSpacing.xxs),

                // Description
                Text(
                  provider.description ?? 'Prestataire professionnel',
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: SDSpacing.xxs),

                // Bouton d'action
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Action contacter
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SDColors.primary600,
                      foregroundColor: SDColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                      ),
                    ),
                    child: Text('Contacter', style: SDTypography.labelSmall),
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
        SizedBox(height: SDSpacing.sm),
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
            image: const DecorationImage(
              image: AssetImage('assets/categories/Image3.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, SDColors.neutral900.withOpacity(0.7)],
                  ),
                ),
              ),
              Padding(
                padding: SDSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: SDSpacing.chipPadding,
                      decoration: BoxDecoration(
                        color: SDColors.warning500,
                        borderRadius: BorderRadius.circular(SDSpacing.xxxs),
                      ),
                      child: Text(
                        'POPULAIRE',
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: SDSpacing.xxs),
                    Text(
                      'Amadou K. - Plombier Professionnel',
                      style: SDTypography.titleMedium.copyWith(
                        color: SDColors.white,
                      ),
                    ),
                    SizedBox(height: SDSpacing.xxxs),
                    Text(
                      '15 ans d\'expérience - Disponible 24/7',
                      style: SDTypography.bodyMedium.copyWith(
                        color: SDColors.white,
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
      margin: EdgeInsets.symmetric(vertical: SDSpacing.xxxs),
      decoration: BoxDecoration(
        color: SDColors.primary50,
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
        boxShadow: [
          BoxShadow(color: SDColors.neutral900.withOpacity(0.05), blurRadius: 4)
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipOval(
            child: AppImage(
                imageUrl: imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                // Error icon handled by AppImage
              ),
            )
          else
            Icon(fallbackIcon, color: SDColors.primary600, size: 40),
          SizedBox(height: SDSpacing.xxs),
          Text(
            name,
            style: SDTypography.labelSmall.copyWith(
              color: SDColors.neutral900,
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
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.local_offer,
                      color: SDColors.error500, size: 22),
                  SizedBox(width: SDSpacing.xxxs),
                  Flexible(
                    child: Text(
                      '🎁 Promotions du moment',
                      style: SDTypography.titleMedium.copyWith(
                        color: SDColors.neutral900,
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
              child: Text(
                'Voir toutes',
                style: SDTypography.labelMedium.copyWith(
                  color: SDColors.primary600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: SDSpacing.sm),
        SizedBox(
          height: 180, // Augmenté de 160 à 180
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: activePromotions.length,
            itemBuilder: (context, index) {
              final promo = activePromotions[index];
              return Container(
                width: 280,
                margin: EdgeInsets.only(right: SDSpacing.sm),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                      gradient: LinearGradient(
                        colors: [
                          promo['color'].withOpacity(0.1),
                          promo['color'].withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: SDSpacing.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                promo['title'],
                                style: SDTypography.titleSmall.copyWith(
                                  color: SDColors.neutral900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: SDSpacing.xxs),
                            Container(
                              padding: SDSpacing.chipPadding,
                              decoration: BoxDecoration(
                                color: promo['color'],
                                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                              ),
                              child: Text(
                                promo['discount'],
                                style: SDTypography.bodyMedium.copyWith(
                                  color: SDColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: SDSpacing.xxxs),
                        Text(
                          promo['description'],
                          style: SDTypography.bodySmall.copyWith(
                            color: SDColors.neutral600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: SDSpacing.xxxs),
                        Row(
                          children: [
                            Icon(Icons.code, size: 14, color: promo['color']),
                            SizedBox(width: SDSpacing.xxxs),
                            Text(
                              promo['code'],
                              style: SDTypography.labelSmall.copyWith(
                                color: promo['color'],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: SDSpacing.xxxs),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Expire le ${promo['expiry']}',
                                style: SDTypography.bodySmall.copyWith(
                                  color: SDColors.neutral500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: SDSpacing.xxxs),
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
                                  foregroundColor: SDColors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: SDSpacing.xxxs,
                                    vertical: SDSpacing.xxxs,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                                  ),
                                  minimumSize: const Size(0, 24),
                                ),
                                child: Text(
                                  'Utiliser',
                                  style: SDTypography.labelSmall,
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
        SizedBox(height: SDSpacing.sm),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Container(
                width: 280,
                margin: EdgeInsets.only(right: SDSpacing.sm),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                  ),
                  child: Padding(
                    padding: SDSpacing.cardPadding,
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
                            SizedBox(width: SDSpacing.xs),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    review['name'],
                                    style: SDTypography.labelSmall.copyWith(
                                      color: SDColors.neutral900,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    review['service'],
                                    style: SDTypography.labelSmall.copyWith(
                                      color: SDColors.neutral500,
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
                                  color: SDColors.warning500,
                                  size: 14,
                                );
                              }),
                            ),
                          ],
                        ),
                        SizedBox(height: SDSpacing.xxxs),
                        Flexible(
                          child: Text(
                            review['comment'],
                            style: SDTypography.labelSmall.copyWith(
                              color: SDColors.neutral900,
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: SDSpacing.xxxs),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Par ${review['provider']}',
                                style: SDTypography.labelSmall.copyWith(
                                  color: SDColors.primary600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: SDSpacing.xxxs),
                            Text(
                              review['date'],
                              style: SDTypography.bodySmall.copyWith(
                                color: SDColors.neutral500,
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
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.recommend,
                          color: SDColors.info500, size: 22),
                      SizedBox(width: SDSpacing.xxxs),
                      Flexible(
                        child: Text(
                          '🎯 Recommandé pour vous',
                          style: SDTypography.titleMedium.copyWith(
                            color: SDColors.neutral900,
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
                  child: Text(
                    'Tout voir',
                    style: SDTypography.labelMedium.copyWith(
                      color: const Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: SDSpacing.sm),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recommendations.length,
                itemBuilder: (context, index) {
                  final rec = recommendations[index];
                  return Container(
                    width: 300,
                    margin: EdgeInsets.only(right: SDSpacing.sm),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // Évite l'overflow
                        children: [
                          // Header avec image et badges
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(SDSpacing.borderRadiusLarge),
                                ),
                                child: Container(
                                  height: 100,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        SDColors.primary600.withOpacity(0.1),
                                        SDColors.primary600.withOpacity(0.05),
                                      ],
                                    ),
                                  ),
                                  child: rec['image'] != null && rec['image'].toString().isNotEmpty
                                      ? AppImage(
                                          imageUrl: rec['image'],
                                          fit: BoxFit.cover,
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
                                    SizedBox(width: SDSpacing.xxxs),
                                    if (rec['discount'] != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: SDColors.primary600,
                                          borderRadius:
                                              BorderRadius.circular(SDSpacing.borderRadiusSmall),
                                        ),
                                        child: Text(
                                          '-${rec['discount']}',
                                          style: SDTypography.labelSmall.copyWith(
                                            color: SDColors.white,
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
                              padding: EdgeInsets.all(SDSpacing.xxxs),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    rec['title'],
                                    style: SDTypography.bodyMedium.copyWith(
                                      color: SDColors.neutral900,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: SDSpacing.xxxs),
                                  Text(
                                    rec['reason'],
                                    style: SDTypography.labelSmall.copyWith(
                                      color: SDColors.info500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: SDSpacing.xxxs),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          rec['provider'],
                                          style: SDTypography.labelSmall.copyWith(
                                            color: SDColors.neutral900,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: SDSpacing.xxxs),
                                      Icon(
                                        Icons.star,
                                        color: SDColors.warning500,
                                        size: 12,
                                      ),
                                      SizedBox(width: SDSpacing.xxxs),
                                      Text(
                                        rec['rating'].toString(),
                                        style: SDTypography.labelSmall.copyWith(
                                          color: SDColors.warning500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: SDSpacing.xxxs),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          rec['price'],
                                          style: SDTypography.labelSmall.copyWith(
                                            color: SDColors.primary600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: SDSpacing.xxxs),
                                      Flexible(
                                        flex: 2,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            // TODO: Navigation vers les détails du service
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: SDColors.primary600,
                                            foregroundColor: SDColors.white,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: SDSpacing.xxxs,
                                              vertical: SDSpacing.xxxs,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(SDSpacing.borderRadiusSmall),
                                            ),
                                            minimumSize: const Size(0, 24),
                                          ),
                                          child: Text(
                                            'Voir',
                                            style: SDTypography.labelSmall,
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
