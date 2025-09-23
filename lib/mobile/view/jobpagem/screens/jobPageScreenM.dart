import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/mobile/view/loginpagem/screens/loginPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/serviceproviderwelcomepagem/screens/serviceProviderWelcomeScreenM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/detailPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/fullMapScreenM.dart';
import 'package:sdealsmobile/mobile/view/common/screens/ai_assistant_chat_screen.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/ai_price_estimator_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../services/custom_marker_service.dart';

import '../../../../data/models/service.dart';
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
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng? _userLocation;
  double _searchRadius = 5.0;
  String _selectedCategory = '';
  String _selectedService = '';

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
      "color": Colors.green,
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

  // Messages promotionnels pour la bannière
  static const List<String> bannerMessages = [
    "✨ Obtenez 10% de réduction sur votre première commande !",
    "🎯 Trouvez le prestataire idéal à proximité",
    "🛠️ Des services de qualité à portée de main",
    "💼 Rejoignez notre communauté de prestataires",
  ];

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

  static const List<Map<String, dynamic>> topPrestataires = [
    {
      "image": "assets/categories/Image1.png",
      "title": "Électricien",
      "subtitle": "Disponible 24h/24",
      "location": "Abidjan",
      "rating": "4.8",
      "verified": true,
      "online": true
    },
    {
      "image": "assets/categories/Image2.png",
      "title": "Maçon",
      "subtitle": "Spécialiste rénovation",
      "location": "yamoussoukro",
      "rating": "4.6",
      "verified": false,
      "online": false
    },
    {
      "image": "assets/categories/Image3.png",
      "title": "Peintre",
      "subtitle": "Peinture intérieure/extérieure",
      "location": "Abobo PK18",
      "rating": "4.7",
      "verified": true,
      "online": true
    },
    {
      "image": "assets/categories/Image4.png",
      "title": "Jardinier",
      "subtitle": "Entretien & aménagement",
      "location": "Cocody",
      "rating": "4.5",
      "verified": false,
      "online": true
    },
    {
      "image": "assets/categories/Image5.png",
      "title": "Cuisinier",
      "subtitle": "Cuisine africaine & européenne",
      "location": "Plateau",
      "rating": "4.9",
      "verified": true,
      "online": false
    },
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });

      // Charger les prestataires à proximité
      if (_userLocation != null) {
        context.read<JobPageBlocM>().add(LoadNearbyProvidersM(
              latitude: _userLocation!.latitude,
              longitude: _userLocation!.longitude,
              radius: _searchRadius,
              category: _selectedCategory.isNotEmpty ? _selectedCategory : null,
              service: _selectedService.isNotEmpty ? _selectedService : null,
            ));
      }
    } catch (e) {
      print('Erreur géolocalisation: $e');
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

      // Déterminer le type de marqueur selon le service
      IconData? serviceIcon;
      String serviceName = provider.service?.nomservice ?? '';
      if (serviceName.toLowerCase().contains('médical') ||
          serviceName.toLowerCase().contains('santé') ||
          serviceName.toLowerCase().contains('docteur')) {
        serviceIcon = Icons.local_hospital;
      } else if (serviceName.toLowerCase().contains('réparation') ||
          serviceName.toLowerCase().contains('plomberie') ||
          serviceName.toLowerCase().contains('électricité')) {
        serviceIcon = Icons.build;
      } else {
        serviceIcon = Icons.work;
      }

      // Créer le marqueur personnalisé avec couleur intelligente
      final providerIcon = await CustomMarkerService.createSmartProviderMarker(
        name: provider.utilisateur?.fullName ?? 'Prestataire',
        category: provider.categorie?.nomcategorie ?? '',
        service: provider.service?.nomservice ?? '',
        isVerified: provider.verifier == true,
        isUrgent: provider.disponibilite == 'urgent' ||
            (provider.note != null && provider.note < 3.0),
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
            backgroundColor: Colors.green, // Vert de base de l'app
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
                        const SizedBox(height: 16),
                        // Quick Actions section (remplace les stories)
                        _buildQuickActionsSection(),
                        const SizedBox(height: 20),

                        // Titre catégories
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Top Catégories',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: const Text(
                                'Voir plus',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Liste horizontale des catégories avec design amélioré

                        BlocBuilder<JobPageBlocM, JobPageStateM>(
                          builder: (context, state) {
                            if (state.isLoading) {
                              return const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.green));
                            }
                            if (state.error.isNotEmpty) {
                              return Text("Erreur: ${state.error}",
                                  style: const TextStyle(color: Colors.red));
                            }
                            if (state.listItems.isEmpty) {
                              return const Text("Aucune catégorie disponible");
                            }

                            return SizedBox(
                              height: 120,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: state.listItems.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 14),
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
                        const SizedBox(height: 20),

                        // Titre Top Services
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Top Services',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: const Text(
                                'Voir plus',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Estimation IA de prix pour un service populaire
                        AIPriceEstimatorWidget(
                          serviceCategory: topServices.isNotEmpty
                              ? topServices[0]['title']!
                              : 'Service',
                          location: 'Abidjan',
                          jobDescription: 'Besoin standard',
                        ),
                        const SizedBox(height: 16),
                        // Carrousel Top Services
                        BlocBuilder<JobPageBlocM, JobPageStateM>(
                          builder: (context, state) {
                            if (state.isLoading2) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (state.listItems2.isEmpty) {
                              return const Center(
                                  child: Text('Aucun service disponible'));
                            }

                            return CarouselSlider.builder(
                              itemCount: state.listItems2.length,
                              options: CarouselOptions(
                                height: 180.0,
                                autoPlay: true,
                                autoPlayInterval: const Duration(seconds: 3),
                                enlargeCenterPage: true,
                                viewportFraction: 0.78,
                              ),
                              itemBuilder: (context, index, realIndex) {
                                final Service item = state.listItems2[index];

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DetailPage(
                                          title: item.nomservice,
                                          image: item.imageservice,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14.0),
                                    ),
                                    color: Colors.green.withOpacity(0.07),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                              top: Radius.circular(14.0),
                                            ),
                                            child: item.imageservice.isNotEmpty
                                                ? Image.network(
                                                    item.imageservice,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                  )
                                                : Image.asset(
                                                    'assets/default.png',
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                  ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.nomservice,
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16.0,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'À partir de ${item.prixmoyen} FCFA/h',
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Catégorie: ${item.categorie?.nomcategorie}',
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 11.0,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        // ✅ NOUVEAU : Section "Autour de moi" avec carte
                        _buildAroundMeSection(),

                        const SizedBox(height: 32),

                        // Titre Top Prestataires
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Top Prestataires',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: const Text(
                                'Voir plus',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // À la une cette semaine
                        _buildFeaturedSection(),
                        const SizedBox(height: 24),

                        // Carrousel Top Prestataires (design différent)
                        CarouselSlider.builder(
                          itemCount: topPrestataires.length,
                          options: CarouselOptions(
                            height: 170.0,
                            autoPlay: true,
                            autoPlayInterval: const Duration(seconds: 4),
                            enlargeCenterPage: true,
                            viewportFraction: 0.85,
                          ),
                          itemBuilder: (context, index, realIndex) {
                            final item = topPrestataires[index];
                            return GestureDetector(
                              onTap: () {
                                // Redirection vers la page de détails du prestataire
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailPage(
                                      title: item['title']!,
                                      image: item['image']!,
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18.0),
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
                                            child: Image.asset(
                                              item['image']!,
                                              fit: BoxFit.cover,
                                              width: 90,
                                              height: 130,
                                            ),
                                          ),
                                          // Indicateur en ligne
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: item['online'] == true
                                                    ? Colors.green
                                                    : Colors.grey,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: Colors.white,
                                                    width: 2),
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
                                                Text(
                                                  item['title'] ?? '',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 17.0,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                if (item['verified'] == true)
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                        left: 4),
                                                    child: Icon(Icons.verified,
                                                        color: Colors.green,
                                                        size: 16),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item['subtitle'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on,
                                                    size: 15,
                                                    color: Colors.green),
                                                const SizedBox(width: 4),
                                                Text(
                                                  item['location'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                                const Spacer(),
                                                const Icon(Icons.star,
                                                    size: 15,
                                                    color: Colors.amber),
                                                const SizedBox(width: 2),
                                                Text(
                                                  item['rating'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.amber,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            ElevatedButton(
                                              onPressed: () {
                                                // Action contacter
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                minimumSize: const Size(
                                                    double.infinity, 30),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: const Text('Contacter'),
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
                        ),
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
      backgroundColor: Colors.green,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Métiers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.search, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 20),
                    ],
                  ),
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
    // Affichage du banner promo pour tous les utilisateurs (peut être conditionné plus tard)
    return SliverPersistentHeader(
      pinned: true,
      delegate: _PromoStickyDelegate(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withOpacity(0.1), // Vert Soutrali transparent
                Colors.green.withOpacity(0.15),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border(
              bottom:
                  BorderSide(color: Colors.green.withOpacity(0.3), width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.verified_user, color: Colors.green, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '✨ Bienvenue ! Découvre nos prestataires vérifiés',
                  style: TextStyle(
                    color: Colors.green.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: InkWell(
                  onTap: () {
                    // TODO: Masquer le banner définitivement pour cet utilisateur
                  },
                  child: Icon(
                    Icons.close,
                    color: Colors.green,
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
                        color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '💳 SoutraPay',
                      style: TextStyle(
                          color: Colors.green,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Actions rapides',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            GestureDetector(
              onTap: () {
                // TODO: Naviguer vers page complète des actions
              },
              child: const Text(
                'Voir tout',
                style: TextStyle(
                  color: Colors.green,
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
                padding: const EdgeInsets.only(right: 12),
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
        width: 85,
        padding: const EdgeInsets.all(6), // Réduit de 8 à 6
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6), // Réduit de 8 à 6
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10), // Réduit de 12 à 10
              ),
              child: Icon(
                icon,
                color: color,
                size: 20, // Réduit de 24 à 20
              ),
            ),
            const SizedBox(height: 4), // Réduit de 6 à 4
            Text(
              title,
              style: const TextStyle(
                fontSize: 11, // Réduit de 12 à 11
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9, // Réduit de 10 à 9
                color: Colors.grey.shade600,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📍 Autour de moi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
                Row(
                  children: [
                    // Slider de rayon
                    SizedBox(
                      width: 120,
                      child: Row(
                        children: [
                          const Icon(Icons.radio_button_unchecked, size: 16),
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
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Bouton actualiser
                    IconButton(
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
                      icon: const Icon(Icons.refresh, color: Colors.green),
                    ),
                    // Bouton zoom vers carte complète
                    IconButton(
                      onPressed: () {
                        if (_userLocation != null) {
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
                      icon: const Icon(Icons.zoom_out_map, color: Colors.blue),
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
                                          color: Colors.green,
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
                                _mapController = controller;
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
                          color: Colors.green,
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
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Navigation vers le détail du prestataire
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailPage(
                  title: provider.utilisateur?.fullName ?? 'Prestataire',
                  image: 'assets/categories/Image${(index % 5) + 1}.png',
                ),
              ),
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
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      provider.note.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on,
                        color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${(index + 1) * 0.5} km',
                      style: const TextStyle(color: Colors.green, fontSize: 12),
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
                      backgroundColor: Colors.green,
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
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'Voir plus',
                style: TextStyle(
                  color: Colors.green,
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
