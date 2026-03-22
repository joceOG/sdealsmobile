import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../locationpageblocm/locationPageBlocM.dart';
import '../locationpageblocm/locationPageEventM.dart';
import '../locationpageblocm/locationPageStateM.dart';
import '../../../../design_system/design_system.dart';

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
        appBar: SDWhiteAppBar.appBar(
          title: 'Gestion de la localisation',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
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
                  content: Text(state.error!, style: SDTypography.bodyMedium.copyWith(color: SDColors.white)),
                  backgroundColor: SDColors.error500,
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
          ? SDColors.success100
          : SDColors.warning100,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
      child: Padding(
        padding: EdgeInsets.all(SDSpacing.md),
        child: Row(
          children: [
            Icon(
              state.isLocationAvailable
                  ? Icons.location_on
                  : Icons.location_off,
              color: state.isLocationAvailable ? SDColors.success600 : SDColors.warning600,
              size: 32,
            ),
            SizedBox(width: SDSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.isLocationAvailable
                        ? 'Localisation activée'
                        : 'Localisation désactivée',
                    style: SDTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: state.isLocationAvailable
                          ? SDColors.success600
                          : SDColors.warning600,
                    ),
                  ),
                  SizedBox(height: SDSpacing.xxs),
                  Text(
                    state.isLocationAvailable
                        ? 'Votre position est partagée pour une meilleure expérience'
                        : 'Activez la localisation pour découvrir les services à proximité',
                    style: SDTypography.bodySmall.copyWith(color: SDColors.neutral600),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        side: BorderSide(color: SDColors.neutral200),
      ),
      child: Padding(
        padding: EdgeInsets.all(SDSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.map, color: SDColors.primary600),
                SizedBox(width: SDSpacing.xs),
                Text(
                  'Votre position actuelle',
                  style: SDTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: SDSpacing.md),
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                border: Border.all(color: SDColors.primary200, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        side: BorderSide(color: SDColors.neutral200),
      ),
      child: Padding(
        padding: EdgeInsets.all(SDSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: SDColors.info500),
                SizedBox(width: SDSpacing.xs),
                Text(
                  'Informations de localisation',
                  style: SDTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: SDSpacing.md),
            if (state.isLocationAvailable) ...[
              _buildInfoRow(
                  'Adresse', state.address ?? 'Non disponible', Icons.home),
              SizedBox(height: SDSpacing.xs),
              _buildInfoRow('Ville', state.currentCity ?? 'Non disponible',
                  Icons.location_city),
              SizedBox(height: SDSpacing.xs),
              _buildInfoRow(
                  'Coordonnées',
                  '${state.latitude?.toStringAsFixed(6)}, ${state.longitude?.toStringAsFixed(6)}',
                  Icons.gps_fixed),
            ] else ...[
              Text(
                'Activez la localisation pour voir vos informations de position',
                style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral500),
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
        Icon(icon, color: SDColors.neutral500, size: 20),
        SizedBox(width: SDSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: SDTypography.labelSmall.copyWith(
                  color: SDColors.neutral500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: SDTypography.bodyMedium.copyWith(
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        side: BorderSide(color: SDColors.neutral200),
      ),
      child: Padding(
        padding: EdgeInsets.all(SDSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: SDColors.primary600),
                SizedBox(width: SDSpacing.xs),
                Text(
                  'Actions de localisation',
                  style: SDTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: SDSpacing.md),
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
                      backgroundColor: SDColors.primary600,
                      foregroundColor: SDColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
                    ),
                  ),
                ),
                SizedBox(width: SDSpacing.xs),
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
                      backgroundColor: SDColors.info600,
                      foregroundColor: SDColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        side: BorderSide(color: SDColors.neutral200),
      ),
      child: Padding(
        padding: EdgeInsets.all(SDSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: SDColors.primary600),
                SizedBox(width: SDSpacing.xs),
                Text(
                  'Paramètres de localisation',
                  style: SDTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: SDSpacing.md),
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
              activeColor: SDColors.primary600,
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
