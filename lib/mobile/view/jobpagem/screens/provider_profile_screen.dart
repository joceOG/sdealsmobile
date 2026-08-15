import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../data/models/prestataire.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart';
import '../screens/fullMapScreenM.dart';
import '../../common/widgets/app_image.dart';
import '../widgets/service_request_sheet.dart';
// ✅ Design System
import '../../../../design_system/design_system.dart';

/// 🎯 Page de profil complète d'un prestataire
/// Affiche toutes les informations détaillées, services, avis, portfolio
class ProviderProfileScreen extends StatefulWidget {
  final String providerId;
  final Map<String, dynamic>? providerData; // Cache optionnel

  const ProviderProfileScreen({
    required this.providerId,
    this.providerData,
    super.key,
  });

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final ApiClient _api = ApiClient();

  /// Remettre à `true` quand le catalogue aura assez de profils proches.
  static const bool _showSimilarProviders = false;
  
  Prestataire? _provider;
  bool _isLoading = true;
  String? _error;
  bool _isFavorited = false;
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
    _getCurrentLocation();
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
        _provider = Prestataire.fromBackend(widget.providerData!);
        setState(() {
          _isLoading = false;
        });
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
        setState(() {
          _provider = Prestataire.fromBackend(data);
          _isLoading = false;
          _error = null;
        });
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

  String? _heroPhotoUrl() {
    final p = _provider;
    if (p == null) return null;
    final selfie = p.selfie?.trim() ?? '';
    if (selfie.isNotEmpty && selfie.toLowerCase().startsWith('http')) {
      return selfie;
    }
    final prof = p.utilisateur.photoProfil?.trim() ?? '';

    if (prof.isNotEmpty && prof.toLowerCase().startsWith('http')) {
      return prof;
    }
    return null;
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
    return Scaffold(
      backgroundColor: SDColors.neutral50,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: SDColors.primary700))
          : _error != null
              ? _buildErrorState()
              : _buildProfileContent(),
      bottomNavigationBar: _provider != null ? _buildBottomActions() : null,
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
              style: SDTypography.titleSmall.copyWith(color: SDColors.neutral600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SDSpacing.md),
            ElevatedButton.icon(
              onPressed: _loadProviderData,
              icon: Icon(Icons.refresh, color: SDColors.white),
              label: Text('Réessayer', style: SDTypography.labelMedium.copyWith(color: SDColors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: SDColors.primary700,
                foregroundColor: SDColors.white,
                padding: EdgeInsets.symmetric(horizontal: SDSpacing.md, vertical: SDSpacing.xs),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    if (_provider == null) return const SizedBox.shrink();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildScrollableHero()),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              SDSpacing.sm,
              SDSpacing.sm,
              SDSpacing.sm,
              SDSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderInfo(),
                SizedBox(height: SDSpacing.lg),
                _buildAboutContent(),
                SizedBox(height: SDSpacing.lg),
                _buildServicesContent(),
                SizedBox(height: SDSpacing.lg),
                _buildReviewsContent(),
                SizedBox(height: SDSpacing.lg),
                _buildPortfolioContent(),
                if (_showSimilarProviders) ...[
                  SizedBox(height: SDSpacing.lg),
                  _buildSimilarProvidersContent(),
                ],
              ],
            ),
          ),
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
    final heroHeight = 280.0 + topInset;

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
                Icon(Icons.payments_outlined, color: SDColors.neutral900, size: 22),
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
              _provider!.description ?? 'Prestataire professionnel et expérimenté.',
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
          if (_provider!.zoneIntervention != null && _provider!.zoneIntervention!.isNotEmpty)
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
          if (_provider!.zoneIntervention != null && _provider!.zoneIntervention!.isNotEmpty)
            SizedBox(height: SDSpacing.lg),
          
          // Diplômes et certifications
          if (_provider!.diplomeCertificat != null && _provider!.diplomeCertificat!.isNotEmpty)
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
          if (_provider!.diplomeCertificat != null && _provider!.diplomeCertificat!.isNotEmpty)
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
          selectedCategory:
              _provider!.service.categorie?.nomcategorie,
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
      return Icon(Icons.star_half_rounded, color: Colors.amber.shade700, size: 22);
    }
    return Icon(Icons.star_outline_rounded, color: Colors.amber.shade400, size: 22);
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
              borderRadius:
                  BorderRadius.circular(SDSpacing.borderRadiusLarge),
              border: Border.all(color: SDColors.neutral200),
            ),
            child: Column(
              children: [
                Icon(Icons.reviews_outlined,
                    size: 48, color: SDColors.neutral400),
                SizedBox(height: SDSpacing.sm),
                Text(
                  'Aucun avis détaillé pour le moment',
                  textAlign: TextAlign.center,
                  style: SDTypography.titleSmall.copyWith(
                    color: SDColors.neutral800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: SDSpacing.xs),
                Text(
                  'Les retours clients détaillés s’afficheront ici lorsque '
                  'cette fonctionnalité sera branchée sur l’API.',
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
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portfolio',
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
                Icon(Icons.photo_library_outlined,
                    size: 56, color: SDColors.neutral400),
                SizedBox(height: SDSpacing.md),
                Text(
                  'Aucune réalisation publiée pour l’instant. Le portfolio '
                  'pourra être enrichi depuis l’espace prestataire lorsque '
                  'des photos seront disponibles côté serveur.',
                  textAlign: TextAlign.center,
                  style: SDTypography.bodyMedium
                      .copyWith(color: SDColors.neutral600, height: 1.45),
                ),
              ],
            ),
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
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(SDSpacing.sm),
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
                  style: SDTypography.labelMedium.copyWith(
                    color: SDColors.primary700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SDColors.primary700,
                  side: BorderSide(color: SDColors.primary700, width: 1.5),
                  padding: EdgeInsets.symmetric(vertical: SDSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(width: SDSpacing.sm),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _onRequestService,
                icon: Icon(Icons.send_rounded, color: SDColors.white),
                label: Text(
                  'Demander un service',
                  style: SDTypography.labelMedium.copyWith(
                    color: SDColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SDColors.primary700,
                  foregroundColor: SDColors.white,
                  padding: EdgeInsets.symmetric(vertical: SDSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Actions
  void _onShareProfile() async {
    final text = 'Découvrez ${_provider!.utilisateur.fullName} - ${_provider!.service.nomservice} sur Soutrali Deals';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lien copié dans le presse-papiers')),
      );
    }
  }

  void _onToggleFavorite() async {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour ajouter en favoris.')),
      );
      context.push('/login');
      return;
    }
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
    final phone = _provider?.utilisateur.telephone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro de téléphone non disponible')),
      );
      return;
    }

    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'appeler ce numéro')),
        );
      }
    }
  }

  void _onRequestService() {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter pour demander un devis.')),
      );
      context.push('/login');
      return;
    }

    // Ouvrir le formulaire de demande de devis
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
      prix: _provider!.prixprestataire,
      apiClient: _api,
    );
  }
}

