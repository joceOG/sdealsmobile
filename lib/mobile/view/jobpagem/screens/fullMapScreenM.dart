import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../services/custom_marker_service.dart';
import '../widgets/provider_popup.dart';

import '../jobpageblocm/jobPageBlocM.dart';
import '../jobpageblocm/jobPageStateM.dart';
import '../jobpageblocm/jobPageEventM.dart';

class FullMapScreenM extends StatefulWidget {
  final LatLng? initialPosition;
  final List<dynamic> providers;
  final double searchRadius;
  final String? selectedCategory;
  final String? selectedService;

  const FullMapScreenM({
    super.key,
    this.initialPosition,
    this.providers = const [],
    this.searchRadius = 10.0,
    this.selectedCategory,
    this.selectedService,
  });

  @override
  State<FullMapScreenM> createState() => _FullMapScreenMState();
}

class _FullMapScreenMState extends State<FullMapScreenM> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng? _userLocation;
  double _currentRadius = 10.0;
  String _selectedCategory = '';
  String _selectedService = '';
  dynamic _selectedProvider;
  bool _showPopup = false;

  @override
  void initState() {
    super.initState();
    _userLocation = widget.initialPosition;
    _currentRadius = widget.searchRadius;
    _selectedCategory = widget.selectedCategory ?? '';
    _selectedService = widget.selectedService ?? '';
    _updateMapMarkers(widget.providers);
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

      // Les icônes sont maintenant gérées dans le service de marqueurs

      // Générer un prix aléatoire pour la démonstration (à remplacer par les vraies données)
      final List<String> priceRanges = [
        '5 000 F CFA',
        '8 000 F CFA',
        '12 000 F CFA',
        '15 000 F CFA',
        '20 000 F CFA',
        '25 000 F CFA',
        '30 000 F CFA',
        '35 000 F CFA',
        '45 000 F CFA',
        '50 000 F CFA',
      ];
      final String price = priceRanges[i % priceRanges.length];

      // Créer le marqueur avec bulle de prix
      final providerIcon =
          await CustomMarkerService.createProviderWithPriceMarker(
        name: provider.utilisateur?.fullName ?? 'Prestataire',
        category: provider.categorie?.nomcategorie ?? '',
        service: provider.service?.nomservice ?? '',
        price: price,
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
          onTap: () {
            setState(() {
              _selectedProvider = provider;
              _showPopup = true;
            });
          },
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _getCurrentLocation() async {
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
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });

      // Animer la caméra vers la nouvelle position
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_userLocation!),
      );

      // Charger les prestataires à proximité
      context.read<JobPageBlocM>().add(LoadNearbyProvidersM(
            latitude: _userLocation!.latitude,
            longitude: _userLocation!.longitude,
            radius: _currentRadius,
            category: _selectedCategory.isNotEmpty ? _selectedCategory : null,
            service: _selectedService.isNotEmpty ? _selectedService : null,
          ));
    } catch (e) {
      print('Erreur de géolocalisation: $e');
    }
  }

  void _searchNearbyProviders() {
    if (_userLocation != null) {
      context.read<JobPageBlocM>().add(LoadNearbyProvidersM(
            latitude: _userLocation!.latitude,
            longitude: _userLocation!.longitude,
            radius: _currentRadius,
            category: _selectedCategory.isNotEmpty ? _selectedCategory : null,
            service: _selectedService.isNotEmpty ? _selectedService : null,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte Complète'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'Ma position',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _searchNearbyProviders,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: BlocProvider(
        create: (_) => JobPageBlocM(),
        child: BlocListener<JobPageBlocM, JobPageStateM>(
          listener: (context, state) {
            if (state.nearbyProviders.isNotEmpty) {
              _updateMapMarkers(state.nearbyProviders);
            }
          },
          child: Column(
            children: [
              // Contrôles de la carte
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade50,
                child: Column(
                  children: [
                    // Slider de rayon
                    Row(
                      children: [
                        const Icon(Icons.radio_button_unchecked, size: 16),
                        const SizedBox(width: 8),
                        const Text('Rayon: '),
                        Expanded(
                          child: Slider(
                            value: _currentRadius,
                            min: 1.0,
                            max: 50.0,
                            divisions: 49,
                            activeColor: Colors.green,
                            onChanged: (value) {
                              setState(() {
                                _currentRadius = value;
                              });
                            },
                          ),
                        ),
                        Text('${_currentRadius.toInt()}km'),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Indicateur de prix
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade800,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade900),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.attach_money,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Prix des services affichés sur la carte',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'F CFA',
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Filtres
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory.isEmpty
                                ? null
                                : _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Catégorie',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              isDense: true,
                            ),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(
                                  value: '', child: Text('Toutes')),
                              const DropdownMenuItem(
                                  value: 'Auto', child: Text('Auto')),
                              const DropdownMenuItem(
                                  value: 'Immobilier',
                                  child: Text('Immobilier')),
                              const DropdownMenuItem(
                                  value: 'Électronique',
                                  child: Text('Électronique')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value ?? '';
                              });
                              _searchNearbyProviders();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedService.isEmpty
                                ? null
                                : _selectedService,
                            decoration: const InputDecoration(
                              labelText: 'Service',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              isDense: true,
                            ),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(
                                  value: '', child: Text('Tous')),
                              const DropdownMenuItem(
                                  value: 'Plombier', child: Text('Plombier')),
                              const DropdownMenuItem(
                                  value: 'Coiffeur', child: Text('Coiffeur')),
                              const DropdownMenuItem(
                                  value: 'Photographe',
                                  child: Text('Photographe')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedService = value ?? '';
                              });
                              _searchNearbyProviders();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Carte Google Maps
              Expanded(
                child: _userLocation != null
                    ? Builder(
                        builder: (context) {
                          // Désactiver Google Maps sur le Web pour éviter l'erreur
                          if (kIsWeb) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.map,
                                        size: 64, color: Colors.green),
                                    SizedBox(height: 16),
                                    Text('Carte complète disponible sur mobile',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        )),
                                    SizedBox(height: 8),
                                    Text(
                                        'Utilisez l\'application mobile pour voir la carte complète',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        )),
                                  ],
                                ),
                              ),
                            );
                          }

                          try {
                            return Stack(
                              children: [
                                GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: _userLocation!,
                                    zoom: 13.0,
                                  ),
                                  markers: _markers,
                                  onMapCreated: _onMapCreated,
                                  myLocationEnabled: true,
                                  myLocationButtonEnabled: true,
                                  zoomControlsEnabled: true,
                                  mapToolbarEnabled: true,
                                ),

                                // Popup du prestataire
                                if (_showPopup && _selectedProvider != null)
                                  ProviderPopup(
                                    provider: _selectedProvider,
                                    onClose: () {
                                      setState(() {
                                        _showPopup = false;
                                        _selectedProvider = null;
                                      });
                                    },
                                  ),
                              ],
                            );
                          } catch (e) {
                            print('Erreur Google Maps: $e');
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 64, color: Colors.red),
                                  SizedBox(height: 16),
                                  Text('Erreur de chargement de la carte',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      )),
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
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Position non disponible',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 18,
                                )),
                            SizedBox(height: 8),
                            Text(
                                'Activez la géolocalisation pour voir la carte',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                )),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
