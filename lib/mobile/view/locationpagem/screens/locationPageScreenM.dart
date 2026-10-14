import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../design_system/design_system.dart';
import '../locationpageblocm/locationPageBlocM.dart';
import '../locationpageblocm/locationPageEventM.dart';
import '../locationpageblocm/locationPageStateM.dart';

/// Choisir ma localisation — recherche manuelle toujours accessible.
class LocationPageScreenM extends StatefulWidget {
  const LocationPageScreenM({super.key});

  @override
  State<LocationPageScreenM> createState() => _LocationPageScreenMState();
}

class _LocationPageScreenMState extends State<LocationPageScreenM> {
  static const double _hPad = 20;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _pickingOnMap = false;
  GoogleMapController? _mapController;
  LatLng _mapTarget = const LatLng(
    SDClientLocationPolicy.fallbackLatitude,
    SDClientLocationPolicy.fallbackLongitude,
  );
  bool _mapMoving = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<LocationPageBlocM>().add(SearchLocationQueryM(value));
    });
  }

  void _confirm(LocationSuggestion? selected) {
    if (selected == null) return;
    Navigator.of(context).pop(selected);
  }

  void _openMap(LocationPageStateM state) {
    final selected = state.selected;
    setState(() {
      _pickingOnMap = true;
      _mapTarget = LatLng(
        selected?.latitude ?? SDClientLocationPolicy.fallbackLatitude,
        selected?.longitude ?? SDClientLocationPolicy.fallbackLongitude,
      );
    });
  }

  void _closeMap() {
    setState(() => _pickingOnMap = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      body: SafeArea(
        child: BlocConsumer<LocationPageBlocM, LocationPageStateM>(
          listener: (context, state) {
            if (state.error != null && state.error!.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.error!,
                    style:
                        SDTypography.bodyMedium.copyWith(color: SDColors.white),
                  ),
                  backgroundColor: SDColors.error500,
                ),
              );
            }
            if (_pickingOnMap &&
                !_mapMoving &&
                state.selected != null &&
                !state.isLocating) {
              final target = LatLng(
                state.selected!.latitude,
                state.selected!.longitude,
              );
              if ((target.latitude - _mapTarget.latitude).abs() > 0.0005 ||
                  (target.longitude - _mapTarget.longitude).abs() > 0.0005) {
                _mapTarget = target;
                _mapController?.animateCamera(CameraUpdate.newLatLng(target));
              }
            }
          },
          builder: (context, state) {
            if (_pickingOnMap) return _buildMapPicker(state);
            return _buildSearchPicker(state);
          },
        ),
      ),
    );
  }

  Widget _buildSearchPicker(LocationPageStateM state) {
    final selected = state.selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopBar(onBack: () => Navigator.of(context).maybePop()),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 16),
            children: [
              Text(
                'Où recherchez-vous ?',
                style: SDTypography.displaySmall.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choisissez une commune ou un quartier.',
                style: SDTypography.bodyMedium.copyWith(
                  color: SDColors.neutral500,
                ),
              ),
              const SizedBox(height: 16),
              _buildSearchField(
                hint: 'Rechercher une commune',
                onChanged: (value) {
                  setState(() {});
                  _onQueryChanged(value);
                },
              ),
              const SizedBox(height: 12),
              _actionRow(
                icon: Icons.my_location,
                iconBackground: SDColors.primary50,
                title: 'Utiliser ma position actuelle',
                subtitle: state.isLocating
                    ? 'Recherche de votre position…'
                    : 'Avec votre autorisation',
                trailing: state.isLocating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: SDColors.primary600,
                        ),
                      )
                    : const Icon(Icons.chevron_right,
                        color: SDColors.neutral400),
                onTap: state.isLocating
                    ? null
                    : () => context
                        .read<LocationPageBlocM>()
                        .add(const GetCurrentLocationM()),
              ),
              if (state.gpsHint != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.gpsHint!,
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral600,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              _actionRow(
                icon: Icons.map_outlined,
                iconBackground: SDColors.neutral100,
                title: 'Choisir sur la carte',
                onTap: () => _openMap(state),
              ),
              if (state.isSearching) ...[
                const SizedBox(height: 24),
                const Center(
                  child: CircularProgressIndicator(color: SDColors.primary600),
                ),
              ] else if (state.suggestions.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Résultats de recherche',
                  style: SDTypography.titleSmall.copyWith(
                    color: SDColors.neutral900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...state.suggestions.map(
                  (item) => _resultTile(
                    item,
                    selected: selected == item,
                    onTap: () => context
                        .read<LocationPageBlocM>()
                        .add(SelectLocationSuggestionM(item)),
                  ),
                ),
              ] else if (state.query.trim().length >= 2) ...[
                const SizedBox(height: 20),
                Text(
                  'Aucun lieu trouvé pour cette recherche.',
                  style: SDTypography.bodyMedium.copyWith(
                    color: SDColors.neutral600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: SDColors.neutral500,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cette zone servira à vos recherches.',
                      style: SDTypography.bodySmall.copyWith(
                        color: SDColors.neutral500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zone sélectionnée',
                style: SDTypography.bodySmall.copyWith(
                  color: SDColors.neutral500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                selected?.zoneLabel ?? SDClientLocationPolicy.fallbackCity,
                style: SDTypography.titleMedium.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              SDButton(
                text: 'Confirmer la localisation',
                fullWidth: true,
                onPressed: selected == null ? null : () => _confirm(selected),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapPicker(LocationPageStateM state) {
    final selected = state.selected;
    return Column(
      children: [
        _buildTopBar(onBack: _closeMap),
        Padding(
          padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 8),
          child: _buildSearchField(
            hint: 'Rechercher une commune',
            readOnly: true,
            onTap: _closeMap,
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _mapTarget,
                  zoom: 13,
                ),
                onMapCreated: (controller) => _mapController = controller,
                onCameraMove: (position) {
                  _mapMoving = true;
                  _mapTarget = position.target;
                },
                onCameraIdle: () {
                  _mapMoving = false;
                  context.read<LocationPageBlocM>().add(
                        ReverseGeocodeLocationM(
                          latitude: _mapTarget.latitude,
                          longitude: _mapTarget.longitude,
                        ),
                      );
                },
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
              ),
              const IgnorePointer(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 28),
                    child: Icon(
                      Icons.location_on,
                      size: 48,
                      color: SDColors.primary600,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 24,
                right: 24,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: SDColors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: SDColors.neutral900.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Déplacez la carte pour choisir',
                      style: SDTypography.labelMedium.copyWith(
                        color: SDColors.neutral800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: Material(
                  color: SDColors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: IconButton(
                    tooltip: 'Utiliser ma position actuelle',
                    onPressed: state.isLocating
                        ? null
                        : () => context
                            .read<LocationPageBlocM>()
                            .add(const GetCurrentLocationM()),
                    icon: state.isLocating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location,
                            color: SDColors.neutral800),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(_hPad, 16, _hPad, 16),
          decoration: const BoxDecoration(
            color: SDColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: SDColors.primary600),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected?.title ??
                              SDClientLocationPolicy.fallbackCity,
                          style: SDTypography.titleMedium.copyWith(
                            color: SDColors.neutral900,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          selected?.subtitle ?? "Côte d'Ivoire",
                          style: SDTypography.bodySmall.copyWith(
                            color: SDColors.neutral500,
                          ),
                        ),
                        Text(
                          'Position choisie sur la carte',
                          style: SDTypography.bodySmall.copyWith(
                            color: SDColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SDButton(
                text: 'Confirmer cette position',
                fullWidth: true,
                onPressed: selected == null ? null : () => _confirm(selected),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar({required VoidCallback onBack}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: SDColors.neutral900),
            tooltip: 'Retour',
          ),
          Expanded(
            child: Text(
              'Ma localisation',
              style: SDTypography.titleLarge.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField({
    required String hint,
    ValueChanged<String>? onChanged,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return TextField(
      controller: _searchController,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral900),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: SDTypography.bodyMedium.copyWith(color: SDColors.neutral500),
        prefixIcon: const Icon(Icons.search, color: SDColors.neutral500),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Effacer',
                onPressed: () {
                  _searchController.clear();
                  context
                      .read<LocationPageBlocM>()
                      .add(const SearchLocationQueryM(''));
                  setState(() {});
                },
                icon: const Icon(Icons.close, color: SDColors.neutral500),
              ),
        filled: true,
        fillColor: SDColors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: SDColors.neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: SDColors.primary600),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: SDColors.neutral200),
        ),
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required Color iconBackground,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: subtitle != null ? SDColors.primary50 : SDColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  subtitle != null ? SDColors.primary100 : SDColors.neutral200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: SDColors.primary700, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: SDTypography.bodyLarge.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.neutral600,
                        ),
                      ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(Icons.chevron_right, color: SDColors.neutral400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultTile(
    LocationSuggestion item, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? SDColors.primary50 : SDColors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? SDColors.primary200 : SDColors.neutral200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? SDColors.primary600 : SDColors.neutral400,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: SDTypography.bodyLarge.copyWith(
                          color: SDColors.neutral900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        item.subtitle,
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
