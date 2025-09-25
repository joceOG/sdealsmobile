import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../locationpageblocm/locationPageBlocM.dart';
import '../locationpageblocm/locationPageEventM.dart';
import '../locationpageblocm/locationPageStateM.dart';

class LocationPageScreenM extends StatefulWidget {
  const LocationPageScreenM({Key? key}) : super(key: key);

  @override
  State<LocationPageScreenM> createState() => _LocationPageScreenMState();
}

class _LocationPageScreenMState extends State<LocationPageScreenM> {
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    // Charger la position actuelle au démarrage
    context.read<LocationPageBlocM>().add(const GetCurrentLocationM());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LocationPageBlocM(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestion de la localisation'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context
                    .read<LocationPageBlocM>()
                    .add(const GetCurrentLocationM());
              },
            ),
          ],
        ),
        body: BlocConsumer<LocationPageBlocM, LocationPageStateM>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec statut
                  _buildStatusCard(state),

                  const SizedBox(height: 20),

                  // Carte Google Maps
                  if (state.isLocationAvailable) ...[
                    _buildMapCard(state),
                    const SizedBox(height: 20),
                  ],

                  // Informations de localisation
                  _buildLocationInfoCard(state),

                  const SizedBox(height: 20),

                  // Actions de localisation
                  _buildActionsCard(state),

                  const SizedBox(height: 20),

                  // Paramètres de localisation
                  _buildSettingsCard(state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusCard(LocationPageStateM state) {
    return Card(
      color: state.isLocationAvailable
          ? Colors.green.shade50
          : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              state.isLocationAvailable
                  ? Icons.location_on
                  : Icons.location_off,
              color: state.isLocationAvailable ? Colors.green : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.isLocationAvailable
                        ? 'Localisation activée'
                        : 'Localisation désactivée',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: state.isLocationAvailable
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.isLocationAvailable
                        ? 'Votre position est partagée pour une meilleure expérience'
                        : 'Activez la localisation pour découvrir les services à proximité',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCard(LocationPageStateM state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.map, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Votre position actuelle',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(state.latitude!, state.longitude!),
                    zoom: 15.0,
                  ),
                  markers: _markers,
                  onMapCreated: (GoogleMapController controller) {
                    _updateMarkers(state);
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfoCard(LocationPageStateM state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Informations de localisation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.isLocationAvailable) ...[
              _buildInfoRow(
                  'Adresse', state.address ?? 'Non disponible', Icons.home),
              const SizedBox(height: 8),
              _buildInfoRow('Ville', state.currentCity ?? 'Non disponible',
                  Icons.location_city),
              const SizedBox(height: 8),
              _buildInfoRow(
                  'Coordonnées',
                  '${state.latitude?.toStringAsFixed(6)}, ${state.longitude?.toStringAsFixed(6)}',
                  Icons.gps_fixed),
            ] else ...[
              const Text(
                'Activez la localisation pour voir vos informations de position',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionsCard(LocationPageStateM state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Actions de localisation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<LocationPageBlocM>()
                          .add(const GetCurrentLocationM());
                    },
                    icon: const Icon(Icons.my_location),
                    label: const Text('Ma position'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<LocationPageBlocM>()
                          .add(const RequestLocationPermissionM());
                    },
                    icon: const Icon(Icons.security),
                    label: const Text('Permissions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(LocationPageStateM state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Paramètres de localisation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Partager ma localisation'),
              subtitle: const Text(
                  'Permettre l\'accès à votre position pour les services'),
              value: state.isLocationEnabled,
              onChanged: (value) {
                context
                    .read<LocationPageBlocM>()
                    .add(const ToggleLocationServiceM());
              },
              activeColor: Colors.green,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Pourquoi partager ma localisation ?'),
              subtitle: const Text(
                  'Découvrir les services à proximité, obtenir des recommandations personnalisées'),
              onTap: () {
                _showLocationHelpDialog();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Confidentialité'),
              subtitle: const Text(
                  'Vos données de localisation sont sécurisées et privées'),
              onTap: () {
                _showPrivacyDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateMarkers(LocationPageStateM state) {
    if (state.isLocationAvailable) {
      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('user_location'),
            position: LatLng(state.latitude!, state.longitude!),
            infoWindow: const InfoWindow(
              title: 'Votre position',
              snippet: 'Position actuelle',
            ),
          ),
        };
      });
    }
  }

  void _showLocationHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pourquoi partager ma localisation ?'),
        content: const Text(
          '• Découvrir les services et prestataires à proximité\n'
          '• Recevoir des recommandations personnalisées\n'
          '• Calculer les distances et temps de trajet\n'
          '• Améliorer votre expérience utilisateur\n\n'
          'Vos données sont sécurisées et ne sont jamais partagées avec des tiers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confidentialité de la localisation'),
        content: const Text(
          '🔒 Vos données de localisation sont :\n\n'
          '• Chiffrées et sécurisées\n'
          '• Stockées localement sur votre appareil\n'
          '• Utilisées uniquement pour améliorer votre expérience\n'
          '• Jamais vendues ou partagées avec des tiers\n\n'
          'Vous pouvez désactiver la localisation à tout moment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
