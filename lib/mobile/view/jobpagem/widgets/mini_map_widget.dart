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
    final providerPosition = _resolveProviderLatLng();
    if (providerPosition == null) {
      _distance = 'Position GPS du prestataire indisponible';
      return;
    }

    if (widget.userLocation != null) {
      final distance = Geolocator.distanceBetween(
        widget.userLocation!.latitude,
        widget.userLocation!.longitude,
        providerPosition.latitude,
        providerPosition.longitude,
      );
      if (distance < 1000) {
        _distance = '${distance.toInt()} m de votre emplacement';
      } else {
        _distance =
            '${(distance / 1000).toStringAsFixed(1)} km de votre emplacement';
      }
    } else {
      _distance = 'Activez la localisation pour voir la distance';
    }

    _createMarkers(providerPosition);
  }

  /// Coordonnées réelles depuis localisationmaps (API), pas de position factice.
  LatLng? _resolveProviderLatLng() {
    final maps = _getProviderProperty('localisationmaps') ??
        _getProviderProperty('localisationMaps');
    double? lat;
    double? lng;
    if (maps is Map) {
      lat = _toDouble(maps['latitude'] ?? maps['lat']);
      lng = _toDouble(maps['longitude'] ?? maps['lng'] ?? maps['lon']);
    } else if (maps != null) {
      try {
        lat = _toDouble(maps.latitude);
        lng = _toDouble(maps.longitude);
      } catch (_) {}
    }
    if (lat == null || lng == null) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    return LatLng(lat, lng);
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.').trim());
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
    final raw = _getProviderProperty('prixprestataire');
    final amount = _toDouble(raw);
    if (amount != null && amount > 0) {
      return '${amount.toStringAsFixed(0)} F CFA';
    }
    return 'Sur devis';
  }

  // ✅ Helper pour accéder aux propriétés de façon universelle (Map ou Objet)
  dynamic _getProviderProperty(String key) {
    if (widget.provider == null) return null;
    
    // Si c'est un Map
    if (widget.provider is Map) {
      final map = Map<String, dynamic>.from(widget.provider as Map);
      if (map.containsKey(key)) return map[key];
      if (key == 'localisationmaps') return map['localisationMaps'];
      if (key == 'localisationMaps') return map['localisationmaps'];
      return null;
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
        case 'localisationmaps':
        case 'localisationMaps':
          return widget.provider.localisationMaps;
        case 'prixprestataire':
          return widget.provider.prixprestataire;
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
    final pos = _resolveProviderLatLng();
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Position du prestataire indisponible')),
      );
      return;
    }

    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${pos.latitude},${pos.longitude}';

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
    final providerPosition = _resolveProviderLatLng();
    if (providerPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Position du prestataire indisponible')),
      );
      return;
    }

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
    final providerPosition = _resolveProviderLatLng();

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
              border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: providerPosition == null
                  ? Container(
                      color: const Color(0xFFF5F5F5),
                      alignment: Alignment.center,
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Carte indisponible\n(GPS prestataire manquant)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF171717),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  : Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: providerPosition,
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
                          color: Color(0xFF171717),
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
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFF171717),
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _distance,
                      style: const TextStyle(
                        color: Color(0xFF171717),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
