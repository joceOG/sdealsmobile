import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../locationpageblocm/locationPageBlocM.dart';
import '../locationpageblocm/locationPageEventM.dart';
import '../locationpageblocm/locationPageStateM.dart';
import '../../../../design_system/design_system.dart';

/// Localisation — maquette Figma, sans adresses sauvegardées ni rayon inventés.
class LocationPageScreenM extends StatefulWidget {
  const LocationPageScreenM({Key? key}) : super(key: key);

  @override
  State<LocationPageScreenM> createState() => _LocationPageScreenMState();
}

class _LocationPageScreenMState extends State<LocationPageScreenM> {
  static const double _hPad = 20;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    context.read<LocationPageBlocM>().add(const GetCurrentLocationM());
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.neutral50,
      body: SafeArea(
        child: BlocConsumer<LocationPageBlocM, LocationPageStateM>(
          listener: (context, state) {
            if (state.error != null && state.error!.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.error!,
                    style: SDTypography.bodyMedium
                        .copyWith(color: SDColors.white),
                  ),
                  backgroundColor: SDColors.error500,
                ),
              );
            }
            _syncMarkers(state);
          },
          builder: (context, state) {
            final placeLabel = _placeLabel(state);

            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, _hPad, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: SDColors.neutral900,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(_hPad, 4, _hPad, 8),
                  child: Text(
                    'Localisation',
                    style: SDTypography.displayMedium.copyWith(
                      color: SDColors.neutral900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 16),
                  child: Text(
                    state.isLocationAvailable
                        ? 'Votre position sert à afficher les services à proximité.'
                        : 'Activez la localisation pour découvrir les services autour de vous.',
                    style: SDTypography.bodyMedium
                        .copyWith(color: SDColors.neutral600),
                  ),
                ),
                if (state.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: SDColors.primary600,
                      ),
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _hPad),
                    child: _buildLocationCard(state, placeLabel),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _hPad),
                    child: _buildPermissionRow(state),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _hPad),
                    child: TextButton.icon(
                      onPressed: () {
                        context
                            .read<LocationPageBlocM>()
                            .add(const GetCurrentLocationM());
                      },
                      icon: const Icon(Icons.my_location_outlined, size: 18),
                      label: const Text('Actualiser ma position'),
                      style: TextButton.styleFrom(
                        foregroundColor: SDColors.primary700,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  String _placeLabel(LocationPageStateM state) {
    if (!state.isLocationAvailable) return 'Position indisponible';
    final city = state.currentCity?.trim();
    if (city != null && city.isNotEmpty) return city;
    final address = state.address?.trim();
    if (address != null && address.isNotEmpty) return address;
    return 'Position actuelle';
  }

  Widget _buildLocationCard(LocationPageStateM state, String placeLabel) {
    return Container(
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SDColors.neutral200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: state.isLocationAvailable
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(state.latitude!, state.longitude!),
                      zoom: 15,
                    ),
                    markers: _markers,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _syncMarkers(state);
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
                  )
                : Container(
                    color: SDColors.neutral100,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_off_outlined,
                          size: 40,
                          color: SDColors.neutral400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Carte indisponible',
                          style: SDTypography.bodyMedium.copyWith(
                            color: SDColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: SDColors.primary600,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        placeLabel,
                        style: SDTypography.bodyLarge.copyWith(
                          color: SDColors.neutral900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Position actuelle',
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: state.isLocationEnabled,
                  onChanged: (_) {
                    context
                        .read<LocationPageBlocM>()
                        .add(const ToggleLocationServiceM());
                  },
                  activeThumbColor: SDColors.white,
                  activeTrackColor: SDColors.primary600,
                  inactiveThumbColor: SDColors.white,
                  inactiveTrackColor: SDColors.neutral300,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(LocationPageStateM state) {
    final enabled = state.isLocationAvailable || state.isLocationEnabled;
    return Material(
      color: SDColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          context
              .read<LocationPageBlocM>()
              .add(const RequestLocationPermissionM());
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SDColors.neutral200),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: SDColors.primary600,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Autorisation de localisation',
                  style: SDTypography.bodyLarge.copyWith(
                    color: SDColors.neutral900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                enabled ? 'Activée' : 'Désactivée',
                style: SDTypography.labelMedium.copyWith(
                  color: enabled ? SDColors.primary700 : SDColors.neutral500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                color: SDColors.neutral400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _syncMarkers(LocationPageStateM state) {
    if (!state.isLocationAvailable ||
        state.latitude == null ||
        state.longitude == null) {
      return;
    }
    final target = LatLng(state.latitude!, state.longitude!);
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('current'),
          position: target,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      };
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(target));
  }
}
