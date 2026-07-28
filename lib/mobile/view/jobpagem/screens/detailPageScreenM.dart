import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/mobile/view/loginpagem/screens/loginPageScreenM.dart';
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
  bool _isFavorited = false;
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
          PopupMenuButton<String>(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: SDSpacing.xs),
              child: Icon(Icons.more_horiz, color: SDColors.neutral900),
            ),
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _onShareTap();
                  break;
                case 'fav':
                  _onFavoriteTap();
                  break;
                case 'report':
                  _onReportTap();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'share', child: Text('Partager')),
              const PopupMenuItem(value: 'fav', child: Text('Favori')),
              const PopupMenuItem(value: 'report', child: Text('Signaler')),
            ],
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
            ? '${u['nom'] ?? ''} ${u['prenom'] ?? ''}'.toLowerCase()
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
    final spec = p['specialite'];
    if (spec is List && spec.isNotEmpty) {
      return spec.first.toString();
    }
    final svc = p['service'];
    if (svc is Map) {
      return (svc['nomservice'] ?? widget.title).toString();
    }
    return widget.title;
  }

  String? _photoUrl(Map<String, dynamic> p) {
    final selfie = p['selfie']?.toString().trim() ?? '';
    final u = p['utilisateur'];
    final profil = u is Map
        ? (u['photoProfil']?.toString().trim() ?? '')
        : '';
    final raw = (selfie.isNotEmpty && selfie.toLowerCase().startsWith('http'))
        ? selfie
        : profil;
    if (raw.isEmpty || !raw.toLowerCase().startsWith('http')) return null;
    return raw;
  }

  String _displayName(Map<String, dynamic> p) {
    final u = p['utilisateur'];
    if (u is Map) {
      final s =
          '${u['prenom'] ?? ''} ${u['nom'] ?? ''}'.trim();
      if (s.isNotEmpty) return s;
    }
    return 'Prestataire';
  }

  List<String> _aggregatedSpecialites() {
    final set = <String>{};
    for (final p in _providers) {
      final s = p['specialite'];
      if (s is List) {
        for (final e in s) {
          final t = e.toString().trim();
          if (t.isNotEmpty) set.add(t);
        }
      }
    }
    final out = set.toList()..sort();
    if (out.length > 14) return out.sublist(0, 14);
    return out;
  }

  Widget _buildCompactServiceHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(SDSpacing.md, SDSpacing.sm, SDSpacing.md, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
            child: SizedBox(
              width: 88,
              height: 88,
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
                  _providers.isEmpty
                      ? 'Chargement des professionnels…'
                      : '${_providers.length} prestataire${_providers.length > 1 ? 's' : ''}',
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral600,
                  ),
                ),
              ],
            ),
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
              label: 'Dist. : toutes',
              selected: _filterMaxDistanceKm == null,
              onTap: () => setState(() => _filterMaxDistanceKm = null),
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
              label: '≤ 20 km',
              selected: _filterMaxDistanceKm == 20,
              onTap: () => setState(() => _filterMaxDistanceKm = 20),
            ),
            _filterChip(
              label: 'Prix : tous',
              selected: _filterMaxPrice == null,
              onTap: () => setState(() => _filterMaxPrice = null),
            ),
            _filterChip(
              label: '≤ 25k F',
              selected: _filterMaxPrice == 25000,
              onTap: () => setState(() => _filterMaxPrice = 25000),
            ),
            _filterChip(
              label: '≤ 50k F',
              selected: _filterMaxPrice == 50000,
              onTap: () => setState(() => _filterMaxPrice = 50000),
            ),
            _filterChip(
              label: '≤ 100k F',
              selected: _filterMaxPrice == 100000,
              onTap: () => setState(() => _filterMaxPrice = 100000),
            ),
            _filterChip(
              label: 'Note : toutes',
              selected: _filterMinNote == null,
              onTap: () => setState(() => _filterMinNote = null),
            ),
            _filterChip(
              label: '≥ 3 ★',
              selected: _filterMinNote == 3,
              onTap: () => setState(() => _filterMinNote = 3),
            ),
            _filterChip(
              label: '≥ 4 ★',
              selected: _filterMinNote == 4,
              onTap: () => setState(() => _filterMinNote = 4),
            ),
            _filterChip(
              label: 'Actifs',
              selected: _filterActiveOnly,
              onTap: () =>
                  setState(() => _filterActiveOnly = !_filterActiveOnly),
            ),
            _filterChip(
              label: 'Vérifiés',
              selected: _filterVerifiedOnly,
              onTap: () =>
                  setState(() => _filterVerifiedOnly = !_filterVerifiedOnly),
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
  }) {
    return Padding(
      padding: EdgeInsets.only(right: SDSpacing.xs),
      child: FilterChip(
        label: Text(
          label,
          style: SDTypography.labelSmall.copyWith(
            color: selected ? SDColors.primary800 : SDColors.neutral700,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: SDColors.primary100,
        checkmarkColor: SDColors.primary800,
        backgroundColor: SDColors.white,
        side: BorderSide(
          color: selected ? SDColors.primary600 : SDColors.neutral300,
        ),
        showCheckmark: false,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildAggregatedSpecialitesRow() {
    final items = _aggregatedSpecialites();
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: SDSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SDSpacing.md),
            child: Text(
              'Spécialités proposées',
              style: SDTypography.labelMedium.copyWith(
                color: SDColors.neutral600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: SDSpacing.xs),
          SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: SDSpacing.md),
              itemCount: items.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: EdgeInsets.only(right: SDSpacing.xs),
                    child: ActionChip(
                      label: Text(
                        'Toutes',
                        style: SDTypography.labelSmall,
                      ),
                      onPressed: () =>
                          setState(() => _filterSpecialite = null),
                      backgroundColor: _filterSpecialite == null
                          ? SDColors.primary100
                          : SDColors.white,
                    ),
                  );
                }
                final s = items[i - 1];
                final sel = _filterSpecialite == s;
                return Padding(
                  padding: EdgeInsets.only(right: SDSpacing.xs),
                  child: ActionChip(
                    label: Text(s, style: SDTypography.labelSmall),
                    onPressed: () => setState(() {
                      _filterSpecialite = sel ? null : s;
                    }),
                    backgroundColor:
                        sel ? SDColors.primary100 : SDColors.white,
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
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(SDSpacing.borderRadiusMedium),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: photo != null
                          ? AppImage(imageUrl: photo, fit: BoxFit.cover)
                          : Container(
                              color: SDColors.primary50,
                              child: Icon(
                                Icons.person,
                                color: SDColors.primary600,
                                size: 36,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: SDSpacing.sm),
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
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (verified)
                              Icon(
                                Icons.verified,
                                color: SDColors.primary600,
                                size: 20,
                              ),
                          ],
                        ),
                        SizedBox(height: SDSpacing.xxxs),
                        Text(
                          metier,
                          style: SDTypography.bodySmall.copyWith(
                            color: SDColors.neutral600,
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
                    SizedBox(width: SDSpacing.sm),
                    Icon(Icons.near_me_outlined,
                        size: 16, color: SDColors.neutral500),
                    SizedBox(width: SDSpacing.xxxs),
                    Text(
                      '${distKm.toStringAsFixed(distKm < 10 ? 1 : 0)} km',
                      style: SDTypography.bodySmall.copyWith(
                        color: SDColors.neutral700,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (price != null && price > 0)
                    Text(
                      '${price.toInt()} FCFA',
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
                    child: OutlinedButton(
                      onPressed: () => _contactProvider(p),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SDColors.primary700,
                        side: BorderSide(color: SDColors.primary700),
                        padding: EdgeInsets.symmetric(vertical: SDSpacing.xs),
                      ),
                      child: Text(
                        'Contacter',
                        style: SDTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: SDSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const LoginPageScreenM(),
                                  ),
                                );
                                return;
                              }
                              _openCheckoutSheet();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SDColors.primary700,
                        foregroundColor: SDColors.white,
                        padding: EdgeInsets.symmetric(vertical: SDSpacing.xs),
                      ),
                      child: Text(
                        'Commander',
                        style: SDTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: SDColors.white,
                        ),
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

  void _onFavoriteTap() {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Connectez-vous pour ajouter en favoris.',
                style: SDTypography.bodyMedium)),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPageScreenM()),
      );
      return;
    }

    setState(() => _isFavorited = !_isFavorited);
    final msg = _isFavorited ? 'Ajouté aux favoris' : 'Retiré des favoris';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: SDTypography.bodyMedium),
        backgroundColor: SDColors.success500));

    // Appel backend (fire-and-forget)
    if (_isFavorited) {
      final token = auth.token;
      _api
          .addFavorite(
            token: token,
            title: widget.title,
            image: widget.image,
          )
          .catchError((e) => debugPrint('Erreur favoris: $e'));
    }
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
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(SDSpacing.sm, SDSpacing.xs, SDSpacing.sm, SDSpacing.sm),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPageScreenM()),
                );
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
                            final prenom = provider['utilisateur']?['prenom'] ?? '';
                            final nom = provider['utilisateur']?['nom'] ?? 'Inconnu';
                            final price = provider['prixprestataire'] ?? 0;
                            final note = provider['note'] ?? 'N/A';
                            return DropdownMenuItem<String>(
                              value: provider['_id']?.toString(),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '$prenom $nom',
                                      style: SDTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(Icons.star, size: 14, color: SDColors.warning500),
                                  SizedBox(width: SDSpacing.xxxs),
                                  Text(
                                    '$note',
                                    style: SDTypography.labelSmall.copyWith(color: SDColors.neutral600),
                                  ),
                                  SizedBox(width: SDSpacing.xs),
                                  Text(
                                    '${price}F',
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
      final s = '${u['prenom'] ?? ''} ${u['nom'] ?? ''}'.trim();
      if (s.isNotEmpty) return s;
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
