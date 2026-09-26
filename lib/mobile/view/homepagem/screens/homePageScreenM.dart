import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/services/websocket_service.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/nav_badge.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/screens/freelancePageScreen.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/jobPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/utils/navigation_helper.dart';
import 'package:sdealsmobile/mobile/view/notificationpagem/bloc/notification_bloc.dart';
import 'package:sdealsmobile/mobile/view/notificationpagem/bloc/notification_event.dart';
import 'package:sdealsmobile/mobile/view/notificationpagem/bloc/notification_state.dart';
import 'package:sdealsmobile/mobile/view/alertpagem/alertpageblocm/alertPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/alertpagem/screens/alertPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/screens/searchPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/locationpagem/screens/locationPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/locationpagem/locationpageblocm/locationPageBlocM.dart';
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/utils/network_user_message.dart';
import 'package:sdealsmobile/data/services/protected_action_intent.dart';
import 'package:sdealsmobile/mobile/view/common/auth_completion.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';
import 'package:sdealsmobile/data/utils/media_url.dart';
import 'package:sdealsmobile/data/utils/string_list_normalizer.dart';
import '../homepageblocm/homePageBlocM.dart';
import '../homepageblocm/homePageEventM.dart';
import '../homepageblocm/homePageStateM.dart';
import '../home_place_label.dart';
import 'package:sdealsmobile/data/config/client_feature_flags.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageEventM.dart'
    as shop_ev;
import '../home_universe_assets.dart';
import '../widgets/home_universe_choice_card.dart';
import '../widgets/home_nearby_card.dart';
import '../widgets/home_hero_background.dart';
import '../../../../design_system/design_system.dart';

class HomePageScreenM extends StatefulWidget {
  final Function(bool)? onScrollUpdate;

  /// État de la bottom bar du shell `Home` (masquée au scroll vers le bas).
  final bool bottomNavVisible;
  final VoidCallback? onOpenExplorer;

  /// Données déjà chargées, uniquement pour les tests. Null en production.
  final List<Map<String, dynamic>>? previewPrestataires;

  const HomePageScreenM({
    super.key,
    this.onScrollUpdate,
    this.bottomNavVisible = true,
    this.onOpenExplorer,
    this.previewPrestataires,
  });

  @override
  State<HomePageScreenM> createState() => _HomePageScreenStateM();
}

class _HomePageScreenStateM extends State<HomePageScreenM>
    with WidgetsBindingObserver {
  double _lastScrollOffset = 0;
  final NotificationBloc _notificationBloc = NotificationBloc();
  final ApiClient _apiClient = ApiClient();
  List<_HomeMiniItem> _metiersItems = const [];
  bool _homePreviewLoadedOnce = false;

  /// Hauteur visuelle approximative de la bottom bar (`SizedBox` 78 + bouton Publier qui remonte).
  static const double _bottomNavShellReserve = 92;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<HomePageBlocM>().add(LoadCategorieDataM());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthAuthenticated) {
        _notificationBloc.setToken(authState.token);
        _notificationBloc.add(
          LoadUserNotifications(userId: authState.utilisateur.idutilisateur),
        );
        _notificationBloc.add(
          StartNotificationPolling(authState.utilisateur.idutilisateur),
        );
      }
      _loadHomePreviewData();
    });
  }

  Future<void> _loadHomePreviewData() async {
    if (widget.previewPrestataires != null) {
      if (!mounted) return;
      setState(() {
        _homePreviewLoadedOnce = true;
        _metiersItems = _buildMetiersItems(widget.previewPrestataires!);
      });
      return;
    }
    // 10D-2 : seul le carrousel « Professionnels près de vous » est visible.
    // fetchFreelances, fetchHomeFreelanceServices et fetchArticle ne sont plus
    // appelés ici : aucun widget initial ne lit ces listes. Pas de nouvelle
    // requête. Réouverture possible quand Freelance ou É-marché redeviennent
    // visibles sur l'accueil.
    try {
      final prestataires = await _apiClient.fetchPrestataires(
        forceRefresh: true,
        page: 1,
        limit: 20,
      );

      if (!mounted) return;
      setState(() {
        _homePreviewLoadedOnce = true;
        _metiersItems = _buildMetiersItems(prestataires);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _homePreviewLoadedOnce = true;
        _metiersItems = const [];
      });
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.'));
  }

  /// `prixprestataire` n'a pas d'unité horaire garantie (tarif journalier à l'inscription).
  String? _formatKnownPrice(dynamic raw) {
    final amount = _toDouble(raw);
    if (amount == null || amount <= 0) return null;
    final digits = amount.toStringAsFixed(0);
    final grouped = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ' ',
    );
    return '$grouped FCFA';
  }

  /// Normalise une URL média (Cloudinary / http / protocole-relatif).
  String? _normalizeMediaUrl(String? raw) => safeImageUrl(raw);

  /// Cherche une image dans les champs usuels API (utilisateur, article, freelance…).
  String? _pickImageUrl(Map<String, dynamic> source) {
    const candidateKeys = [
      'photoArticle',
      'imageArticle',
      'photoProfil',
      'coverImage',
      'imagePath',
      'selfie',
      'avatar',
      'image',
      'photo',
      'profilePhoto',
      'url',
    ];
    for (final key in candidateKeys) {
      final normalized = _normalizeMediaUrl(source[key]?.toString());
      if (normalized != null) return normalized;
    }
    return null;
  }

  String? _metierLabelForPrestataire(Map<String, dynamic> p) {
    final service = p['service'] as Map<String, dynamic>? ?? const {};
    for (final key in ['nomservice', 'nomService', 'nom', 'label']) {
      final v = service[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    final categorie = service['categorie'] as Map<String, dynamic>?;
    final nomCat = categorie?['nomcategorie']?.toString().trim();
    if (nomCat != null && nomCat.isNotEmpty) return nomCat;
    final spec = normalizeStringList(p['specialite']);
    if (spec.isNotEmpty) {
      return spec.take(2).join(', ');
    }
    return null;
  }

  String? _placeForPrestataire(Map<String, dynamic> p) {
    final zones = normalizeStringList(p['zoneIntervention']);
    return firstReadablePlace([
      p['commune']?.toString(),
      p['quartier']?.toString(),
      p['ville']?.toString(),
      ...zones,
      p['localisation']?.toString(),
      p['adresse']?.toString(),
    ]);
  }

  List<_HomeMiniItem> _buildMetiersItems(List<Map<String, dynamic>> data) {
    // Affiche le profil même sans photo : le placeholder reste discret.
    return data
        .map((p) {
          final utilisateur =
              p['utilisateur'] as Map<String, dynamic>? ?? const {};
          final fullName =
              personNameFromMap(utilisateur, fallback: 'Prestataire');
          final metier = _metierLabelForPrestataire(p);
          final location = _placeForPrestataire(p);
          final verifiedLabel = SDClientTrust.identityVerifiedLabel(
            verified: p['verifier'] == true,
          );
          final imageUrl = providerPhotoUrl(
            utilisateurMap: utilisateur,
            prestataireMap: p,
          );
          return _HomeMiniItem(
            title: fullName,
            subtitle: metier ?? '',
            imageUrl: imageUrl,
            metaText: location,
            priceText: _formatKnownPrice(p['prixprestataire']),
            statusText: verifiedLabel,
            onCardTap: () => _openProviderFromHome(p),
            onFavoriteTap: () => _addProviderFavorite(p),
          );
        })
        .whereType<_HomeMiniItem>()
        .take(5)
        .toList();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationBloc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Évite un double fetch au tout premier `resumed` juste après le cold start.
    if (state == AppLifecycleState.resumed &&
        mounted &&
        _homePreviewLoadedOnce) {
      _loadHomePreviewData();
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthAuthenticated) {
        _notificationBloc.add(
          LoadUnreadCount(authState.utilisateur.idutilisateur),
        );
        // STAB-05 : reprise Socket seulement si déconnecté (pas de reconnect forcé).
        WebSocketService().resumeIfNeeded();
      }
    }
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => AlertPageBlocM(),
          child: const AlertPageScreenM(),
        ),
      ),
    );
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SearchPageScreenM(),
      ),
    );
  }

  void _openLocation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => LocationPageBlocM(),
          child: const LocationPageScreenM(),
        ),
      ),
    );
  }

  String _greeting(AuthState authState) {
    if (authState is! AuthAuthenticated) return 'Bonjour';
    final raw = authState.utilisateur.prenom?.trim() ?? '';
    final lower = raw.toLowerCase();
    if (raw.isEmpty ||
        lower == 'null' ||
        lower == 'invité' ||
        lower == 'invite' ||
        lower == 'utilisateur') {
      return 'Bonjour';
    }
    return 'Bonjour, $raw';
  }

  Future<void> _addProviderFavorite(Map<String, dynamic> p) async {
    final id = p['_id']?.toString() ?? p['idprestataire']?.toString() ?? '';
    final ready = await ensureAuthenticatedForAction(
      context: context,
      type: ProtectedActionType.addFavorite,
      originRoute: 'home',
      technicalId: id,
      explanation: 'Connectez-vous pour ajouter un favori',
    );
    if (!ready || !mounted) return;
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return;
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prestataire invalide')),
      );
      return;
    }
    final utilisateur = p['utilisateur'] as Map<String, dynamic>? ?? const {};
    final fullName = personNameFromMap(utilisateur, fallback: 'Prestataire');
    final imageUrl = _pickImageUrl(utilisateur) ?? _pickImageUrl(p);
    try {
      await _apiClient.addFavorite(
        token: auth.token,
        objetType: 'PRESTATAIRE',
        objetId: id,
        titre: fullName,
        image: imageUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajouté aux favoris')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec favoris : $e')),
      );
    }
  }

  void _openMetiers() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const JobPageScreenM()),
    );
  }

  void _openFreelance(List<dynamic> categories) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FreelancePageScreen(categories: categories),
      ),
    );
  }

  void _openMarketplace() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => ShoppingPageBlocM()
            ..add(shop_ev.LoadCategorieDataM())
            ..add(shop_ev.LoadProductsEvent()),
          child: const ShoppingPageScreenM(),
        ),
      ),
    );
  }

  void _openProviderFromHome(Map<String, dynamic> p) {
    final id = p['_id']?.toString() ?? p['idprestataire']?.toString() ?? '';
    if (id.isEmpty) {
      _openMetiers();
      return;
    }
    NavigationHelper.navigateToProviderProfile(
      context,
      providerId: id,
      providerData: p,
    );
  }

  Widget _buildNotificationAction() {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType ||
          (current is AuthAuthenticated &&
              previous is AuthAuthenticated &&
              (previous.token != current.token ||
                  previous.utilisateur.idutilisateur !=
                      current.utilisateur.idutilisateur)),
      listener: (context, authState) {
        if (authState is AuthAuthenticated) {
          _notificationBloc.setToken(authState.token);
          _notificationBloc.add(
            LoadUserNotifications(userId: authState.utilisateur.idutilisateur),
          );
          _notificationBloc.add(
            StartNotificationPolling(authState.utilisateur.idutilisateur),
          );
        } else {
          _notificationBloc.add(const StopNotificationPolling());
        }
      },
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return IconButton(
            tooltip: 'Notifications',
            onPressed: _openNotifications,
            icon: const Icon(
              Icons.notifications_none_rounded,
              size: 24,
              color: SDColors.primary800,
            ),
          );
        }

        return BlocBuilder<NotificationBloc, NotificationState>(
          bloc: _notificationBloc,
          builder: (context, state) {
            final unreadCount =
                state is NotificationLoaded ? state.unreadCount : 0;
            return NavBadge(
              count: unreadCount,
              badgeColor: SDColors.error500,
              child: IconButton(
                tooltip: 'Notifications',
                onPressed: _openNotifications,
                icon: const Icon(
              Icons.notifications_none_rounded,
              size: 24,
              color: SDColors.primary800,
            ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomePageBlocM, HomePageStateM>(
      builder: (context, state) {
        final categories = state.listItems ?? [];
        final authState = context.watch<AuthCubit>().state;
        final firstName = _greeting(authState);

        final mq = MediaQuery.of(context);
        final systemBottomInset = mq.viewPadding.bottom;
        final reserveWhenNavHidden =
            widget.onScrollUpdate != null && !widget.bottomNavVisible
                ? _bottomNavShellReserve
                : 0.0;
        final listBottomPadding =
            SDSpacing.spaceBlock + systemBottomInset + reserveWhenNavHidden;
        final hasCategoryError = (state.error ?? '').isNotEmpty;

        return Scaffold(
          backgroundColor: SDColors.white,
          body: NotificationListener<ScrollNotification>(
            onNotification: (scrollNotification) {
              if (scrollNotification is ScrollUpdateNotification) {
                final currentOffset = scrollNotification.metrics.pixels;
                final isScrollingDown = currentOffset > _lastScrollOffset;
                final isScrollingUp = currentOffset < _lastScrollOffset;
                if (isScrollingDown && currentOffset > 30) {
                  widget.onScrollUpdate?.call(false);
                } else if (isScrollingUp || currentOffset <= 30) {
                  widget.onScrollUpdate?.call(true);
                }
                _lastScrollOffset = currentOffset;
              }
              return false;
            },
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<HomePageBlocM>().add(LoadCategorieDataM());
                await _loadHomePreviewData();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(bottom: listBottomPadding),
                children: [
                  if (hasCategoryError) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        SDSpacing.clientHorizontalMargin,
                        SDSpacing.spaceRelated,
                        SDSpacing.clientHorizontalMargin,
                        0,
                      ),
                      child: _buildInlineErrorBanner(state.error!),
                    ),
                    const SizedBox(height: SDSpacing.spaceRelated),
                  ] else if (state.isLoading && categories.isEmpty) ...[
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  _buildHero(firstName, categories),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      SDSpacing.clientHorizontalMargin,
                      SDSpacing.spaceRelated,
                      SDSpacing.clientHorizontalMargin,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLocationRow(),
                        const SizedBox(height: SDSpacing.spaceRelated),
                        _buildNearbySection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHero(String greeting, List<Categorie> categories) {
    final top = MediaQuery.paddingOf(context).top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(SDSpacing.radiusSheet),
      ),
      child: HomeHeroBackground(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            SDSpacing.clientHorizontalMargin,
            top + SDSpacing.spaceSmall,
            SDSpacing.clientHorizontalMargin,
            SDSpacing.spaceRelated,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      greeting,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SDTypography.cardTitle.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildNotificationAction(),
                ],
              ),
              const SizedBox(height: SDSpacing.spaceSmall),
              Text(
                'Trouvez un professionnel près de vous',
                style: SDTypography.screenTitle.copyWith(
                  color: SDColors.primary800,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: SDSpacing.spaceMinimal),
              Text(
                'Comparez les services et contactez le bon profil.',
                style: SDTypography.body.copyWith(color: SDColors.neutral700),
              ),
              const SizedBox(height: SDSpacing.spaceRelated),
              _buildSearchEntry(),
              const SizedBox(height: SDSpacing.spaceRelated),
              _buildUniverseChoices(categories),
            ],
          ),
        ),
      ),
    );
  }

  /// Cartes univers (photo + bandeau texte). É-marché si flag activé.
  Widget _buildUniverseChoices(List<Categorie> categories) {
    final cards = <Widget>[
      HomeUniverseChoiceCard(
        title: 'Métiers',
        subtitle: 'Artisans et services près de vous',
        imageAsset: HomeUniverseAssets.metiers,
        onTap: _openMetiers,
      ),
      HomeUniverseChoiceCard(
        title: 'Freelance',
        subtitle: 'Compétences à distance ou au projet',
        imageAsset: HomeUniverseAssets.freelance,
        onTap: () => _openFreelance(categories),
      ),
    ];

    if (ClientFeatureFlags.emarketEnabled) {
      cards.add(
        HomeUniverseChoiceCard(
          title: 'É-marché',
          subtitle: 'Boutiques et articles près de chez vous',
          imageAsset: HomeUniverseAssets.marketplace,
          onTap: _openMarketplace,
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(height: SDSpacing.cardInterval),
          cards[i],
        ],
      ],
    );
  }

  Widget _buildSearchEntry() {
    return Semantics(
      button: true,
      label: 'Quel service recherchez-vous ?',
      child: Material(
        color: SDColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SDSpacing.radiusField),
        ),
        child: InkWell(
          onTap: _openSearch,
          borderRadius: BorderRadius.circular(SDSpacing.radiusField),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(minHeight: SDSpacing.minTouchTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SDSpacing.spaceRelated,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    size: SDSpacing.iconStandard,
                    color: SDColors.neutral700,
                  ),
                  const SizedBox(width: SDSpacing.spaceRelated),
                  Expanded(
                    child: Text(
                      'Quel service recherchez-vous ?',
                      style: SDTypography.body
                          .copyWith(color: SDColors.neutral600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNearbySection() {
    final width = NearbyCarouselMetrics.cardWidth(
      MediaQuery.sizeOf(context).width,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Professionnels près de vous',
          style: SDTypography.sectionTitle.copyWith(color: SDColors.neutral900),
        ),
        const SizedBox(height: SDSpacing.cardInterval),
        if (!_homePreviewLoadedOnce)
          const SDLoadingInline()
        else if (_metiersItems.isEmpty)
          SDEmptyState(
            title: 'Aucun professionnel à afficher',
            message:
                'Les profils proches apparaîtront ici. Vous pouvez aussi explorer.',
            icon: Icons.person_search_outlined,
            action: SDButton(
              text: 'Ouvrir Explorer',
              size: SDButtonSize.medium,
              onPressed: widget.onOpenExplorer,
            ),
          )
        else ...[
          SizedBox(
            height: HomeNearbyCard.heightFor(context),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: NearbyCarouselMetrics.peek),
              itemCount: _metiersItems.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: SDSpacing.cardInterval),
              itemBuilder: (context, index) {
                final item = _metiersItems[index];
                return HomeNearbyCard(
                  width: width,
                  name: item.title,
                  metier: item.subtitle,
                  price: item.priceText,
                  place: item.metaText,
                  verifiedLabel: item.statusText,
                  imageUrl: item.imageUrl,
                  onTap: item.onCardTap,
                  onFavorite: item.onFavoriteTap,
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _openMetiers,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.chevron_right, size: 20),
              label: const Text('Voir tous les professionnels'),
              style: TextButton.styleFrom(
                foregroundColor: SDColors.primary600,
                textStyle: SDTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                minimumSize: const Size(48, SDSpacing.minTouchTarget),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationRow() {
    return Semantics(
      button: true,
      label: 'Ville ${SDClientLocationPolicy.fallbackCity}. Modifier',
      child: InkWell(
        onTap: _openLocation,
        borderRadius: BorderRadius.circular(SDSpacing.radiusChip),
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(minHeight: SDSpacing.minTouchTarget),
          child: Row(
            children: [
              const Icon(
                Icons.location_on,
                size: SDSpacing.iconStandard,
                color: SDColors.primary600,
              ),
              const SizedBox(width: SDSpacing.spaceSmall),
              Expanded(
                child: Text(
                  SDClientLocationPolicy.fallbackCity,
                  style: SDTypography.body.copyWith(
                    color: SDColors.neutral900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'Modifier',
                style: SDTypography.caption.copyWith(
                  color: SDColors.primary600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInlineErrorBanner(String message) {
    final shortMsg = homeBannerDisplayMessage(message);
    final offline = homeBannerLooksOffline(shortMsg);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SDColors.error50,
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        border: Border.all(color: SDColors.error200),
      ),
      child: Row(
        children: [
          Icon(
            offline ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
            color: SDColors.error600,
            size: 20,
          ),
          SizedBox(width: SDSpacing.xs),
          Expanded(
            child: Text(
              shortMsg,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SDTypography.bodySmall.copyWith(color: SDColors.error600),
            ),
          ),
          SizedBox(width: SDSpacing.xs),
          TextButton(
            onPressed: () =>
                context.read<HomePageBlocM>().add(LoadCategorieDataM()),
            style: TextButton.styleFrom(
              foregroundColor: SDColors.error600,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Réessayer',
              style: SDTypography.labelSmall.copyWith(
                color: SDColors.error600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeMiniItem {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? metaText;
  final String? statusText;
  final String? priceText;
  final VoidCallback? onCardTap;
  final VoidCallback? onFavoriteTap;

  const _HomeMiniItem({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.metaText,
    this.statusText,
    this.priceText,
    this.onCardTap,
    this.onFavoriteTap,
  });
}
