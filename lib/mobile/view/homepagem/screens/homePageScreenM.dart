import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/nav_badge.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/screens/freelancePageScreen.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/jobPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/notificationpagem/bloc/notification_bloc.dart';
import 'package:sdealsmobile/mobile/view/notificationpagem/bloc/notification_event.dart';
import 'package:sdealsmobile/mobile/view/notificationpagem/bloc/notification_state.dart';
import 'package:sdealsmobile/mobile/view/notificationpagem/screens/notification_screen.dart';
import 'package:sdealsmobile/mobile/view/orderpagem/orderpageblocm/commande_bloc.dart';
import 'package:sdealsmobile/mobile/view/orderpagem/screens/orderPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageBlocM.dart';
import '../homepageblocm/homePageBlocM.dart';
import '../homepageblocm/homePageEventM.dart';
import '../homepageblocm/homePageStateM.dart';
import '../home_universe_assets.dart';
import '../../../../design_system/design_system.dart';

class HomePageScreenM extends StatefulWidget {
  final Function(bool)? onScrollUpdate;
  const HomePageScreenM({super.key, this.onScrollUpdate});

  @override
  State<HomePageScreenM> createState() => _HomePageScreenStateM();
}

class _HomePageScreenStateM extends State<HomePageScreenM> {
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    context.read<HomePageBlocM>().add(LoadCategorieDataM());
  }

  void _openNotifications() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => NotificationBloc()
            ..setToken(authState.token)
            ..add(LoadUserNotifications(userId: authState.utilisateur.idutilisateur)),
          child: const NotificationScreen(),
        ),
      ),
    );
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
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: _openNotifications,
          );
        }

        return BlocProvider(
          create: (_) => NotificationBloc()
            ..setToken(authState.token)
            ..add(LoadUserNotifications(userId: authState.utilisateur.idutilisateur)),
          child: BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              final unreadCount = state is NotificationLoaded ? state.unreadCount : 0;
              return NavBadge(
                count: unreadCount,
                badgeColor: SDColors.error500,
                child: IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: _openNotifications,
                ),
              );
            },
          ),
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

        return Scaffold(
          backgroundColor: SDColors.neutral50,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: SDColors.white,
            surfaceTintColor: SDColors.white,
            automaticallyImplyLeading: false,
            iconTheme: const IconThemeData(color: SDColors.neutral900, size: 22),
            titleSpacing: 16,
            title: Text(
              'Bonjour, $firstName 👋',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SDTypography.titleLarge.copyWith(color: SDColors.neutral900),
            ),
            actions: [
              _buildNotificationAction(),
              IconButton(
                onPressed: _openOrders,
                icon: const Icon(Icons.shopping_bag_outlined),
                tooltip: 'Commandes',
              ),
              const SizedBox(width: 4),
            ],
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
            child: ListView(
              padding: EdgeInsets.all(SDSpacing.md),
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
                        backgroundColor: SDColors.primary50,
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
                        backgroundColor: SDColors.warning50,
                        iconColor: SDColors.warning700,
                        titleColor: SDColors.warning700,
                        onTap: () => _openFreelance(categories),
                      ),
                    ),
                    SizedBox(width: SDSpacing.sm),
                    Expanded(
                      child: _buildUniverseCard(
                        title: 'Marketplace',
                        illustrationAsset: HomeUniverseAssets.marketplace,
                        icon: Icons.shopping_basket_rounded,
                        backgroundColor: SDColors.secondary50,
                        iconColor: SDColors.secondary600,
                        titleColor: SDColors.secondary700,
                        onTap: _openMarketplace,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SDSpacing.lg),
                _buildSectionTeaser(
                  title: 'Métiers près de vous',
                  subtitle: 'Trouvez un artisan rapidement',
                  buttonLabel: 'Voir tous les artisans',
                  onPressed: _openMetiers,
                ),
                SizedBox(height: SDSpacing.sm),
                _buildSectionTeaser(
                  title: 'Freelances disponibles',
                  subtitle: 'Des talents digitaux pour vos projets',
                  buttonLabel: 'Explorer les freelances',
                  onPressed: () => _openFreelance(categories),
                ),
                SizedBox(height: SDSpacing.sm),
                _buildSectionTeaser(
                  title: 'Produits populaires',
                  subtitle: 'Achetez vite sur le marketplace',
                  buttonLabel: 'Voir les produits',
                  onPressed: _openMarketplace,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Cartes « univers » : ratio 1:1 (carré), pastel, titre en bas.
  static const double _universeCardRadius = 22;

  /// Fusion du blanc des PNG avec le fond pastel (évite le « cadre blanc »).
  Widget _buildUniverseIllustration({
    required String illustrationAsset,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Image.asset(
      illustrationAsset,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      gaplessPlayback: true,
      filterQuality: FilterQuality.high,
      // Blanc × couleur du fond → le fond « traverse » le blanc du visuel.
      color: backgroundColor,
      colorBlendMode: BlendMode.multiply,
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
    required Color backgroundColor,
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
              color: backgroundColor,
              borderRadius: BorderRadius.circular(_universeCardRadius),
              boxShadow: [
                BoxShadow(
                  color: SDColors.neutral900.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_universeCardRadius),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.35),
                          radius: 1.25,
                          colors: [
                            Color.lerp(
                              backgroundColor,
                              SDColors.white,
                              0.2,
                            ) ??
                                backgroundColor,
                            backgroundColor,
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                        child: Transform.scale(
                          scale: 1.1,
                          alignment: Alignment.center,
                          child: _buildUniverseIllustration(
                            illustrationAsset: illustrationAsset,
                            icon: icon,
                            iconColor: iconColor,
                            backgroundColor: backgroundColor,
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
                      color: backgroundColor,
                      border: Border(
                        top: BorderSide(
                          color: titleColor.withOpacity(0.12),
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

  Widget _buildSectionTeaser({
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: SDTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
          SizedBox(height: SDSpacing.xxxs),
          Text(subtitle, style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral600)),
          SizedBox(height: SDSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
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