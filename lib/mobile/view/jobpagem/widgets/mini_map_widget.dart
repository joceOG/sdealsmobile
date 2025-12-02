import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/custom_marker_service.dart';
import '../screens/fullMapScreenM.dart';

class MiniMapWidget extends StatefulWidget {
  final dynamic provider;
  final LatLng? userLocation;

  const MiniMapWidget({
    Key? key,
    required this.provider,
    this.userLocation,
  }) : super(key: key);

  @override
  State<MiniMapWidget> createState() => _MiniMapWidgetState();
}

class _MiniMapWidgetState extends State<MiniMapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  String _distance = '';
  String _address = 'Adresse non disponible';

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    // Position du prestataire (simulée pour la démo)
    final providerLat = 5.3599 + (widget.provider.hashCode % 100) * 0.001;
    final providerLng = -4.0083 + (widget.provider.hashCode % 100) * 0.001;
    final providerPosition = LatLng(providerLat, providerLng);

    // Calculer la distance si position utilisateur disponible
    if (widget.userLocation != null) {
      final distance = Geolocator.distanceBetween(
        widget.userLocation!.latitude,
        widget.userLocation!.longitude,
        providerLat,
        providerLng,
      );
      _distance = '${distance.toInt()} m de votre emplacement actuel';
    } else {
      _distance = 'Distance non calculée';
    }

    // Créer les marqueurs
    _createMarkers(providerPosition);
  }

  Future<void> _createMarkers(LatLng providerPosition) async {
    final markers = <Marker>{};

    // Marqueur de l'utilisateur (si disponible)
    if (widget.userLocation != null) {
      final userIcon = await CustomMarkerService.createUserMarker();
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: widget.userLocation!,
          icon: userIcon,
          infoWindow: const InfoWindow(title: 'Votre position'),
        ),
      );
    }

    // Récupérer les données de façon sécurisée
    final categorie = _getProviderProperty('categorie');
    final service = _getProviderProperty('service');
    final verifier = _getProviderProperty('verifier');
    final disponibilite = _getProviderProperty('disponibilite');
    final note = _getProviderProperty('note');
    
    String categoryName = '';
    if (categorie is Map<String, dynamic>) {
      categoryName = categorie['nomcategorie']?.toString() ?? '';
    } else if (categorie != null) {
      try {
        categoryName = categorie.nomcategorie ?? '';
      } catch (e) {
        // Ignore
      }
    }
    
    String serviceName = '';
    if (service is Map<String, dynamic>) {
      serviceName = service['nomservice']?.toString() ?? '';
    } else if (service != null) {
      try {
        serviceName = service.nomservice ?? '';
      } catch (e) {
        // Ignore
      }
    }

    // Marqueur du prestataire avec prix
    final providerIcon =
        await CustomMarkerService.createProviderWithPriceMarker(
      name: _getProviderName(),
      category: categoryName,
      service: serviceName,
      price: _getProviderPrice(),
      isVerified: verifier == true,
      isUrgent: disponibilite == 'urgent' ||
          (note != null && note is num && note < 3.0),
    );

    markers.add(
      Marker(
        markerId: const MarkerId('provider'),
        position: providerPosition,
        icon: providerIcon,
        infoWindow: InfoWindow(
          title: _getProviderName(),
          snippet: serviceName.isNotEmpty ? serviceName : 'Service',
        ),
      ),
    );

    setState(() {
      _markers = markers;
    });
  }

  String _getProviderPrice() {
    // Générer un prix aléatoire pour la démo
    final prices = [
      '5 000 F CFA',
      '8 000 F CFA',
      '12 000 F CFA',
      '15 000 F CFA',
      '20 000 F CFA',
      '25 000 F CFA',
    ];
    return prices[widget.provider.hashCode % prices.length];
  }

  // ✅ Helper pour accéder aux propriétés de façon universelle (Map ou Objet)
  dynamic _getProviderProperty(String key) {
    if (widget.provider == null) return null;
    
    // Si c'est un Map
    if (widget.provider is Map<String, dynamic>) {
      return widget.provider[key];
    }
    
    // Si c'est un objet avec propriétés
    try {
      switch (key) {
        case 'utilisateur':
          return widget.provider.utilisateur;
        case 'categorie':
          return widget.provider.categorie;
        case 'service':
          return widget.provider.service;
        case 'verifier':
          return widget.provider.verifier;
        case 'disponibilite':
          return widget.provider.disponibilite;
        case 'note':
          return widget.provider.note;
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  String _getProviderName() {
    // Récupérer l'utilisateur de façon sécurisée
    final utilisateur = _getProviderProperty('utilisateur');
    
    if (utilisateur != null) {
      // Si utilisateur est un Map
      if (utilisateur is Map<String, dynamic>) {
        final nom = utilisateur['nom']?.toString() ?? '';
        final prenom = utilisateur['prenom']?.toString() ?? '';
        
        if (nom.isNotEmpty && prenom.isNotEmpty) {
          return '$nom $prenom';
        } else if (nom.isNotEmpty) {
          return nom;
        } else if (prenom.isNotEmpty) {
          return prenom;
        }
        
        // Essayer fullName
        final fullName = utilisateur['fullName']?.toString() ?? '';
        if (fullName.isNotEmpty) {
          return fullName;
        }
      } else {
        // Si utilisateur est un objet
        try {
          final fullName = utilisateur.fullName ?? '';
          if (fullName.isNotEmpty) return fullName;
          
          final nom = utilisateur.nom ?? '';
          final prenom = utilisateur.prenom ?? '';
          if (nom.isNotEmpty && prenom.isNotEmpty) {
            return '$nom $prenom';
          } else if (nom.isNotEmpty) {
            return nom;
          } else if (prenom.isNotEmpty) {
            return prenom;
          }
        } catch (e) {
          // Ignore
        }
      }
    }

    // Fallback
    return 'Prestataire';
  }

  Future<void> _getDirections() async {
    // Position du prestataire
    final providerLat = 5.3599 + (widget.provider.hashCode % 100) * 0.001;
    final providerLng = -4.0083 + (widget.provider.hashCode % 100) * 0.001;

    // Ouvrir Google Maps avec l'itinéraire
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$providerLat,$providerLng';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir l\'itinéraire')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _openFullMap() {
    // Position du prestataire
    final providerLat = 5.3599 + (widget.provider.hashCode % 100) * 0.001;
    final providerLng = -4.0083 + (widget.provider.hashCode % 100) * 0.001;
    final providerPosition = LatLng(providerLat, providerLng);

    // Récupérer les données de façon sécurisée
    final categorie = _getProviderProperty('categorie');
    final service = _getProviderProperty('service');
    
    String categoryName = '';
    if (categorie is Map<String, dynamic>) {
      categoryName = categorie['nomcategorie']?.toString() ?? '';
    } else if (categorie != null) {
      try {
        categoryName = categorie.nomcategorie ?? '';
      } catch (e) {
        // Ignore
      }
    }
    
    String serviceName = '';
    if (service is Map<String, dynamic>) {
      serviceName = service['nomservice']?.toString() ?? '';
    } else if (service != null) {
      try {
        serviceName = service.nomservice ?? '';
      } catch (e) {
        // Ignore
      }
    }

    // Naviguer vers la full map
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullMapScreenM(
          initialPosition: providerPosition,
          providers: [widget.provider], // Liste avec le prestataire actuel
          searchRadius: 10.0,
          selectedCategory: categoryName,
          selectedService: serviceName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mini carte Google Maps (adaptative avec Expanded)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        5.3599 + (widget.provider.hashCode % 100) * 0.001,
                        -4.0083 + (widget.provider.hashCode % 100) * 0.001,
                      ),
                      zoom: 15.0,
                    ),
                    markers: _markers,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    mapToolbarEnabled: false,
                    zoomGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                  ),

                  // Bouton plein écran (fullscreen)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _openFullMap,
                        icon: const Icon(
                          Icons.fullscreen,
                          color: Colors.green,
                          size: 20,
                        ),
                        tooltip: 'Voir la carte complète',
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),

          const SizedBox(height: 4),

          // Informations de localisation compactes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.amber.shade700,
                    size: 11,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _distance,
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
