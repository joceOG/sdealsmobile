import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import 'package:sdealsmobile/data/models/prestataire.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';
import 'package:sdealsmobile/data/utils/media_url.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/app_image.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageEventM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageStateM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/jobPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/services/custom_marker_service.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/utils/navigation_helper.dart';

/// Carte Métiers pour l’onglet Explorer : markers avatar+prix + mini-fiche Figma.
class ExplorerMetiersMapPanel extends StatefulWidget {
  const ExplorerMetiersMapPanel({super.key});

  @override
  State<ExplorerMetiersMapPanel> createState() =>
      _ExplorerMetiersMapPanelState();
}

class _ExplorerMetiersMapPanelState extends State<ExplorerMetiersMapPanel> {
  GoogleMapController? _mapController;
  LatLng? _userLocation;
  Set<Marker> _markers = {};
  Prestataire? _selected;
  double _mapZoom = 13;
  int _syncToken = 0;
  List<Prestataire> _lastProviders = const [];
  Map<String, double> _lastDistances = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initLocation();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (!mounted) return;
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
      context.read<JobPageBlocM>().add(LoadNearbyProvidersM(
            latitude: position.latitude,
            longitude: position.longitude,
            radius: context.read<JobPageBlocM>().state.searchRadius,
          ));
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, 13),
      );
    } catch (_) {}
  }

  Future<void> _syncMarkers(
    List<Prestataire> providers,
    Map<String, double> distances, {
    double? zoom,
  }) async {
    _mapZoom = zoom ?? _mapZoom;
    _lastProviders = providers;
    _lastDistances = distances;
    final token = ++_syncToken;
    final markers = <Marker>{};

    final withCoords = <Prestataire>[];
    for (final p in providers) {
      final lat = p.localisationMaps?.latitude;
      final lng = p.localisationMaps?.longitude;
      if (lat == null || lng == null || lat == 0 || lng == 0) continue;
      withCoords.add(p);
    }

    for (final p in withCoords.take(40)) {
      final icon = await _avatarIconFor(p);
      if (!mounted || token != _syncToken) return;
      markers.add(Marker(
        markerId: MarkerId(p.idprestataire),
        position: LatLng(
          p.localisationMaps!.latitude,
          p.localisationMaps!.longitude,
        ),
        icon: icon,
        onTap: () => setState(() => _selected = p),
      ));
    }

    if (!mounted || token != _syncToken) return;
    setState(() => _markers = markers);
  }

  Future<BitmapDescriptor> _avatarIconFor(Prestataire p) {
    final photo = providerPhotoUrl(
      selfie: p.selfie,
      photoProfil: p.utilisateur.photoProfil,
    );
    final name = _name(p);
    final initials = name.isNotEmpty
        ? name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((e) => e.isNotEmpty ? e[0] : '')
            .join()
        : '?';
    return CustomMarkerService.createAvatarPriceMarker(
      priceLabel: _price(p),
      initials: initials,
      photoUrl: photo,
      isVerified: p.verifier,
    );
  }

  String _name(Prestataire p) {
    final n = joinPersonName(
      prenom: p.utilisateur.prenom,
      nom: p.utilisateur.nom,
      fallback: 'Prestataire',
    );
    return n.isEmpty ? 'Prestataire' : n;
  }

  String _metier(Prestataire p) {
    final s = p.service.nomservice.trim();
    if (s.isNotEmpty && s != 'Service inconnu') return s;
    if (p.specialite != null && p.specialite!.isNotEmpty) {
      return p.specialite!.first;
    }
    return p.service.categorie?.nomcategorie ?? 'Prestataire';
  }

  String _price(Prestataire p) {
    final price = p.prixprestataire > 0
        ? p.prixprestataire
        : (p.tarifHoraireMin ?? 0);
    if (price <= 0) return '—';
    return NumberFormat('#,###', 'fr_FR')
        .format(price.round())
        .replaceAll(',', ' ');
  }

  String _rating(Prestataire p) {
    final n = double.tryParse('${p.note ?? ''}'.replaceAll(',', '.'));
    if (n == null || n <= 0) return '—';
    return n.toStringAsFixed(1).replaceAll('.', ',');
  }

  String? _distance(Prestataire p, Map<String, double> distances) {
    final d = distances[p.idprestataire];
    if (d == null) return null;
    return '${d.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  void _openFullMetiers() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<JobPageBlocM>(),
          child: const JobPageScreenM(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = _userLocation ?? const LatLng(5.3599, -4.0083);

    return BlocConsumer<JobPageBlocM, JobPageStateM>(
      listenWhen: (p, c) =>
          p.displayProviders != c.displayProviders ||
          p.providerDistances != c.providerDistances,
      listener: (context, state) {
        _syncMarkers(state.displayProviders, state.providerDistances);
      },
      builder: (context, state) {
        final providers = state.displayProviders;
        final sheetPad = _selected != null ? 200.0 : 88.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition:
                    CameraPosition(target: initial, zoom: 13),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                markers: _markers,
                onMapCreated: (c) {
                  _mapController = c;
                  if (_lastProviders.isEmpty && providers.isNotEmpty) {
                    _syncMarkers(providers, state.providerDistances);
                  }
                },
                onTap: (_) => setState(() => _selected = null),
                onCameraMove: (pos) => _mapZoom = pos.zoom,
                onCameraIdle: () {
                  _syncMarkers(
                    _lastProviders.isEmpty ? providers : _lastProviders,
                    _lastDistances.isEmpty
                        ? state.providerDistances
                        : _lastDistances,
                    zoom: _mapZoom,
                  );
                },
              ),
            ),
            Positioned(
              left: 12,
              bottom: sheetPad,
              child: Material(
                color: SDColors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: IconButton(
                  tooltip: 'Agrandir / Voir tout Métiers',
                  onPressed: _openFullMetiers,
                  icon: const Icon(Icons.open_in_full_rounded,
                      color: SDColors.neutral900, size: 22),
                ),
              ),
            ),
            Positioned(
              left: 68,
              bottom: sheetPad + 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: SDColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: SDColors.neutral900.withValues(alpha: 0.08),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  '• ${providers.length} professionnel${providers.length > 1 ? 's' : ''} à proximité',
                  style: SDTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: SDColors.neutral800,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: sheetPad,
              child: Material(
                color: SDColors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: IconButton(
                  tooltip: 'Recentrer',
                  onPressed: () {
                    if (_userLocation != null) {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(_userLocation!, 13),
                      );
                    }
                  },
                  icon: const Icon(Icons.my_location_outlined,
                      color: SDColors.neutral900),
                ),
              ),
            ),
            if (_selected != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _ExplorerMiniProviderCard(
                  provider: _selected!,
                  name: _name(_selected!),
                  metier: _metier(_selected!),
                  rating: _rating(_selected!),
                  distance: _distance(_selected!, state.providerDistances),
                  price: _price(_selected!),
                  photoUrl: providerPhotoUrl(
                    selfie: _selected!.selfie,
                    photoProfil: _selected!.utilisateur.photoProfil,
                  ),
                  onClose: () => setState(() => _selected = null),
                  onContact: () {
                    NavigationHelper.navigateToProviderProfile(
                      context,
                      providerId: _selected!.idprestataire,
                      providerData: _selected!.toJson(),
                    );
                  },
                  onProfile: () {
                    NavigationHelper.navigateToProviderProfile(
                      context,
                      providerId: _selected!.idprestataire,
                      providerData: _selected!.toJson(),
                    );
                  },
                ),
              ),
            if (state.isNearbyLoading || state.isMatchingLoading)
              const Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ExplorerMiniProviderCard extends StatelessWidget {
  final Prestataire provider;
  final String name;
  final String metier;
  final String rating;
  final String? distance;
  final String price;
  final String? photoUrl;
  final VoidCallback onClose;
  final VoidCallback onContact;
  final VoidCallback onProfile;

  const _ExplorerMiniProviderCard({
    required this.provider,
    required this.name,
    required this.metier,
    required this.rating,
    required this.distance,
    required this.price,
    required this.photoUrl,
    required this.onClose,
    required this.onContact,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    final priceText =
        price == '—' ? 'Sur devis' : 'À partir de $price FCFA/h';

    return Material(
      color: SDColors.white,
      elevation: 8,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: SDColors.primary600,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: AppImage(
                          imageUrl: photoUrl ?? '',
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          borderRadius: 32,
                        ),
                      ),
                    ),
                    if (provider.verifier)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: SDColors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified,
                              size: 16, color: SDColors.primary600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: SDTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: SDColors.neutral900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (provider.verifier) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified,
                                size: 16, color: SDColors.primary600),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        metier,
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.neutral600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '⭐ $rating',
                            style: SDTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (distance != null)
                            Text(
                              distance!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SDTypography.labelSmall.copyWith(
                                color: SDColors.neutral600,
                              ),
                            ),
                          Text(
                            'Disponible aujourd’hui',
                            style: SDTypography.labelSmall.copyWith(
                              color: SDColors.primary700,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        priceText,
                        style: SDTypography.labelMedium.copyWith(
                          color: SDColors.primary700,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded,
                      color: SDColors.neutral500, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onContact,
                    icon: const Icon(Icons.chat_bubble_outline_rounded,
                        size: 16),
                    label: const Text('Contacter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SDColors.primary700,
                      side: const BorderSide(color: SDColors.primary600),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SDColors.primary600,
                      foregroundColor: SDColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Voir profil'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
