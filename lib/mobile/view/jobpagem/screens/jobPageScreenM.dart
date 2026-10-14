import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/models/prestataire.dart';
import 'package:sdealsmobile/data/models/service.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/services/protected_action_intent.dart';
import 'package:sdealsmobile/mobile/view/common/auth_completion.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';
import 'package:sdealsmobile/data/utils/media_url.dart';
import 'package:sdealsmobile/data/utils/network_user_message.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageEventM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageStateM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/categories_list_screen.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/detailPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/services/custom_marker_service.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/utils/metier_catalog.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/utils/navigation_helper.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/widgets/service_request_sheet.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/screens/searchPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/app_image.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/client_provider_list_card.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/universe_hub_header.dart';

/// Métiers / Explorer — Vue Liste (défaut) + Vue Carte, même état BLoC.
class JobPageScreenM extends StatelessWidget {
  final List<dynamic> categories;

  const JobPageScreenM({super.key, this.categories = const []});

  @override
  Widget build(BuildContext context) {
    final existing =
        context.findAncestorWidgetOfExactType<BlocProvider<JobPageBlocM>>();
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
  String _locationLabel = SDClientLocationPolicy.fallbackCity;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  String? _selectedProviderId;
  double _mapZoom = 13;
  int _markerSyncToken = 0;
  List<Prestataire> _lastMapProviders = const [];
  Map<String, double> _lastDistances = const {};
  String? _markerLayoutKey;
  bool _mapExpanded = false;
  bool _providersLoadSeen = false;
  bool _providersSettled = false;
  final ScrollController _scroll = ScrollController();
  final DraggableScrollableController _resultsSheet =
      DraggableScrollableController();
  final Map<String, GlobalKey> _resultKeys = {};
  ScrollController? _resultsScroll;
  double _resultsSheetSize = 0.62;
  double _listOffset = 0;
  bool _restoreListOffset = false;

  @override
  void initState() {
    super.initState();
    _resultsSheet.addListener(_onResultsSheet);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // La géolocalisation déclenche _reloadNearby() si accordée,
      // sinon _getCurrentLocation() appelle _reloadNearby() en fallback.
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _resultsSheet.removeListener(_onResultsSheet);
    _resultsSheet.dispose();
    _scroll.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onResultsSheet() {
    if (!mounted || !_resultsSheet.isAttached) return;
    final size = _resultsSheet.size;
    if ((size - _resultsSheetSize).abs() < 0.015) return;
    setState(() => _resultsSheetSize = size);
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Pas de prompt GPS automatique : seulement si deja accorde.
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _locationLabel = SDClientLocationPolicy.fallbackCity);
        // GPS refusé : charge quand même les prestataires sans filtre géo
        _reloadNearby();
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _locationLabel = SDClientLocationPolicy.fallbackCity);
      // Erreur GPS : charge les prestataires sans coordonnées
      _reloadNearby();
    }
  }

  Future<void> _updateLocationLabel(double lat, double lng) async {
    try {
      final marks = await placemarkFromCoordinates(lat, lng);
      if (!mounted || marks.isEmpty) return;
      final p = marks.first;
      final area =
          (p.subLocality?.isNotEmpty == true) ? p.subLocality : p.locality;
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

  void _reloadNearby({
    String? category,
    String? categoryId,
    String? service,
    String? serviceId,
    double? radius,
    bool clearFilters = false,
  }) {
    final bloc = context.read<JobPageBlocM>();
    final cat = clearFilters ? '' : (category ?? bloc.state.selectedCategory);
    final catId =
        clearFilters ? '' : (categoryId ?? bloc.state.selectedCategoryId);
    final svc = clearFilters ? '' : (service ?? bloc.state.selectedService);
    final svcId =
        clearFilters ? '' : (serviceId ?? bloc.state.selectedServiceId);
    final usedRadius = radius ?? bloc.state.searchRadius;
    if (_userLocation != null) {
      bloc.add(LoadNearbyProvidersM(
        latitude: _userLocation!.latitude,
        longitude: _userLocation!.longitude,
        radius: usedRadius,
        category: cat.isNotEmpty ? cat : null,
        categoryId: catId.isNotEmpty ? catId : null,
        service: svc.isNotEmpty ? svc : null,
        serviceId: svcId.isNotEmpty ? svcId : null,
      ));
    } else if (svcId.isNotEmpty) {
      bloc.add(LoadProviderMatchingM(
        serviceType: svc,
        location: '',
        serviceId: svcId,
        categoryId: catId.isNotEmpty ? catId : null,
      ));
      if (radius != null) {
        bloc.add(UpdateExplorerFiltersM(searchRadius: radius));
      }
    } else if (catId.isNotEmpty) {
      bloc.add(LoadProvidersByCategoryM(
        category: cat,
        categoryId: catId,
      ));
      if (radius != null) {
        bloc.add(UpdateExplorerFiltersM(searchRadius: radius));
      }
    } else {
      bloc.add(const LoadProviderMatchingM(
        serviceType: '',
        location: '',
      ));
      if (radius != null) {
        bloc.add(UpdateExplorerFiltersM(searchRadius: radius));
      }
    }
  }

  void _applyExplorerFilters({
    required String serviceName,
    required String serviceId,
    required double radius,
    required bool verifiedOnly,
  }) {
    context.read<JobPageBlocM>().add(UpdateExplorerFiltersM(
          searchRadius: radius,
          filterVerifiedOnly: verifiedOnly,
        ));
    _reloadNearby(
      service: serviceName,
      serviceId: serviceId,
      radius: radius,
    );
  }

  Future<void> _syncMapMarkers(
    List<Prestataire> providers,
    Map<String, double> distances, {
    double? zoom,
  }) async {
    final z = zoom ?? _mapZoom;
    _lastMapProviders = providers;
    _lastDistances = distances;

    final withCoords = <Prestataire>[];
    for (final p in providers) {
      final lat = p.localisationMaps?.latitude;
      final lng = p.localisationMaps?.longitude;
      if (lat == null || lng == null || lat == 0 || lng == 0) continue;
      withCoords.add(p);
    }
    final layoutKey = _markerLayoutSignature(withCoords, z);
    if (layoutKey == _markerLayoutKey && _markers.isNotEmpty) return;
    final token = ++_markerSyncToken;

    final markers = <Marker>{};
    // Pas de marker custom « user » : le point GPS natif (myLocationEnabled) est plus pro.
    // createUserMarker() reste dispo pour FullMap / mini-map.

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
            zIndex: _selectedProviderId == p.idprestataire ? 2 : 0,
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
          zIndex: _selectedProviderId == p.idprestataire ? 2 : 0,
          onTap: () => _onProviderMarkerTap(p),
        ));
      }
    }

    if (!mounted || token != _markerSyncToken) return;
    _markerLayoutKey = layoutKey;
    setState(() => _markers = markers);
  }

  String _markerLayoutSignature(List<Prestataire> providers, double zoom) {
    final bucket = zoom >= 12.5
        ? 3
        : zoom >= 11
            ? 2
            : zoom >= 10
                ? 1
                : 0;
    final parts = [
      for (final p in providers)
        '${p.idprestataire}:${_prices(p).marker}:${p.verifier}:${p.utilisateur.photoProfil ?? ''}:${p.selfie ?? ''}',
    ]..sort();
    return '$bucket|${parts.join('|')}';
  }

  Prestataire? _providerById(String? id) {
    if (id == null) return null;
    for (final p in _lastMapProviders) {
      if (p.idprestataire == id) return p;
    }
    return null;
  }

  Future<void> _chooseProvider(Prestataire? next) async {
    final previousId = _selectedProviderId;
    final nextId = next?.idprestataire;
    if (previousId == nextId) return;
    final previous = _providerById(previousId);
    setState(() => _selectedProviderId = nextId);
    await _repaintMarkerSelection(previous, next);
  }

  Future<void> _repaintMarkerSelection(
    Prestataire? previous,
    Prestataire? next,
  ) async {
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

  Future<BitmapDescriptor> _avatarIconFor(
    Prestataire p, {
    bool? selected,
    double? dpr,
  }) {
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
      priceLabel: _prices(p).marker,
      initials: initials,
      photoUrl: photo,
      isVerified: p.verifier,
      selected: selected ?? _selectedProviderId == p.idprestataire,
      devicePixelRatio: dpr ?? MediaQuery.devicePixelRatioOf(context),
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
      final key = '${(lat / cell).floor()}_${(lng / cell).floor()}';
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
    final n = joinPersonName(
      prenom: p.utilisateur.prenom,
      nom: p.utilisateur.nom,
      fallback: 'Prestataire',
    );
    return n.isEmpty ? 'Prestataire' : displayTitleCase(n);
  }

  String _metier(Prestataire p) {
    final s = p.service.nomservice.trim();
    if (s.isNotEmpty && s != 'Service inconnu') return s;
    if (p.specialite != null && p.specialite!.isNotEmpty) {
      return p.specialite!.first;
    }
    return p.service.categorie?.nomcategorie ?? 'Prestataire';
  }

  ProviderPriceCopy _prices(Prestataire p) {
    return providerPriceCopy(
      prixprestataire: p.prixprestataire,
      tarifHoraireMin: p.tarifHoraireMin,
    );
  }

  String? _ratingLabel(Prestataire p) {
    final n = double.tryParse('${p.note ?? ''}'.replaceAll(',', '.'));
    if (n == null || n <= 0) return null;
    return n.toStringAsFixed(1).replaceAll('.', ',');
  }

  String? _distanceLabel(Prestataire p, Map<String, double> distances) {
    final d = distances[p.idprestataire];
    if (d == null || d.isNaN || d < 0) return null;
    if (d < 0.1) return '< 100 m';
    if (d < 1.0) return '${(d * 1000).round()} m';
    if ((d - d.round()).abs() < 0.05) return '${d.round()} km';
    return '${d.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  Future<void> _callProvider(Prestataire p) async {
    final ready = await ensureAuthenticatedForAction(
      context: context,
      type: ProtectedActionType.callProvider,
      originRoute: 'jobList',
      technicalId: p.idprestataire,
      explanation: 'Connectez-vous pour appeler ce professionnel',
    );
    if (!ready || !mounted) return;
    final tel = cleanDisplayPart(p.utilisateur.telephone) ?? '';
    if (tel.isEmpty) {
      NavigationHelper.navigateToProviderProfile(
        context,
        providerId: p.idprestataire,
        providerData: p.toJson(),
      );
      return;
    }
    final result = await DialerSession.openOnce(tel);
    if (!mounted) return;
    await showDialerFeedback(context, result);
  }

  Future<void> _onProviderMarkerTap(Prestataire p) async {
    await _chooseProvider(p);
    if (!mounted) return;
    if (_mapExpanded) {
      await _showProviderDetailSheet(p);
      return;
    }
    _revealMapResult(p.idprestataire);
  }

  void _revealMapResult(String id) {
    if (_resultsSheet.isAttached && _resultsSheet.size < 0.5) {
      _resultsSheet.animateTo(
        0.62,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final card = _resultKeys[id]?.currentContext;
      if (card != null) {
        Scrollable.ensureVisible(
          card,
          alignment: 0.25,
          duration: const Duration(milliseconds: 250),
        );
        return;
      }
      final scroll = _resultsScroll;
      if (scroll == null || !scroll.hasClients) return;
      final providers = _onMap(context.read<JobPageBlocM>().state.displayProviders);
      final index = providers.indexWhere((p) => p.idprestataire == id);
      if (index < 0) return;
      final target = (128.0 + index * 96.0)
          .clamp(0.0, scroll.position.maxScrollExtent);
      scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _openMapProvider(Prestataire p) {
    _chooseProvider(p);
    final lat = p.localisationMaps?.latitude;
    final lng = p.localisationMaps?.longitude;
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15),
      );
    }
    NavigationHelper.navigateToProviderProfile(
      context,
      providerId: p.idprestataire,
      providerData: p.toJson(),
    );
  }

  bool _hasMapCoords(Prestataire p) {
    final lat = p.localisationMaps?.latitude;
    final lng = p.localisationMaps?.longitude;
    return lat != null && lng != null && lat != 0 && lng != 0;
  }

  List<Prestataire> _onMap(List<Prestataire> providers) {
    return [for (final p in providers) if (_hasMapCoords(p)) p];
  }

  GlobalKey _resultKey(String id) => _resultKeys.putIfAbsent(id, GlobalKey.new);

  /// Tarif seulement si l’unité est dans le modèle (horaire). Pas de « / jour ».
  String? _unitPrice(Prestataire p) {
    final hourly = p.tarifHoraireMin;
    if (hourly == null || hourly <= 0) return null;
    return formatOptionalPrice(hourly, perUnit: ' / h');
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
        price: _prices(p).sheet,
        photoUrl: providerPhotoUrl(
          selfie: p.selfie,
          photoProfil: p.utilisateur.photoProfil,
        ),
        onContact: () {
          Navigator.pop(ctx);
          _callProvider(p);
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
    if (mounted && _selectedProviderId == p.idprestataire) {
      await _chooseProvider(null);
    }
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
      providerMetier: p.service.nomservice,
      providerPhotoUrl: providerPhotoUrl(
        selfie: p.selfie,
        photoProfil: p.utilisateur.photoProfil,
      ),
      prix:
          p.prixprestataire > 0 ? p.prixprestataire : (p.tarifHoraireMin ?? 0),
    );
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SearchPageScreenM(scope: 'metiers'),
      ),
    );
  }

  void _hintFilters() => _openFilters(context.read<JobPageBlocM>().state);

  void _ensureMetierCatalog() {
    final bloc = context.read<JobPageBlocM>();
    if (bloc.state.listItems2.isEmpty && !bloc.state.isLoading2) {
      bloc.add(LoadServiceDataJobM());
    }
  }

  Future<_MetierPick?> _showMetierSheet({
    required String initialId,
    String initialName = '',
  }) {
    _ensureMetierCatalog();
    final bloc = context.read<JobPageBlocM>();
    return showModalBottomSheet<_MetierPick>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SDColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: _MetierChoiceSheet(
          initialId: initialId,
          initialName: initialName,
        ),
      ),
    );
  }

  Future<void> _pickMetier(JobPageStateM state) async {
    final picked = await _showMetierSheet(
      initialId: state.selectedServiceId,
      initialName: state.selectedService,
    );
    if (picked == null || !mounted) return;
    if (picked.id == state.selectedServiceId) return;
    _reloadNearby(service: picked.name, serviceId: picked.id);
  }

  Future<void> _openFilters(JobPageStateM state) async {
    final bloc = context.read<JobPageBlocM>();
    final draft = await showModalBottomSheet<_FilterDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SDColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: _FiltersSheet(
          initialServiceId: state.selectedServiceId,
          initialServiceName: state.selectedService,
          initialRadius: state.searchRadius,
          initialVerified: state.filterVerifiedOnly,
          radiusFilters: state.appliesSearchRadius,
          onPickMetier: (currentId, currentName) => _showMetierSheet(
            initialId: currentId,
            initialName: currentName,
          ),
          onPickRadius: (current) => showModalBottomSheet<double>(
            context: context,
            isScrollControlled: true,
            backgroundColor: SDColors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => _RadiusChoiceSheet(
              options: const [2.0, 5.0, 10.0, 20.0],
              current: current,
              filtersResults: state.appliesSearchRadius,
            ),
          ),
        ),
      ),
    );
    if (draft == null || !mounted) return;
    _applyExplorerFilters(
      serviceName: draft.serviceName,
      serviceId: draft.serviceId,
      radius: draft.radius,
      verifiedOnly: draft.verifiedOnly,
    );
  }

  void _showList() {
    if (_view == _ExplorerView.list) return;
    _restoreListOffset = true;
    setState(() {
      _view = _ExplorerView.list;
      _mapExpanded = false;
    });
  }

  void _showMap(JobPageStateM state) {
    if (_view == _ExplorerView.map) return;
    if (_scroll.hasClients) _listOffset = _scroll.offset;
    setState(() => _view = _ExplorerView.map);
    _syncMapMarkers(state.displayProviders, state.providerDistances);
  }

  double _paintedHeight(
    String text,
    TextStyle style,
    double maxWidth,
    int maxLines,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxWidth < 40 ? 40 : maxWidth);
    final height = painter.height;
    painter.dispose();
    return height;
  }

  /// Hauteur du grand header, calée sur [UniverseHubHeader] + la puce lieu.
  double _fullHeaderExtent(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final titleW = width - 96;
    final titleH = _paintedHeight(
      UniverseHubCopy.metiers.title,
      SDTypography.displayMedium.copyWith(
        color: SDColors.neutral900,
        fontWeight: FontWeight.w800,
      ),
      titleW,
      1,
    );
    final subtitleH = _paintedHeight(
      UniverseHubCopy.metiers.subtitle,
      SDTypography.body.copyWith(color: SDColors.neutral700),
      titleW,
      2,
    );
    final rowH = _atLeast(6 + titleH + 2 + subtitleH, 48);
    final searchH = _atLeast(
      _paintedHeight(
            UniverseHubCopy.metiers.searchHint,
            SDTypography.bodyMedium.copyWith(
              color: SDColors.neutral500,
              fontSize: 14,
            ),
            width - 146,
            1,
          ) +
          24,
      48,
    );
    final locationH = _atLeast(
      _paintedHeight(
            _locationLabel,
            SDTypography.labelMedium.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
            220,
            1,
          ) +
          16,
      36,
    );
    return media.padding.top +
        6 +
        rowH +
        12 +
        searchH +
        10 +
        locationH +
        14 +
        12;
  }

  double _prosBarExtent(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final toggle = _atLeast(16 + scaler.scale(12) * 1.2, 44);
    final chip = _atLeast(16 + scaler.scale(12) * 1.2, 44);
    return 20 + 6 + toggle + chip + 8 + 1 + 24;
  }

  double _atLeast(double value, double min) => value < min ? min : value;

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
        _trackProvidersLoad(state);
        if (_mapExpanded && _view == _ExplorerView.map) {
          return _buildFullMapScreen(state);
        }

        return Scaffold(
          backgroundColor: SDColors.white,
          body: _view == _ExplorerView.map
              ? _buildMapColumn(state)
              : _buildExplorerScroll(state),
        );
      },
    );
  }

  Widget _buildMapColumn(JobPageStateM state) {
    final refreshing = (state.isNearbyLoading || state.isMatchingLoading) &&
        state.displayProviders.isNotEmpty;
    return Column(
      children: [
        _CompactMetiersBar(
          onSearch: _openSearch,
          onFilter: _hintFilters,
        ),
        Material(
          color: SDColors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildViewToggle(state),
              _buildFilterChips(state),
              const Divider(height: 1, color: SDColors.neutral200),
            ],
          ),
        ),
        if (refreshing)
          const LinearProgressIndicator(
            minHeight: 2,
            color: SDColors.primary600,
            backgroundColor: SDColors.primary50,
          ),
        Expanded(child: _buildMapBody(state)),
      ],
    );
  }

  Widget _buildExplorerScroll(JobPageStateM state) {
    if (_restoreListOffset) {
      _restoreListOffset = false;
      final target = _listOffset;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        final max = _scroll.position.maxScrollExtent;
        _scroll.jumpTo(target < 0 ? 0 : (target > max ? max : target));
      });
    }

    final top = MediaQuery.paddingOf(context).top;
    final fullExtent = _fullHeaderExtent(context);
    final compactExtent = top + 56;
    return RefreshIndicator(
      onRefresh: () async {
        _reloadNearby();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      },
      color: SDColors.primary600,
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _CollapsingMetiersHeaderDelegate(
              minExtent:
                  compactExtent < fullExtent ? compactExtent : fullExtent,
              maxExtent:
                  fullExtent < compactExtent ? compactExtent : fullExtent,
              full: UniverseHubHeader(
                copy: UniverseHubCopy.metiers,
                onSearch: _openSearch,
                onFilter: _hintFilters,
                belowSearch: _buildLocationChip(),
              ),
              compact: _CompactMetiersBar(
                reservedTop: top,
                onSearch: _openSearch,
                onFilter: _hintFilters,
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildNeedShortcuts(state)),
          SliverToBoxAdapter(child: _buildCategories(state)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _PinnedBoxDelegate(
              height: _prosBarExtent(context),
              child: ColoredBox(
                color: SDColors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildViewToggle(state),
                    _buildFilterChips(state),
                    const Divider(height: 1, color: SDColors.neutral200),
                  ],
                ),
              ),
            ),
          ),
          ..._resultSlivers(state),
        ],
      ),
    );
  }

  Widget _buildLocationChip() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: SDColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: SDColors.neutral200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_outlined,
                size: 16, color: SDColors.primary600),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
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
    );
  }

  /// Libellé court pour les cartes raccourcis — uniquement visuel, ne touche pas la base.
  String _shortcutLabel(String name) {
    const labelMap = <String, String>{
      'plomberie': 'Plombier',
      'plombier': 'Plombier',
      'électricité': 'Électricien',
      'electricite': 'Électricien',
      'électricien': 'Électricien',
      // "ménagère" (è grave) ≠ "ménage" (e plein) — nécessite une entrée dédiée
      'aide ménagère': 'Ménage',
      'aide menagere': 'Ménage',
      'ménagère': 'Ménage',
      'menagere': 'Ménage',
      'ménage': 'Ménage',
      'menage': 'Ménage',
      'maçonnerie': 'Maçon',
      'maconnerie': 'Maçon',
      'maçon': 'Maçon',
      'mécanique auto': 'Mécanicien auto',
      'mecanique auto': 'Mécanicien auto',
      'mécanicien': 'Mécanicien auto',
      'coiffure': 'Coiffeur',
      'coiffeur': 'Coiffeur',
    };
    final lower = name.toLowerCase().trim();
    for (final entry in labelMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    // Fallback : tronque à 14 caractères
    return name.length > 14 ? '${name.substring(0, 13)}…' : name;
  }

  Widget _buildNeedShortcuts(JobPageStateM state) {
    final items = state.shortcuts.take(6).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'De quoi avez-vous besoin ?',
            style: SDTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: SDColors.neutral900,
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(
              'Aucun raccourci éditorial pour le moment.',
              style:
                  SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
            )
          else
            SizedBox(
              height: 128,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final s = items[i];
                  final img = normalizeMediaUrl(s.imageservice);
                  final label = _shortcutLabel(s.nomservice);
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DetailPage(
                            title: s.nomservice,
                            image: img ?? '',
                            serviceId: s.idservice,
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 116,
                        height: 128,
                        child: Stack(
                          children: [
                            // ── Image plein-cadre ──────────────────────────
                            Positioned.fill(
                              child: img != null
                                  ? AppImage(
                                      imageUrl: img,
                                      fit: BoxFit.cover,
                                    )
                                  : const ColoredBox(
                                      color: SDColors.neutral200,
                                    ),
                            ),
                            // Icône fallback quand pas d'image
                            if (img == null)
                              const Positioned.fill(
                                child: Center(
                                  child: Icon(
                                    Icons.handyman_outlined,
                                    color: SDColors.neutral500,
                                    size: 36,
                                  ),
                                ),
                              ),
                            // ── Dégradé sombre en bas ──────────────────────
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: 64,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.72),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // ── Libellé blanc bas-gauche ───────────────────
                            Positioned(
                              left: 8,
                              bottom: 8,
                              right: 4,
                              child: Text(
                                label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: SDTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  height: 1.2,
                                  shadows: [
                                    Shadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
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

  Widget _buildCategories(JobPageStateM state) {
    final cats = state.listItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Toutes les catégories',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SDTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: SDColors.neutral900,
                  ),
                ),
              ),
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
                  'Voir tout',
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
                            state.selectedCategoryId == c.idcategorie;
                        return _CategoryChip(
                          categorie: c,
                          selected: selected,
                          onTap: () {
                            if (selected) {
                              _reloadNearby(clearFilters: true);
                            } else {
                              _reloadNearby(
                                category: c.nomcategorie,
                                categoryId: c.idcategorie,
                                service: '',
                                serviceId: '',
                              );
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
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    'Professionnels',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SDTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: SDColors.neutral900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              ],
            ),
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Container(
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
                      onTap: _showList,
                    ),
                    _ToggleBtn(
                      label: 'Carte',
                      icon: Icons.map_outlined,
                      selected: _view == _ExplorerView.map,
                      onTap: () => _showMap(state),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(JobPageStateM state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          _FilterChip(
            label: state.selectedService.trim().isNotEmpty
                ? state.selectedService.trim()
                : 'Tous les métiers',
            icon: Icons.handyman_outlined,
            selected: state.selectedServiceId.isNotEmpty,
            onTap: () => _pickMetier(state),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: state.appliesSearchRadius
                ? '≤ ${_kmLabel(state.searchRadius)}'
                : 'Rayon',
            icon: Icons.place_outlined,
            selected: state.appliesSearchRadius,
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
          if (state.selectedCategory.isNotEmpty) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: state.selectedCategory,
              icon: Icons.category_outlined,
              selected: true,
              onTap: () => _reloadNearby(clearFilters: true),
            ),
          ],
        ],
      ),
    );
  }

  String _kmLabel(double radius) {
    if (radius == radius.roundToDouble()) return '${radius.toInt()} km';
    return '${radius.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  Future<void> _pickRadius(JobPageStateM state) async {
    const options = [2.0, 5.0, 10.0, 20.0];
    final chosen = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SDColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _RadiusChoiceSheet(
        options: options,
        current: state.searchRadius,
        filtersResults: state.appliesSearchRadius,
      ),
    );
    if (chosen == null || !mounted || chosen == state.searchRadius) return;
    context
        .read<JobPageBlocM>()
        .add(UpdateExplorerFiltersM(searchRadius: chosen));
  }

  void _trackProvidersLoad(JobPageStateM state) {
    final loading =
        state.isNearbyLoading || state.isMatchingLoading || state.isLoadingMore;
    if (loading) {
      _providersLoadSeen = true;
      _providersSettled = false;
    } else if (_providersLoadSeen) {
      _providersSettled = true;
    }
  }

  List<Widget> _resultSlivers(JobPageStateM state) {
    final isLoading = state.isNearbyLoading || state.isMatchingLoading;
    final list = state.displayProviders;
    final errorMsg =
        state.nearbyError.isNotEmpty ? state.nearbyError : state.matchError;
    final bottom = MediaQuery.paddingOf(context).bottom + 24;

    if (isLoading && list.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: SDColors.primary600,
              ),
            ),
          ),
        ),
      ];
    }

    if (list.isEmpty && errorMsg.isNotEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 28, 24, bottom),
            child: SDSectionNeedsConnection(
              detail:
                  'Les professionnels de cette recherche ne sont pas enregistrés sur cet appareil.',
              onRetry: _reloadNearby,
            ),
          ),
        ),
      ];
    }

    if (list.isEmpty) {
      final showIllustration = _providersSettled && !state.isLoadingMore;
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: Column(
              children: [
                if (showIllustration) ...[
                  const SDIllustration(
                    asset: SDIllustrations.professionalsEmpty,
                  ),
                  const SizedBox(height: 12),
                ],
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
                  state.appliesSearchRadius
                      ? 'Aucun professionnel dont la distance estimée est dans ce rayon. Ce périmètre n’est pas exhaustif.'
                      : 'Les distances sont indicatives. Sans position, la liste n’est pas limitée à un rayon.',
                  textAlign: TextAlign.center,
                  style: SDTypography.bodySmall
                      .copyWith(color: SDColors.neutral500),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    final refreshing = isLoading || state.isLoadingMore;
    return [
      if (refreshing)
        const SliverToBoxAdapter(
          child: LinearProgressIndicator(
            minHeight: 2,
            color: SDColors.primary600,
            backgroundColor: SDColors.primary50,
          ),
        ),
      if (errorMsg.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SDOfflineSavedBanner(
              offline: homeBannerLooksOffline(errorMsg),
              limitedExcerpt: true,
            ),
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        sliver: SliverList.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final p = list[i];
            final price = _prices(p).sheet;
            final loc = cleanDisplayPart(p.localisation);
            return ClientProviderListCard(
              key: ValueKey(p.idprestataire),
              name: _providerName(p),
              metier: _metier(p),
              location: loc != null ? displayTitleCase(loc) : null,
              ratingLabel: _ratingLabel(p),
              distanceLabel: _distanceLabel(p, state.providerDistances),
              priceLabel: price.isEmpty ? null : price,
              photoUrl: providerPhotoUrl(
                selfie: p.selfie,
                photoProfil: p.utilisateur.photoProfil,
              ),
              verified: p.verifier == true,
              onOpen: () => NavigationHelper.navigateToProviderProfile(
                context,
                providerId: p.idprestataire,
                providerData: p.toJson(),
              ),
              onCall: () => _callProvider(p),
              onAsk: () => _requestService(p),
            );
          },
        ),
      ),
      if (state.nearbyProviders.isNotEmpty &&
          (state.providersHasMore || state.isLoadingMore))
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: OutlinedButton(
              onPressed: state.isLoadingMore ||
                      state.isNearbyLoading ||
                      state.isMatchingLoading
                  ? null
                  : () => context
                      .read<JobPageBlocM>()
                      .add(const LoadMoreProvidersM()),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: state.isLoadingMore
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Charger plus de professionnels'),
            ),
          ),
        ),
      SliverToBoxAdapter(child: SizedBox(height: bottom)),
    ];
  }

  Widget _buildFullMapScreen(JobPageStateM state) {
    final providers = state.displayProviders;
    final initial = _userLocation ?? const LatLng(5.3599, -4.0083);
    final count = providers.length;
    final metierLabel = state.selectedService.trim().isNotEmpty
        ? state.selectedService.trim()
        : 'Tous les métiers';
    final radiusLabel = state.appliesSearchRadius
        ? '≤ ${_kmLabel(state.searchRadius)}'
        : 'Rayon';

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
                        icon: Icons.handyman_outlined,
                        selected: state.selectedServiceId.isNotEmpty,
                        onTap: () => _pickMetier(state),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: radiusLabel,
                        icon: Icons.place_outlined,
                        selected: state.appliesSearchRadius,
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
                                  filterVerifiedOnly: !state.filterVerifiedOnly,
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
                    onTap: (_) => _chooseProvider(null),
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
                              '$count professionnel${count > 1 ? 's' : ''} dans cette zone',
                              textAlign: TextAlign.center,
                              style: SDTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                color: SDColors.neutral800,
                              ),
                            ),
                          ),
                          ..._onMap(providers).map((p) {
                            final name = _providerName(p);
                            final distance =
                                _distanceLabel(p, state.providerDistances);
                            final price = _prices(p).sheet;
                            final photo = providerPhotoUrl(
                              selfie: p.selfie,
                              photoProfil: p.utilisateur.photoProfil,
                            );
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                              child: _FullMapProviderRow(
                                name: name,
                                metier: _metier(p),
                                distance: distance,
                                price: price,
                                photoUrl: photo,
                                selected:
                                    p.idprestataire == _selectedProviderId,
                                onTap: () async {
                                  final lat = p.localisationMaps?.latitude;
                                  final lng = p.localisationMaps?.longitude;
                                  if (lat != null &&
                                      lng != null &&
                                      lat != 0 &&
                                      lng != 0) {
                                    _mapController?.animateCamera(
                                      CameraUpdate.newLatLngZoom(
                                        LatLng(lat, lng),
                                        15,
                                      ),
                                    );
                                  }
                                  await _chooseProvider(p);
                                  if (!mounted) return;
                                  await _showProviderDetailSheet(p);
                                },
                              ),
                            );
                          }),
                          if (state.providersHasMore)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: OutlinedButton(
                                onPressed: state.isLoadingMore
                                    ? null
                                    : () => context
                                        .read<JobPageBlocM>()
                                        .add(const LoadMoreProvidersM()),
                                child: state.isLoadingMore
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Charger plus de professionnels'),
                              ),
                            ),
                          if (!state.providersHasMore && providers.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                'Fin de la liste',
                                textAlign: TextAlign.center,
                                style: SDTypography.bodySmall.copyWith(
                                  color: SDColors.neutral500,
                                ),
                              ),
                            ),
                          SizedBox(
                            height: 16 + SDResponsive.occupiedBottomInset(context),
                          ),
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
    final initial = _userLocation ?? const LatLng(5.3599, -4.0083);
    final onMap = _onMap(state.displayProviders);
    final loading = state.isNearbyLoading || state.isMatchingLoading;

    return LayoutBuilder(
      builder: (context, constraints) {
        final sheetPx = constraints.maxHeight * _resultsSheetSize;
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
                onMapCreated: (c) => _mapController = c,
                onTap: (_) => _chooseProvider(null),
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
                  onPressed: () => setState(() => _mapExpanded = true),
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
              bottom: sheetPx + 8,
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
                  '• ${onMap.length} professionnel${onMap.length > 1 ? 's' : ''} à proximité',
                  style: SDTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: SDColors.neutral800,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: sheetPx + 8,
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
            DraggableScrollableSheet(
              controller: _resultsSheet,
              initialChildSize: 0.62,
              minChildSize: 0.2,
              maxChildSize: 0.78,
              snap: true,
              snapSizes: const [0.2, 0.62],
              builder: (context, scrollController) {
                _resultsScroll = scrollController;
                return _MapResultsSheet(
                  scrollController: scrollController,
                  providers: onMap,
                  selectedId: _selectedProviderId,
                  loading: loading,
                  bottomInset: SDResponsive.occupiedBottomInset(context),
                  nameOf: _providerName,
                  metierOf: _metier,
                  placeOf: (p) {
                    final place = cleanDisplayPart(p.localisation);
                    return place == null ? null : displayTitleCase(place);
                  },
                  distanceOf: (p) =>
                      _distanceLabel(p, state.providerDistances),
                  priceOf: _unitPrice,
                  photoOf: (p) => providerPhotoUrl(
                    selfie: p.selfie,
                    photoProfil: p.utilisateur.photoProfil,
                  ),
                  keyOf: _resultKey,
                  onOpen: _openMapProvider,
                  onCollapse: () {
                    if (!_resultsSheet.isAttached) return;
                    _resultsSheet.animateTo(
                      0.2,
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOut,
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _CompactMetiersBar extends StatelessWidget {
  const _CompactMetiersBar({
    required this.onSearch,
    required this.onFilter,
    this.reservedTop,
  });

  final VoidCallback onSearch;
  final VoidCallback onFilter;
  final double? reservedTop;

  @override
  Widget build(BuildContext context) {
    final row = SizedBox(
      height: 56,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Métiers',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SDTypography.titleMedium.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Rechercher',
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded, color: SDColors.neutral900),
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          IconButton(
            tooltip: 'Filtres',
            onPressed: onFilter,
            icon: const Icon(Icons.tune_rounded, color: SDColors.neutral900),
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          SDCircleCloseButton(
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );

    final bar = reservedTop == null
        ? SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 4),
              child: row,
            ),
          )
        : Padding(
            padding: EdgeInsets.only(top: reservedTop!, left: 16, right: 4),
            child: row,
          );

    return ColoredBox(color: SDColors.primary50, child: bar);
  }
}

class _CollapsingMetiersHeaderDelegate extends SliverPersistentHeaderDelegate {
  _CollapsingMetiersHeaderDelegate({
    required double minExtent,
    required double maxExtent,
    required this.full,
    required this.compact,
  })  : _minExtent = minExtent,
        _maxExtent = maxExtent;

  final double _minExtent;
  final double _maxExtent;
  final Widget full;
  final Widget compact;

  @override
  double get minExtent => _minExtent;

  @override
  double get maxExtent => _maxExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = _maxExtent - _minExtent;
    final t = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    final fullOpacity = (1 - t / 0.72).clamp(0.0, 1.0);
    final compactOpacity = ((t - 0.42) / 0.58).clamp(0.0, 1.0);
    return ClipRect(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: SDColors.primary50,
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20 * (1 - t)),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: _maxExtent,
              maxHeight: _maxExtent,
              child: IgnorePointer(
                ignoring: t > 0.5,
                child: Opacity(opacity: fullOpacity, child: full),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: _minExtent,
                child: IgnorePointer(
                  ignoring: t < 0.55,
                  child: Opacity(opacity: compactOpacity, child: compact),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CollapsingMetiersHeaderDelegate oldDelegate) {
    return oldDelegate._minExtent != _minExtent ||
        oldDelegate._maxExtent != _maxExtent ||
        oldDelegate.full != full ||
        oldDelegate.compact != compact;
  }
}

class _PinnedBoxDelegate extends SliverPersistentHeaderDelegate {
  _PinnedBoxDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: height, child: child);
  }

  @override
  bool shouldRebuild(covariant _PinnedBoxDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(icon,
                    size: 16,
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
          constraints: const BoxConstraints(minHeight: 44),
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
              Icon(icon,
                  size: 14, color: selected ? color : SDColors.neutral700),
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
                            Flexible(
                              child: Text(
                                rating,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SDTypography.labelSmall
                                    .copyWith(color: SDColors.neutral600),
                              ),
                            ),
                            if (distance != null) ...[
                              Text(' · ',
                                  style: SDTypography.labelSmall
                                      .copyWith(color: SDColors.neutral400)),
                              const Icon(Icons.place_outlined,
                                  size: 12, color: SDColors.neutral900),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  distance!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: SDTypography.labelSmall
                                      .copyWith(color: SDColors.neutral600),
                                ),
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

class _MapResultsSheet extends StatelessWidget {
  final ScrollController scrollController;
  final List<Prestataire> providers;
  final String? selectedId;
  final bool loading;
  final double bottomInset;
  final String Function(Prestataire) nameOf;
  final String Function(Prestataire) metierOf;
  final String? Function(Prestataire) placeOf;
  final String? Function(Prestataire) distanceOf;
  final String? Function(Prestataire) priceOf;
  final String? Function(Prestataire) photoOf;
  final GlobalKey Function(String id) keyOf;
  final ValueChanged<Prestataire> onOpen;
  final VoidCallback onCollapse;

  const _MapResultsSheet({
    required this.scrollController,
    required this.providers,
    required this.selectedId,
    required this.loading,
    required this.bottomInset,
    required this.nameOf,
    required this.metierOf,
    required this.placeOf,
    required this.distanceOf,
    required this.priceOf,
    required this.photoOf,
    required this.keyOf,
    required this.onOpen,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final count = providers.length;
    final subtitle = loading ? 'Chargement…' : 'Résultats chargés';
    return Material(
      color: SDColors.white,
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
              child: Column(
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: SDColors.primary50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.groups_outlined,
                            size: 20, color: SDColors.primary700),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$count professionnel${count > 1 ? 's' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SDTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: SDColors.neutral900,
                              ),
                            ),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SDTypography.labelSmall.copyWith(
                                color: SDColors.neutral500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Réduire',
                        onPressed: onCollapse,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: SDColors.neutral700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: SDColors.neutral500),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Distances indicatives',
                          style: SDTypography.labelSmall.copyWith(
                            color: SDColors.neutral600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (providers.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 28, 24, 24 + bottomInset),
                child: Text(
                  loading
                      ? 'Chargement des professionnels…'
                      : 'Aucun professionnel géolocalisé dans ces résultats.',
                  textAlign: TextAlign.center,
                  style: SDTypography.bodySmall
                      .copyWith(color: SDColors.neutral600),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverList.separated(
                itemCount: providers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final p = providers[i];
                  return _MapResultCard(
                    key: keyOf(p.idprestataire),
                    provider: p,
                    name: nameOf(p),
                    metier: metierOf(p),
                    place: placeOf(p),
                    distance: distanceOf(p),
                    price: priceOf(p),
                    photoUrl: photoOf(p),
                    selected: p.idprestataire == selectedId,
                    onOpen: () => onOpen(p),
                  );
                },
              ),
            ),
          if (providers.length > 3)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8 + bottomInset),
                child: Text(
                  'Faites défiler pour voir les autres résultats',
                  textAlign: TextAlign.center,
                  style: SDTypography.labelSmall.copyWith(
                    color: SDColors.neutral500,
                  ),
                ),
              ),
            )
          else
            SliverToBoxAdapter(child: SizedBox(height: 12 + bottomInset)),
        ],
      ),
    );
  }
}

class _MapResultCard extends StatelessWidget {
  final Prestataire provider;
  final String name;
  final String metier;
  final String? place;
  final String? distance;
  final String? price;
  final String? photoUrl;
  final bool selected;
  final VoidCallback onOpen;

  const _MapResultCard({
    super.key,
    required this.provider,
    required this.name,
    required this.metier,
    required this.place,
    required this.distance,
    required this.price,
    required this.photoUrl,
    required this.selected,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0])
        .join();
    final initials = parts.isEmpty ? '?' : parts.toUpperCase();
    final where = [
      if (place != null && place!.isNotEmpty) place!,
      if (distance != null && distance!.isNotEmpty) distance!,
    ].join(' · ');

    return Material(
      color: selected ? SDColors.primary50 : SDColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? SDColors.primary600 : SDColors.neutral200,
            ),
          ),
          child: Row(
            children: [
              ClipOval(
                child: hasPhoto
                    ? AppImage(
                        imageUrl: photoUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        borderRadius: 24,
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        color: SDColors.primary50,
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: SDTypography.labelMedium.copyWith(
                            color: SDColors.primary700,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: SDTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: SDColors.neutral900,
                            ),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SDTypography.bodySmall.copyWith(
                        color: SDColors.neutral700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (where.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              size: 14, color: SDColors.neutral700),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              where,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SDTypography.labelSmall.copyWith(
                                color: SDColors.neutral600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (price != null && price!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        price!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SDTypography.labelMedium.copyWith(
                          color: SDColors.primary700,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: SDColors.neutral400),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadiusChoiceSheet extends StatefulWidget {
  final List<double> options;
  final double current;
  final bool filtersResults;

  const _RadiusChoiceSheet({
    required this.options,
    required this.current,
    required this.filtersResults,
  });

  @override
  State<_RadiusChoiceSheet> createState() => _RadiusChoiceSheetState();
}

class _RadiusChoiceSheetState extends State<_RadiusChoiceSheet> {
  late double _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.options.contains(widget.current)
        ? widget.current
        : widget.options.first;
  }

  @override
  Widget build(BuildContext context) {
    final inset = SDResponsive.occupiedBottomInset(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 8 + inset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: SDColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Rayon des résultats',
                    style: SDTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: SDColors.neutral900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fermer',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: SDColors.neutral700),
                ),
              ],
            ),
            Text(
              widget.filtersResults
                  ? 'Appliquer limite la liste et les pastilles aux professionnels dont la distance estimée est dans ce rayon. La carte ne se recadre pas. Ce périmètre n’est pas exhaustif.'
                  : 'Sans position connue, ce rayon ne limite ni la liste ni la carte. Il sera utilisé dès qu’une position permettra d’estimer les distances.',
              style: SDTypography.bodySmall.copyWith(
                color: SDColors.neutral600,
              ),
            ),
            const SizedBox(height: 14),
            for (final r in widget.options) ...[
              _RadiusOption(
                label: '${r.toInt()} km',
                selected: _selected == r,
                onTap: () => setState(() => _selected = r),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.pop(context, _selected),
              style: FilledButton.styleFrom(
                backgroundColor: SDColors.primary600,
                foregroundColor: SDColors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Appliquer'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadiusOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RadiusOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? SDColors.primary50 : SDColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? SDColors.primary600 : SDColors.neutral200,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: SDTypography.bodyMedium.copyWith(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: SDColors.neutral900,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? SDColors.primary600 : SDColors.neutral400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullMapProviderRow extends StatelessWidget {
  final String name;
  final String metier;
  final String? distance;
  final String? price;
  final String? photoUrl;
  final bool selected;
  final VoidCallback onTap;

  const _FullMapProviderRow({
    required this.name,
    required this.metier,
    required this.distance,
    required this.price,
    required this.photoUrl,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0])
        .join();
    final initials = parts.isEmpty ? '?' : parts.toUpperCase();
    final detail = [
      metier,
      if (distance != null && distance!.isNotEmpty) distance!,
    ].join(' · ');

    return Material(
      color: selected ? SDColors.primary50 : SDColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? SDColors.primary600 : SDColors.neutral200,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: ClipOval(
                  child: hasPhoto
                      ? AppImage(
                          imageUrl: photoUrl!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          borderRadius: 22,
                        )
                      : ColoredBox(
                          color: SDColors.primary50,
                          child: Center(
                            child: Text(
                              initials,
                              style: SDTypography.labelMedium.copyWith(
                                color: SDColors.primary700,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SDTypography.bodyMedium.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (detail.isNotEmpty)
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.neutral600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              if (price != null && price!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    price!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: SDTypography.labelSmall.copyWith(
                      color: SDColors.primary700,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetierPick {
  final String id;
  final String name;

  const _MetierPick({required this.id, required this.name});
}

class _FilterDraft {
  final String serviceId;
  final String serviceName;
  final double radius;
  final bool verifiedOnly;

  const _FilterDraft({
    required this.serviceId,
    required this.serviceName,
    required this.radius,
    required this.verifiedOnly,
  });

  static const defaults = _FilterDraft(
    serviceId: '',
    serviceName: '',
    radius: 5,
    verifiedOnly: false,
  );
}

class _MetierChoiceSheet extends StatefulWidget {
  final String initialId;
  final String initialName;

  const _MetierChoiceSheet({
    required this.initialId,
    this.initialName = '',
  });

  @override
  State<_MetierChoiceSheet> createState() => _MetierChoiceSheetState();
}

class _MetierChoiceSheetState extends State<_MetierChoiceSheet> {
  late String _selectedId;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialId;
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _confirm(List<Service> services) {
    if (_selectedId.isEmpty) {
      Navigator.pop(context, const _MetierPick(id: '', name: ''));
      return;
    }
    for (final s in services) {
      if (s.idservice == _selectedId) {
        Navigator.pop(
          context,
          _MetierPick(id: s.idservice, name: s.nomservice.trim()),
        );
        return;
      }
    }
    Navigator.pop(
      context,
      _MetierPick(
        id: _selectedId,
        name: widget.initialId == _selectedId ? widget.initialName : '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inset = SDResponsive.occupiedBottomInset(context);
    final available = MediaQuery.sizeOf(context).height -
        inset -
        MediaQuery.paddingOf(context).top;
    final sheetH = available < 240 ? 240.0 : available;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SizedBox(
        height: sheetH > MediaQuery.sizeOf(context).height * 0.92
            ? MediaQuery.sizeOf(context).height * 0.92
            : sheetH,
        child: BlocBuilder<JobPageBlocM, JobPageStateM>(
          builder: (context, state) {
            final services =
                matchingMetierCatalog(state.listItems2, _search.text);
            final showHint = services.length > 6;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: SDColors.neutral300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Choisir un métier',
                              style: SDTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                color: SDColors.neutral900,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Fermer',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded,
                                color: SDColors.neutral700),
                          ),
                        ],
                      ),
                      Text(
                        'Recherchez un service du catalogue Métiers.',
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.neutral600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _search,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Rechercher un métier',
                          prefixIcon: const Icon(Icons.search_rounded),
                          isDense: true,
                          filled: true,
                          fillColor: SDColors.neutral50,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: SDColors.neutral200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: SDColors.neutral200),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                Expanded(
                  child: state.isLoading2 && state.listItems2.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          children: [
                            if (state.error2.isNotEmpty &&
                                state.listItems2.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  state.error2,
                                  textAlign: TextAlign.center,
                                  style: SDTypography.bodySmall.copyWith(
                                    color: SDColors.neutral600,
                                  ),
                                ),
                              )
                            else if (services.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  _search.text.trim().isEmpty
                                      ? 'Aucun métier dans le catalogue.'
                                      : 'Aucun métier ne correspond à cette recherche.',
                                  textAlign: TextAlign.center,
                                  style: SDTypography.bodySmall.copyWith(
                                    color: SDColors.neutral600,
                                  ),
                                ),
                              )
                            else ...[
                              if (_search.text.trim().isEmpty)
                                _MetierOption(
                                  icon: Icons.grid_view_rounded,
                                  title: 'Tous les métiers',
                                  subtitle: 'Retirer le filtre métier',
                                  selected: _selectedId.isEmpty,
                                  emphasized: _selectedId.isEmpty,
                                  onTap: () =>
                                      setState(() => _selectedId = ''),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                'Métiers',
                                style: SDTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: SDColors.neutral800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              for (final s in services) ...[
                                _MetierOption(
                                  icon: Icons.handyman_outlined,
                                  title: s.nomservice.trim(),
                                  selected: _selectedId == s.idservice,
                                  onTap: () => setState(
                                      () => _selectedId = s.idservice),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ],
                        ],
                      ),
                ),
                if (showHint)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'Faites défiler pour voir les autres métiers.',
                      textAlign: TextAlign.center,
                      style: SDTypography.labelSmall.copyWith(
                        color: SDColors.neutral500,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: FilledButton(
                    onPressed: state.isLoading2 && state.listItems2.isEmpty
                        ? null
                        : () => _confirm(state.listItems2),
                    style: FilledButton.styleFrom(
                      backgroundColor: SDColors.primary600,
                      foregroundColor: SDColors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Afficher les résultats'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetierOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final bool emphasized;
  final VoidCallback onTap;

  const _MetierOption({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected || emphasized ? SDColors.primary50 : SDColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? SDColors.primary600 : SDColors.neutral200,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: SDColors.primary700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SDTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: SDColors.neutral900,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.neutral600,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? SDColors.primary600 : SDColors.neutral400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FiltersSheet extends StatefulWidget {
  final String initialServiceId;
  final String initialServiceName;
  final double initialRadius;
  final bool initialVerified;
  final bool radiusFilters;
  final Future<_MetierPick?> Function(String currentId, String currentName)
      onPickMetier;
  final Future<double?> Function(double current) onPickRadius;

  const _FiltersSheet({
    required this.initialServiceId,
    required this.initialServiceName,
    required this.initialRadius,
    required this.initialVerified,
    required this.radiusFilters,
    required this.onPickMetier,
    required this.onPickRadius,
  });

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late String _serviceId;
  late String _serviceName;
  late double _radius;
  late bool _verified;

  @override
  void initState() {
    super.initState();
    _serviceId = widget.initialServiceId;
    _serviceName = widget.initialServiceName;
    _radius = widget.initialRadius;
    _verified = widget.initialVerified;
  }

  String _km(double radius) {
    if (radius == radius.roundToDouble()) return '${radius.toInt()} km';
    return '${radius.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  _FilterDraft get _draft => _FilterDraft(
        serviceId: _serviceId,
        serviceName: _serviceName,
        radius: _radius,
        verifiedOnly: _verified,
      );

  @override
  Widget build(BuildContext context) {
    final inset = SDResponsive.occupiedBottomInset(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;
    final metier = _serviceName.trim().isNotEmpty
        ? _serviceName.trim()
        : 'Tous les métiers';
    final distanceValue =
        widget.radiusFilters ? _km(_radius) : 'Non appliquée';
    final distanceCaption = widget.radiusFilters
        ? 'Limite la liste et la carte à cette distance estimée.'
        : '${_km(_radius)} seront enregistrés. Sans position, les résultats ne sont pas limités.';

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 8 + inset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: SDColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filtres',
                    style: SDTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: SDColors.neutral900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fermer',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: SDColors.neutral700),
                ),
              ],
            ),
            Text(
              'Affinez les professionnels affichés.',
              style: SDTypography.bodySmall.copyWith(
                color: SDColors.neutral600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Métier',
              style: SDTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: SDColors.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            _FilterNavRow(
              icon: Icons.handyman_outlined,
              label: metier,
              onTap: () async {
                final picked =
                    await widget.onPickMetier(_serviceId, _serviceName);
                if (picked == null || !mounted) return;
                setState(() {
                  _serviceId = picked.id;
                  _serviceName = picked.name;
                });
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Distance',
              style: SDTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: SDColors.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            _FilterNavRow(
              icon: Icons.place_outlined,
              label: distanceValue,
              onTap: () async {
                final chosen = await widget.onPickRadius(_radius);
                if (chosen == null || !mounted) return;
                setState(() => _radius = chosen);
              },
            ),
            const SizedBox(height: 6),
            Text(
              distanceCaption,
              style: SDTypography.labelSmall.copyWith(
                color: SDColors.neutral500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Vérification',
              style: SDTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: SDColors.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: _verified ? SDColors.primary50 : SDColors.white,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        _verified ? SDColors.primary600 : SDColors.neutral200,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined,
                        color: SDColors.primary700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profils vérifiés uniquement',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: SDTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: SDColors.neutral900,
                            ),
                          ),
                          Text(
                            'Selon le statut du profil',
                            style: SDTypography.labelSmall.copyWith(
                              color: SDColors.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _verified,
                      activeThumbColor: SDColors.primary600,
                      onChanged: (v) => setState(() => _verified = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () =>
                  Navigator.pop(context, _FilterDraft.defaults),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réinitialiser les filtres'),
            ),
            const SizedBox(height: 4),
            FilledButton(
              onPressed: () => Navigator.pop(context, _draft),
              style: FilledButton.styleFrom(
                backgroundColor: SDColors.primary600,
                foregroundColor: SDColors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Afficher les résultats'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterNavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FilterNavRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SDColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SDColors.neutral200),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: SDColors.neutral800),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SDTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: SDColors.neutral900,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: SDColors.neutral500),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fiche prestataire (tap marqueur carte plein écran).
class _ProviderMapDetailSheet extends StatelessWidget {
  final Prestataire provider;
  final String name;
  final String metier;
  final String? rating;
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
    final experience = formatExperienceLabel(provider.anneeExperience);
    final zone = (provider.zoneIntervention != null &&
            provider.zoneIntervention!.isNotEmpty)
        ? provider.zoneIntervention!.take(2).join(', ')
        : (provider.localisation.trim().isNotEmpty
            ? displayTitleCase(provider.localisation)
            : null);
    final priceText = price.trim().isEmpty ? null : price;

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: SDColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipOval(
                  child: AppImage(
                    imageUrl: photoUrl ?? '',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    borderRadius: 32,
                  ),
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
                          if (rating != null)
                            Text(
                              '★ $rating',
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
                          if (zone != null)
                            Text(
                              zone,
                              style: SDTypography.labelSmall.copyWith(
                                color: SDColors.neutral600,
                              ),
                            ),
                          if (experience != null)
                            Text(
                              experience,
                              style: SDTypography.labelSmall.copyWith(
                                color: SDColors.neutral600,
                              ),
                            ),
                        ],
                      ),
                      if (priceText != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          priceText,
                          style: SDTypography.labelMedium.copyWith(
                            color: SDColors.primary700,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onOpenProfile,
              child: const Text('Voir le profil'),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onContact,
                    icon: const Icon(Icons.phone_rounded, size: 18),
                    label: const Text('Appeler'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SDColors.primary600,
                      foregroundColor: SDColors.white,
                      minimumSize: const Size(48, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRequest,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SDColors.primary700,
                      side: const BorderSide(color: SDColors.primary600),
                      minimumSize: const Size(48, 48),
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
    );
  }
}
