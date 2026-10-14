import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/provider_profile_bloc.dart';
import '../bloc/provider_profile_event.dart';
import '../bloc/provider_profile_state.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../data/utils/display_text.dart';
import '../../../../design_system/design_system.dart';
import '../../common/widgets/app_image.dart';
import 'provider_profile_edit_screen.dart';
import 'provider_portfolio_screen.dart';
import 'provider_edit_zone_screen.dart';
import 'provider_reviews_screen.dart';

/// Profil = fiche éditable (pas un 2ᵉ dashboard).
/// Dispo + KPI ops restent sur Accueil uniquement.
class ProviderProfileScreen extends StatefulWidget {
  final String? prestataireDocId;
  final bool embeddedInTab;
  final bool lookupSettled;

  const ProviderProfileScreen({
    super.key,
    this.prestataireDocId,
    this.embeddedInTab = false,
    this.lookupSettled = false,
  });

  @override
  ProviderProfileScreenState createState() => ProviderProfileScreenState();
}

class ProviderProfileScreenState extends State<ProviderProfileScreen> {
  String? _prestataireId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void didUpdateWidget(covariant ProviderProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.prestataireDocId;
    if (next != null &&
        next.isNotEmpty &&
        next != oldWidget.prestataireDocId) {
      _prestataireId = next;
      _refreshProfile();
    }
  }

  void _bootstrap() {
    if (!mounted) return;
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return;

    context.read<ProviderProfileBloc>().setToken(auth.token);
    // Attendre le vrai docId prestataire (comme Planning).
    _prestataireId = widget.prestataireDocId;
    if (_prestataireId != null && _prestataireId!.isNotEmpty) {
      _refreshProfile();
    }
  }

  void _refreshProfile() {
    if (_prestataireId == null || _prestataireId!.isEmpty) return;
    context
        .read<ProviderProfileBloc>()
        .add(LoadProviderProfile(_prestataireId!));
  }

  /// AppBar parent — enrichissement profil (≠ finalisation KYC).
  void openEdit({ProviderProfileEditIntent intent = ProviderProfileEditIntent.auto}) {
    if (_prestataireId == null || _prestataireId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil prestataire non chargé')),
      );
      return;
    }

    final currentState = context.read<ProviderProfileBloc>().state;
    if (currentState is! ProviderProfileLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chargement du profil en cours…')),
      );
      return;
    }

    final profileBloc = context.read<ProviderProfileBloc>();
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: profileBloc,
          child: ProviderProfileEditScreen(
            prestataireId: _prestataireId!,
            initial: currentState,
            intent: intent,
          ),
        ),
      ),
    ).then((saved) {
      if (saved == true) _refreshProfile();
    });
  }

  void openCompleteProfile() =>
      openEdit(intent: ProviderProfileEditIntent.complete);

  num? _asNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString().replaceAll(',', '.'));
  }

  String _authDisplayName() {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return '';
    return joinPersonName(
      prenom: auth.utilisateur.prenom,
      nom: auth.utilisateur.nom,
      fallback: '',
    );
  }

  String? _authPhoto() {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return null;
    return auth.utilisateur.photoProfil;
  }

  String _displayName(ProviderProfileLoaded state) {
    final fromApi = state.profile['fullName']?.toString().trim() ?? '';
    if (fromApi.isNotEmpty) return fromApi;
    final fromAuth = _authDisplayName();
    return fromAuth.isNotEmpty ? fromAuth : 'Prestataire';
  }

  String _metier(ProviderProfileLoaded state) {
    final serviceName = state.profile['serviceName']?.toString().trim() ?? '';
    if (serviceName.isNotEmpty) return serviceName;
    if (state.services.isNotEmpty) return state.services.first;
    final m = state.profile['metier']?.toString().trim() ?? '';
    return m.isNotEmpty ? m : 'Prestataire';
  }

  String? _categoryLabel(ProviderProfileLoaded state) {
    final c = state.profile['categoryLabel']?.toString().trim() ?? '';
    if (c.isEmpty) return null;
    if (c.toLowerCase() == _metier(state).toLowerCase()) return null;
    return c;
  }

  String? _profilePhotoUrl(ProviderProfileLoaded state) {
    final fromApi = safeImageUrl(state.profile['profileImage']);
    if (fromApi != null) return fromApi;
    return safeImageUrl(_authPhoto());
  }

  bool _shouldShowPhotoInvite(ProviderProfileLoaded state) {
    return _profilePhotoUrl(state) == null;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.elementAt(1)[0]}'.toUpperCase();
  }

  bool _isActiveProfile(ProviderProfileLoaded state) {
    final status =
        (state.profile['status'] ?? '').toString().toLowerCase();
    final disponible = state.profile['disponible'] != false;
    return disponible &&
        (status == 'active' || state.profile['verifier'] == true);
  }

  void _openPortfolio() {
    final id = _prestataireId;
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil prestataire non chargé')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderPortfolioScreen(prestataireId: id),
      ),
    );
  }

  void _openReviews() {
    final id = _prestataireId;
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil prestataire non chargé')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderReviewsScreen(prestataireId: id),
      ),
    ).then((_) => _refreshProfile());
  }

  void _openZoneEditor() {
    final id = _prestataireId;
    if (id == null || id.isEmpty) return;
    final currentState = context.read<ProviderProfileBloc>().state;
    if (currentState is! ProviderProfileLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chargement du profil en cours…')),
      );
      return;
    }
    final loc = cleanDisplayPart(currentState.serviceZone['address']) ??
        cleanDisplayPart(currentState.profile['location']) ??
        '';
    final radiusRaw =
        currentState.serviceZone['radius'] ?? currentState.profile['serviceRadius'];
    double? radius;
    if (radiusRaw is num) radius = radiusRaw.toDouble();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ProviderProfileBloc>(),
          child: ProviderEditZoneScreen(
            prestataireId: id,
            initialLocation: loc,
            initialRadiusKm: radius,
          ),
        ),
      ),
    ).then((_) => _refreshProfile());
  }

  @override
  Widget build(BuildContext context) {
    final waitingId =
        _prestataireId == null || _prestataireId!.isEmpty;

    final body = BlocBuilder<ProviderProfileBloc, ProviderProfileState>(
      builder: (context, state) {
        if (waitingId && widget.lookupSettled) {
          return SDConnectionRequired(onRetry: _bootstrap);
        }
        if (waitingId ||
            state is ProviderProfileLoading ||
            state is ProviderProfileUpdated) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        if (state is ProviderProfileError) {
          return SDSectionNeedsConnection(
            detail: 'Le profil professionnel n’a pas pu être chargé.',
            onRetry: _refreshProfile,
          );
        }
        if (state is ProviderProfileLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              _refreshProfile();
              await Future<void>.delayed(const Duration(milliseconds: 250));
            },
            color: SDColors.primary600,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (widget.embeddedInTab)
                  SliverToBoxAdapter(child: _buildPageHeader()),
                SliverToBoxAdapter(child: _buildIdentity(state)),
                SliverToBoxAdapter(child: _buildEditProfileButton()),
                if (_shouldShowPhotoInvite(state))
                  SliverToBoxAdapter(child: _buildPhotoInviteBanner()),
                SliverToBoxAdapter(child: _buildAbout(state)),
                SliverToBoxAdapter(child: _buildServiceAndTariff(state)),
                SliverToBoxAdapter(child: _buildZone(state)),
                SliverToBoxAdapter(child: _buildExtraLinks(state)),
                SliverToBoxAdapter(child: _buildProInfo(state)),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        }
        return const Center(child: Text('Initialisation…'));
      },
    );

    if (widget.embeddedInTab) {
      return ColoredBox(color: SDColors.white, child: body);
    }

    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: SDWhiteAppBar.appBar(
        title: 'Profil',
        actions: [
          IconButton(
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit_outlined, color: SDColors.neutral900),
            onPressed: openEdit,
          ),
          IconButton(
            tooltip: 'Actualiser',
            icon:
                const Icon(Icons.refresh_rounded, color: SDColors.neutral900),
            onPressed: _refreshProfile,
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildPageHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mon profil',
            style: SDTypography.titleLarge.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Espace prestataire',
            style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentity(ProviderProfileLoaded state) {
    final name = _displayName(state);
    final photoUrl = _profilePhotoUrl(state);
    final verified = state.profile['verifier'] == true;
    final active = _isActiveProfile(state);
    final location = state.profile['location']?.toString() ?? '';
    final metier = _metier(state);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipOval(
                child: photoUrl != null
                    ? AppImage(
                        imageUrl: photoUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      )
                    : _avatarFallback(name),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: SDColors.primary600,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: openEdit,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.photo_camera_outlined,
                          size: 14, color: SDColors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: SDTypography.titleSmall.copyWith(
                    color: SDColors.neutral900,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  metier,
                  style: SDTypography.bodyMedium.copyWith(
                    color: SDColors.primary700,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 14, color: SDColors.neutral500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: SDTypography.bodySmall
                              .copyWith(color: SDColors.neutral600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (verified) _badgeChip('Profil vérifié', Icons.verified_user_outlined),
                    if (active) _badgeChip('Actif', Icons.circle, dot: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      width: 72,
      height: 72,
      color: SDColors.primary50,
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: SDTypography.titleMedium.copyWith(
          color: SDColors.primary700,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _badgeChip(String label, IconData icon, {bool dot = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: SDColors.primary50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SDColors.primary100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: SDColors.primary600,
                shape: BoxShape.circle,
              ),
            )
          else
            Icon(icon, size: 14, color: SDColors.primary700),
          const SizedBox(width: 6),
          Text(
            label,
            style: SDTypography.labelSmall.copyWith(
              color: SDColors.primary700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: OutlinedButton.icon(
        onPressed: openEdit,
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text('Modifier mon profil'),
        style: OutlinedButton.styleFrom(
          foregroundColor: SDColors.neutral900,
          side: const BorderSide(color: SDColors.neutral300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoInviteBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Material(
        color: SDColors.primary50,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: openEdit,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SDColors.primary100),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: SDColors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.image_outlined,
                      color: SDColors.primary700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ajoutez une photo de profil',
                        style: SDTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: SDColors.neutral900,
                        ),
                      ),
                      Text(
                        'Pour personnaliser votre présentation.',
                        style: SDTypography.bodySmall
                            .copyWith(color: SDColors.neutral600),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: SDColors.neutral400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAbout(ProviderProfileLoaded state) {
    final bio = state.profile['bio'].toString().trim();
    final years = _asNum(state.profile['anneeExperience']);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('À propos', action: 'Modifier', onAction: openEdit),
          const SizedBox(height: 8),
          if (bio.isEmpty)
            Text(
              'Ajoutez une présentation pour décrire votre activité.',
              style: SDTypography.bodyMedium.copyWith(
                color: SDColors.neutral500,
                height: 1.4,
              ),
            )
          else
            Text(
              bio,
              style: SDTypography.bodyMedium.copyWith(
                color: SDColors.neutral700,
                height: 1.4,
              ),
            ),
          if (years != null && years > 0) ...[
            const SizedBox(height: 10),
            _tag('${years.round()} ans d\'expérience'),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceAndTariff(ProviderProfileLoaded state) {
    final metier = _metier(state);
    final category = _categoryLabel(state);
    final rate = _asNum(state.profile['prixprestataire']);
    final rateLabel = formatOptionalPrice(rate, suffix: 'FCFA');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Service et tarif'),
          const SizedBox(height: 10),
          _linkCard(
            icon: Icons.handyman_outlined,
            title: metier,
            subtitle: category,
            trailing: rateLabel,
            onTap: openEdit,
          ),
        ],
      ),
    );
  }

  Widget _buildZone(ProviderProfileLoaded state) {
    final z = state.serviceZone;
    final addr = cleanDisplayPart(z['address']) ??
        cleanDisplayPart(state.profile['location']) ??
        '—';
    final radius = z['radius'];
    final radiusNum = radius is num ? radius : null;
    final radiusLabel = radiusNum != null && radiusNum > 0
        ? 'Rayon : ${radiusNum.round()} km'
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Zone d\'intervention',
            action: 'Modifier',
            onAction: _openZoneEditor,
          ),
          const SizedBox(height: 10),
          _linkCard(
            icon: Icons.place_outlined,
            title: addr,
            subtitle: radiusLabel,
            onTap: _openZoneEditor,
          ),
        ],
      ),
    );
  }

  Widget _buildExtraLinks(ProviderProfileLoaded state) {
    final avis = _asNum(state.profile['nbAvis'])?.toInt() ?? 0;
    final ratingText = formatOptionalRating(
      state.profile['note'],
      reviewCount: avis,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          _simpleLinkRow(
            icon: Icons.photo_library_outlined,
            title: 'Mes réalisations',
            onTap: _openPortfolio,
          ),
          const SizedBox(height: 10),
          _simpleLinkRow(
            icon: Icons.star_outline_rounded,
            title: 'Avis reçus',
            trailing: ratingText ?? (avis > 0 ? '$avis avis' : 'Aucun avis'),
            onTap: _openReviews,
          ),
        ],
      ),
    );
  }

  Widget _linkCard({
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: SDColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SDColors.neutral200),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: SDColors.primary50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: SDColors.primary700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: SDTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: SDColors.neutral900,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: SDTypography.bodySmall
                            .copyWith(color: SDColors.neutral500),
                      ),
                    ],
                    if (trailing != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        trailing,
                        style: SDTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: SDColors.neutral900,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: SDColors.neutral400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _simpleLinkRow({
    required IconData icon,
    required String title,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: SDColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SDColors.neutral200),
          ),
          child: Row(
            children: [
              Icon(icon, color: SDColors.primary700, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: SDTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: SDColors.neutral900,
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing,
                  style: SDTypography.bodySmall
                      .copyWith(color: SDColors.neutral500),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: SDColors.neutral400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProInfo(ProviderProfileLoaded state) {
    final phone = state.profile['phone']?.toString().trim();
    final email = state.profile['email']?.toString().trim();
    final verified = state.profile['verifier'] == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Informations pro'),
          const SizedBox(height: 10),
          if (phone != null && phone.isNotEmpty)
            _proRow(Icons.phone_outlined, phone, verified ? 'Vérifié' : null),
          if (phone != null && phone.isNotEmpty) const SizedBox(height: 8),
          if (email != null && email.isNotEmpty)
            _proRow(Icons.mail_outline_rounded, email, null),
          if (email != null && email.isNotEmpty) const SizedBox(height: 8),
          _proRow(
            Icons.badge_outlined,
            verified
                ? 'Identité vérifiée'
                : 'Identité en attente de vérification',
            verified ? 'Vérifié' : 'En cours',
          ),
        ],
      ),
    );
  }

  Widget _proRow(IconData icon, String text, String? badge) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: SDColors.neutral900),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: SDTypography.bodyMedium.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (badge != null)
            Text(
              badge,
              style: SDTypography.labelSmall.copyWith(
                color: SDColors.primary700,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, {String? action, VoidCallback? onAction}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: SDTypography.titleSmall.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (action != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: SDColors.primary700,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              action,
              style: SDTypography.labelMedium.copyWith(
                color: SDColors.primary700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: SDColors.neutral100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Text(
        label,
        style: SDTypography.labelSmall.copyWith(
          color: SDColors.neutral800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
