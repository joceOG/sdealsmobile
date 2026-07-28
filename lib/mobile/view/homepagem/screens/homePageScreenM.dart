
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/nav_badge.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/screens/freelancePageScreen.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/screens/freelance_details_screen.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/screens/freelance_service_offer_detail_screen.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/models/freelance_model.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/jobPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/notificationpagem/bloc/notification_bloc.dart';
import 'package:sdealsmobile/mobile/view/notificationpagem/bloc/notification_event.dart';
import 'package:sdealsmobile/mobile/view/notificationpagem/bloc/notification_state.dart';
import 'package:sdealsmobile/mobile/view/notificationpagem/screens/notification_screen.dart';
import 'package:sdealsmobile/mobile/view/orderpagem/orderpageblocm/commande_bloc.dart';
import 'package:sdealsmobile/mobile/view/orderpagem/screens/orderPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageBlocM.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import '../homepageblocm/homePageBlocM.dart';
import '../homepageblocm/homePageEventM.dart';
import '../homepageblocm/homePageStateM.dart';
import '../home_universe_assets.dart';
import '../../../../design_system/design_system.dart';

class HomePageScreenM extends StatefulWidget {
  final Function(bool)? onScrollUpdate;
  /// État de la bottom bar du shell `Home` (masquée au scroll vers le bas).
  final bool bottomNavVisible;

  const HomePageScreenM({
    super.key,
    this.onScrollUpdate,
    this.bottomNavVisible = true,
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
  List<_HomeMiniItem> _freelanceServiceItems = const [];
  List<_HomeMiniItem> _freelanceItems = const [];
  List<_HomeMiniItem> _productItems = const [];
  List<_HomeMiniItem> _promoItems = const [];
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
    try {
      final prestatairesFuture = _apiClient.fetchPrestataires(forceRefresh: true);
      final freelancesFuture = _apiClient.fetchFreelances(limit: 6);
      final articlesFuture = _apiClient.fetchArticle();
      final results = await Future.wait<dynamic>([
        prestatairesFuture,
        freelancesFuture,
        articlesFuture,
      ]);

      final prestataires = (results[0] as List<dynamic>).cast<Map<String, dynamic>>();
      final freelancesWrap = results[1] as Map<String, dynamic>;
      final freelances = (freelancesWrap['freelances'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      final articles = results[2] as List<dynamic>;

      List<Map<String, dynamic>> offers = const [];
      try {
        final homeWrap = await _apiClient.fetchHomeFreelanceServices(limit: 8);
        offers = (homeWrap['offers'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
      } catch (_) {
        offers = const [];
      }

      if (!mounted) return;
      setState(() {
        _homePreviewLoadedOnce = true;
        _metiersItems = _buildMetiersItems(prestataires);
        _freelanceServiceItems = _buildFreelanceServiceOfferItems(offers);
        _freelanceItems = _buildFreelanceItems(freelances);
        _productItems = _buildProductItems(articles);
        _promoItems = _buildPromoItems(articles);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _homePreviewLoadedOnce = true;
        _metiersItems = const [];
        _freelanceServiceItems = const [];
        _freelanceItems = const [];
        _productItems = const [];
        _promoItems = const [];
      });
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.'));
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  String? _formatPricePerHour(dynamic raw) {
    final amount = _toDouble(raw);
    if (amount == null || amount <= 0) return null;
    return '${amount.toStringAsFixed(0)} FCFA /h';
  }

  String? _formatPrice(dynamic raw) {
    final amount = _toDouble(raw);
    if (amount == null || amount <= 0) return null;
    return '${amount.toStringAsFixed(0)} FCFA';
  }

  String _ratingWithReviews(dynamic noteRaw, dynamic reviewsRaw) {
    final note = _toDouble(noteRaw);
    final reviews = _toInt(reviewsRaw) ?? 0;
    final score = (note != null && note > 0) ? note.toStringAsFixed(1) : 'Nouveau';
    if (reviews > 0 && note != null && note > 0) {
      return '$score ($reviews avis)';
    }
    return score;
  }

  String? _pickImageUrl(Map<String, dynamic> source) {
    final candidateKeys = ['photoProfil', 'avatar', 'image', 'photo', 'profilePhoto'];
    for (final key in candidateKeys) {
      final value = source[key]?.toString();
      if (value != null && value.isNotEmpty && value.startsWith('http')) {
        return value;
      }
    }
    return null;
  }

  Map<String, dynamic> _extractArticleData(dynamic article) {
    if (article is Map<String, dynamic>) {
      return article;
    }
    // Fallback modèle Article (mobile) + champs optionnels backend.
    return {
      'nomArticle': article.nomArticle,
      'prixArticle': article.prixArticle,
      'photoArticle': article.photoArticle,
      'ancienPrixArticle': null,
      'discountPercent': null,
      'rating': null,
      'salesCount': null,
      'isPromo': null,
    };
  }

  /// Libellé « ce qu’il / elle fait » pour la carte Métiers (plusieurs formes API).
  String _metierLabelForPrestataire(Map<String, dynamic> p) {
    final service = p['service'] as Map<String, dynamic>? ?? const {};
    for (final key in ['nomservice', 'nomService', 'nom', 'label']) {
      final v = service[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    final categorie = service['categorie'] as Map<String, dynamic>?;
    final nomCat = categorie?['nomcategorie']?.toString().trim();
    if (nomCat != null && nomCat.isNotEmpty) return nomCat;
    final spec = p['specialite'];
    if (spec is List && spec.isNotEmpty) {
      return spec.take(2).map((e) => e.toString()).where((s) => s.isNotEmpty).join(', ');
    }
    if (spec is String && spec.trim().isNotEmpty) return spec.trim();
    final desc = p['description']?.toString().trim();
    if (desc != null && desc.isNotEmpty) {
      return desc.length > 72 ? '${desc.substring(0, 69)}…' : desc;
    }
    return 'Prestation à découvrir';
  }

  List<_HomeMiniItem> _buildMetiersItems(List<Map<String, dynamic>> data) {
    return data.take(3).map((p) {
      final utilisateur = p['utilisateur'] as Map<String, dynamic>? ?? const {};
      final prenom = utilisateur['prenom']?.toString() ?? '';
      final nom = utilisateur['nom']?.toString() ?? '';
      final fullName = ('$prenom $nom').trim().isEmpty ? 'Prestataire' : ('$prenom $nom').trim();
      final metier = _metierLabelForPrestataire(p);
      final location = p['localisation']?.toString() ?? 'Abidjan';
      final isVerified = p['verifier'] == true;
      final expYears = _toInt(p['anneeExperience']);
      final imageUrl = _pickImageUrl(utilisateur);
      final rating = _ratingWithReviews(p['note'], p['nbAvis']);
      final meta = isVerified
          ? '$location • Vérifié${expYears != null && expYears > 0 ? ' • $expYears ans' : ''}'
          : '$location${expYears != null && expYears > 0 ? ' • $expYears ans' : ''}';
      return _HomeMiniItem(
        cardType: SDEntityCardType.provider,
        title: fullName,
        subtitle: metier,
        icon: Icons.handyman_rounded,
        listingLayout: true,
        imageUrl: imageUrl,
        ratingText: rating,
        metaText: meta,
        priceText: _formatPricePerHour(p['prixprestataire']) ?? 'Sur devis',
        statusText: 'Disponible rapidement',
        ctaText: 'Contacter',
      );
    }).toList();
  }

  List<_HomeMiniItem> _buildFreelanceServiceOfferItems(List<Map<String, dynamic>> data) {
    return data.take(8).map((o) {
      final title = o['displayTitle']?.toString() ?? 'Service';
      final cover = o['coverImage']?.toString();
      final priceVal = _toDouble(o['startingPrice']);
      final priceText = priceVal != null && priceVal > 0
          ? 'À partir de ${priceVal.toStringAsFixed(0)} FCFA'
          : 'Sur devis';
      final note = _toDouble(o['ratingAvg']);
      final reviews = _toInt(o['reviewsCount']) ?? 0;
      final ratingText = (note != null && note > 0)
          ? (reviews > 0 ? '${note.toStringAsFixed(1)} ($reviews avis)' : note.toStringAsFixed(1))
          : 'Nouveau';
      final par = o['par']?.toString() ?? '';
      final delivery = o['deliveryTime']?.toString() ?? '';
      final meta = delivery.isNotEmpty ? 'Livraison $delivery' : 'Freelance';
      final freelance = o['freelance'] as Map<String, dynamic>?;
      final u = freelance?['utilisateur'] as Map<String, dynamic>?;
      final avatar = u?['photoProfil']?.toString() ??
          freelance?['imagePath']?.toString() ??
          '';
      final freelanceId = freelance?['_id']?.toString();
      final offerId = o['_id']?.toString();

      return _HomeMiniItem(
        cardType: SDEntityCardType.freelance,
        title: title,
        subtitle: par.isNotEmpty ? 'Par $par' : 'Freelance',
        icon: Icons.work_outline_rounded,
        imageUrl: (cover != null && cover.isNotEmpty) ? cover : (avatar.isNotEmpty ? avatar : null),
        ratingText: ratingText,
        metaText: meta,
        priceText: priceText,
        statusText: o['isFeatured'] == true ? 'À la une' : null,
        ctaText: 'Voir l’offre',
        listingLayout: true,
        onCardTap: offerId != null
            ? () => _openFreelanceServiceOffer(offerId)
            : (freelanceId != null ? () => _openFreelanceById(freelanceId) : null),
      );
    }).toList();
  }

  List<_HomeMiniItem> _buildFreelanceItems(List<Map<String, dynamic>> data) {
    return data.take(3).map((f) {
      final utilisateur = f['utilisateur'] as Map<String, dynamic>? ?? const {};
      final nom = f['nom']?.toString() ??
          f['fullName']?.toString() ??
          utilisateur['fullName']?.toString() ??
          'Freelance';
      final skills = (f['skills'] is List && (f['skills'] as List).isNotEmpty)
          ? (f['skills'] as List).take(2).join(', ')
          : (f['specialite']?.toString() ?? f['metier']?.toString() ?? 'Expert confirmé');
      final expYears = _toInt(f['anneeExperience'] ?? f['experienceYears']);
      final rating = _ratingWithReviews(f['note'] ?? f['rating'], f['nbAvis'] ?? f['reviewsCount']);
      final imageUrl = _pickImageUrl(f) ?? _pickImageUrl(utilisateur);
      final isVerified = f['verifier'] == true || f['isVerified'] == true;
      final meta = isVerified
          ? 'Remote/Projet • Vérifié${expYears != null && expYears > 0 ? ' • $expYears ans' : ''}'
          : 'Remote/Projet${expYears != null && expYears > 0 ? ' • $expYears ans' : ''}';

      return _HomeMiniItem(
        cardType: SDEntityCardType.freelance,
        title: nom,
        subtitle: skills,
        icon: Icons.laptop_mac_rounded,
        listingLayout: true,
        imageUrl: imageUrl,
        ratingText: rating,
        metaText: meta,
        priceText:
            _formatPricePerHour(f['tarifHoraire'] ?? f['hourlyRate'] ?? f['tarif']) ?? 'Sur devis',
        statusText: 'Répond rapidement',
        ctaText: 'Voir profil',
      );
    }).toList();
  }

  List<_HomeMiniItem> _buildProductItems(List<dynamic> data) {
    return data.take(3).map((a) {
      final item = _extractArticleData(a);
      final name =
          (item['nomArticle']?.toString() ?? '').isEmpty ? 'Produit' : item['nomArticle'].toString();
      final imageUrl = _pickImageUrl(item);
      final price = _formatPrice(item['prixArticle']) ?? 'Sur devis';
      final ratingValue = _toDouble(item['rating']);
      final sales = _toInt(item['salesCount']);
      final ratingText = ratingValue != null && ratingValue > 0
          ? (sales != null && sales > 0
              ? '${ratingValue.toStringAsFixed(1)} (${sales.toString()} ventes)'
              : ratingValue.toStringAsFixed(1))
          : (sales != null && sales > 0 ? 'Populaire • ${sales.toString()} ventes' : null);
      final hasPromo = (item['isPromo'] == true) ||
          ((_toDouble(item['discountPercent']) ?? 0) > 0) ||
          ((_toDouble(item['ancienPrixArticle']) ?? 0) > 0);
      final discount = _toDouble(item['discountPercent']);
      final oldPrice = _formatPrice(item['ancienPrixArticle']);
      final promoBadge = discount != null && discount > 0
          ? '-${discount.toStringAsFixed(0)}%'
          : (hasPromo ? 'PROMO' : null);
      return _HomeMiniItem(
        cardType: SDEntityCardType.product,
        title: name,
        subtitle: 'Marketplace',
        icon: Icons.shopping_bag_rounded,
        listingLayout: true,
        imageUrl: imageUrl,
        ratingText: ratingText,
        metaText: oldPrice != null ? 'Avant: $oldPrice' : 'Produit populaire',
        priceText: price,
        promoText: promoBadge,
        ctaText: 'Commander',
      );
    }).toList();
  }

  /// Promo réelle côté backend (pas de mock : la section reste masquée si vide).
  bool _isArticleRealPromo(Map<String, dynamic> item) {
    if (item['isPromo'] == true) return true;
    final d = _toDouble(item['discountPercent']);
    if (d != null && d > 0) return true;
    final ancien = _toDouble(item['ancienPrixArticle']);
    final prix = _toDouble(item['prixArticle']);
    if (ancien != null && prix != null && ancien > prix) return true;
    return false;
  }

  List<_HomeMiniItem> _buildPromoItems(List<dynamic> data) {
    if (data.isEmpty) return const [];
    final promos = data.where((a) => _isArticleRealPromo(_extractArticleData(a))).take(8).toList();
    if (promos.isEmpty) return const [];

    return promos.map((a) {
      final item = _extractArticleData(a);
      final name = (item['nomArticle']?.toString() ?? '').isEmpty
          ? 'Produit en promo'
          : item['nomArticle'].toString();
      final imageUrl = _pickImageUrl(item);
      final price = _formatPrice(item['prixArticle']);
      final oldPrice = _formatPrice(item['ancienPrixArticle']);
      final discount = _toDouble(item['discountPercent']);
      final ancien = _toDouble(item['ancienPrixArticle']);
      final prix = _toDouble(item['prixArticle']);
      final sales = _toInt(item['salesCount']);
      final ratingValue = _toDouble(item['rating']);
      final ratingText = ratingValue != null && ratingValue > 0
          ? (sales != null && sales > 0
              ? '${ratingValue.toStringAsFixed(1)} (${sales.toString()} ventes)'
              : ratingValue.toStringAsFixed(1))
          : null;

      String? promoBadge;
      if (discount != null && discount > 0) {
        promoBadge = '-${discount.toStringAsFixed(0)}%';
      } else if (ancien != null && prix != null && ancien > prix) {
        final pct = ((ancien - prix) / ancien * 100).round();
        promoBadge = pct > 0 ? '-$pct%' : 'Promo';
      } else if (item['isPromo'] == true) {
        promoBadge = 'Promo';
      }

      return _HomeMiniItem(
        cardType: SDEntityCardType.product,
        title: name,
        subtitle: 'Promo limitée',
        icon: Icons.local_offer_rounded,
        listingLayout: true,
        imageUrl: imageUrl,
        ratingText: ratingText,
        metaText: oldPrice != null ? 'Avant: $oldPrice' : 'Marketplace',
        priceText: price ?? 'Sur devis',
        promoText: promoBadge,
        ctaText: 'Commander',
      );
    }).toList();
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
      }
    }
  }

  void _openNotifications() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: _notificationBloc,
            child: const NotificationScreen(),
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => NotificationBloc(),
            child: const NotificationScreen(),
          ),
        ),
      );
    }
  }

  void _openOrders() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => CommandeBloc(),
          child: const OrderPageScreenM(),
        ),
      ),
    );
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

  void _openFreelanceServiceOffer(String offerId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FreelanceServiceOfferDetailScreen(offerId: offerId),
      ),
    );
  }

  Future<void> _openFreelanceById(String freelanceId) async {
    try {
      final raw = await _apiClient.getFreelanceById(freelanceId);
      if (!mounted) return;
      final model = FreelanceModel.fromBackend(Map<String, dynamic>.from(raw));
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FreelanceDetailsScreen(freelance: model),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d’ouvrir le profil : $e')),
      );
    }
  }

  void _openMarketplace() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => ShoppingPageBlocM(),
          child: const ShoppingPageScreenM(),
        ),
      ),
    );
  }

  Widget _buildNotificationAction() {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) => previous.runtimeType != current.runtimeType ||
          (current is AuthAuthenticated && previous is AuthAuthenticated &&
              (previous.token != current.token ||
                  previous.utilisateur.idutilisateur != current.utilisateur.idutilisateur)),
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
            icon: const Icon(Icons.notifications_none_rounded),
          );
        }

        return BlocBuilder<NotificationBloc, NotificationState>(
          bloc: _notificationBloc,
          builder: (context, state) {
            final unreadCount = state is NotificationLoaded ? state.unreadCount : 0;
            return NavBadge(
              count: unreadCount,
              badgeColor: SDColors.error500,
              child: IconButton(
                tooltip: 'Notifications',
                onPressed: _openNotifications,
                icon: const Icon(Icons.notifications_none_rounded),
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
        if (state.isLoading && (state.listItems == null || state.listItems!.isEmpty)) {
          return const Center(child: CircularProgressIndicator());
        }
        if ((state.error ?? '').isNotEmpty) {
          return _buildError(state.error ?? 'Erreur inconnue');
        }

        final categories = state.listItems ?? [];
        final authState = context.watch<AuthCubit>().state;
        final firstName = authState is AuthAuthenticated
            ? (authState.utilisateur.prenom?.isNotEmpty == true
                ? authState.utilisateur.prenom!
                : authState.utilisateur.nom ?? 'Utilisateur')
            : 'Invité';

        final mq = MediaQuery.of(context);
        final systemBottomInset = mq.viewPadding.bottom;
        final reserveWhenNavHidden = widget.onScrollUpdate != null &&
                !widget.bottomNavVisible
            ? _bottomNavShellReserve
            : 0.0;
        final listBottomPadding =
            SDSpacing.md + systemBottomInset + reserveWhenNavHidden;

        return Scaffold(
          backgroundColor: SDColors.neutral50,
          appBar: SDAppBarIconThemed(
            style: SDAppBarIconStyles.onLightSurface,
            bar: AppBar(
              elevation: 0,
              backgroundColor: SDColors.white,
              surfaceTintColor: SDColors.white,
              iconTheme:
                  const IconThemeData(color: SDColors.neutral900, size: 22),
              automaticallyImplyLeading: false,
              // Titre collé à gauche (pas d’espace “leading” fantôme).
              leadingWidth: 0,
              leading: const SizedBox.shrink(),
              centerTitle: false,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  'Bonjour, $firstName 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SDTypography.titleLarge
                      .copyWith(color: SDColors.neutral900),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _buildNotificationAction(),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8, left: 4),
                  child: IconButton(
                    tooltip: 'Commandes',
                    onPressed: _openOrders,
                    icon: const Icon(Icons.shopping_bag_outlined),
                  ),
                ),
              ],
            ),
          ),
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
              onRefresh: _loadHomePreviewData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  SDSpacing.md,
                  SDSpacing.md,
                  SDSpacing.md,
                  // Barre Android + quand la bottom bar de l’app est cachée, garder la même marge qu’avec la barre.
                  listBottomPadding,
                ),
                children: [
                Text(
                  'Que voulez-vous faire aujourd\'hui ?',
                  style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral600),
                ),
                SizedBox(height: SDSpacing.md),
                Text(
                  'Explorer les univers',
                  style: SDTypography.titleMedium.copyWith(color: SDColors.neutral900),
                ),
                SizedBox(height: SDSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _buildUniverseCard(
                        title: 'Métiers',
                        illustrationAsset: HomeUniverseAssets.metiers,
                        icon: Icons.handyman_rounded,
                        iconColor: SDColors.primary800,
                        titleColor: SDColors.primary800,
                        onTap: _openMetiers,
                      ),
                    ),
                    SizedBox(width: SDSpacing.sm),
                    Expanded(
                      child: _buildUniverseCard(
                        title: 'Freelance',
                        illustrationAsset: HomeUniverseAssets.freelance,
                        icon: Icons.laptop_mac_rounded,
                        iconColor: SDColors.primary800,
                        titleColor: SDColors.primary800,
                        onTap: () => _openFreelance(categories),
                      ),
                    ),
                    SizedBox(width: SDSpacing.sm),
                    Expanded(
                      child: _buildUniverseCard(
                        title: 'Marketplace',
                        illustrationAsset: HomeUniverseAssets.marketplace,
                        icon: Icons.shopping_basket_rounded,
                        iconColor: SDColors.primary800,
                        titleColor: SDColors.primary800,
                        onTap: _openMarketplace,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SDSpacing.lg),
                _buildMiniSection(
                  title: 'Métiers près de vous',
                  subtitle: 'Trouvez un artisan rapidement',
                  items: _metiersItems,
                  ctaLabel: 'Voir tous les artisans',
                  onTapCta: _openMetiers,
                  useBlockContainer: false,
                  useListingCardStyle: true,
                  listingSquareImage: true,
                ),
                SizedBox(height: SDSpacing.sm),
                if (_freelanceServiceItems.isNotEmpty) ...[
                  _buildMiniSection(
                    title: 'Services freelance populaires',
                    subtitle: 'Des offres précises avec prix — explorez toutes les catégories ensuite',
                    items: _freelanceServiceItems,
                    ctaLabel: 'Tout voir',
                    onTapCta: () => _openFreelance(categories),
                    useListingCardStyle: true,
                  ),
                  SizedBox(height: SDSpacing.sm),
                ],
                _buildMiniSection(
                  title: 'Freelances disponibles',
                  subtitle: 'Des talents digitaux pour vos projets',
                  items: _freelanceItems,
                  ctaLabel: 'Explorer les freelances',
                  onTapCta: () => _openFreelance(categories),
                  useListingCardStyle: true,
                  listingSquareImage: true,
                ),
                SizedBox(height: SDSpacing.sm),
                _buildMiniSection(
                  title: 'Produits populaires',
                  subtitle: 'Achetez vite sur le marketplace',
                  items: _productItems,
                  ctaLabel: 'Voir les produits',
                  onTapCta: _openMarketplace,
                  useListingCardStyle: true,
                  listingSquareImage: true,
                ),
                if (_promoItems.isNotEmpty) ...[
                  SizedBox(height: SDSpacing.sm),
                  _buildMiniSection(
                    title: 'Promotions du moment',
                    subtitle: 'Articles en promotion (données boutique)',
                    items: _promoItems,
                    ctaLabel: 'Voir les promotions',
                    onTapCta: _openMarketplace,
                    useListingCardStyle: true,
                    listingSquareImage: false,
                    listingBannerCompact: true,
                  ),
                ],
              ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Cartes « univers » : ratio 1:1 (carré), zone image sur fond blanc, titre en bas.
  static const double _universeCardRadius = 22;

  /// Illustrations sans teinte : couleurs natives du PNG.
  Widget _buildUniverseIllustration({
    required String illustrationAsset,
    required IconData icon,
    required Color iconColor,
  }) {
    return Image.asset(
      illustrationAsset,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      gaplessPlayback: true,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Icon(
        icon,
        color: iconColor,
        size: 56,
      ),
    );
  }

  Widget _buildUniverseCard({
    required String title,
    required String illustrationAsset,
    required IconData icon,
    required Color iconColor,
    required Color titleColor,
    required VoidCallback onTap,
  }) {
    const double titleBandHeight = 40;

    return AspectRatio(
      aspectRatio: 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_universeCardRadius),
          child: Ink(
            decoration: BoxDecoration(
              color: SDColors.white,
              borderRadius: BorderRadius.circular(_universeCardRadius),
              border: Border.all(color: SDColors.neutral200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: SDColors.neutral900.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_universeCardRadius),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ColoredBox(
                      color: SDColors.white,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                        child: Transform.scale(
                          scale: 1.1,
                          alignment: Alignment.center,
                          child: _buildUniverseIllustration(
                            illustrationAsset: illustrationAsset,
                            icon: icon,
                            iconColor: iconColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: titleBandHeight,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: SDColors.white,
                      border: Border(
                        top: BorderSide(
                          color: SDColors.neutral200,
                          width: 1,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: SDTypography.titleSmall.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: -0.2,
                        ),
                      ),
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

  Widget _buildMiniSection({
    required String title,
    required String subtitle,
    required List<_HomeMiniItem> items,
    required String ctaLabel,
    required VoidCallback onTapCta,
    bool useBlockContainer = false,
    bool useListingCardStyle = false,
    /// `true` = image carrée (toutes les sections listing sauf services freelance / promos).
    bool listingSquareImage = false,
    /// Bannière 16:9 plus étroite que les offres freelance (ex. promos marketplace).
    bool listingBannerCompact = false,
  }) {
    assert(
      !listingBannerCompact || (!listingSquareImage && useListingCardStyle),
      'listingBannerCompact: bannière seulement (pas carré).',
    );
    final screenWidth = MediaQuery.of(context).size.width;
    final viewportInner = screenWidth - SDSpacing.md * 2;
    // Services freelance (bannière large) : ~236–300 px.
    // Promos (bannière compacte) : ~188–248 px.
    // Autres sections (carré) : carrousel ~2–3 cartes visibles.
    final listingCardWidth = !useListingCardStyle
        ? 0.0
        : listingSquareImage
            ? ((viewportInner - SDSpacing.sm) / 2.28).clamp(132.0, 176.0)
            : listingBannerCompact
                ? (viewportInner - SDSpacing.sm * 2).clamp(188.0, 248.0)
                : (viewportInner - SDSpacing.sm * 2).clamp(236.0, 300.0);
    final horizontalListHeight = useListingCardStyle
        ? SDListingPreviewCard.totalHeightForWidth(
            listingCardWidth,
            squareImage: listingSquareImage,
          )
        : 205.0;
    final safeItems = items.isNotEmpty
        ? items
        : [
            _HomeMiniItem(
              cardType: SDEntityCardType.product,
              title: 'Chargement...',
              subtitle: 'Veuillez patienter',
              icon: Icons.hourglass_top_rounded,
              listingLayout: useListingCardStyle,
            ),
          ];
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: SDTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        Text(subtitle, style: SDTypography.bodySmall.copyWith(color: SDColors.neutral600)),
        SizedBox(height: SDSpacing.sm),
        SizedBox(
          height: horizontalListHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: listingSquareImage
                ? EdgeInsets.only(right: SDSpacing.md)
                : (listingBannerCompact
                    ? EdgeInsets.only(right: SDSpacing.sm)
                    : EdgeInsets.zero),
            itemCount: safeItems.take(5).length,
            separatorBuilder: (_, __) => SizedBox(width: SDSpacing.sm),
            itemBuilder: (context, index) => _buildPreviewCard(
              safeItems[index],
              listingCardWidth:
                  useListingCardStyle ? listingCardWidth : null,
              listingSquareImage:
                  useListingCardStyle && listingSquareImage,
            ),
          ),
        ),
        SizedBox(height: SDSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onTapCta,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: Text(ctaLabel),
          ),
        ),
      ],
    );

    if (!useBlockContainer) return content;

    return Container(
      padding: EdgeInsets.all(SDSpacing.md),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: SDColors.neutral900.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: content,
    );
  }

  Widget _buildPreviewCard(
    _HomeMiniItem item, {
    double? listingCardWidth,
    bool listingSquareImage = false,
  }) {
    if (item.listingLayout && listingCardWidth != null) {
      return SDListingPreviewCard(
        width: listingCardWidth,
        title: item.title,
        subtitle: item.subtitle,
        fallbackIcon: item.icon,
        imageUrl: item.imageUrl,
        ratingText: item.ratingText,
        metaText: item.metaText,
        priceText: item.priceText,
        badgeText: item.statusText,
        promoBadgeText: item.promoText,
        squareImage: listingSquareImage,
        onTap: item.onCardTap,
      );
    }
    return SDEntityCard(
      type: item.cardType,
      title: item.title,
      subtitle: item.subtitle,
      fallbackIcon: item.icon,
      imageUrl: item.imageUrl,
      ratingText: item.ratingText,
      metaText: item.metaText,
      statusText: item.statusText,
      priceText: item.priceText,
      promoText: item.promoText,
      ctaLabel: item.ctaText,
      onTap: item.onCardTap ?? () {},
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: SDColors.error500, size: 48),
          SizedBox(height: SDSpacing.sm),
          Text(
            'Erreur: $error',
            style: SDTypography.bodyMedium.copyWith(color: SDColors.error500),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SDSpacing.sm),
          ElevatedButton(
            onPressed: () => context.read<HomePageBlocM>().add(LoadCategorieDataM()),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

class _HomeMiniItem {
  final SDEntityCardType cardType;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? imageUrl;
  final String? ratingText;
  final String? metaText;
  final String? statusText;
  final String? priceText;
  final String? promoText;
  final String? ctaText;
  /// Carte type annonce (grande photo + texte compact), style Airbnb.
  final bool listingLayout;
  final VoidCallback? onCardTap;

  const _HomeMiniItem({
    required this.cardType,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.imageUrl,
    this.ratingText,
    this.metaText,
    this.statusText,
    this.priceText,
    this.promoText,
    this.ctaText,
    this.listingLayout = false,
    this.onCardTap,
  });
}
