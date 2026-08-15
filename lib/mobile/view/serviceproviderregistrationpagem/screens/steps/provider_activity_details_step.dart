import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../design_system/design_system.dart';

/// Étape 2 Figma — zones d’intervention + position GPS.
class ProviderActivityDetailsStep extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onDataChanged;

  const ProviderActivityDetailsStep({
    Key? key,
    required this.formData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<ProviderActivityDetailsStep> createState() =>
      _ProviderActivityDetailsStepState();
}

class _ProviderActivityDetailsStepState
    extends State<ProviderActivityDetailsStep> {
  final TextEditingController _zoneSearchCtrl = TextEditingController();
  List<String> _selectedAreas = [];
  LatLng? _selectedPosition;
  String? _selectedAddress;
  bool _isLoadingLocation = false;
  GoogleMapController? _mapController;

  static const _availableAreas = [
    'Abidjan',
    'Abobo',
    'Adjamé',
    'Attécoubé',
    'Cocody',
    'Koumassi',
    'Marcory',
    'Plateau',
    'Port-Bouët',
    'Treichville',
    'Yopougon',
    'Bingerville',
    'Riviera',
    'Yamoussoukro',
    'Bouaké',
    'Daloa',
    'San Pedro',
    'Korhogo',
    'Anyama',
    'Divo',
  ];

  @override
  void initState() {
    super.initState();
    _selectedAreas =
        List<String>.from(widget.formData['serviceAreas'] ?? <String>[]);
    if (widget.formData['position'] != null) {
      _selectedPosition = widget.formData['position'] as LatLng;
      _selectedAddress = widget.formData['address'];
    }
  }

  @override
  void dispose() {
    _zoneSearchCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _sync() {
    widget.onDataChanged({
      'serviceAreas': List<String>.from(_selectedAreas),
      'position': _selectedPosition,
      'address': _selectedAddress,
    });
  }

  List<String> get _filteredAreas {
    final q = _zoneSearchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _availableAreas;
    return _availableAreas
        .where((z) => z.toLowerCase().contains(q))
        .toList();
  }

  void _toggleZone(String zone) {
    setState(() {
      if (_selectedAreas.contains(zone)) {
        _selectedAreas.remove(zone);
      } else {
        _selectedAreas.add(zone);
      }
    });
    _sync();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission de localisation refusée')),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedPosition = latLng;
        _selectedAddress = 'Position actuelle';
        _isLoadingLocation = false;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));
      _sync();
    } catch (_) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Impossible de récupérer la position')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = _selectedPosition ?? const LatLng(5.3599, -4.0083);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zones d’intervention *',
          style: SDTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: SDColors.neutral900,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _zoneSearchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Rechercher une zone',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: SDColors.neutral50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: SDColors.neutral200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: SDColors.neutral200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: SDColors.primary600),
            ),
          ),
        ),
        if (_selectedAreas.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Zones sélectionnées',
            style: SDTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: SDColors.neutral700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedAreas
                .map(
                  (z) => InputChip(
                    label: Text(z),
                    selected: true,
                    onDeleted: () => _toggleZone(z),
                    deleteIconColor: SDColors.primary700,
                    selectedColor: SDColors.primary50,
                    labelStyle: SDTypography.labelSmall.copyWith(
                      color: SDColors.primary800,
                      fontWeight: FontWeight.w700,
                    ),
                    side: const BorderSide(color: SDColors.primary300),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _filteredAreas
              .where((z) => !_selectedAreas.contains(z))
              .take(12)
              .map(
                (z) => ActionChip(
                  label: Text('+ $z'),
                  onPressed: () => _toggleZone(z),
                  backgroundColor: SDColors.white,
                  side: BorderSide(
                    color: SDColors.neutral300,
                    style: BorderStyle.solid,
                  ),
                  labelStyle: SDTypography.labelSmall.copyWith(
                    color: SDColors.neutral700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            final q = _zoneSearchCtrl.text.trim();
            if (q.isEmpty) return;
            final match = _availableAreas.firstWhere(
              (z) => z.toLowerCase() == q.toLowerCase(),
              orElse: () => q,
            );
            if (!_selectedAreas.contains(match)) {
              setState(() => _selectedAreas.add(match));
              _sync();
              _zoneSearchCtrl.clear();
              setState(() {});
            }
          },
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Ajouter une zone'),
          style: OutlinedButton.styleFrom(
            foregroundColor: SDColors.primary700,
            side: BorderSide(
              color: SDColors.primary300,
              width: 1.2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Position GPS (recommandée)',
          style: SDTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: SDColors.neutral900,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 180,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: initial, zoom: 12),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              markers: _selectedPosition == null
                  ? {}
                  : {
                      Marker(
                        markerId: const MarkerId('provider'),
                        position: _selectedPosition!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen,
                        ),
                      ),
                    },
              onMapCreated: (c) => _mapController = c,
              onTap: (pos) {
                setState(() {
                  _selectedPosition = pos;
                  _selectedAddress = 'Position choisie sur la carte';
                });
                _sync();
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoadingLocation ? null : _getCurrentLocation,
            icon: _isLoadingLocation
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_outlined),
            label: Text(
              _isLoadingLocation
                  ? 'Récupération…'
                  : 'Utiliser ma position actuelle',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: SDColors.primary700,
              side: const BorderSide(color: SDColors.primary600),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SDColors.primary50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SDColors.primary100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined,
                  color: SDColors.primary700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Votre position exacte reste confidentielle. Seule votre zone d’intervention est visible des clients.',
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.primary800,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
