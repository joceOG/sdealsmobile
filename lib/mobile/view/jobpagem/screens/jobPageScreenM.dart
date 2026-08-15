import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/models/prestataire.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/utils/media_url.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageEventM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageStateM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/categories_list_screen.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/services/custom_marker_service.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/utils/navigation_helper.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/widgets/service_request_sheet.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/screens/searchPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/app_image.dart';

/// Métiers / Explorer — Vue Liste (défaut) + Vue Carte, même état BLoC.
class JobPageScreenM extends StatelessWidget {
  final List<dynamic> categories;

  const JobPageScreenM({super.key, this.categories = const []});

  @override
  Widget build(BuildContext context) {
    final existing = context.findAncestorWidgetOfExactType<
        BlocProvider<JobPageBlocM>>();
    if (existing != null) {
      return const _JobPageView();
    }
    return BlocProvider(
      create: (_) => JobPageBlocM()
        ..add(LoadCategorieDataJobM())
        ..add(LoadServiceDataJobM()),
      child: const _JobPageView(),
    );
  }
}

enum _ExplorerView { list, map }

class _JobPageView extends StatefulWidget {
  const _JobPageView();

  @override
  State<_JobPageView> createState() => _JobPageViewState();
}

class _JobPageViewState extends State<_JobPageView> {
  _ExplorerView _view = _ExplorerView.list;
  LatLng? _userLocation;
  String _locationLabel = 'Localisation…';
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  String? _selectedProviderId;
  double _mapZoom = 13;
  int _markerSyncToken = 0;
  List<Prestataire> _lastMapProviders = const [];
  Map<String, double> _lastDistances = const {};
  bool _mapExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _getCurrentLocation();
      context.read<JobPageBlocM>().add(const LoadProviderMatchingM(
            serviceType: '',
            location: '',
          ));
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
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
      await _updateLocationLabel(position.latitude, position.longitude);
      _reloadNearby();
    } catch (_) {}
  }

  Future<void> _updateLocationLabel(double lat, double lng) async {
    try {
      final marks = await placemarkFromCoordinates(lat, lng);
      if (!mounted || marks.isEmpty) return;
      final p = marks.first;
      final area = (p.subLocality?.isNotEmpty == true)
          ? p.subLocality
          : p.locality;
      final city = p.locality ?? p.country;
      setState(() {
        _locationLabel = [area, city]
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .take(2)
            .join(', ');
        if (_locationLabel.isEmpty) _locationLabel = 'Position actuelle';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _locationLabel = 'Position actuelle');
    }
  }

  void _reloadNearby({String? category}) {
    final bloc = context.read<JobPageBlocM>();
    final cat = category ?? bloc.state.selectedCategory;
    if (_userLocation != null) {
      bloc.add(LoadNearbyProvidersM(
        latitude: _userLocation!.latitude,
        longitude: _userLocation!.longitude,
        radius: bloc.state.searchRadius,
        category: cat.isNotEmpty ? cat : null,
      ));
    } else {
      bloc.add(LoadProviderMatchingM(
        serviceType: cat,
        location: '',
      ));
    }
  }

  Future<void> _syncMapMarkers(
    List<Prestataire> providers,
    Map<String, double> distances, {
    double? zoom,
  }) async {
    final z = zoom ?? _mapZoom;
    _lastMapProviders = providers;
    _lastDistances = distances;
    final token = ++_markerSyncToken;

    final markers = <Marker>{};
    // Pas de marker custom « user » : le point GPS natif (myLocationEnabled) est plus pro.
    // createUserMarker() reste dispo pour FullMap / mini-map.

    final withCoords = <Prestataire>[];
    for (final p in providers) {
      final lat = p.localisationMaps?.latitude;
      final lng = p.localisationMaps?.longitude;
      if (lat == null || lng == null || lat == 0 || lng == 0) continue;
      withCoords.add(p);
    }

    // Zoom éloigné → clusters ; zoom proche → avatar + prix (max 40)
    final useClusters = z < 12.5 && withCoords.length > 8;
    if (useClusters) {
      final clusters = _buildClusters(withCoords, z);
      for (final c in clusters) {
        if (c.members.length == 1) {
          final p = c.members.first;
          final icon = await _avatarIconFor(p);
          if (!mounted || token != _markerSyncToken) return;
          markers.add(Marker(
            markerId: MarkerId(p.idprestataire),
            position: LatLng(c.lat, c.lng),
            icon: icon,
            onTap: () => _onProviderMarkerTap(p),
          ));
        } else {
          final icon =
              await CustomMarkerService.createClusterMarker(c.members.length);
          if (!mounted || token != _markerSyncToken) return;
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
        final lat = p.localisationMaps!.latitude;
        final lng = p.localisationMaps!.longitude;
        final icon = await _avatarIconFor(p);
        if (!mounted || token != _markerSyncToken) return;
        markers.add(Marker(
          markerId: MarkerId(p.idprestataire),
          position: LatLng(lat, lng),
          icon: icon,
          onTap: () => _onProviderMarkerTap(p),
        ));
      }
    }

    if (!mounted || token != _markerSyncToken) return;
    setState(() => _markers = markers);
  }

  Future<BitmapDescriptor> _avatarIconFor(Prestataire p) {
    final photo = providerPhotoUrl(
      selfie: p.selfie,
      photoProfil: p.utilisateur.photoProfil,
    );
    final name = _providerName(p);
    final initials = name.isNotEmpty
        ? name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((e) => e.isNotEmpty ? e[0] : '')
            .join()
        : '?';
    return CustomMarkerService.createAvatarPriceMarker(
      priceLabel: _priceLabel(p),
      initials: initials,
      photoUrl: photo,
      isVerified: p.verifier,
    );
  }

  List<_MapCluster> _buildClusters(List<Prestataire> providers, double zoom) {
    final cell = zoom >= 12.5
        ? 0.0
        : zoom >= 11
            ? 0.012
            : zoom >= 10
                ? 0.025
                : 0.05;
    if (cell <= 0) {
      return providers
          .map((p) => _MapCluster(
                lat: p.localisationMaps!.latitude,
                lng: p.localisationMaps!.longitude,
                members: [p],
              ))
          .toList();
    }

    final buckets = <String, _MapCluster>{};
    for (final p in providers) {
      final lat = p.localisationMaps!.latitude;
      final lng = p.localisationMaps!.longitude;
      final key =
          '${(lat / cell).floor()}_${(lng / cell).floor()}';
      final existing = buckets[key];
      if (existing == null) {
        buckets[key] = _MapCluster(lat: lat, lng: lng, members: [p]);
      } else {
        existing.members.add(p);
        // centroïde simple
        final n = existing.members.length;
        existing.lat = ((existing.lat * (n - 1)) + lat) / n;
        existing.lng = ((existing.lng * (n - 1)) + lng) / n;
      }
    }
    return buckets.values.toList();
  }

  String _providerName(Prestataire p) {
    final n = '${p.utilisateur.prenom} ${p.utilisateur.nom}'.trim();
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

  String _priceLabel(Prestataire p) {
    final price = p.prixprestataire > 0
        ? p.prixprestataire
        : (p.tarifHoraireMin ?? 0);
    if (price <= 0) return '—';
    return NumberFormat('#,###', 'fr_FR')
        .format(price.round())
        .replaceAll(',', ' ');
  }

  String _ratingLabel(Prestataire p) {
    final n = double.tryParse('${p.note ?? ''}'.replaceAll(',', '.'));
    if (n == null || n <= 0) return '—';
    return n.toStringAsFixed(1).replaceAll('.', ',');
  }

  String? _distanceLabel(Prestataire p, Map<String, double> distances) {
    final d = distances[p.idprestataire];
    if (d == null) return null;
    return '${d.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  void _onProviderMarkerTap(Prestataire p) {
    setState(() => _selectedProviderId = p.idprestataire);
    if (_mapExpanded) {
      _showProviderDetailSheet(p);
    }
  }

  void _recenterMap({double zoom = 13}) {
    if (_userLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, zoom),
      );
    }
  }

  Future<void> _showProviderDetailSheet(Prestataire p) async {
    final state = context.read<JobPageBlocM>().state;
    final distance = _distanceLabel(p, state.providerDistances);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProviderMapDetailSheet(
        provider: p,
        name: _providerName(p),
        metier: _metier(p),
        rating: _ratingLabel(p),
        distance: distance,
        price: _priceLabel(p),
        photoUrl: providerPhotoUrl(
          selfie: p.selfie,
          photoProfil: p.utilisateur.photoProfil,
        ),
        onContact: () {
          Navigator.pop(ctx);
          NavigationHelper.navigateToProviderProfile(
            context,
            providerId: p.idprestataire,
            providerData: p.toJson(),
          );
        },
        onRequest: () {
          Navigator.pop(ctx);
          _requestService(p);
        },
        onOpenProfile: () {
          Navigator.pop(ctx);
          NavigationHelper.navigateToProviderProfile(
            context,
            providerId: p.idprestataire,
            providerData: p.toJson(),
          );
        },
      ),
    );
  }

  void _requestService(Prestataire p) {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez vous connecter pour demander un service.')),
      );
      context.push('/login');
      return;
    }
    showServiceRequestSheet(
      context: context,
      token: auth.token,
      utilisateurId: auth.utilisateur.idutilisateur,
      prestataireId: p.idprestataire,
      serviceId: p.service.idservice,
      serviceName: p.service.nomservice,
      providerName: _providerName(p),
      prix: p.prixprestataire > 0
          ? p.prixprestataire
          : (p.tarifHoraireMin ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JobPageBlocM, JobPageStateM>(
      listenWhen: (p, c) =>
          p.displayProviders != c.displayProviders ||
          p.providerDistances != c.providerDistances,
      listener: (context, state) {
        if (_view == _ExplorerView.map) {
          _syncMapMarkers(state.displayProviders, state.providerDistances);
        }
      },
      builder: (context, state) {
        if (_mapExpanded && _view == _ExplorerView.map) {
          return _buildFullMapScreen(state);
        }

        return Scaffold(
          backgroundColor: SDColors.white,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(state),
                _buildSearchRow(),
                if (_view == _ExplorerView.list) ...[
                  _buildCategories(state),
                  _buildViewToggle(state),
                  _buildFilterChips(state),
                  Expanded(child: _buildListBody(state)),
                ] else ...[
                  _buildViewToggle(state),
                  _buildFilterChips(state),
                  Expanded(child: _buildMapBody(state)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(JobPageStateM state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: SDColors.primary600),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: SDColors.primary600),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    _locationLabel,
                    style: SDTypography.labelMedium.copyWith(
                      color: SDColors.neutral900,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Fermer',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded, color: SDColors.neutral900),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SearchPageScreenM()),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: SDColors.neutral50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SDColors.neutral200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        color: SDColors.neutral900),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Quel service recherchez-vous ?',
                        style: SDTypography.bodyMedium
                            .copyWith(color: SDColors.neutral500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: SDColors.primary600,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                // Les chips servent de filtres ; sheet avancé plus tard.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Utilisez les filtres ci-dessous'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.tune_rounded, color: SDColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(JobPageStateM state) {
    final cats = state.listItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              Text(
                'Catégories',
                style: SDTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: SDColors.neutral900,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) =>
                            JobPageBlocM()..add(LoadCategorieDataJobM()),
                        child: const CategoriesListScreen(),
                      ),
                    ),
                  );
                },
                child: Text(
                  'Voir tout >',
                  style: SDTypography.labelMedium.copyWith(
                    color: SDColors.primary700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 92,
          child: state.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : cats.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune catégorie',
                        style: SDTypography.bodySmall
                            .copyWith(color: SDColors.neutral500),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: cats.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final c = cats[i];
                        final selected =
                            state.selectedCategory == c.nomcategorie;
                        return _CategoryChip(
                          categorie: c,
                          selected: selected,
                          onTap: () {
                            final next =
                                selected ? '' : c.nomcategorie;
                            if (_userLocation != null) {
                              context.read<JobPageBlocM>().add(
                                    LoadNearbyProvidersM(
                                      latitude: _userLocation!.latitude,
                                      longitude: _userLocation!.longitude,
                                      radius: state.searchRadius,
                                      category:
                                          next.isEmpty ? null : next,
                                    ),
                                  );
                            } else {
                              context.read<JobPageBlocM>().add(
                                    LoadProvidersByCategoryM(
                                      category: next.isEmpty ? ' ' : next,
                                    ),
                                  );
                              // clear: reload matching
                              if (next.isEmpty) {
                                context.read<JobPageBlocM>().add(
                                      const LoadProviderMatchingM(
                                        serviceType: '',
                                        location: '',
                                      ),
                                    );
                              }
                            }
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildViewToggle(JobPageStateM state) {
    final count = state.displayProviders.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Professionnels près de vous  ',
                    style: SDTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: SDColors.neutral900,
                    ),
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: SDColors.primary50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.primary700,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: SDColors.neutral100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _ToggleBtn(
                  label: 'Liste',
                  icon: Icons.view_list_rounded,
                  selected: _view == _ExplorerView.list,
                  onTap: () => setState(() {
                    _view = _ExplorerView.list;
                    _mapExpanded = false;
                  }),
                ),
                _ToggleBtn(
                  label: 'Carte',
                  icon: Icons.map_outlined,
                  selected: _view == _ExplorerView.map,
                  onTap: () {
                    setState(() => _view = _ExplorerView.map);
                    _syncMapMarkers(
                      state.displayProviders,
                      state.providerDistances,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(JobPageStateM state) {
    final radius = state.searchRadius;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          _FilterChip(
            label: '≤ ${radius == radius.roundToDouble() ? radius.toInt() : radius} km',
            icon: Icons.place_outlined,
            selected: true,
            onTap: () => _pickRadius(state),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Vérifiés',
            icon: Icons.verified_outlined,
            selected: state.filterVerifiedOnly,
            onTap: () {
              context.read<JobPageBlocM>().add(UpdateExplorerFiltersM(
                    filterVerifiedOnly: !state.filterVerifiedOnly,
                  ));
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '4 +',
            icon: Icons.star_border_rounded,
            selected: state.filterMinRating != null,
            accent: const Color(0xFFFBBF24),
            onTap: () {
              context.read<JobPageBlocM>().add(UpdateExplorerFiltersM(
                    filterMinRating:
                        state.filterMinRating == null ? 4.0 : null,
                    clearMinRating: state.filterMinRating != null,
                  ));
            },
          ),
          if (state.selectedCategory.isNotEmpty) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: state.selectedCategory,
              icon: Icons.category_outlined,
              selected: true,
              onTap: () {
                if (_userLocation != null) {
                  context.read<JobPageBlocM>().add(LoadNearbyProvidersM(
                        latitude: _userLocation!.latitude,
                        longitude: _userLocation!.longitude,
                        radius: state.searchRadius,
                      ));
                } else {
                  context.read<JobPageBlocM>().add(
                        const LoadProviderMatchingM(
                          serviceType: '',
                          location: '',
                        ),
                      );
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickRadius(JobPageStateM state) async {
    final options = [2.0, 5.0, 10.0, 20.0];
    final chosen = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: SDColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              'Rayon de recherche',
              style: SDTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: SDColors.neutral900,
              ),
            ),
            ...options.map(
              (r) => ListTile(
                title: Text('≤ ${r.toInt()} km'),
                trailing: state.searchRadius == r
                    ? const Icon(Icons.check, color: SDColors.primary600)
                    : null,
                onTap: () => Navigator.pop(ctx, r),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    if (_userLocation != null) {
      context.read<JobPageBlocM>().add(LoadNearbyProvidersM(
            latitude: _userLocation!.latitude,
            longitude: _userLocation!.longitude,
            radius: chosen,
            category: state.selectedCategory.isNotEmpty
                ? state.selectedCategory
                : null,
          ));
    }
  }

  Widget _buildListBody(JobPageStateM state) {
    if (state.isNearbyLoading || state.isMatchingLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final list = state.displayProviders;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_search_outlined,
                  size: 48,
                  color: SDColors.neutral900.withValues(alpha: 0.35)),
              const SizedBox(height: 12),
              Text(
                'Aucun professionnel pour ces filtres',
                textAlign: TextAlign.center,
                style: SDTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: SDColors.neutral900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Élargissez le rayon ou retirez un filtre.',
                textAlign: TextAlign.center,
                style: SDTypography.bodySmall
                    .copyWith(color: SDColors.neutral500),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _reloadNearby();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      },
      color: SDColors.primary600,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final p = list[i];
          return _ProviderCompareCard(
            provider: p,
            name: _providerName(p),
            metier: _metier(p),
            rating: _ratingLabel(p),
            distance: _distanceLabel(p, state.providerDistances),
            price: _priceLabel(p),
            photoUrl: providerPhotoUrl(
              selfie: p.selfie,
              photoProfil: p.utilisateur.photoProfil,
            ),
            onOpen: () => NavigationHelper.navigateToProviderProfile(
              context,
              providerId: p.idprestataire,
            ),
            onContact: () => NavigationHelper.navigateToProviderProfile(
              context,
              providerId: p.idprestataire,
            ),
            onAsk: () => NavigationHelper.navigateToProviderProfile(
              context,
              providerId: p.idprestataire,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFullMapScreen(JobPageStateM state) {
    final providers = state.displayProviders;
    final initial = _userLocation ?? const LatLng(5.3599, -4.0083);
    final count = providers.length;
    final metierLabel = state.selectedCategory.isNotEmpty
        ? state.selectedCategory
        : 'Tous métiers';
    final radius = state.searchRadius;
    final radiusLabel =
        '≤ ${radius == radius.roundToDouble() ? radius.toInt() : radius} km';

    return Scaffold(
      backgroundColor: SDColors.white,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Retour',
                        onPressed: () => setState(() => _mapExpanded = false),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: SDColors.neutral900),
                      ),
                      Expanded(
                        child: Text(
                          'Prestataires autour de vous',
                          style: SDTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: SDColors.neutral900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Filtres',
                        onPressed: () => _pickRadius(state),
                        icon: const Icon(Icons.tune_rounded,
                            color: SDColors.neutral900),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: metierLabel,
                        icon: Icons.work_outline_rounded,
                        selected: state.selectedCategory.isNotEmpty,
                        onTap: () {
                          // Retour mini pour changer de catégorie via Explorer
                          setState(() => _mapExpanded = false);
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: radiusLabel,
                        icon: Icons.place_outlined,
                        selected: true,
                        onTap: () => _pickRadius(state),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Vérifiés',
                        icon: Icons.verified_outlined,
                        selected: state.filterVerifiedOnly,
                        onTap: () {
                          context.read<JobPageBlocM>().add(
                                UpdateExplorerFiltersM(
                                  filterVerifiedOnly:
                                      !state.filterVerifiedOnly,
                                ),
                              );
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '4 +',
                        icon: Icons.star_border_rounded,
                        selected: state.filterMinRating != null,
                        accent: const Color(0xFFFBBF24),
                        onTap: () {
                          context.read<JobPageBlocM>().add(
                                UpdateExplorerFiltersM(
                                  filterMinRating: state.filterMinRating == null
                                      ? 4.0
                                      : null,
                                  clearMinRating:
                                      state.filterMinRating != null,
                                ),
                              );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
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
                    onMapCreated: (c) => _mapController = c,
                    onCameraMove: (pos) => _mapZoom = pos.zoom,
                    onCameraIdle: () {
                      _syncMapMarkers(
                        _lastMapProviders,
                        _lastDistances,
                        zoom: _mapZoom,
                      );
                    },
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 120,
                  child: _MapRoundBtn(
                    icon: Icons.my_location_outlined,
                    tooltip: 'Ma position',
                    onTap: () => _recenterMap(zoom: 14),
                  ),
                ),
                DraggableScrollableSheet(
                  initialChildSize: 0.14,
                  minChildSize: 0.12,
                  maxChildSize: 0.55,
                  builder: (context, scrollController) {
                    return Material(
                      color: SDColors.white,
                      elevation: 8,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: ListView(
                        controller: scrollController,
                        padding: EdgeInsets.zero,
                        children: [
                          const SizedBox(height: 10),
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: SDColors.neutral300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Text(
                              '$count professionnel${count > 1 ? 's' : ''} à proximité',
                              textAlign: TextAlign.center,
                              style: SDTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                color: SDColors.neutral800,
                              ),
                            ),
                          ),
                          ...providers.take(12).map((p) {
                            final selected =
                                p.idprestataire == _selectedProviderId;
                            final d = state.providerDistances[p.idprestataire];
                            return ListTile(
                              selected: selected,
                              selectedTileColor: SDColors.primary50,
                              leading: ClipOval(
                                child: AppImage(
                                  imageUrl: providerPhotoUrl(
                                        selfie: p.selfie,
                                        photoProfil: p.utilisateur.photoProfil,
                                      ) ??
                                      '',
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  borderRadius: 22,
                                ),
                              ),
                              title: Text(
                                _providerName(p),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                '${_metier(p)}${d != null ? ' · ${d.toStringAsFixed(1)} km' : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                _priceLabel(p) == '—'
                                    ? '—'
                                    : '${_priceLabel(p)} F',
                                style: SDTypography.labelSmall.copyWith(
                                  color: SDColors.primary700,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              onTap: () {
                                setState(() =>
                                    _selectedProviderId = p.idprestataire);
                                final lat = p.localisationMaps?.latitude;
                                final lng = p.localisationMaps?.longitude;
                                if (lat != null && lng != null) {
                                  _mapController?.animateCamera(
                                    CameraUpdate.newLatLngZoom(
                                      LatLng(lat, lng),
                                      15,
                                    ),
                                  );
                                }
                                _showProviderDetailSheet(p);
                              },
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapBody(JobPageStateM state) {
    final providers = state.displayProviders;
    final initial = _userLocation ?? const LatLng(5.3599, -4.0083);
    final sheetBottom = 210.0;

    final sheetList = List<Prestataire>.from(providers);
    if (_selectedProviderId != null) {
      sheetList.sort((a, b) {
        if (a.idprestataire == _selectedProviderId) return -1;
        if (b.idprestataire == _selectedProviderId) return 1;
        return 0;
      });
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: initial, zoom: 13),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            markers: _markers,
            onMapCreated: (c) => _mapController = c,
            onCameraMove: (pos) {
              _mapZoom = pos.zoom;
            },
            onCameraIdle: () {
              if (_view == _ExplorerView.map) {
                _syncMapMarkers(
                  _lastMapProviders,
                  _lastDistances,
                  zoom: _mapZoom,
                );
              }
            },
          ),
        ),
        // Agrandir — extrême gauche
        Positioned(
          left: 12,
          bottom: sheetBottom,
          child: Material(
            color: SDColors.white,
            shape: const CircleBorder(),
            elevation: 2,
            child: IconButton(
              tooltip: 'Agrandir la carte',
              onPressed: () => setState(() => _mapExpanded = true),
              icon: const Icon(Icons.open_in_full_rounded,
                  color: SDColors.neutral900, size: 22),
            ),
          ),
        ),
        Positioned(
          left: 68,
          bottom: sheetBottom + 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          bottom: sheetBottom,
          child: Material(
            color: SDColors.white,
            shape: const CircleBorder(),
            elevation: 2,
            child: IconButton(
              tooltip: 'Recentrer',
              onPressed: () => _recenterMap(),
              icon: const Icon(Icons.my_location_outlined,
                  color: SDColors.neutral900),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _MapBottomSheet(
            providers: sheetList.take(8).toList(),
            distances: state.providerDistances,
            selectedId: _selectedProviderId,
            nameOf: _providerName,
            metierOf: _metier,
            ratingOf: _ratingLabel,
            priceOf: _priceLabel,
            onOpen: (p) => NavigationHelper.navigateToProviderProfile(
              context,
              providerId: p.idprestataire,
              providerData: p.toJson(),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapCluster {
  double lat;
  double lng;
  final List<Prestataire> members;

  _MapCluster({
    required this.lat,
    required this.lng,
    required this.members,
  });
}

class _MapRoundBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapRoundBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SDColors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, color: SDColors.neutral900),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? SDColors.primary600 : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              Icon(icon,
                  size: 14,
                  color: selected ? SDColors.white : SDColors.neutral600),
              const SizedBox(width: 4),
              Text(
                label,
                style: SDTypography.labelSmall.copyWith(
                  color: selected ? SDColors.white : SDColors.neutral600,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? accent;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? SDColors.primary600;
    return Material(
      color: selected ? color.withValues(alpha: 0.08) : SDColors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? color : SDColors.neutral300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: selected ? color : SDColors.neutral700),
              const SizedBox(width: 6),
              Text(
                label,
                style: SDTypography.labelSmall.copyWith(
                  color: selected ? color : SDColors.neutral800,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final Categorie categorie;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.categorie,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = categorie.nomcategorie;
    final img = normalizeMediaUrl(categorie.imagecategorie);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 84,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? SDColors.primary50 : SDColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? SDColors.primary600 : SDColors.neutral200,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (img != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AppImage(
                  imageUrl: img,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              )
            else
              const Icon(Icons.category_outlined,
                  color: SDColors.neutral900, size: 28),
            const SizedBox(height: 6),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SDTypography.labelSmall.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderCompareCard extends StatelessWidget {
  final Prestataire provider;
  final String name;
  final String metier;
  final String rating;
  final String? distance;
  final String price;
  final String? photoUrl;
  final VoidCallback onOpen;
  final VoidCallback onContact;
  final VoidCallback onAsk;

  const _ProviderCompareCard({
    required this.provider,
    required this.name,
    required this.metier,
    required this.rating,
    required this.distance,
    required this.price,
    required this.photoUrl,
    required this.onOpen,
    required this.onContact,
    required this.onAsk,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SDColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SDColors.neutral200),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: photoUrl != null && photoUrl!.startsWith('http')
                            ? AppImage(
                                imageUrl: photoUrl!,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 72,
                                height: 72,
                                color: SDColors.neutral100,
                                child: const Icon(Icons.person_outline_rounded,
                                    color: SDColors.neutral900),
                              ),
                      ),
                      if (provider.verifier)
                        Positioned(
                          left: 4,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: SDColors.primary600,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check,
                                size: 10, color: SDColors.white),
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
                            Expanded(
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
                            if (provider.verifier)
                              const Icon(Icons.verified,
                                  size: 16, color: SDColors.primary600),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          metier,
                          style: SDTypography.bodySmall.copyWith(
                            color: SDColors.neutral700,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 14, color: Color(0xFFFBBF24)),
                            const SizedBox(width: 2),
                            Text(
                              rating,
                              style: SDTypography.labelSmall
                                  .copyWith(color: SDColors.neutral600),
                            ),
                            if (distance != null) ...[
                              Text(' · ',
                                  style: SDTypography.labelSmall
                                      .copyWith(color: SDColors.neutral400)),
                              const Icon(Icons.place_outlined,
                                  size: 12, color: SDColors.neutral900),
                              const SizedBox(width: 2),
                              Text(
                                distance!,
                                style: SDTypography.labelSmall
                                    .copyWith(color: SDColors.neutral600),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          price == '—'
                              ? 'Tarif sur devis'
                              : 'À partir de $price FCFA',
                          style: SDTypography.labelMedium.copyWith(
                            color: SDColors.primary700,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
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
                      onPressed: onAsk,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SDColors.primary600,
                        foregroundColor: SDColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Demander'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapBottomSheet extends StatelessWidget {
  final List<Prestataire> providers;
  final Map<String, double> distances;
  final String? selectedId;
  final String Function(Prestataire) nameOf;
  final String Function(Prestataire) metierOf;
  final String Function(Prestataire) ratingOf;
  final String Function(Prestataire) priceOf;
  final ValueChanged<Prestataire> onOpen;

  const _MapBottomSheet({
    required this.providers,
    required this.distances,
    required this.selectedId,
    required this.nameOf,
    required this.metierOf,
    required this.ratingOf,
    required this.priceOf,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
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
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: SDColors.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                const Icon(Icons.groups_outlined,
                    size: 18, color: SDColors.primary600),
                const SizedBox(width: 6),
                Text(
                  'Prestataires proches',
                  style: SDTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: SDColors.neutral900,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              itemCount: providers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = providers[i];
                final selected = p.idprestataire == selectedId;
                final d = distances[p.idprestataire];
                return Material(
                  color: selected ? SDColors.primary50 : SDColors.neutral50,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => onOpen(p),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        nameOf(p),
                                        style: SDTypography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: SDColors.neutral900,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (p.verifier) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified,
                                          size: 14,
                                          color: SDColors.primary600),
                                    ],
                                  ],
                                ),
                                Text(
                                  '${metierOf(p)} · ⭐ ${ratingOf(p)}${d != null ? ' · ${d.toStringAsFixed(1)} km' : ''}',
                                  style: SDTypography.labelSmall
                                      .copyWith(color: SDColors.neutral600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  priceOf(p) == '—'
                                      ? 'Sur devis'
                                      : '${priceOf(p)} FCFA',
                                  style: SDTypography.labelSmall.copyWith(
                                    color: SDColors.primary700,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => onOpen(p),
                            child: const Text('Voir profil'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Fiche prestataire détaillée (carte plein écran / tap marker).
class _ProviderMapDetailSheet extends StatelessWidget {
  final Prestataire provider;
  final String name;
  final String metier;
  final String rating;
  final String? distance;
  final String price;
  final String? photoUrl;
  final VoidCallback onContact;
  final VoidCallback onRequest;
  final VoidCallback onOpenProfile;

  const _ProviderMapDetailSheet({
    required this.provider,
    required this.name,
    required this.metier,
    required this.rating,
    required this.distance,
    required this.price,
    required this.photoUrl,
    required this.onContact,
    required this.onRequest,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    final specialites = provider.specialite ?? const <String>[];
    final experience = provider.anneeExperience?.trim();
    final zone = (provider.zoneIntervention != null &&
            provider.zoneIntervention!.isNotEmpty)
        ? provider.zoneIntervention!.take(2).join(', ')
        : (provider.localisation.trim().isNotEmpty
            ? provider.localisation
            : null);
    final priceText = price == '—' ? 'Sur devis' : 'À partir de $price FCFA/h';

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: SDColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SDColors.neutral300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipOval(
                    child: AppImage(
                      imageUrl: photoUrl ?? '',
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      borderRadius: 36,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: SDTypography.titleMedium.copyWith(
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
                                  size: 18, color: SDColors.primary600),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          metier,
                          style: SDTypography.bodyMedium.copyWith(
                            color: SDColors.neutral600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          children: [
                            Text(
                              '⭐ $rating',
                              style: SDTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: SDColors.neutral800,
                              ),
                            ),
                            if (distance != null)
                              Text(
                                distance!,
                                style: SDTypography.labelSmall.copyWith(
                                  color: SDColors.neutral600,
                                ),
                              ),
                            Text(
                              'Disponible',
                              style: SDTypography.labelSmall.copyWith(
                                color: SDColors.primary700,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onOpenProfile,
                    icon: const Icon(Icons.favorite_border_rounded,
                        color: SDColors.neutral500),
                    tooltip: 'Voir profil',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: SDColors.primary600,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  priceText,
                  textAlign: TextAlign.center,
                  style: SDTypography.titleSmall.copyWith(
                    color: SDColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onContact,
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          size: 18),
                      label: const Text('Contacter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SDColors.primary700,
                        side: const BorderSide(color: SDColors.primary600),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: onRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SDColors.primary600,
                        foregroundColor: SDColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Demander un service'),
                    ),
                  ),
                ],
              ),
              if (specialites.isNotEmpty) ...[
                const SizedBox(height: 22),
                Text(
                  'Services proposés',
                  style: SDTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: SDColors.neutral900,
                  ),
                ),
                const SizedBox(height: 10),
                ...specialites.take(5).map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: SDColors.primary50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.handyman_outlined,
                                  color: SDColors.primary700, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                s,
                                style: SDTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: SDColors.neutral900,
                                ),
                              ),
                            ),
                            if (price != '—')
                              Text(
                                'dès $price F',
                                style: SDTypography.labelSmall.copyWith(
                                  color: SDColors.primary700,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
              ],
              const SizedBox(height: 18),
              Text(
                'À propos',
                style: SDTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: SDColors.neutral900,
                ),
              ),
              const SizedBox(height: 8),
              if (experience != null && experience.isNotEmpty)
                Text(
                  '$experience ans d’expérience',
                  style: SDTypography.bodyMedium.copyWith(
                    color: SDColors.neutral700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (zone != null) ...[
                const SizedBox(height: 4),
                Text(
                  zone,
                  style: SDTypography.bodySmall
                      .copyWith(color: SDColors.neutral600),
                ),
              ],
              if ((provider.description ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  provider.description!.trim(),
                  style: SDTypography.bodyMedium
                      .copyWith(color: SDColors.neutral600),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: onOpenProfile,
                child: const Text('Voir le profil complet'),
              ),
            ],
          ),
        );
      },
    );
  }
}
