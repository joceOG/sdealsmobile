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
// ✅ Design System
import '../../../../design_system/design_system.dart';

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
  static const List<String> _defaultCategories = [
    'Auto',
    'Immobilier',
    'Électronique',
  ];
  static const List<String> _defaultServices = [
    'Plombier',
    'Coiffeur',
    'Photographe',
  ];

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
    _selectedCategory = (widget.selectedCategory ?? '').trim();
    _selectedService = (widget.selectedService ?? '').trim();
    _updateMapMarkers(widget.providers);
  }

  /// Valeurs affichables : defaults + valeur passée depuis la fiche (évite le crash Dropdown).
  List<String> _categoryChoices() {
    final names = <String>{..._defaultCategories};
    final incoming = (widget.selectedCategory ?? '').trim();
    if (incoming.isNotEmpty) names.add(incoming);
    if (_selectedCategory.isNotEmpty) names.add(_selectedCategory);
    return names.toList()..sort();
  }

  List<String> _serviceChoices() {
    final names = <String>{..._defaultServices};
    final incoming = (widget.selectedService ?? '').trim();
    if (incoming.isNotEmpty) names.add(incoming);
    if (_selectedService.isNotEmpty) names.add(_selectedService);
    return names.toList()..sort();
  }

  String? _safeDropdownValue(String current, List<String> choices) {
    if (current.isEmpty) return null;
    return choices.contains(current) ? current : null;
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

  void _getCurrentLocation([BuildContext? blocContext]) async {
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

      if (!mounted) return;
      final ctx = blocContext ?? context;
      try {
        ctx.read<JobPageBlocM>().add(LoadNearbyProvidersM(
              latitude: _userLocation!.latitude,
              longitude: _userLocation!.longitude,
              radius: _currentRadius,
              category:
                  _selectedCategory.isNotEmpty ? _selectedCategory : null,
              service: _selectedService.isNotEmpty ? _selectedService : null,
            ));
      } catch (e) {
        print('JobPageBlocM indisponible pour reload: $e');
      }
    } catch (e) {
      print('Erreur de géolocalisation: $e');
    }
  }

  void _searchNearbyProviders(BuildContext blocContext) {
    if (_userLocation == null) return;
    blocContext.read<JobPageBlocM>().add(LoadNearbyProvidersM(
          latitude: _userLocation!.latitude,
          longitude: _userLocation!.longitude,
          radius: _currentRadius,
          category: _selectedCategory.isNotEmpty ? _selectedCategory : null,
          service: _selectedService.isNotEmpty ? _selectedService : null,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => JobPageBlocM(),
      child: Builder(
        builder: (blocContext) {
          return Scaffold(
            appBar: SDWhiteAppBar.appBar(
              title: 'Carte complète',
              actions: [
                IconButton(
                  icon: const Icon(Icons.my_location_outlined),
                  onPressed: () => _getCurrentLocation(blocContext),
                  tooltip: 'Ma position',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => _searchNearbyProviders(blocContext),
                  tooltip: 'Actualiser',
                ),
              ],
            ),
            body: BlocListener<JobPageBlocM, JobPageStateM>(
              listener: (context, state) {
                if (state.nearbyProviders.isNotEmpty) {
                  _updateMapMarkers(state.nearbyProviders);
                }
              },
              child: Column(
            children: [
              // Contrôles de la carte
              Container(
                padding: EdgeInsets.all(SDSpacing.sm),
                color: SDColors.neutral50,
                child: Column(
                  children: [
                    // Slider de rayon
                    Row(
                      children: [
                        Icon(Icons.radio_button_unchecked, size: 16, color: SDColors.neutral600),
                        SizedBox(width: SDSpacing.xs),
                        Text('Rayon: ', style: SDTypography.bodyMedium),
                        Expanded(
                          child: Slider(
                            value: _currentRadius,
                            min: 1.0,
                            max: 50.0,
                            divisions: 49,
                            activeColor: SDColors.primary500,
                            onChanged: (value) {
                              setState(() {
                                _currentRadius = value;
                              });
                            },
                          ),
                        ),
                        Text('${_currentRadius.toInt()}km', style: SDTypography.bodyMedium),
                      ],
                    ),
                    SizedBox(height: SDSpacing.xs),

                    // Indicateur de prix
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: SDSpacing.sm, vertical: SDSpacing.xs),
                      margin: EdgeInsets.only(bottom: SDSpacing.xs),
                      decoration: BoxDecoration(
                        color: SDColors.primary700,
                        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                        border: Border.all(color: SDColors.primary800),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.attach_money,
                              color: SDColors.white, size: 14),
                          SizedBox(width: SDSpacing.xxxs),
                          Expanded(
                            child: Text(
                              'Prix des services affichés sur la carte',
                              style: SDTypography.labelSmall.copyWith(
                                color: SDColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: SDSpacing.xxxs),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: SDSpacing.xxxs, vertical: SDSpacing.xxxs),
                            decoration: BoxDecoration(
                              color: SDColors.white,
                              borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                            ),
                            child: Text(
                              'FCFA',
                              style: SDTypography.labelSmall.copyWith(
                                color: SDColors.primary700,
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
                          child: Builder(
                            builder: (context) {
                              final choices = _categoryChoices();
                              return DropdownButtonFormField<String>(
                                value: _safeDropdownValue(
                                    _selectedCategory, choices),
                                decoration: InputDecoration(
                                  labelText: 'Catégorie',
                                  labelStyle: SDTypography.bodyMedium,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        SDSpacing.borderRadiusMedium),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: SDSpacing.xs,
                                      vertical: SDSpacing.xxxs),
                                  isDense: true,
                                ),
                                style: SDTypography.bodyMedium,
                                isExpanded: true,
                                items: [
                                  DropdownMenuItem(
                                      value: '',
                                      child: Text('Toutes',
                                          style: SDTypography.bodyMedium)),
                                  ...choices.map(
                                    (name) => DropdownMenuItem(
                                      value: name,
                                      child: Text(name,
                                          style: SDTypography.bodyMedium,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategory = value ?? '';
                                  });
                                  _searchNearbyProviders(blocContext);
                                },
                              );
                            },
                          ),
                        ),
                        SizedBox(width: SDSpacing.xs),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final choices = _serviceChoices();
                              return DropdownButtonFormField<String>(
                                value: _safeDropdownValue(
                                    _selectedService, choices),
                                decoration: InputDecoration(
                                  labelText: 'Service',
                                  labelStyle: SDTypography.bodyMedium,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        SDSpacing.borderRadiusMedium),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: SDSpacing.xs,
                                      vertical: SDSpacing.xxxs),
                                  isDense: true,
                                ),
                                style: SDTypography.bodyMedium,
                                isExpanded: true,
                                items: [
                                  DropdownMenuItem(
                                      value: '',
                                      child: Text('Tous',
                                          style: SDTypography.bodyMedium)),
                                  ...choices.map(
                                    (name) => DropdownMenuItem(
                                      value: name,
                                      child: Text(name,
                                          style: SDTypography.bodyMedium,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedService = value ?? '';
                                  });
                                  _searchNearbyProviders(blocContext);
                                },
                              );
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
                                color: SDColors.neutral100,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.map,
                                        size: 64, color: SDColors.primary500),
                                    SizedBox(height: SDSpacing.sm),
                                    Text('Carte complète disponible sur mobile',
                                        style: SDTypography.titleMedium.copyWith(
                                          color: SDColors.primary500,
                                          fontWeight: FontWeight.bold,
                                        )),
                                    SizedBox(height: SDSpacing.xs),
                                    Text(
                                        'Utilisez l\'application mobile pour voir la carte complète',
                                        style: SDTypography.bodySmall.copyWith(
                                          color: SDColors.neutral500,
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
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 64, color: SDColors.error500),
                                  SizedBox(height: SDSpacing.sm),
                                  Text('Erreur de chargement de la carte',
                                      style: SDTypography.titleMedium.copyWith(
                                        color: SDColors.error500,
                                        fontWeight: FontWeight.bold,
                                      )),
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
                                size: 64, color: SDColors.neutral500),
                            SizedBox(height: SDSpacing.sm),
                            Text('Position non disponible',
                                style: SDTypography.titleMedium.copyWith(
                                  color: SDColors.neutral500,
                                )),
                            SizedBox(height: SDSpacing.xs),
                            Text(
                                'Activez la géolocalisation pour voir la carte',
                                style: SDTypography.bodySmall.copyWith(
                                  color: SDColors.neutral500,
                                )),
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
    );
  }
}
