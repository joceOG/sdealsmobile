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

    // Marqueur du prestataire avec prix
    final providerIcon =
        await CustomMarkerService.createProviderWithPriceMarker(
      name: _getProviderName(),
      category: widget.provider.categorie?.nomcategorie ?? '',
      service: widget.provider.service?.nomservice ?? '',
      price: _getProviderPrice(),
      isVerified: widget.provider.verifier == true,
      isUrgent: widget.provider.disponibilite == 'urgent' ||
          (widget.provider.note != null && widget.provider.note < 3.0),
    );

    markers.add(
      Marker(
        markerId: const MarkerId('provider'),
        position: providerPosition,
        icon: providerIcon,
        infoWindow: InfoWindow(
          title: widget.provider.utilisateur?.fullName ?? 'Prestataire',
          snippet: widget.provider.service?.nomservice ?? 'Service',
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

  String _getProviderName() {
    // Gérer différents formats de données utilisateur
    if (widget.provider.utilisateur != null) {
      // Format avec objet utilisateur
      final user = widget.provider.utilisateur;
      if (user is Map<String, dynamic>) {
        final nom = user['nom'] ?? '';
        final prenom = user['prenom'] ?? '';
        if (nom.isNotEmpty && prenom.isNotEmpty) {
          return '$nom $prenom';
        } else if (nom.isNotEmpty) {
          return nom;
        } else if (prenom.isNotEmpty) {
          return prenom;
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

    // Naviguer vers la full map
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullMapScreenM(
          initialPosition: providerPosition,
          providers: [widget.provider], // Liste avec le prestataire actuel
          searchRadius: 10.0,
          selectedCategory: widget.provider.categorie?.nomcategorie ?? '',
          selectedService: widget.provider.service?.nomservice ?? '',
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
          // En-tête de la section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Emplacement du prestataire',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Mini carte Google Maps
          Container(
            height: 200,
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

          const SizedBox(height: 12),

          // Informations de localisation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Adresse
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.home,
                        color: Colors.grey.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _address,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Distance
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.amber.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _distance,
                          style: TextStyle(
                            color: Colors.amber.shade800,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.amber.shade700,
                        size: 12,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Bouton "Obtenir l'itinéraire"
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _getDirections,
                    icon: const Icon(Icons.directions, color: Colors.white),
                    label: const Text(
                      'Obtenir l\'itinéraire',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
