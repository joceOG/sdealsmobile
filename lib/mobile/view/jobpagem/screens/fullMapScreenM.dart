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
import '../../../../data/models/prestataire.dart'; // ✅ Import nécessaire

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
    print('🗺️ FullMap _updateMapMarkers appelé avec ${providers.length} prestataires');
    print('🗺️ Type des providers: ${providers.map((p) => p.runtimeType).toList()}');
    if (providers.isNotEmpty) {
      print('🗺️ Premier provider: ${providers.first}');
    }
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

    // Marqueurs des prestataires avec leurs vraies coordonnées
    for (int i = 0; i < providers.length; i++) {
      final provider = providers[i];
      
      // Utiliser les vraies coordonnées du prestataire
      double? lat;
      double? lng;
      
      // Les prestataires arrivent maintenant comme objets Prestataire convertis
      if (provider is Prestataire) {
        // C'est un objet Prestataire
        if (provider.localisationMaps != null) {
          lat = provider.localisationMaps!.latitude;
          lng = provider.localisationMaps!.longitude;
        }
      } else if (provider is Map<String, dynamic>) {
        // Fallback si c'est encore un Map (données du backend)
        final locMaps = provider['localisationmaps'];
        if (locMaps != null && locMaps is Map<String, dynamic>) {
          // Conversion sécurisée int/double
          final latValue = locMaps['latitude'];
          final lngValue = locMaps['longitude'];
          
          if (latValue is num) lat = latValue.toDouble();
          if (lngValue is num) lng = lngValue.toDouble();
        }
      } else {
        // Autre type d'objet - tentative d'accès dynamique
        try {
          final prestataireData = provider as dynamic;
          if (prestataireData.localisationMaps != null) {
            lat = prestataireData.localisationMaps.latitude;
            lng = prestataireData.localisationMaps.longitude;
          }
        } catch (e) {
          print('Erreur extraction coordonnées prestataire: $e');
        }
      }
      
      // Ignorer ce prestataire s'il n'a pas de coordonnées
      if (lat == null || lng == null || lat == 0.0 || lng == 0.0) {
        final providerId = provider is Prestataire ? provider.idprestataire : (provider is Map ? provider['_id'] ?? i : i);
        print('❌ Prestataire $providerId ignoré: pas de coordonnées valides (lat: $lat, lng: $lng)');
        continue;
      }
      
      final providerId = provider is Prestataire ? provider.idprestataire : (provider is Map ? provider['_id'] ?? i : i);
      print('✅ Prestataire $providerId ajouté à la carte: lat=$lat, lng=$lng');

      // Extraire les vraies données du prestataire
      String providerName = 'Prestataire';
      String serviceName = 'Service';
      String categoryName = '';
      String price = '0 FCFA';
      bool isVerified = false;
      String note = 'N/A';
      
      if (provider is Prestataire) {
        // C'est un objet Prestataire converti ✅
        providerName = provider.utilisateur.fullName;
        if (providerName.isEmpty) providerName = 'Prestataire';
        serviceName = provider.service.nomservice;
        categoryName = provider.service.categorie?.nomcategorie ?? '';
        price = '${provider.prixprestataire.toStringAsFixed(0)} FCFA/h';
        isVerified = provider.verifier;
        note = provider.note ?? 'N/A';
      } else if (provider is Map<String, dynamic>) {
        // Fallback pour Map (données du backend)
        final utilisateur = provider['utilisateur'];
        if (utilisateur is Map<String, dynamic>) {
          providerName = '${utilisateur['prenom'] ?? ''} ${utilisateur['nom'] ?? ''}'.trim();
          if (providerName.isEmpty) providerName = 'Prestataire';
        }
        
        final service = provider['service'];
        if (service is Map<String, dynamic>) {
          serviceName = service['nomservice'] ?? 'Service';
          categoryName = service['nomcategorie'] ?? '';
        }
        
        // Prix réel du prestataire (conversion sécurisée)
        final prixPrestataire = provider['prixprestataire'] ?? provider['hourlyRate'];
        if (prixPrestataire != null && prixPrestataire is num) {
          final prixDouble = prixPrestataire.toDouble();
          price = '${prixDouble.toStringAsFixed(0)} FCFA/h';
        }
        
        isVerified = provider['verifier'] == true || 
                    (provider['verificationDocuments']?['isVerified'] == true);
        
        note = provider['note']?.toString() ?? 'N/A';
      } else {
        // Autre type d'objet - tentative d'accès dynamique
        try {
          final prestataireData = provider as dynamic;
          if (prestataireData.utilisateur != null) {
            providerName = '${prestataireData.utilisateur.prenom ?? ''} ${prestataireData.utilisateur.nom ?? ''}'.trim();
            if (providerName.isEmpty) providerName = 'Prestataire';
          }
          
          if (prestataireData.service != null) {
            serviceName = prestataireData.service.nomservice ?? 'Service';
            categoryName = prestataireData.service.nomcategorie ?? '';
          }
          
          price = '${prestataireData.prixprestataire?.toString() ?? '0'} FCFA/h';
          isVerified = prestataireData.verifier == true;
          note = prestataireData.note?.toString() ?? 'N/A';
        } catch (e) {
          print('Erreur extraction données prestataire: $e');
        }
      }

      // Créer le marqueur personnalisé avec couleur intelligente (même style que "Autour de moi")
      final providerIcon = await CustomMarkerService.createSmartProviderMarker(
        name: providerName,
        category: categoryName,
        service: serviceName,
        isVerified: isVerified,
        isUrgent: false,
      );

      markers.add(
        Marker(
          markerId: MarkerId('provider_${provider is Prestataire ? provider.idprestataire : i}'),
          position: LatLng(lat, lng),
          icon: providerIcon,
          infoWindow: InfoWindow(
            title: providerName,
            snippet: 'Note: $note/5 • $serviceName • $price',
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

    print('🎯 Total markers créés: ${markers.length} (dont 1 utilisateur + ${markers.length - 1} prestataires)');
    
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
                              color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Prix des services affichés sur la carte',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'FCFA',
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontSize: 10,
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
