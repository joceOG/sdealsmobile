import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';
import 'package:sdealsmobile/data/utils/media_url.dart';
import 'package:sdealsmobile/data/utils/string_list_normalizer.dart';
import 'package:sdealsmobile/mobile/view/orderpagem/screens/service_request_summary_screen.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/provider_profile_screen.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/app_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
// ✅ Design System
import '../../../../design_system/design_system.dart';

// Page de détails de service (2025) avec header moderne, prestataires réels, et CTA sticky
class DetailPage extends StatefulWidget {
  final String title;
  final String image;
  /// ID Mongo du service — filtre `/prestataire?service=` (recommandé).
  final String? serviceId;

  const DetailPage({
    required this.title,
    required this.image,
    this.serviceId,
    super.key,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final ApiClient _api = ApiClient();
  bool _loading = true;
  List<Map<String, dynamic>> _providers = [];
  bool _filterVerifiedOnly = false;
  LatLng? _userLocation;
  /// ID service résolu (paramètre ou premier prestataire chargé).
  String? _effectiveServiceId;
  String? _selectedProviderId;

  final TextEditingController _searchController = TextEditingController();
  bool _showSearchField = false;
  bool _mapMode = false;
  double? _filterMaxDistanceKm;
  double? _filterMinNote;
  double? _filterMaxPrice;
  bool _filterActiveOnly = false;
  String? _filterSpecialite;
  final Set<String> _favoritedProviderIds = {};
  bool _showAllSpecialites = false;

  @override
  void initState() {
    super.initState();
    _effectiveServiceId =
        widget.serviceId != null && widget.serviceId!.trim().isNotEmpty
            ? widget.serviceId!.trim()
            : null;
    _searchController.addListener(() => setState(() {}));
    _loadProviders();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      // Position par défaut (Abidjan) si géolocalisation échoue
      setState(() {
        _userLocation = const LatLng(5.3599, -4.0083);
      });
    }
  }

  Future<void> _loadProviders() async {
    setState(() {
      _loading = true;
    });
    try {
      final results = await _api.fetchPrestatairesByService(
        serviceId: _effectiveServiceId,
        serviceName: _effectiveServiceId == null ? widget.title : null,
        verified: null,
        limit: 50,
      );
      if (!mounted) return;
      setState(() {
        _providers = results;
        if (_effectiveServiceId == null &&
            _providers.isNotEmpty &&
            _providers.first['service'] != null) {
          final svc = _providers.first['service'];
          if (svc is Map<String, dynamic>) {
            _effectiveServiceId = svc['_id']?.toString();
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement prestataires: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSortedProviders;
    return Scaffold(
      backgroundColor: SDColors.neutral50,
      appBar: SDWhiteAppBar.appBar(
        title: widget.title,
        actions: [
          IconButton(
            tooltip: 'Rechercher',
            icon: Icon(_showSearchField ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _showSearchField = !_showSearchField;
              if (!_showSearchField) _searchController.clear();
            }),
          ),
          IconButton(
            tooltip: 'Filtres',
            icon: const Icon(Icons.tune),
            onPressed: _openExtraFiltersSheet,
          ),
        ],
        bottom: _showSearchField
            ? PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        SDSpacing.md,
                        0,
                        SDSpacing.md,
                        SDSpacing.sm,
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: SDTypography.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Nom, ville, spécialité…',
                          prefixIcon: Icon(Icons.search, color: SDColors.neutral500),
                          filled: true,
                          fillColor: SDColors.neutral100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              SDSpacing.borderRadiusMedium,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: SDSpacing.sm,
                            vertical: SDSpacing.xs,
                          ),
                        ),
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: SDColors.neutral200),
                  ],
                ),
              )
            : null,
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: SDColors.primary700),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildCompactServiceHeader()),
                SliverToBoxAdapter(child: _buildQuickFilters()),
                SliverToBoxAdapter(child: _buildAggregatedSpecialitesRow()),
                SliverToBoxAdapter(child: _buildListMapToggle()),
                if (_providers.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(SDSpacing.xl),
                      child: Center(
                        child: Text(
                          'Aucun prestataire pour ce service pour le moment.',
                          textAlign: TextAlign.center,
                          style: SDTypography.bodyMedium.copyWith(
                            color: SDColors.neutral600,
                          ),
                        ),
                      ),
                    ),
                  )
                else if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(SDSpacing.xl),
                      child: Center(
                        child: Text(
                          'Aucun résultat avec ces filtres. Modifiez la recherche ou les filtres.',
                          textAlign: TextAlign.center,
                          style: SDTypography.bodyMedium.copyWith(
                            color: SDColors.neutral600,
                          ),
                        ),
                      ),
                    ),
                  )
                else if (_mapMode)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: SDSpacing.md),
                      child: _DetailProvidersMap(
                        providers: filtered,
                        userLocation: _userLocation,
                        onMarkerTap: (p) {
                          final id = p['_id']?.toString();
                          if (id == null || id.isEmpty) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProviderProfileScreen(
                                providerId: id,
                                providerData: p,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      SDSpacing.md,
                      SDSpacing.xs,
                      SDSpacing.md,
                      SDSpacing.sm,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: SDSpacing.sm),
                            child: _buildProviderCard(filtered[index]),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
                SliverToBoxAdapter(child: SizedBox(height: SDSpacing.xxl)),
              ],
            ),
      bottomNavigationBar:
          _providers.isEmpty ? null : _buildStickyCta(context),
    );
  }

  /// Données issues du backend uniquement — filtres & tri côté client.
  List<Map<String, dynamic>> get _filteredSortedProviders {
    var list = List<Map<String, dynamic>>.from(_providers);
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) {
        final u = p['utilisateur'];
        final nom = u is Map
            ? personNameFromMap(
                Map<String, dynamic>.from(u),
                fallback: '',
              ).toLowerCase()
            : '';
        final loc = (p['localisation'] ?? '').toString().toLowerCase();
        final specs = p['specialite'] is List
            ? (p['specialite'] as List).map((e) => e.toString().toLowerCase()).join(' ')
            : '';
        return nom.contains(q) || loc.contains(q) || specs.contains(q);
      }).toList();
    }
    if (_filterSpecialite != null) {
      list = list.where((p) {
        final s = p['specialite'];
        if (s is! List) return false;
        return s.map((e) => e.toString()).contains(_filterSpecialite);
      }).toList();
    }
    if (_filterActiveOnly) {
      list = list.where((p) => p['status']?.toString() == 'active').toList();
    }
    if (_filterVerifiedOnly) {
      list = list.where((p) {
        return p['verifier'] == true || p['verified'] == true;
      }).toList();
    }
    if (_filterMinNote != null) {
      list = list.where((p) => _noteAsDouble(p) >= _filterMinNote!).toList();
    }
    if (_filterMaxPrice != null) {
      list = list.where((p) {
        final price = _priceAsDouble(p);
        return price != null && price <= _filterMaxPrice!;
      }).toList();
    }
    if (_filterMaxDistanceKm != null && _userLocation != null) {
      list = list.where((p) {
        final d = _distanceToProviderKm(p);
        return d != null && d <= _filterMaxDistanceKm!;
      }).toList();
    }
    _sortProvidersInPlace(list);
    return list;
  }

  LatLng? _providerLatLng(Map<String, dynamic> p) {
    final m = p['localisationmaps'];
    if (m is! Map) return null;
    final lat = m['latitude'];
    final lng = m['longitude'];
    if (lat == null || lng == null) return null;
    final la = lat is num ? lat.toDouble() : double.tryParse('$lat');
    final lo = lng is num ? lng.toDouble() : double.tryParse('$lng');
    if (la == null || lo == null) return null;
    return LatLng(la, lo);
  }

  double? _distanceToProviderKm(Map<String, dynamic> p) {
    final pos = _providerLatLng(p);
    if (pos == null || _userLocation == null) return null;
    final m = Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      pos.latitude,
      pos.longitude,
    );
    return m / 1000.0;
  }

  double _noteAsDouble(Map<String, dynamic> p) {
    final v = p['note'];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  double? _priceAsDouble(Map<String, dynamic> p) {
    final v = p['prixprestataire'];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '');
  }

  int _nbAvisInt(Map<String, dynamic> p) {
    final v = p['nbAvis'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  int _nbMissionInt(Map<String, dynamic> p) {
    final v = p['nbMission'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  bool _isActiveStatus(Map<String, dynamic> p) =>
      p['status']?.toString() == 'active';

  bool _isVerified(Map<String, dynamic> p) =>
      p['verifier'] == true || p['verified'] == true;

  /// Heuristique « Top » : champs backend uniquement (pas de délai fictif).
  bool _showTopBadge(Map<String, dynamic> p) {
    return _isVerified(p) &&
        _noteAsDouble(p) >= 4.0 &&
        _nbMissionInt(p) >= 3;
  }

  void _sortProvidersInPlace(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      final sa = _isActiveStatus(a) ? 1 : 0;
      final sb = _isActiveStatus(b) ? 1 : 0;
      if (sa != sb) return sb.compareTo(sa);
      final da = _distanceToProviderKm(a);
      final db = _distanceToProviderKm(b);
      if (da != null && db != null && (da - db).abs() > 1e-6) {
        return da.compareTo(db);
      }
      if (da != null && db == null) return -1;
      if (da == null && db != null) return 1;
      final na = _noteAsDouble(a);
      final nb = _noteAsDouble(b);
      if (nb != na) return nb.compareTo(na);
      final va = _isVerified(a) ? 1 : 0;
      final vb = _isVerified(b) ? 1 : 0;
      return vb.compareTo(va);
    });
  }

  String _metierLine(Map<String, dynamic> p) {
    final specs = normalizeStringList(p['specialite']);
    if (specs.isNotEmpty) return specs.first;
    final svc = p['service'];
    if (svc is Map) {
      return (svc['nomservice'] ?? widget.title).toString();
    }
    return widget.title;
  }

  String? _photoUrl(Map<String, dynamic> p) {
    final u = p['utilisateur'];
    return providerPhotoUrl(
      utilisateurMap: u is Map ? Map<String, dynamic>.from(u) : null,
      prestataireMap: p,
    );
  }

  String _displayName(Map<String, dynamic> p) {
    final u = p['utilisateur'];
    if (u is Map) {
      return personNameFromMap(
        Map<String, dynamic>.from(u),
        fallback: 'Prestataire',
      );
    }
    return 'Prestataire';
  }

  List<String> _aggregatedSpecialites() {
    final set = <String>{};
    for (final p in _providers) {
      set.addAll(normalizeStringList(p['specialite']));
    }
    final out = set.toList()..sort();
    if (out.length > 14) return out.sublist(0, 14);
    return out;
  }

  Widget _buildCompactServiceHeader() {
    final verifiedCount =
        _providers.where(_isVerified).length;
    final n = _providers.length;
    return Padding(
      padding: EdgeInsets.fromLTRB(SDSpacing.md, SDSpacing.sm, SDSpacing.md, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
            child: SizedBox(
              width: 72,
              height: 72,
              child: _buildServiceThumb(widget.image),
            ),
          ),
          SizedBox(width: SDSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: SDTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: SDColors.neutral900,
                  ),
                ),
                SizedBox(height: SDSpacing.xxxs),
                Text(
                  n == 0
                      ? 'Chargement des professionnels…'
                      : '$n prestataire${n > 1 ? 's' : ''} disponible${n > 1 ? 's' : ''}',
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
          if (verifiedCount > 0)
            Column(
              children: [
                Icon(
                  Icons.verified_user,
                  color: SDColors.primary600,
                  size: 22,
                ),
                const SizedBox(height: 2),
                Text(
                  'Prestataires\nvérifiés',
                  textAlign: TextAlign.center,
                  style: SDTypography.labelSmall.copyWith(
                    color: SDColors.primary700,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    height: 1.15,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildServiceThumb(String path) {
    final isUrl = path.toLowerCase().startsWith('http');
    if (isUrl) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: SDColors.primary100,
          child: Icon(Icons.handyman_outlined, color: SDColors.primary700),
        ),
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: SDColors.primary100,
        child: Icon(Icons.handyman_outlined, color: SDColors.primary700),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Padding(
      padding: EdgeInsets.only(top: SDSpacing.sm),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: SDSpacing.md),
          children: [
            _filterChip(
              label: 'Distance : toutes',
              selected: _filterMaxDistanceKm == null,
              icon: Icons.place,
              onTap: () => setState(() => _filterMaxDistanceKm = null),
            ),
            _filterChip(
              label: '≤ 2 km',
              selected: _filterMaxDistanceKm == 2,
              onTap: () => setState(() => _filterMaxDistanceKm = 2),
            ),
            _filterChip(
              label: '≤ 5 km',
              selected: _filterMaxDistanceKm == 5,
              onTap: () => setState(() => _filterMaxDistanceKm = 5),
            ),
            _filterChip(
              label: '≤ 10 km',
              selected: _filterMaxDistanceKm == 10,
              onTap: () => setState(() => _filterMaxDistanceKm = 10),
            ),
            _filterChip(
              label: 'Plus',
              selected: _filterMaxDistanceKm != null &&
                  _filterMaxDistanceKm! > 10,
              onTap: () => setState(() => _filterMaxDistanceKm = 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: SDSpacing.xs),
      child: FilterChip(
        avatar: icon == null
            ? null
            : Icon(
                icon,
                size: 16,
                color: selected ? SDColors.white : SDColors.primary700,
              ),
        label: Text(
          label,
          style: SDTypography.labelSmall.copyWith(
            color: selected ? SDColors.white : SDColors.neutral800,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: SDColors.primary700,
        checkmarkColor: SDColors.white,
        backgroundColor: SDColors.neutral100,
        side: BorderSide.none,
        showCheckmark: false,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildAggregatedSpecialitesRow() {
    final all = _aggregatedSpecialites();
    if (all.isEmpty) return const SizedBox.shrink();
    final visible = _showAllSpecialites ? all : all.take(6).toList();
    return Padding(
      padding: EdgeInsets.only(top: SDSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SDSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Spécialités proposées',
                    style: SDTypography.labelMedium.copyWith(
                      color: SDColors.neutral800,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (all.length > 6)
                  TextButton(
                    onPressed: () => setState(
                      () => _showAllSpecialites = !_showAllSpecialites,
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _showAllSpecialites ? 'Réduire' : 'Voir tout →',
                      style: SDTypography.labelMedium.copyWith(
                        color: SDColors.primary700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: SDSpacing.xs),
          SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: SDSpacing.md),
              itemCount: visible.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: EdgeInsets.only(right: SDSpacing.xs),
                    child: ActionChip(
                      label: Text(
                        'Toutes',
                        style: SDTypography.labelSmall.copyWith(
                          color: _filterSpecialite == null
                              ? SDColors.white
                              : SDColors.neutral800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () =>
                          setState(() => _filterSpecialite = null),
                      backgroundColor: _filterSpecialite == null
                          ? SDColors.primary700
                          : SDColors.neutral100,
                      side: BorderSide.none,
                    ),
                  );
                }
                final s = visible[i - 1];
                final sel = _filterSpecialite == s;
                return Padding(
                  padding: EdgeInsets.only(right: SDSpacing.xs),
                  child: ActionChip(
                    label: Text(
                      s,
                      style: SDTypography.labelSmall.copyWith(
                        color: sel ? SDColors.white : SDColors.neutral800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => setState(() {
                      _filterSpecialite = sel ? null : s;
                    }),
                    backgroundColor:
                        sel ? SDColors.primary700 : SDColors.neutral100,
                    side: BorderSide.none,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListMapToggle() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SDSpacing.md,
        SDSpacing.md,
        SDSpacing.md,
        SDSpacing.xs,
      ),
      child: Container(
        padding: EdgeInsets.all(SDSpacing.xxxs),
        decoration: BoxDecoration(
          color: SDColors.white,
          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
          border: Border.all(color: SDColors.neutral200),
        ),
        child: Row(
          children: [
            Expanded(
              child: _segmentButton(
                label: 'Liste',
                icon: Icons.view_list_rounded,
                selected: !_mapMode,
                onTap: () => setState(() => _mapMode = false),
              ),
            ),
            Expanded(
              child: _segmentButton(
                label: 'Carte',
                icon: Icons.map_outlined,
                selected: _mapMode,
                onTap: () => setState(() => _mapMode = true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segmentButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? SDColors.primary700 : Colors.transparent,
      borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: SDSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? SDColors.white : SDColors.neutral600,
              ),
              SizedBox(width: SDSpacing.xs),
              Text(
                label,
                style: SDTypography.labelMedium.copyWith(
                  color: selected ? SDColors.white : SDColors.neutral700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _contactProvider(Map<String, dynamic> p) async {
    final u = p['utilisateur'];
    final tel = u is Map ? (u['telephone']?.toString().trim() ?? '') : '';
    if (tel.isNotEmpty) {
      final uri = Uri.parse('tel:$tel');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    }
    if (!mounted) return;
    final id = p['_id']?.toString();
    if (id == null || id.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderProfileScreen(
          providerId: id,
          providerData: p,
        ),
      ),
    );
  }

  String _formatPrice(num price) {
    final formatted =
        NumberFormat('#,###', 'fr_FR').format(price.toInt()).replaceAll(',', ' ');
    return '$formatted FCFA';
  }

  void _toggleProviderFavorite(String id) {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connectez-vous pour ajouter en favoris.',
            style: SDTypography.bodyMedium,
          ),
        ),
      );
      context.push('/login');
      return;
    }
    setState(() {
      if (_favoritedProviderIds.contains(id)) {
        _favoritedProviderIds.remove(id);
      } else {
        _favoritedProviderIds.add(id);
      }
    });
  }

  void _openExtraFiltersSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: SDColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            void apply(VoidCallback fn) {
              setSheet(fn);
              setState(fn);
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                SDSpacing.md,
                SDSpacing.md,
                SDSpacing.md,
                MediaQuery.of(ctx).padding.bottom + SDSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtres',
                    style: SDTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: SDSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _filterChip(
                        label: 'Prix : tous',
                        selected: _filterMaxPrice == null,
                        onTap: () => apply(() => _filterMaxPrice = null),
                      ),
                      _filterChip(
                        label: '≤ 25k F',
                        selected: _filterMaxPrice == 25000,
                        onTap: () => apply(() => _filterMaxPrice = 25000),
                      ),
                      _filterChip(
                        label: '≤ 50k F',
                        selected: _filterMaxPrice == 50000,
                        onTap: () => apply(() => _filterMaxPrice = 50000),
                      ),
                      _filterChip(
                        label: '≥ 4 ★',
                        selected: _filterMinNote == 4,
                        onTap: () => apply(
                          () => _filterMinNote =
                              _filterMinNote == 4 ? null : 4,
                        ),
                      ),
                      _filterChip(
                        label: 'Actifs',
                        selected: _filterActiveOnly,
                        onTap: () => apply(
                          () => _filterActiveOnly = !_filterActiveOnly,
                        ),
                      ),
                      _filterChip(
                        label: 'Vérifiés',
                        selected: _filterVerifiedOnly,
                        onTap: () => apply(
                          () => _filterVerifiedOnly = !_filterVerifiedOnly,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SDSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SDColors.primary700,
                        foregroundColor: SDColors.white,
                      ),
                      child: const Text('Appliquer'),
                    ),
                  ),
                  SizedBox(height: SDSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _onShareTap();
                        },
                        child: Text(
                          'Partager',
                          style: SDTypography.labelMedium
                              .copyWith(color: SDColors.neutral700),
                        ),
                      ),
                      Text(
                        '·',
                        style: TextStyle(color: SDColors.neutral400),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _onReportTap();
                        },
                        child: Text(
                          'Signaler',
                          style: SDTypography.labelMedium
                              .copyWith(color: SDColors.neutral700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> p) {
    final id = p['_id']?.toString() ?? '';
    final name = _displayName(p);
    final metier = _metierLine(p);
    final note = _noteAsDouble(p);
    final nbAvis = _nbAvisInt(p);
    final price = _priceAsDouble(p);
    final distKm = _distanceToProviderKm(p);
    final verified = _isVerified(p);
    final active = _isActiveStatus(p);
    final top = _showTopBadge(p);
    final photo = _photoUrl(p);
    final isFav = id.isNotEmpty && _favoritedProviderIds.contains(id);

    return Material(
      color: SDColors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
      child: InkWell(
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
        onTap: id.isEmpty
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderProfileScreen(
                      providerId: id,
                      providerData: p,
                    ),
                  ),
                );
              },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
            border: Border.all(color: SDColors.neutral200),
          ),
          padding: EdgeInsets.all(SDSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          SDSpacing.borderRadiusMedium,
                        ),
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: photo != null
                              ? AppImage(imageUrl: photo, fit: BoxFit.cover)
                              : Container(
                                  color: SDColors.neutral100,
                                  child: Icon(
                                    Icons.person,
                                    color: SDColors.neutral500,
                                    size: 36,
                                  ),
                                ),
                        ),
                      ),
                      if (verified)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: SDColors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.verified_user,
                              color: SDColors.primary600,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: SDSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      name,
                                      style: SDTypography.titleSmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: SDColors.neutral900,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (verified) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.verified,
                                      color: SDColors.primary600,
                                      size: 16,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (id.isNotEmpty)
                              IconButton(
                                onPressed: () => _toggleProviderFavorite(id),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                icon: Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFav
                                      ? SDColors.error500
                                      : SDColors.neutral400,
                                  size: 22,
                                ),
                              ),
                          ],
                        ),
                        Text(
                          '[${metier.isEmpty ? widget.title : metier}]',
                          style: SDTypography.bodySmall.copyWith(
                            color: SDColors.neutral700,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: SDSpacing.xs),
                        Wrap(
                          spacing: SDSpacing.xs,
                          runSpacing: SDSpacing.xxxs,
                          children: [
                            if (top)
                              _miniBadge(
                                'Top prestataire',
                                SDColors.warning100,
                                SDColors.warning700,
                              ),
                            if (active)
                              _miniBadge(
                                'Profil actif',
                                SDColors.success50,
                                SDColors.success700,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: SDSpacing.sm),
              Row(
                children: [
                  Icon(Icons.star_rounded,
                      size: 18, color: Colors.amber.shade700),
                  SizedBox(width: SDSpacing.xxxs),
                  Text(
                    note > 0 ? note.toStringAsFixed(1) : '—',
                    style: SDTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    nbAvis > 0 ? ' ($nbAvis avis)' : '',
                    style: SDTypography.bodySmall.copyWith(
                      color: SDColors.neutral600,
                    ),
                  ),
                  if (distKm != null) ...[
                    Text(
                      '  ·  ${distKm.toStringAsFixed(distKm < 10 ? 1 : 0)} km',
                      style: SDTypography.bodySmall.copyWith(
                        color: SDColors.neutral600,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (price != null && price > 0)
                    Text(
                      _formatPrice(price),
                      style: SDTypography.titleSmall.copyWith(
                        color: SDColors.primary700,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
              SizedBox(height: SDSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _contactProvider(p),
                      icon: Icon(Icons.chat_bubble_outline, size: 18),
                      label: Text(
                        'Contacter',
                        style: SDTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SDColors.primary700,
                        side: BorderSide(color: SDColors.primary700),
                        padding: EdgeInsets.symmetric(vertical: SDSpacing.xs),
                      ),
                    ),
                  ),
                  SizedBox(width: SDSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: id.isEmpty
                          ? null
                          : () {
                              setState(() => _selectedProviderId = id);
                              final auth =
                                  context.read<AuthCubit>().state;
                              if (auth is! AuthAuthenticated) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Connectez-vous pour commander.',
                                      style: SDTypography.bodyMedium,
                                    ),
                                  ),
                                );
                                context.push('/login');
                                return;
                              }
                              _openCheckoutSheet();
                            },
                      icon: Icon(Icons.shopping_cart_outlined,
                          size: 18, color: SDColors.white),
                      label: Text(
                        'Commander',
                        style: SDTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: SDColors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SDColors.primary700,
                        foregroundColor: SDColors.white,
                        padding: EdgeInsets.symmetric(vertical: SDSpacing.xs),
                      ),
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

  Widget _miniBadge(String text, Color bg, Color fg) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SDSpacing.xs,
        vertical: SDSpacing.xxxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: SDTypography.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _onShareTap() async {
    final text = 'Découvrez ${widget.title} sur Soutrali Deals';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Texte copié dans le presse-papiers',
          style: SDTypography.bodyMedium)),
    );
  }

  void _onReportTap() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Signaler le service', style: SDTypography.titleMedium),
          content: TextField(
            controller: controller,
            maxLines: 4,
            style: SDTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Décrivez le problème…',
              hintStyle: SDTypography.bodyMedium.copyWith(color: SDColors.neutral400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Annuler', style: SDTypography.labelMedium),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Veuillez saisir un motif.',
                        style: SDTypography.bodyMedium)),
                  );
                  return;
                }
                // envoyer au backend si connecté
                final auth = context.read<AuthCubit>().state;
                if (auth is AuthAuthenticated) {
                  final sid = _effectiveServiceId;
                  if (sid != null && sid.isNotEmpty) {
                    try {
                      await _api.createReport(
                        token: auth.token,
                        targetType: 'SERVICE',
                        targetId: sid,
                        reason: controller.text.trim(),
                      );
                    } catch (e) {
                      debugPrint('Erreur signalement: $e');
                    }
                  }
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: SDColors.error500,
                foregroundColor: SDColors.white,
              ),
              child: Text('Envoyer', style: SDTypography.labelMedium.copyWith(color: SDColors.white)),
            ),
          ],
        );
      },
    );

    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signalement envoyé. Merci.',
            style: SDTypography.bodyMedium),
            backgroundColor: SDColors.success500),
      );
    }
  }

  Widget _buildStickyCta(BuildContext context) {
    // Politique safe-bottom unifiée (SDResponsive.systemBottomInset) —
    // SafeArea seul est inopérant sur EMUI (insets remontés via gestureInsets).
    final double sysBottom = SDResponsive.systemBottomInset(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          SDSpacing.sm, SDSpacing.xs, SDSpacing.sm, SDSpacing.sm + sysBottom),
      child: Padding(
        padding: EdgeInsets.zero,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: SDColors.primary700,
              padding: EdgeInsets.symmetric(vertical: SDSpacing.sm),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
              ),
              elevation: 6,
            ),
            icon: Icon(Icons.shopping_cart_checkout_rounded,
                color: SDColors.white),
            label: Text(
              "Commander ce service",
              style: SDTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: SDColors.white),
            ),
            onPressed: () {
              final auth = context.read<AuthCubit>().state;
              if (auth is! AuthAuthenticated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Veuillez vous connecter pour commander.',
                          style: SDTypography.bodyMedium)),
                );
                context.push('/login');
                return;
              }
              _openCheckoutSheet();
            },
          ),
        ),
      ),
    );
  }

  void _openCheckoutSheet() {
    final adresseCtrl = TextEditingController();
    final villeCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime? selectedDateTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: SDColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(SDSpacing.xxxl)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + SDSpacing.sm,
            left: SDSpacing.md,
            right: SDSpacing.md,
            top: SDSpacing.md,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête moderne
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(SDSpacing.xs),
                          decoration: BoxDecoration(
                            color: SDColors.primary700.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                          ),
                          child: Icon(
                            Icons.shopping_cart_checkout_rounded,
                            color: SDColors.primary700,
                            size: 28,
                          ),
                        ),
                        SizedBox(width: SDSpacing.xs),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Commander',
                                style: SDTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: SDColors.neutral900,
                                ),
                              ),
                              Text(
                                widget.title,
                                style: SDTypography.bodySmall.copyWith(
                                  color: SDColors.neutral600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: SDColors.neutral400),
                        ),
                      ],
                    ),
                    SizedBox(height: SDSpacing.md),
                    
                    // Sélecteur de prestataire moderne
                    if (_providers.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.person, color: SDColors.neutral700, size: 20),
                          SizedBox(width: SDSpacing.xs),
                          Text(
                            'Choisir un prestataire',
                            style: SDTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(' *', style: SDTypography.titleSmall.copyWith(color: SDColors.error500)),
                        ],
                      ),
                      SizedBox(height: SDSpacing.xs),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: SDColors.neutral300),
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedProviderId != null &&
                                  _filteredSortedProviders.any(
                                    (p) =>
                                        p['_id']?.toString() ==
                                        _selectedProviderId,
                                  )
                              ? _selectedProviderId
                              : null,
                          style: SDTypography.bodyMedium,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: SDSpacing.sm, vertical: SDSpacing.xs),
                            prefixIcon: Icon(Icons.person_pin_circle, color: SDColors.primary700),
                          ),
                          hint: Text('Sélectionnez un prestataire', style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral500)),
                          items: _filteredSortedProviders.map((provider) {
                            final u = provider['utilisateur'] is Map
                                ? Map<String, dynamic>.from(
                                    provider['utilisateur'] as Map)
                                : null;
                            final name = personNameFromMap(
                              u,
                              fallback: 'Prestataire',
                            );
                            final price = provider['prixprestataire'];
                            final note = cleanDisplayPart(provider['note']);
                            final priceLabel =
                                formatOptionalPrice(price, suffix: 'F') ??
                                    'Sur devis';
                            final noteLabel = note ?? '—';
                            return DropdownMenuItem<String>(
                              value: provider['_id']?.toString(),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: SDTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(Icons.star, size: 14, color: SDColors.warning500),
                                  SizedBox(width: SDSpacing.xxxs),
                                  Text(
                                    noteLabel,
                                    style: SDTypography.labelSmall.copyWith(color: SDColors.neutral600),
                                  ),
                                  SizedBox(width: SDSpacing.xs),
                                  Text(
                                    priceLabel,
                                    style: SDTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: SDColors.primary700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setSheetState(() {
                              _selectedProviderId = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: SDSpacing.sm),
                    ],
                    
                    // Adresse
                    TextField(
                      controller: adresseCtrl,
                      style: SDTypography.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'Adresse',
                        labelStyle: SDTypography.bodyMedium,
                        hintText: 'Ex: Rue 12, Cocody',
                        hintStyle: SDTypography.bodyMedium.copyWith(color: SDColors.neutral400),
                        prefixIcon: Icon(Icons.home, color: SDColors.primary700),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                          borderSide: BorderSide(color: SDColors.primary700, width: 2),
                        ),
                      ),
                    ),
                    SizedBox(height: SDSpacing.xs),
                    
                    // Ville
                    TextField(
                      controller: villeCtrl,
                      style: SDTypography.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'Ville',
                        labelStyle: SDTypography.bodyMedium,
                        hintText: 'Ex: Abidjan',
                        hintStyle: SDTypography.bodyMedium.copyWith(color: SDColors.neutral400),
                        prefixIcon: Icon(Icons.location_city, color: SDColors.primary700),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                          borderSide: BorderSide(color: SDColors.primary700, width: 2),
                        ),
                      ),
                    ),
                    SizedBox(height: SDSpacing.xs),
                    
                    // Date/Heure
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: SDColors.neutral300),
                        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: SDSpacing.sm, vertical: SDSpacing.xs),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: SDColors.primary700),
                          SizedBox(width: SDSpacing.xs),
                          Expanded(
                            child: Text(
                              selectedDateTime == null
                                  ? 'Choisir une date et heure (optionnel)'
                                  : '${selectedDateTime!.day}/${selectedDateTime!.month}/${selectedDateTime!.year} à ${selectedDateTime!.hour}:${selectedDateTime!.minute.toString().padLeft(2, '0')}',
                              style: SDTypography.bodyMedium.copyWith(
                                color: selectedDateTime == null ? SDColors.neutral500 : SDColors.neutral900,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                                initialDate: DateTime.now().add(const Duration(days: 1)),
                              );
                              if (date == null) return;
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time == null) return;
                              final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                              setSheetState(() => selectedDateTime = dt);
                            },
                            child: Text('Choisir', style: SDTypography.labelMedium.copyWith(color: SDColors.primary700)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: SDSpacing.xs),
                    
                    // Notes
                    TextField(
                      controller: notesCtrl,
                      maxLines: 3,
                      style: SDTypography.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'Notes / Instructions (optionnel)',
                        labelStyle: SDTypography.bodyMedium,
                        hintText: 'Ajoutez des détails supplémentaires...',
                        hintStyle: SDTypography.bodyMedium.copyWith(color: SDColors.neutral400),
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: SDSpacing.lg),
                          child: Icon(Icons.note_alt, color: SDColors.primary700),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                          borderSide: BorderSide(color: SDColors.primary700, width: 2),
                        ),
                      ),
                    ),
                    SizedBox(height: SDSpacing.md),
                    
                    // Message GRATUIT amélioré et plus visible
                    Container(
                      padding: EdgeInsets.all(SDSpacing.sm),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [SDColors.success100, SDColors.success50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                        border: Border.all(color: SDColors.success200, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: SDColors.success200.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(SDSpacing.xs),
                            decoration: BoxDecoration(
                              color: SDColors.success500,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check_circle, color: SDColors.white, size: 24),
                          ),
                          SizedBox(width: SDSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Service 100% GRATUIT',
                                  style: SDTypography.titleSmall.copyWith(
                                    color: SDColors.success700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: SDSpacing.xxxs),
                                Text(
                                  'Aucun paiement requis • Accès immédiat',
                                  style: SDTypography.bodySmall.copyWith(
                                    color: SDColors.success600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: SDSpacing.md),
                    
                    // Bouton de soumission moderne
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SDColors.primary700,
                          foregroundColor: SDColors.white,
                          elevation: 3,
                          shadowColor: SDColors.primary700.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                          ),
                        ),
                        onPressed: () async {
                          final auth = context.read<AuthCubit>().state
                              as AuthAuthenticated;

                          // Validation simplifiée - seulement les champs essentiels
                          if (_selectedProviderId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: SDColors.white),
                                    SizedBox(width: SDSpacing.xs),
                                    Expanded(child: Text('Veuillez sélectionner un prestataire',
                                        style: SDTypography.bodyMedium.copyWith(color: SDColors.white))),
                                  ],
                                ),
                                backgroundColor: SDColors.warning500,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
                              ),
                            );
                            return;
                          }
                          
                          // Validation adresse et ville (requis)
                          if (adresseCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.location_off, color: SDColors.white),
                                    SizedBox(width: SDSpacing.xs),
                                    Expanded(child: Text('Veuillez renseigner votre adresse',
                                        style: SDTypography.bodyMedium.copyWith(color: SDColors.white))),
                                  ],
                                ),
                                backgroundColor: SDColors.error500,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
                              ),
                            );
                            return;
                          }
                          
                          if (villeCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.location_city_outlined, color: SDColors.white),
                                    SizedBox(width: SDSpacing.xs),
                                    Expanded(child: Text('Veuillez renseigner votre ville',
                                        style: SDTypography.bodyMedium.copyWith(color: SDColors.white))),
                                  ],
                                ),
                                backgroundColor: SDColors.error500,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
                              ),
                            );
                            return;
                          }
                          
                          // Date/heure optionnels - utiliser valeur par défaut si non renseigné
                          final dateTimeToUse = selectedDateTime ?? DateTime.now().add(Duration(days: 1));

                          // Montrer un loader
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => Center(
                              child: Card(
                                child: Padding(
                                  padding: EdgeInsets.all(SDSpacing.md),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(color: SDColors.primary700),
                                      SizedBox(height: SDSpacing.sm),
                                      Text('Envoi en cours...', style: SDTypography.bodyMedium),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );

                          try {
                            final created = await _api.createPrestation(
                              token: auth.token,
                              utilisateurId: auth.utilisateur.idutilisateur,
                              prestataireId: _selectedProviderId,
                              serviceId: _effectiveServiceId,
                              adresse: adresseCtrl.text.trim(),
                              ville: villeCtrl.text.trim(),
                              datePrestation: dateTimeToUse,
                              notesClient: notesCtrl.text.trim().isEmpty
                                  ? null
                                  : notesCtrl.text.trim(),
                              moyenPaiement: 'GRATUIT',
                            );
                            
                            if (!mounted) return;
                            Navigator.pop(context); // Fermer le loader
                            Navigator.pop(context); // Fermer le modal
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: SDColors.white),
                                    SizedBox(width: SDSpacing.xs),
                                    Expanded(child: Text('Commande confirmée',
                                        style: SDTypography.bodyMedium.copyWith(color: SDColors.white))),
                                  ],
                                ),
                                backgroundColor: SDColors.primary700,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
                                duration: Duration(seconds: 3),
                              ),
                            );
                            
                            final id = created['_id']?.toString();
                            if (id != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ServiceRequestSummaryScreen(
                                    requestId: id,
                                    token: auth.token,
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;
                            Navigator.pop(context); // Fermer le loader
                            Navigator.pop(context); // Fermer le modal
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: SDColors.white),
                                    SizedBox(width: SDSpacing.xs),
                                    Expanded(child: Text('Erreur: ${e.toString()}',
                                        style: SDTypography.bodyMedium.copyWith(color: SDColors.white))),
                                  ],
                                ),
                                backgroundColor: SDColors.error500,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
                                duration: Duration(seconds: 4),
                              ),
                            );
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 22, color: SDColors.white),
                            SizedBox(width: SDSpacing.xs),
                            Text(
                              'Confirmer la commande',
                              style: SDTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: SDColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

}

/// Carte inline : marqueurs uniquement si `localisationmaps` présent (données réelles).
class _DetailProvidersMap extends StatefulWidget {
  final List<Map<String, dynamic>> providers;
  final LatLng? userLocation;
  final void Function(Map<String, dynamic> p) onMarkerTap;

  const _DetailProvidersMap({
    required this.providers,
    required this.userLocation,
    required this.onMarkerTap,
  });

  @override
  State<_DetailProvidersMap> createState() => _DetailProvidersMapState();
}

class _DetailProvidersMapState extends State<_DetailProvidersMap> {
  GoogleMapController? _controller;
  late Set<Marker> _markers;

  static LatLng? _latLng(Map<String, dynamic> p) {
    final m = p['localisationmaps'];
    if (m is! Map) return null;
    final lat = m['latitude'];
    final lng = m['longitude'];
    if (lat == null || lng == null) return null;
    final la = lat is num ? lat.toDouble() : double.tryParse('$lat');
    final lo = lng is num ? lng.toDouble() : double.tryParse('$lng');
    if (la == null || lo == null) return null;
    return LatLng(la, lo);
  }

  static String _name(Map<String, dynamic> p) {
    final u = p['utilisateur'];
    if (u is Map) {
      return personNameFromMap(
        Map<String, dynamic>.from(u),
        fallback: 'Prestataire',
      );
    }
    return 'Prestataire';
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    var i = 0;
    for (final p in widget.providers) {
      final pos = _latLng(p);
      if (pos == null) continue;
      final id = p['_id']?.toString() ?? 'p$i';
      final price = p['prixprestataire'];
      final snippet = price != null ? '$price FCFA' : '';
      markers.add(
        Marker(
          markerId: MarkerId(id),
          position: pos,
          infoWindow: InfoWindow(title: _name(p), snippet: snippet),
          onTap: () => widget.onMarkerTap(p),
        ),
      );
      i++;
    }
    if (widget.userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('__user__'),
          position: widget.userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Votre position'),
        ),
      );
    }
    return markers;
  }

  void _fitCamera() {
    if (!mounted || _controller == null) return;
    if (_markers.isEmpty) {
      final fallback = widget.userLocation ?? const LatLng(5.3599, -4.0083);
      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(fallback, 12),
      );
      return;
    }
    if (_markers.length == 1) {
      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(_markers.first.position, 13),
      );
      return;
    }
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final m in _markers) {
      final p = m.position;
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    if ((maxLat - minLat).abs() < 1e-5 && (maxLng - minLng).abs() < 1e-5) {
      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(minLat, minLng), 14),
      );
      return;
    }
    _controller!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        56,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _markers = _buildMarkers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
  }

  @override
  void didUpdateWidget(covariant _DetailProvidersMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.providers != widget.providers ||
        oldWidget.userLocation != widget.userLocation) {
      setState(() => _markers = _buildMarkers());
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = (MediaQuery.sizeOf(context).height * 0.42).clamp(280.0, 420.0);
    final providerMarkers =
        _markers.where((m) => m.markerId.value != '__user__').toList();
    final target = widget.userLocation ??
        (providerMarkers.isNotEmpty
            ? providerMarkers.first.position
            : const LatLng(5.3599, -4.0083));

    if (providerMarkers.isEmpty) {
      return Container(
        height: h,
        alignment: Alignment.center,
        padding: EdgeInsets.all(SDSpacing.lg),
        decoration: BoxDecoration(
          color: SDColors.white,
          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
          border: Border.all(color: SDColors.neutral200),
        ),
        child: Text(
          'Aucune position précise sur la carte pour ces prestataires '
          '(coordonnées non renseignées).',
          textAlign: TextAlign.center,
          style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral600),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
      child: SizedBox(
        height: h,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: target, zoom: 12),
          markers: _markers,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
          onMapCreated: (c) {
            _controller = c;
            _fitCamera();
          },
        ),
      ),
    );
  }
}
