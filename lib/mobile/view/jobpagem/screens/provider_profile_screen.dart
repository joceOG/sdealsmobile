import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../data/models/prestataire.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../data/services/protected_action_intent.dart';
import '../../common/auth_completion.dart';
import '../../../../data/utils/media_url.dart';
import '../screens/fullMapScreenM.dart';
import '../../common/widgets/app_image.dart';
import '../widgets/service_request_sheet.dart';
import '../../historypagem/consultation_recorder.dart';
// ✅ Design System
import '../../../../design_system/design_system.dart';
import '../../provider_dashboard/models/provider_portfolio.dart';
import '../../provider_dashboard/screens/provider_portfolio_detail_screen.dart';
import '../../provider_dashboard/screens/provider_portfolio_screen.dart';

/// 🎯 Page de profil complète d'un prestataire
/// Affiche toutes les informations détaillées, services, avis, portfolio
class ProviderProfileScreen extends StatefulWidget {
  final String providerId;
  final Map<String, dynamic>? providerData; // Cache optionnel
  final int initialTabIndex;

  const ProviderProfileScreen({
    required this.providerId,
    this.providerData,
    this.initialTabIndex = 0,
    super.key,
  });

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();

  Prestataire? _provider;
  Map<String, dynamic>? _prestataireJson;
  bool _isLoading = true;
  String? _error;
  bool _isFavorited = false;
  LatLng? _userLocation;
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _loadProviderData();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      // Position par défaut (Abidjan)
      if (mounted) {
        setState(() {
          _userLocation = const LatLng(5.3599, -4.0083);
        });
      }
    }
  }

  Future<void> _loadProviderData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Si on a des données en cache, les utiliser temporairement
      if (widget.providerData != null) {
        _prestataireJson = widget.providerData;
        _provider = Prestataire.fromBackend(widget.providerData!);
        setState(() {
          _isLoading = false;
        });
        _recordVisitIfAuthenticated();
        // Puis recharger en background pour avoir les données fraîches
        _reloadProviderData();
      } else {
        // Charger depuis l'API
        await _reloadProviderData();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur lors du chargement du profil: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _reloadProviderData() async {
    try {
      final data = await _api.fetchPrestataireById(widget.providerId);
      if (mounted) {
        // GET /prestataire/:id applique désormais le même fallback
        // FieldRecensement que la liste — photoProfil est correctement
        // résolu y compris pour les profils recensement.
        // On ne préserve plus systématiquement l'ancienne photo : si le backend
        // retourne null, c'est soit une suppression explicite soit un profil
        // sans photo publique.
        setState(() {
          _prestataireJson = data;
          _provider = Prestataire.fromBackend(data);
          _isLoading = false;
          _error = null;
        });
        _recordVisitIfAuthenticated();
      }
    } catch (e) {
      debugPrint('Erreur rechargement prestataire: $e');
      if (_provider == null && mounted) {
        setState(() {
          _error = 'Impossible de charger le profil';
          _isLoading = false;
        });
      }
    }
  }

  void _recordVisitIfAuthenticated() {
    final p = _provider;
    if (p == null || !mounted) return;
    AuthCubit authCubit;
    try {
      authCubit = context.read<AuthCubit>();
    } catch (_) {
      return;
    }
    final auth = authCubit.state;
    if (auth is! AuthAuthenticated) return;
    ConsultationRecorder.recordProfileVisit(
      objetType: 'PRESTATAIRE',
      objetId: p.idprestataire,
      titre: p.utilisateur.fullName,
      image: _heroPhotoUrl(),
      categorie: p.service.nomservice,
    );
  }

  String? _heroPhotoUrl() {
    final p = _provider;
    if (p == null) return null;
    return providerPhotoUrl(
      selfie: p.selfie,
      photoProfil: p.utilisateur.photoProfil,
    );
  }

  double? _parsedProviderNote() {
    final raw = _provider?.note?.trim();
    if (raw == null || raw.isEmpty) return null;
    final v = double.tryParse(raw.replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    if (v > 5) return 5;
    return v;
  }

  String _statNoteLabel() {
    final v = _parsedProviderNote();
    if (v == null) return '—';
    final s = v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
    return '$s/5';
  }

  String _statExperienceLabel() {
    final e = _provider?.anneeExperience?.trim();
    if (e == null || e.isEmpty) return '—';
    return e;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: SDColors.white,
        body: Center(
            child: CircularProgressIndicator(color: SDColors.primary700)),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: SDColors.white,
        body: _buildErrorState(),
      );
    }
    if (_provider == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: SDColors.white,
      body: NestedScrollView(
        headerSliverBuilder: _buildHeader,
        body: TabBarView(
          controller: _tab,
          physics: const ClampingScrollPhysics(),
          children: [
            _buildPresentationTab(),
            _buildInterventionTab(),
            _buildAvisTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(SDSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: SDColors.error200),
            SizedBox(height: SDSpacing.sm),
            Text(
              'Erreur',
              style: SDTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: SDColors.neutral800,
              ),
            ),
            SizedBox(height: SDSpacing.xs),
            Text(
              _error ?? 'Une erreur est survenue',
              style:
                  SDTypography.titleSmall.copyWith(color: SDColors.neutral600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SDSpacing.md),
            ElevatedButton.icon(
              onPressed: _loadProviderData,
              icon: Icon(Icons.refresh, color: SDColors.white),
              label: Text('Réessayer',
                  style:
                      SDTypography.labelMedium.copyWith(color: SDColors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: SDColors.primary700,
                foregroundColor: SDColors.white,
                padding: EdgeInsets.symmetric(
                    horizontal: SDSpacing.md, vertical: SDSpacing.xs),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sliver header : hero + identité + infos + tabs ──────────────────────────

  List<Widget> _buildHeader(BuildContext ctx, bool innerScrolled) {
    final p = _provider!;
    final photoUrl = _heroPhotoUrl() ?? '';
    final isUrl =
        photoUrl.isNotEmpty && photoUrl.toLowerCase().startsWith('http');
    final cat = p.service.categorie?.nomcategorie ?? '';
    final note = _parsedProviderNote();
    final hasNote = note != null;
    final hasZone = (p.localisation.trim().isNotEmpty);
    final zones = p.zoneIntervention ?? [];

    return [
      // ── SliverAppBar (héro + barre compacte) ─────────────────────────
      SliverAppBar(
        expandedHeight: 200,
        pinned: true,
        backgroundColor: SDColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: innerScrolled ? 1 : 0,
        shadowColor: SDColors.neutral200,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: innerScrolled ? SDColors.neutral900 : SDColors.white),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        title: innerScrolled
            ? Row(children: [
                // Mini avatar
                ClipOval(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: isUrl
                        ? AppImage(imageUrl: photoUrl, fit: BoxFit.cover)
                        : ColoredBox(
                            color: SDColors.primary50,
                            child: Center(
                              child: Text(
                                p.utilisateur.fullName.isNotEmpty
                                    ? p.utilisateur.fullName[0].toUpperCase()
                                    : '?',
                                style: SDTypography.labelSmall.copyWith(
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
                        p.utilisateur.fullName,
                        overflow: TextOverflow.ellipsis,
                        style: SDTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: SDColors.neutral900,
                        ),
                      ),
                      Text(
                        p.service.nomservice,
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                ),
              ])
            : null,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorited ? Icons.favorite : Icons.favorite_border_rounded,
              color: innerScrolled ? SDColors.neutral700 : SDColors.white,
            ),
            onPressed: _onToggleFavorite,
          ),
          if (!innerScrolled)
            IconButton(
              icon: const Icon(Icons.share_outlined, color: SDColors.white),
              onPressed: _onShareProfile,
            ),
        ],
        flexibleSpace: FlexibleSpaceBar(
          collapseMode: CollapseMode.pin,
          background: _buildHero(photoUrl, isUrl),
        ),
      ),

      // ── Identité : nom · job · catégorie · localisation ───────────────
      SliverToBoxAdapter(
        child: Container(
          color: SDColors.white,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.utilisateur.fullName,
                style: SDTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  color: SDColors.neutral900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                p.service.nomservice,
                style: SDTypography.bodyMedium.copyWith(
                  color: SDColors.primary600,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (cat.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  cat,
                  style: SDTypography.bodySmall
                      .copyWith(color: SDColors.neutral500),
                ),
              ],
              if (p.localisation.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: SDColors.neutral400),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Basé à ${p.localisation.trim()}',
                      style: SDTypography.bodySmall
                          .copyWith(color: SDColors.neutral600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ],
              const SizedBox(height: 12),
              // Stats : note + vérification
              Row(children: [
                if (hasNote) ...[
                  const Icon(Icons.star_rounded,
                      size: 16, color: Color(0xFFFBBF24)),
                  const SizedBox(width: 4),
                  Text(
                    note.toStringAsFixed(1),
                    style: SDTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SDColors.neutral900,
                    ),
                  ),
                  Text(
                    '\u00a0·\u00a018\u00a0avis',
                    style: SDTypography.labelSmall
                        .copyWith(color: SDColors.neutral500),
                  ),
                ],
                if (hasNote && p.verifier) const SizedBox(width: 14),
                if (p.verifier) ...[
                  const Icon(Icons.verified_rounded,
                      size: 16, color: SDColors.primary600),
                  const SizedBox(width: 4),
                  Text(
                    'Identité vérifiée',
                    style: SDTypography.labelSmall.copyWith(
                      color: SDColors.primary700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: SDColors.neutral400),
                ],
              ]),
              const SizedBox(height: 14),
              // Info summary box (vert clair)
              Container(
                decoration: BoxDecoration(
                  color: SDColors.primary50,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasZone)
                      _InfoSummaryRow(
                        icon: Icons.location_on_outlined,
                        label: 'Zone\u00a0: '
                            '${zones.isNotEmpty ? zones.take(2).join(", ") : p.localisation.trim()}'
                            '${zones.length > 2 ? " et environs" : ""}',
                      ),
                    const _InfoSummaryRow(
                      icon: Icons.directions_car_outlined,
                      label: 'Déplacement à domicile',
                    ),
                    _InfoSummaryRow(
                      icon: Icons.payments_outlined,
                      label: (p.tarifHoraireMin != null ||
                              p.tarifHoraireMax != null)
                          ? _formatPriceRange()
                          : (p.prixprestataire > 0
                              ? '${p.prixprestataire.toInt()}\u00a0FCFA'
                              : 'Tarif à convenir après échange'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // ── TabBar sticky ─────────────────────────────────────────────────
      SliverPersistentHeader(
        pinned: true,
        delegate: _ProviderTabBarDelegate(_tab),
      ),
    ];
  }

  // ── Hero banner ───────────────────────────────────────────────────────────

  Widget _buildHero(String photoUrl, bool isUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Photo de fond (paysage)
        isUrl
            ? AppImage(imageUrl: photoUrl, fit: BoxFit.cover)
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [SDColors.primary600, SDColors.primary400],
                  ),
                ),
              ),
        // Dégradé assombrissant le bas
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.55),
                ],
                stops: const [0.4, 1.0],
              ),
            ),
          ),
        ),
        // Avatar rond (gauche)
        Positioned(
          left: 20,
          bottom: 16,
          child: _buildProviderAvatar(photoUrl, isUrl),
        ),
      ],
    );
  }

  Widget _buildProviderAvatar(String photoUrl, bool isUrl) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        color: SDColors.primary50,
      ),
      clipBehavior: Clip.antiAlias,
      child: isUrl
          ? AppImage(imageUrl: photoUrl, fit: BoxFit.cover)
          : Center(
              child: Text(
                _provider!.utilisateur.fullName.isNotEmpty
                    ? _provider!.utilisateur.fullName[0].toUpperCase()
                    : '?',
                style: SDTypography.titleLarge.copyWith(
                  color: SDColors.primary700,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
    );
  }

  // ── Tab 1 — Présentation ─────────────────────────────────────────────────

  Widget _buildPresentationTab() {
    final p = _provider!;
    final hasDesc = p.description != null && p.description!.trim().isNotEmpty;
    final specialites =
        (p.specialite ?? []).where((s) => s.trim().isNotEmpty).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // À propos
        if (hasDesc) ...[
          _ProvSectionTitle('À propos'),
          const SizedBox(height: 10),
          Text(
            p.description!.trim(),
            style: SDTypography.bodyMedium
                .copyWith(color: SDColors.neutral700, height: 1.65),
          ),
          const SizedBox(height: 24),
        ],
        // Interventions proposées
        if (specialites.isNotEmpty) ...[
          _ProvSectionTitle('Interventions proposées'),
          const SizedBox(height: 10),
          ...specialites.take(5).map((s) => _InterventionRow(label: s)),
          const SizedBox(height: 24),
        ],
        // Réalisations (portfolio)
        _buildPortfolioContent(),
      ],
    );
  }

  // ── Tab 2 — Intervention ──────────────────────────────────────────────────

  Widget _buildInterventionTab() {
    final p = _provider!;
    final maps = p.localisationMaps;
    final hasGps = maps != null &&
        maps.latitude.abs() <= 90 &&
        maps.longitude.abs() <= 180;
    final zones =
        (p.zoneIntervention ?? []).where((z) => z.trim().isNotEmpty).toList();
    final rayon = p.rayonIntervention ?? 5.0;
    final note = _parsedProviderNote();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // Zone d'intervention (carte)
        _ProvSectionTitle('Zone d\'intervention'),
        const SizedBox(height: 12),
        if (hasGps) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 200,
              child: Stack(children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(maps.latitude, maps.longitude),
                    zoom: 12.5,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('provider'),
                      position: LatLng(maps.latitude, maps.longitude),
                    ),
                  },
                  circles: {
                    Circle(
                      circleId: const CircleId('zone'),
                      center: LatLng(maps.latitude, maps.longitude),
                      radius: rayon * 1000,
                      fillColor: SDColors.primary600.withOpacity(0.15),
                      strokeColor: SDColors.primary600.withOpacity(0.5),
                      strokeWidth: 2,
                    ),
                  },
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  onTap: (_) => _openProviderFullMap(),
                ),
                // Badge "Zone indicative"
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: SDColors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: SDColors.neutral200),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: SDColors.primary600.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: SDColors.primary600, width: 1.5),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Zone indicative',
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.neutral700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.info_outline_rounded,
                          size: 12, color: SDColors.neutral400),
                    ]),
                  ),
                ),
                // Overlay pour capturer le tap
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(onTap: _openProviderFullMap),
                  ),
                ),
              ]),
            ),
          ),
        ] else ...[
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: SDColors.neutral100,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              'Position GPS non enregistrée',
              style:
                  SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
            ),
          ),
        ],
        // Chips de zones
        if (zones.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: zones
                .map((z) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: SDColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: SDColors.neutral200),
                      ),
                      child: Text(
                        z,
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.neutral700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Confirmez votre adresse avec le professionnel.',
          style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
        ),
        const SizedBox(height: 24),

        // Informations pratiques
        _ProvSectionTitle('Informations pratiques'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SDColors.neutral100),
          ),
          child: Column(children: [
            _PracticalInfoRow(
                icon: Icons.phone_outlined,
                label: 'Adresse et besoin à préciser'),
            const Divider(height: 1, color: SDColors.neutral100),
            _PracticalInfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Créneau à convenir ensemble'),
            const Divider(height: 1, color: SDColors.neutral100),
            _PracticalInfoRow(
                icon: Icons.description_outlined,
                label: 'Montant et déplacement à confirmer'),
          ]),
        ),
        const SizedBox(height: 24),

        // Confiance et avis
        _ProvSectionTitle('Confiance et avis'),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.verifier)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SDColors.primary50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SDColors.primary100),
                  ),
                  child: Row(children: [
                    const Icon(Icons.verified_rounded,
                        size: 16, color: SDColors.primary600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Identité vérifiée',
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.primary700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.info_outline_rounded,
                        size: 14, color: SDColors.primary400),
                  ]),
                ),
              ),
            if (p.verifier && note != null) const SizedBox(width: 10),
            if (note != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SDColors.neutral50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SDColors.neutral200),
                ),
                child: Column(children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded,
                        size: 18, color: Color(0xFFFBBF24)),
                    const SizedBox(width: 4),
                    Text(
                      '${note.toStringAsFixed(1)}\u00a0/\u00a05',
                      style: SDTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: SDColors.neutral900,
                      ),
                    ),
                  ]),
                  Text(
                    '18\u00a0avis',
                    style: SDTypography.labelSmall
                        .copyWith(color: SDColors.neutral500),
                  ),
                ]),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SDColors.neutral50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Les avis clients apparaîtront ici dès la première mission terminée.',
            style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
          ),
        ),
        const SizedBox(height: 24),

        // Signaler ce profil
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SDColors.neutral100),
          ),
          child: ListTile(
            leading: const Icon(Icons.flag_outlined,
                size: 20, color: SDColors.neutral500),
            title: Text(
              'Signaler ce profil',
              style:
                  SDTypography.bodyMedium.copyWith(color: SDColors.neutral700),
            ),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: SDColors.neutral400),
            dense: true,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onTap: _onReportProfile,
          ),
        ),
      ],
    );
  }

  // ── Tab 3 — Avis ─────────────────────────────────────────────────────────

  Widget _buildAvisTab() {
    final note = _parsedProviderNote();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        if (note != null) ...[
          Row(children: [
            const Icon(Icons.star_rounded, size: 22, color: Color(0xFFFBBF24)),
            const SizedBox(width: 6),
            Text(
              '${note.toStringAsFixed(1)}\u00a0/\u00a05',
              style: SDTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: SDColors.neutral900,
              ),
            ),
          ]),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SDColors.neutral50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            const Icon(Icons.rate_review_outlined,
                size: 40, color: SDColors.neutral300),
            const SizedBox(height: 10),
            Text(
              'Aucun avis pour le moment',
              style: SDTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: SDColors.neutral700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Les avis clients apparaîtront ici dès la première mission terminée.',
              textAlign: TextAlign.center,
              style:
                  SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _heroActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: SDColors.neutral900.withOpacity(0.38),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: SDColors.white, size: 22),
        ),
      ),
    );
  }

  /// En-tête visuel entièrement défilant (même esprit que la fiche offre freelance).
  Widget _buildScrollableHero() {
    final photoUrl = _heroPhotoUrl() ?? '';
    final isUrl =
        photoUrl.isNotEmpty && photoUrl.toLowerCase().startsWith('http');
    final mq = MediaQuery.of(context);
    final topInset = mq.padding.top;
    final heroHeight = SDResponsive.heroHeight(context) + topInset;

    return SizedBox(
      height: heroHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: isUrl
                ? AppImage(
                    imageUrl: photoUrl,
                    width: double.infinity,
                    height: heroHeight,
                    fit: BoxFit.cover,
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          SDColors.primary600,
                          SDColors.primary400,
                        ],
                      ),
                    ),
                  ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    SDColors.neutral900.withOpacity(0.25),
                    SDColors.neutral900.withOpacity(0.68),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: topInset + 4,
            left: 4,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: SDColors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            top: topInset + 4,
            right: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _heroActionButton(
                  icon: Icons.ios_share_rounded,
                  onPressed: _onShareProfile,
                ),
                SizedBox(width: SDSpacing.xs),
                _heroActionButton(
                  icon: _isFavorited ? Icons.favorite : Icons.favorite_border,
                  onPressed: _onToggleFavorite,
                ),
                SizedBox(width: SDSpacing.xs),
                _heroActionButton(
                  icon: Icons.flag_outlined,
                  onPressed: _onReportProfile,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.only(top: topInset * 0.35),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: SDColors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: SDColors.neutral900.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: isUrl
                          ? AppImage(
                              imageUrl: photoUrl,
                              fit: BoxFit.cover,
                            )
                          : _buildDefaultAvatar(),
                    ),
                  ),
                  if (_provider!.verifier)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: SDColors.primary600,
                          shape: BoxShape.circle,
                          border: Border.all(color: SDColors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: SDColors.white,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: SDColors.primary700.withOpacity(0.2),
      child: Icon(
        Icons.person,
        color: SDColors.primary700,
        size: 60,
      ),
    );
  }

  Widget _buildHeaderInfo() {
    final cat = _provider!.service.categorie?.nomcategorie;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cat != null && cat.isNotEmpty) ...[
          Text(
            cat,
            style: SDTypography.labelMedium.copyWith(
              color: SDColors.primary600,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: SDSpacing.xs),
        ],
        Text(
          _provider!.utilisateur.fullName,
          style: SDTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: SDColors.neutral900,
          ),
        ),
        SizedBox(height: SDSpacing.xs),
        Text(
          _provider!.service.nomservice,
          style: SDTypography.titleSmall.copyWith(
            color: SDColors.neutral700,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: SDSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildStatItem(
                Icons.star_rounded,
                _statNoteLabel(),
                'Note',
              ),
            ),
            Expanded(
              child: _buildStatItem(
                Icons.work_outline_rounded,
                _statExperienceLabel(),
                'Expérience',
              ),
            ),
            Expanded(
              child: _buildStatItem(
                Icons.location_on_outlined,
                _calculateDistance(),
                'Distance',
              ),
            ),
          ],
        ),
        SizedBox(height: SDSpacing.md),
        Material(
          color: SDColors.white,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: SDSpacing.md,
              vertical: SDSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SDColors.neutral200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payments_outlined,
                    color: SDColors.neutral900, size: 22),
                SizedBox(width: SDSpacing.xs),
                Flexible(
                  child: Text(
                    (_provider!.tarifHoraireMin != null ||
                            _provider!.tarifHoraireMax != null)
                        ? _formatPriceRange()
                        : '${_provider!.prixprestataire.toInt()} FCFA',
                    style: SDTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: SDColors.neutral900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: SDColors.neutral900, size: 26),
        SizedBox(height: SDSpacing.xxxs),
        Text(
          value,
          style: SDTypography.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: SDColors.neutral900,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: SDTypography.bodySmall.copyWith(
            color: SDColors.neutral600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _calculateDistance() {
    if (_userLocation == null || _provider!.localisationMaps == null) {
      return 'N/A';
    }

    final distance = Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      _provider!.localisationMaps!.latitude,
      _provider!.localisationMaps!.longitude,
    );

    if (distance < 1000) {
      return '${distance.toInt()}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }

  String _formatPriceRange() {
    final min = _provider!.tarifHoraireMin;
    final max = _provider!.tarifHoraireMax;

    if (min != null && max != null) {
      return '${min.toInt()} - ${max.toInt()} FCFA/h';
    } else if (min != null) {
      return 'À partir de ${min.toInt()} FCFA/h';
    } else if (max != null) {
      return "Jusqu'à ${max.toInt()} FCFA/h";
    } else {
      return '${_provider!.prixprestataire.toInt()} FCFA/h';
    }
  }

  Widget _buildAboutContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        _buildSection(
          'Description',
          Icons.description_outlined,
          child: Text(
            _provider!.description ??
                'Prestataire professionnel et expérimenté.',
            style: SDTypography.bodyMedium.copyWith(height: 1.5),
          ),
        ),
        SizedBox(height: SDSpacing.lg),

        // Spécialités
        if (_provider!.specialite != null && _provider!.specialite!.isNotEmpty)
          _buildSection(
            'Spécialités',
            Icons.auto_awesome_outlined,
            child: Wrap(
              spacing: SDSpacing.xs,
              runSpacing: SDSpacing.xs,
              children: _provider!.specialite!
                  .map((s) => Chip(
                        label: Text(
                          s,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SDTypography.labelMedium,
                        ),
                        backgroundColor: SDColors.primary50,
                        side: BorderSide(color: SDColors.primary200),
                        labelStyle: SDTypography.labelMedium.copyWith(
                          color: SDColors.primary800,
                        ),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ),
        if (_provider!.specialite != null && _provider!.specialite!.isNotEmpty)
          SizedBox(height: SDSpacing.lg),

        // Zones d'intervention
        if (_provider!.zoneIntervention != null &&
            _provider!.zoneIntervention!.isNotEmpty)
          _buildSection(
            'Zones d\'intervention',
            Icons.location_city_outlined,
            child: Wrap(
              spacing: SDSpacing.xs,
              runSpacing: SDSpacing.xs,
              children: _provider!.zoneIntervention!
                  .map((z) => Chip(
                        label: Text(
                          z,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SDTypography.labelMedium,
                        ),
                        avatar: Icon(Icons.location_on_outlined,
                            size: 16, color: SDColors.neutral900),
                        backgroundColor: SDColors.neutral100,
                        side: BorderSide(color: SDColors.neutral200),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ),
        if (_provider!.zoneIntervention != null &&
            _provider!.zoneIntervention!.isNotEmpty)
          SizedBox(height: SDSpacing.lg),

        // Diplômes et certifications
        if (_provider!.diplomeCertificat != null &&
            _provider!.diplomeCertificat!.isNotEmpty)
          _buildSection(
            'Diplômes & Certifications',
            Icons.school_outlined,
            child: Column(
              children: _provider!.diplomeCertificat!
                  .map((d) => ListTile(
                        leading: Icon(Icons.verified_outlined,
                            color: SDColors.neutral900, size: 22),
                        title: Text(
                          d,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: SDTypography.bodyMedium,
                        ),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ))
                  .toList(),
            ),
          ),
        if (_provider!.diplomeCertificat != null &&
            _provider!.diplomeCertificat!.isNotEmpty)
          SizedBox(height: SDSpacing.lg),

        // Localisation compacte (adresse + vignette map)
        _buildCompactLocationBlock(),
      ],
    );
  }

  Widget _buildCompactLocationBlock() {
    final address = _provider!.localisation.trim().isNotEmpty
        ? _provider!.localisation.trim()
        : 'Adresse non renseignée';
    final maps = _provider!.localisationMaps;
    final hasGps = maps != null &&
        maps.latitude.abs() <= 90 &&
        maps.longitude.abs() <= 180;
    final subtitle = _locationSubtitle(hasGps: hasGps);

    return Padding(
      padding: EdgeInsets.only(bottom: SDSpacing.md),
      child: InkWell(
        onTap: hasGps ? _openProviderFullMap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 18,
                          color: SDColors.primary600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Localisation',
                          style: SDTypography.titleSmall.copyWith(
                            color: SDColors.neutral900,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      address,
                      style: SDTypography.bodyLarge.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.neutral500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildLocationThumb(hasGps: hasGps, maps: maps),
            ],
          ),
        ),
      ),
    );
  }

  String? _locationSubtitle({required bool hasGps}) {
    final rayon = _provider!.rayonIntervention;
    if (rayon != null && rayon > 0) {
      final r = rayon == rayon.roundToDouble()
          ? rayon.toInt().toString()
          : rayon.toStringAsFixed(1);
      return 'Déplacement possible dans un rayon de $r km';
    }

    if (_userLocation != null && hasGps) {
      final maps = _provider!.localisationMaps!;
      final meters = Geolocator.distanceBetween(
        _userLocation!.latitude,
        _userLocation!.longitude,
        maps.latitude,
        maps.longitude,
      );
      if (meters < 1000) {
        return 'À ${meters.toInt()} m de vous';
      }
      return 'À ${(meters / 1000).toStringAsFixed(1)} km de vous';
    }

    if (!hasGps) {
      return 'Position GPS non enregistrée';
    }
    return 'Activez la localisation pour voir la distance';
  }

  Widget _buildLocationThumb({
    required bool hasGps,
    required LocalisationMaps? maps,
  }) {
    const size = 88.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: size,
        height: size,
        child: !hasGps || maps == null
            ? Container(
                color: SDColors.neutral100,
                alignment: Alignment.center,
                child: Icon(
                  Icons.map_outlined,
                  color: SDColors.neutral400,
                  size: 28,
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(maps.latitude, maps.longitude),
                      zoom: 14.5,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('provider'),
                        position: LatLng(maps.latitude, maps.longitude),
                      ),
                    },
                    liteModeEnabled: true,
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
                    rotateGesturesEnabled: false,
                    scrollGesturesEnabled: false,
                    zoomGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    onTap: (_) => _openProviderFullMap(),
                  ),
                  // Overlay pour capturer le tap (Android liteMode)
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(onTap: _openProviderFullMap),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _openProviderFullMap() {
    final maps = _provider?.localisationMaps;
    if (maps == null) return;
    final pos = LatLng(maps.latitude, maps.longitude);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullMapScreenM(
          initialPosition: pos,
          providers: [_provider!.toJson()],
          searchRadius: _provider!.rayonIntervention ?? 10.0,
          selectedCategory: _provider!.service.categorie?.nomcategorie,
          selectedService: _provider!.service.nomservice,
        ),
      ),
    );
  }

  Widget _buildServicesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          'Service principal',
          Icons.work_outline_rounded,
          child: Material(
            color: SDColors.white,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(SDSpacing.sm),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(SDSpacing.sm),
                    decoration: BoxDecoration(
                      color: SDColors.primary50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.build_circle_outlined,
                        color: SDColors.neutral900, size: 24),
                  ),
                  SizedBox(width: SDSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _provider!.service.nomservice,
                          style: SDTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((_provider!.service.categorie?.nomcategorie ?? '')
                            .isNotEmpty)
                          Text(
                            _provider!.service.categorie?.nomcategorie ?? '',
                            style: SDTypography.bodySmall.copyWith(
                              color: SDColors.neutral600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${_provider!.prixprestataire.toInt()} FCFA',
                    style: SDTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: SDColors.neutral900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: SDSpacing.sm),
        Text(
          'Ce prestataire propose des services de qualité avec une expertise reconnue.',
          style: SDTypography.bodyMedium.copyWith(
            color: SDColors.neutral600,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _reviewStarIcon(int index, double n) {
    final i = index + 1;
    if (n >= i) {
      return Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 22);
    }
    if (n > index && n < i) {
      return Icon(Icons.star_half_rounded,
          color: Colors.amber.shade700, size: 22);
    }
    return Icon(Icons.star_outline_rounded,
        color: Colors.amber.shade400, size: 22);
  }

  Widget _buildReviewsContent() {
    final note = _parsedProviderNote();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note & avis',
          style: SDTypography.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: SDSpacing.sm),
        if (note != null) ...[
          Material(
            color: SDColors.white,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(SDSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SDColors.neutral200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.toStringAsFixed(
                      note == note.roundToDouble() ? 0 : 1,
                    ),
                    style: SDTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                  SizedBox(height: SDSpacing.xxxs),
                  Row(
                    children: List.generate(
                      5,
                      (i) => _reviewStarIcon(i, note),
                    ),
                  ),
                  SizedBox(height: SDSpacing.xs),
                  Text(
                    'Note moyenne (agrégée)',
                    style: SDTypography.bodySmall
                        .copyWith(color: SDColors.neutral600),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: SDSpacing.md),
        ],
        Text(
          'Avis clients',
          style: SDTypography.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: SDSpacing.sm),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(SDSpacing.lg),
          decoration: BoxDecoration(
            color: SDColors.white,
            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
            border: Border.all(color: SDColors.neutral200),
          ),
          child: Column(
            children: [
              Icon(Icons.reviews_outlined,
                  size: 48, color: SDColors.neutral400),
              SizedBox(height: SDSpacing.sm),
              Text(
                'Aucun avis pour le moment',
                textAlign: TextAlign.center,
                style: SDTypography.titleSmall.copyWith(
                  color: SDColors.neutral800,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: SDSpacing.xs),
              Text(
                'Les avis apparaîtront ici après les prestations réalisées.',
                textAlign: TextAlign.center,
                style: SDTypography.bodySmall
                    .copyWith(color: SDColors.neutral600, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioContent() {
    final raw = _prestataireJson ?? widget.providerData;
    final portfolio = raw != null
        ? parseProviderPortfolioFromPrestataireJson(raw)
        : const ProviderPortfolioData(
            entries: [],
            capabilities: ProviderPortfolioCapabilities.readOnlyPrestataire,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Réalisations',
          style: SDTypography.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: SDSpacing.sm),
        if (portfolio.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(SDSpacing.lg),
            decoration: BoxDecoration(
              color: SDColors.white,
              borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
              border: Border.all(color: SDColors.neutral200),
            ),
            child: Column(
              children: [
                Icon(Icons.photo_library_outlined,
                    size: 56, color: SDColors.neutral400),
                SizedBox(height: SDSpacing.md),
                Text(
                  'Aucune réalisation publiée pour le moment',
                  textAlign: TextAlign.center,
                  style: SDTypography.bodyMedium
                      .copyWith(color: SDColors.neutral600, height: 1.45),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: portfolio.entries.length,
            itemBuilder: (context, index) {
              final entry = portfolio.entries[index];
              return ProviderPortfolioEntryCard(
                entry: entry,
                photosOnly: portfolio.photosOnly,
                showMenu: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderPortfolioDetailScreen(
                        entry: entry,
                        allEntries: portfolio.entries,
                      ),
                    ),
                  );
                },
                onMenu: () {},
              );
            },
          ),
      ],
    );
  }

  /// Emplacement prêt pour une liste horizontale de profils proches.
  Widget _buildSimilarProvidersContent() {
    return _buildSection(
      'Prestataires similaires',
      Icons.people_outline,
      child: Text(
        'Bientôt disponible.',
        style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral600),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: SDColors.neutral900, size: 22),
            SizedBox(width: SDSpacing.xs),
            Expanded(
              child: Text(
                title,
                style: SDTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: SDColors.neutral900,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: SDSpacing.sm),
        child,
      ],
    );
  }

  Widget _buildBottomActions() {
    return Builder(
      builder: (context) {
        // SDResponsive.systemBottomInset choisit max(padding, viewPadding)
        // pour être fiable sur EMUI/Huawei qui ne remontent pas correctement
        // MediaQuery.padding.bottom (navigation 3 boutons).
        final double sysBottom = SDResponsive.systemBottomInset(context);
        return Container(
          padding: EdgeInsets.fromLTRB(
            SDSpacing.sm,
            SDSpacing.sm,
            SDSpacing.sm,
            SDSpacing.sm + sysBottom,
          ),
          decoration: BoxDecoration(
            color: SDColors.white,
            boxShadow: [
              BoxShadow(
                color: SDColors.neutral900.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _onContactProvider,
                  icon: Icon(Icons.phone_outlined, color: SDColors.primary700),
                  label: Text(
                    'Appeler',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SDTypography.labelMedium.copyWith(
                      color: SDColors.primary700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SDColors.primary700,
                    side: const BorderSide(
                        color: SDColors.primary700, width: 1.5),
                    minimumSize: const Size(double.infinity, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: SDSpacing.xs,
                      vertical: SDSpacing.xs,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              SizedBox(width: SDSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _onRequestService,
                  icon: const Icon(Icons.send_rounded,
                      color: SDColors.white, size: 18),
                  label: Text(
                    'Demander un service',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SDTypography.labelMedium.copyWith(
                      color: SDColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SDColors.primary700,
                    foregroundColor: SDColors.white,
                    minimumSize: const Size(double.infinity, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: SDSpacing.xs,
                      vertical: SDSpacing.xs,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Actions
  void _onShareProfile() async {
    final text =
        'Découvrez ${_provider!.utilisateur.fullName} - ${_provider!.service.nomservice} sur Soutrali Deals';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lien copié dans le presse-papiers')),
      );
    }
  }

  void _onToggleFavorite() async {
    final ready = await ensureAuthenticatedForAction(
      context: context,
      type: ProtectedActionType.addFavorite,
      originRoute: 'providerProfile',
      technicalId: _provider?.idprestataire,
      explanation: 'Connectez-vous pour ajouter un favori',
    );
    if (!ready || !mounted) return;
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return;
    if (_provider == null) return;

    final previous = _isFavorited;
    setState(() => _isFavorited = !_isFavorited);

    try {
      final nowFavorite = await _api.toggleFavorite(
        token: auth.token,
        objetType: 'PRESTATAIRE',
        objetId: _provider!.idprestataire,
        titre: _provider!.utilisateur.fullName,
        image: _provider!.utilisateur.photoProfil,
      );
      if (!mounted) return;
      setState(() => _isFavorited = nowFavorite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nowFavorite ? 'Ajouté aux favoris' : 'Retiré des favoris',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFavorited = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec favoris : $e')),
      );
    }
  }

  void _onReportProfile() async {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour signaler.')),
      );
      context.push('/login');
      return;
    }
    if (_provider == null) return;

    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Signaler ce prestataire'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Décrivez le problème...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Signaler'),
            ),
          ],
        );
      },
    );

    if (result != true || !mounted) return;
    final reason = controller.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un motif.')),
      );
      return;
    }

    try {
      await _api.createReport(
        token: auth.token,
        targetType: 'PRESTATAIRE',
        targetId: _provider!.idprestataire,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signalement envoyé. Merci.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec du signalement : $e')),
      );
    }
  }

  void _onContactProvider() async {
    final ready = await ensureAuthenticatedForAction(
      context: context,
      type: ProtectedActionType.callProvider,
      originRoute: 'providerProfile',
      technicalId: _provider?.idprestataire,
      explanation: 'Connectez-vous pour contacter ce professionnel',
    );
    if (!ready || !mounted) return;
    final result =
        await DialerSession.openOnce(_provider?.utilisateur.telephone);
    if (!mounted) return;
    await showDialerFeedback(context, result);
  }

  void _onRequestService() async {
    final ready = await ensureAuthenticatedForAction(
      context: context,
      type: ProtectedActionType.requestService,
      originRoute: 'providerProfile',
      technicalId: _provider?.idprestataire,
      explanation: 'Connectez-vous pour demander un service',
    );
    if (!ready || !mounted) return;
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated || _provider == null) return;
    _openRequestQuoteSheet(auth);
  }

  void _openRequestQuoteSheet(AuthAuthenticated auth) {
    showServiceRequestSheet(
      context: context,
      token: auth.token,
      utilisateurId: auth.utilisateur.idutilisateur,
      prestataireId: _provider!.idprestataire,
      serviceId: _provider!.service.idservice,
      serviceName: _provider!.service.nomservice,
      providerName: _provider!.utilisateur.fullName,
      providerMetier: _provider!.service.nomservice,
      providerPhotoUrl: _heroPhotoUrl(),
      prix: _provider!.prixprestataire,
      apiClient: _api,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets utilitaires locaux
// ─────────────────────────────────────────────────────────────────────────────

/// TabBar sticky delegate.
class _ProviderTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController controller;
  const _ProviderTabBarDelegate(this.controller);

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: const BoxDecoration(
        color: SDColors.white,
        border: Border(bottom: BorderSide(color: SDColors.neutral100)),
      ),
      child: TabBar(
        controller: controller,
        labelColor: SDColors.primary600,
        unselectedLabelColor: SDColors.neutral500,
        indicatorColor: SDColors.primary600,
        indicatorWeight: 2.5,
        labelStyle:
            SDTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: SDTypography.labelMedium,
        tabs: const [
          Tab(text: 'Présentation'),
          Tab(text: 'Intervention'),
          Tab(text: 'Avis'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_ProviderTabBarDelegate old) => false;
}

/// Ligne dans la boîte résumé info (zone / déplacement / tarif).
class _InfoSummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoSummaryRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: SDColors.primary700),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: SDTypography.bodySmall.copyWith(
              color: SDColors.primary800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ]),
    );
  }
}

/// Titre de section (Présentation tab).
class _ProvSectionTitle extends StatelessWidget {
  final String text;
  const _ProvSectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: SDTypography.titleSmall.copyWith(
        fontWeight: FontWeight.w800,
        color: SDColors.neutral900,
      ),
    );
  }
}

/// Ligne d'intervention proposée (spécialité).
class _InterventionRow extends StatelessWidget {
  final String label;
  const _InterventionRow({required this.label});

  static IconData _icon(String s) {
    final n = s.toLowerCase();
    if (n.contains('fuite') || n.contains('eau'))
      return Icons.water_drop_outlined;
    if (n.contains('robinet') || n.contains('sanitaire')) {
      return Icons.plumbing_outlined;
    }
    if (n.contains('débouchage') || n.contains('canalisation')) {
      return Icons.settings_input_component_outlined;
    }
    if (n.contains('électr')) return Icons.electrical_services_outlined;
    if (n.contains('peinture')) return Icons.format_paint_outlined;
    if (n.contains('carrel')) return Icons.grid_view_rounded;
    if (n.contains('menuis') || n.contains('bois'))
      return Icons.carpenter_outlined;
    if (n.contains('clima') || n.contains('froid'))
      return Icons.ac_unit_outlined;
    if (n.contains('jardin')) return Icons.yard_outlined;
    if (n.contains('nettoy')) return Icons.cleaning_services_outlined;
    return Icons.build_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SDColors.neutral100),
      ),
      child: Row(children: [
        Icon(_icon(label), size: 20, color: SDColors.primary600),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: SDTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: SDColors.neutral900,
            ),
          ),
        ),
      ]),
    );
  }
}

/// Ligne dans "Informations pratiques".
class _PracticalInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PracticalInfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(children: [
        Icon(icon, size: 18, color: SDColors.primary600),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral700),
          ),
        ),
      ]),
    );
  }
}
