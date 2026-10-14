import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:sdealsmobile/data/models/prestataire.dart';
import 'package:sdealsmobile/data/services/protected_action_intent.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';
import 'package:sdealsmobile/data/utils/media_url.dart';
import 'package:sdealsmobile/mobile/view/common/auth_completion.dart';
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
  String? _markerLayoutKey;

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
      // 10D-3 : pas de demande GPS au chargement d'Explorer.
      final permission = await Geolocator.checkPermission();
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
    final z = zoom ?? _mapZoom;
    _mapZoom = z;
    _lastProviders = providers;
    _lastDistances = distances;
    final withCoords = _withCoords(providers);
    final layoutKey = _layoutKey(withCoords, z);
    if (layoutKey == _markerLayoutKey && _markers.isNotEmpty) return;
    final token = ++_syncToken;
    final markers = <Marker>{};

    // Même règle que Métiers : zoom éloigné → clusters ; zoom proche → avatar + prix.
    final useClusters = z < 12.5 && withCoords.length > 8;
    if (useClusters) {
      for (final c in _buildClusters(withCoords, z)) {
        if (c.members.length == 1) {
          final p = c.members.first;
          final icon = await _avatarIconFor(p);
          if (!mounted || token != _syncToken) return;
          markers.add(Marker(
            markerId: MarkerId(p.idprestataire),
            position: LatLng(c.lat, c.lng),
            icon: icon,
            zIndex: _selected?.idprestataire == p.idprestataire ? 2 : 0,
            onTap: () => _choose(p),
          ));
        } else {
          final icon =
              await CustomMarkerService.createClusterMarker(c.members.length);
          if (!mounted || token != _syncToken) return;
          markers.add(Marker(
            markerId: MarkerId('cluster_${c.lat}_${c.lng}'),
            position: LatLng(c.lat, c.lng),
            icon: icon,
            onTap: () {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(LatLng(c.lat, c.lng), z + 2),
              );
            },
          ));
        }
      }
    } else {
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
          zIndex: _selected?.idprestataire == p.idprestataire ? 2 : 0,
          onTap: () => _choose(p),
        ));
      }
    }

    if (!mounted || token != _syncToken) return;
    _markerLayoutKey = layoutKey;
    setState(() => _markers = markers);
  }

  String _layoutKey(List<Prestataire> providers, double zoom) {
    final bucket = zoom >= 12.5
        ? 3
        : zoom >= 11
            ? 2
            : zoom >= 10
                ? 1
                : 0;
    final parts = [
      for (final p in providers)
        '${p.idprestataire}:${providerPriceCopy(prixprestataire: p.prixprestataire, tarifHoraireMin: p.tarifHoraireMin).marker}:${p.verifier}:${p.utilisateur.photoProfil ?? ''}:${p.selfie ?? ''}',
    ]..sort();
    return '$bucket|${parts.join('|')}';
  }

  Future<void> _choose(Prestataire? next) async {
    final previous = _selected;
    if (previous?.idprestataire == next?.idprestataire) return;
    setState(() => _selected = next);
    await _repaintSelection(previous, next);
  }

  Future<void> _repaintSelection(Prestataire? previous, Prestataire? next) async {
    if (!mounted) return;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final icons = <String, BitmapDescriptor>{};
    if (previous != null) {
      icons[previous.idprestataire] =
          await _avatarIconFor(previous, selected: false, dpr: dpr);
    }
    if (next != null && next.idprestataire != previous?.idprestataire) {
      icons[next.idprestataire] =
          await _avatarIconFor(next, selected: true, dpr: dpr);
    }
    if (!mounted || icons.isEmpty) return;
    setState(() {
      _markers = _markers
          .map((m) {
            final icon = icons[m.markerId.value];
            if (icon == null) return m;
            return m.copyWith(
              iconParam: icon,
              zIndexParam: m.markerId.value == next?.idprestataire ? 2 : 0,
            );
          })
          .toSet();
    });
  }

  List<_ExplorerMapCluster> _buildClusters(
    List<Prestataire> providers,
    double zoom,
  ) {
    final cell = zoom >= 12.5
        ? 0.0
        : zoom >= 11
            ? 0.012
            : zoom >= 10
                ? 0.025
                : 0.05;
    if (cell <= 0) {
      return providers
          .map((p) => _ExplorerMapCluster(
                lat: p.localisationMaps!.latitude,
                lng: p.localisationMaps!.longitude,
                members: [p],
              ))
          .toList();
    }

    final buckets = <String, _ExplorerMapCluster>{};
    for (final p in providers) {
      final lat = p.localisationMaps!.latitude;
      final lng = p.localisationMaps!.longitude;
      final key = '${(lat / cell).floor()}_${(lng / cell).floor()}';
      final existing = buckets[key];
      if (existing == null) {
        buckets[key] = _ExplorerMapCluster(lat: lat, lng: lng, members: [p]);
      } else {
        existing.members.add(p);
        final n = existing.members.length;
        existing.lat = ((existing.lat * (n - 1)) + lat) / n;
        existing.lng = ((existing.lng * (n - 1)) + lng) / n;
      }
    }
    return buckets.values.toList();
  }

  List<Prestataire> _withCoords(List<Prestataire> providers) {
    final withCoords = <Prestataire>[];
    for (final p in providers) {
      final lat = p.localisationMaps?.latitude;
      final lng = p.localisationMaps?.longitude;
      if (lat == null || lng == null || lat == 0 || lng == 0) continue;
      withCoords.add(p);
    }
    return withCoords;
  }

  Future<BitmapDescriptor> _avatarIconFor(
    Prestataire p, {
    bool? selected,
    double? dpr,
  }) {
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
      priceLabel: providerPriceCopy(
        prixprestataire: p.prixprestataire,
        tarifHoraireMin: p.tarifHoraireMin,
      ).marker,
      initials: initials,
      photoUrl: photo,
      isVerified: p.verifier,
      selected: selected ?? _selected?.idprestataire == p.idprestataire,
      devicePixelRatio: dpr ?? MediaQuery.devicePixelRatioOf(context),
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

  String? _rating(Prestataire p) {
    final n = double.tryParse('${p.note ?? ''}'.replaceAll(',', '.'));
    if (n == null || n <= 0) return null;
    return n.toStringAsFixed(1).replaceAll('.', ',');
  }

  String? _distance(Prestataire p, Map<String, double> distances) {
    final d = distances[p.idprestataire];
    if (d == null) return null;
    return '${d.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  Future<void> _contactProvider(Prestataire p) async {
    final ready = await ensureAuthenticatedForAction(
      context: context,
      type: ProtectedActionType.callProvider,
      originRoute: 'explorer',
      technicalId: p.idprestataire,
      explanation: 'Connectez-vous pour contacter ce professionnel',
    );
    if (!ready || !mounted) return;
    final tel = cleanDisplayPart(p.utilisateur.telephone) ?? '';
    if (tel.isEmpty) return;
    final result = await DialerSession.openOnce(tel);
    if (!mounted) return;
    await showDialerFeedback(context, result);
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
        final nearbyCount = _withCoords(providers).length;
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
                onTap: (_) => _choose(null),
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
              top: 12,
              right: 12,
              child: Material(
                color: SDColors.white,
                elevation: 2,
                borderRadius: BorderRadius.circular(8),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  tooltip: 'Agrandir la carte',
                  onPressed: _openFullMetiers,
                  icon: const Icon(Icons.fullscreen,
                      color: SDColors.neutral900, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
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
                  '• $nearbyCount professionnel${nearbyCount > 1 ? 's' : ''} à proximité',
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
                bottom: 12 + MediaQuery.paddingOf(context).bottom,
                child: _ExplorerMiniProviderCard(
                  provider: _selected!,
                  name: _name(_selected!),
                  metier: _metier(_selected!),
                  rating: _rating(_selected!),
                  distance: _distance(_selected!, state.providerDistances),
                  price: providerPriceCopy(
                    prixprestataire: _selected!.prixprestataire,
                    tarifHoraireMin: _selected!.tarifHoraireMin,
                  ).sheet,
                  photoUrl: providerPhotoUrl(
                    selfie: _selected!.selfie,
                    photoProfil: _selected!.utilisateur.photoProfil,
                  ),
                  onClose: () => _choose(null),
                  onContact: (cleanDisplayPart(_selected!.utilisateur.telephone) ??
                              '')
                          .isEmpty
                      ? null
                      : () => _contactProvider(_selected!),
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
  final String? rating;
  final String? distance;
  final String price;
  final String? photoUrl;
  final VoidCallback onClose;
  final VoidCallback? onContact;
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
                          if (rating != null)
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
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        price,
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
                if (onContact != null) ...[
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
                ],
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

class _ExplorerMapCluster {
  double lat;
  double lng;
  final List<Prestataire> members;

  _ExplorerMapCluster({
    required this.lat,
    required this.lng,
    required this.members,
  });
}
