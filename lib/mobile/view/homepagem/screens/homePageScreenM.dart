import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/jobPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/screens/searchPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/notificationpagem/screens/notification_screen.dart';
import 'package:sdealsmobile/mobile/view/notificationpagem/bloc/notification_bloc.dart';
import 'package:sdealsmobile/mobile/view/notificationpagem/bloc/notification_event.dart';
import 'package:sdealsmobile/mobile/view/notificationpagem/bloc/notification_state.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/nav_badge.dart';
import '../../freelancepagem/screens/freelancePageScreen.dart';
import '../../loginpagem/screens/loginPageScreenM.dart';
import '../homepageblocm/homePageBlocM.dart';
import '../homepageblocm/homePageEventM.dart';
import '../homepageblocm/homePageStateM.dart';
import '../../locationpagem/locationpageblocm/locationPageBlocM.dart';
import '../../locationpagem/locationpageblocm/locationPageEventM.dart';
import '../../locationpagem/locationpageblocm/locationPageStateM.dart';

// ✅ Design System
import '../../../../design_system/design_system.dart';

class HomePageScreenM extends StatefulWidget {
  final Function(bool)? onScrollUpdate;
  
  const HomePageScreenM({super.key, this.onScrollUpdate});
  
  @override
  State<HomePageScreenM> createState() => _HomePageScreenStateM();
}

class _HomePageScreenStateM extends State<HomePageScreenM>
    with TickerProviderStateMixin {
  late TabController _tabController;
  // ✅ Scroll detection state
  double _lastScrollOffset = 0;

  late List<Map<String, dynamic>> _tabsData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    BlocProvider.of<HomePageBlocM>(context).add(LoadCategorieDataM());

    _tabsData = [
      {"label": "Métiers", "icon": Icons.work, "page": null},
      {"label": "Freelance", "icon": Icons.person, "page": null},
      {"label": "Marketplace", "icon": Icons.shopping_cart, "page": null},
    ];

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = BlocProvider.of<HomePageBlocM>(context).state;
    if (state.listItems != null && state.isLoading == false) {
      _updateTabsPages(state.listItems);
    }
  }

  void _updateTabsPages(dynamic categories) {
    if (categories == null) return;
    try {
      _tabsData[0]["page"] = BlocProvider<JobPageBlocM>(
        create: (context) => JobPageBlocM(),
        child: const JobPageScreenM(),
      );

      _tabsData[1]["page"] = FreelancePageScreen(categories: categories);

      _tabsData[2]["page"] = BlocProvider<ShoppingPageBlocM>(
        create: (context) => ShoppingPageBlocM(),
        child: const ShoppingPageScreenM(),
      );

      setState(() {});
    } catch (e) {
      print("Erreur lors de la mise à jour des onglets: $e");
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(() {});
    _tabController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPageScreenM()),
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => NotificationBloc()
            ..add(LoadUserNotifications(
              userId: (context.read<AuthCubit>().state as AuthAuthenticated).utilisateur.idutilisateur,
            )),
          child: NotificationScreen(),
        ),
      ),
    );
  }
  
  // Badge de notifications dans l'AppBar
  Widget _buildNotificationBadge() {
    final isMetiersTab = _tabController.index == 0;
    final iconColor = isMetiersTab ? SDColors.primary600 : SDColors.white;
    
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            iconSize: 18,
            icon: Icon(Icons.notifications_outlined, color: iconColor),
            onPressed: _openNotifications,
          );
        }
        
        return BlocProvider(
          create: (context) => NotificationBloc()
            ..add(LoadUserNotifications(userId: authState.utilisateur.idutilisateur)),
          child: BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              int unreadCount = 0;
              if (state is NotificationLoaded) {
                unreadCount = state.unreadCount;
              }
              
              return NavBadge(
                count: unreadCount,
                badgeColor: SDColors.error500,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  iconSize: 18,
                  icon: Icon(Icons.notifications_outlined, color: iconColor),
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
    return BlocConsumer<HomePageBlocM, HomePageStateM>(
      listener: (context, state) {
        if (state.listItems != null && state.isLoading == false) {
          _updateTabsPages(state.listItems);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: SDColors.white,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(150),
            child: AppBar(
              backgroundColor: _tabController.index == 0 
                  ? Colors.transparent // Transparente pour Métiers (bannière en dessous)
                  : SDColors.primary600, // Verte pour les autres onglets
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: _buildAppBarContent(),
            ),
          ),
          body: state.isLoading == true && state.listItems == null
              ? Center(
                  child: CircularProgressIndicator(color: SDColors.primary600))
              : state.error != null && state.error!.isNotEmpty
                  ? _buildError(state.error!)
                  : NotificationListener<ScrollNotification>(
                      onNotification: (scrollNotification) {
                        if (scrollNotification is ScrollUpdateNotification) {
                          final currentOffset = scrollNotification.metrics.pixels;
                          final isScrollingDown = currentOffset > _lastScrollOffset;
                          final isScrollingUp = currentOffset < _lastScrollOffset;
                          
                          // Hide bottom nav when scrolling down, show when scrolling up
                          if (isScrollingDown && currentOffset > 50) {
                            widget.onScrollUpdate?.call(false);
                          } else if (isScrollingUp || currentOffset <= 50) {
                            widget.onScrollUpdate?.call(true);
                          }
                          
                          _lastScrollOffset = currentOffset;
                        }
                        return false;
                      },
                      child: TabBarView(
                          controller: _tabController,
                          children: _tabsData
                              .map<Widget>((tab) => tab["page"] != null
                                  ? tab["page"] as Widget
                                  : const Center(
                                      child: Text("Chargement des données...")))
                              .toList(),
                        ),
                    ),
        );
      },
    );
  }

  Widget _buildAppBarContent() {
    final isMetiersTab = _tabController.index == 0;
    
    return Container(
      decoration: BoxDecoration(
        color: isMetiersTab 
            ? Colors.white.withOpacity(0.95) // Blanc semi-transparent pour Métiers (par-dessus bannière)
            : SDColors.primary600, // Verte pour les autres onglets
        borderRadius: isMetiersTab 
            ? null // Pas de border radius pour Métiers (pleine largeur)
            : BorderRadius.only(
                bottomLeft: Radius.circular(SDSpacing.xxxl),
                bottomRight: Radius.circular(SDSpacing.xxxl),
              ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: SDSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: SDSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      "SOUTRALI DEALS",
                      overflow: TextOverflow.ellipsis,
                      style: SDTypography.titleMedium.copyWith(
                        color: isMetiersTab ? SDColors.primary600 : SDColors.white,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(child: _buildRoleSwitcher()),
                      SizedBox(width: SDSpacing.xxxs),
                      _buildNotificationBadge(),
                      SizedBox(width: SDSpacing.xxxs),
                      Flexible(child: _buildAuthButtons()),
                    ],
                  ),
                ],
              ),
              _buildTabBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSwitcher() {
    final isMetiersTab = _tabController.index == 0;
    
    return BlocBuilder<AuthCubit, AuthState>(builder: (context, state) {
      if (state is! AuthAuthenticated) return const SizedBox.shrink();
      final roles = state.roles;
      if (roles.isEmpty) return const SizedBox.shrink();
      final active = state.activeRole ?? roles.first;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: SDSpacing.xs, vertical: SDSpacing.xxxs),
        decoration: BoxDecoration(
          color: isMetiersTab 
              ? SDColors.primary50 // Fond vert clair pour Métiers
              : SDColors.white.withOpacity(0.15), // Fond blanc transparent pour autres onglets
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            dropdownColor: SDColors.primary600,
            value: active,
            iconEnabledColor: isMetiersTab ? SDColors.primary600 : SDColors.white,
            iconSize: 16,
            style: SDTypography.labelSmall.copyWith(
              color: isMetiersTab ? SDColors.primary600 : SDColors.white,
              fontSize: 11,
            ),
            items: roles
                .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(
                        r,
                        style: TextStyle(color: SDColors.white, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                context.read<AuthCubit>().switchActiveRole(val);
              }
            },
          ),
        ),
      );
    });
  }

  Widget _buildAuthButtons() {
    final isMetiersTab = _tabController.index == 0;
    final iconColor = isMetiersTab ? SDColors.primary600 : SDColors.white;
    
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          final utilisateur = state.utilisateur;
          final initials = ((utilisateur.nom?.isNotEmpty == true ||
                  utilisateur.prenom?.isNotEmpty == true))
              ? '${utilisateur.nom?.isNotEmpty == true ? utilisateur.nom![0] : ''}'
                      '${utilisateur.prenom?.isNotEmpty == true ? utilisateur.prenom![0] : ''}'
                  .toUpperCase()
              : '';

          return Wrap(
            spacing: SDSpacing.xxxs,
            runSpacing: SDSpacing.xxxs,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: SDColors.warning500,
                child: Text(
                  initials,
                  style: SDTypography.labelSmall.copyWith(
                    color: SDColors.white,
                    fontSize: 9,
                  ),
                ),
              ),
              if (_hasAnyPendingRole(context))
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: SDColors.secondary600,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'P',
                    style: SDTypography.labelSmall.copyWith(
                      color: SDColors.white,
                      fontSize: 7,
                    ),
                  ),
                ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                iconSize: 18,
                icon: Icon(Icons.search, color: iconColor),
                onPressed: _toggleSearch,
              ),
            ],
          );
        } else {
          // Pas connecté : seulement recherche (notification déjà dans l'AppBar)
          return IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            iconSize: 18,
            icon: Icon(Icons.search, color: iconColor),
            onPressed: _toggleSearch,
          );
        }
      },
    );
  }

  bool _hasAnyPendingRole(BuildContext context) {
    final state = context.read<AuthCubit>().state;
    if (state is! AuthAuthenticated) return false;
    final d = state.roleDetails;
    if (d == null) return false;
    final prestPending = (d['prestataire']?['verifier'] == false);
    final freePending = ((d['freelance']?['accountStatus']) == 'Pending');
    final vendPending = (d['vendeur']?['verifier'] == false);
    return prestPending || freePending || vendPending;
  }

  Widget _buildTabBar() {
    final isMetiersTab = _tabController.index == 0;
    
    return Container(
      height: 38,
      margin: EdgeInsets.only(top: SDSpacing.xxxs, left: SDSpacing.xs, right: SDSpacing.xs),
      padding: EdgeInsets.all(SDSpacing.xxxs),
      decoration: BoxDecoration(
        color: isMetiersTab 
            ? SDColors.neutral100 // Fond gris clair pour Métiers (sur fond blanc)
            : SDColors.white.withOpacity(0.15), // Fond blanc transparent pour autres onglets (sur fond vert)
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
      ),
      child: TabBar(
        controller: _tabController,
<<<<<<< HEAD
        indicator: BoxDecoration(
          color: SDColors.white,
          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: SDColors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: SDColors.primary600,
        unselectedLabelColor: isMetiersTab ? SDColors.neutral600 : SDColors.white,
        labelStyle: SDTypography.labelMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: SDTypography.labelMedium,
        tabs: _tabsData.map((tab) {
          final isSelected = _tabController.index == _tabsData.indexOf(tab);
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tab["icon"] as IconData,
                  size: 16,
                  color: isSelected 
                      ? SDColors.primary600 
                      : (isMetiersTab ? SDColors.neutral600 : SDColors.white),
                ),
                SizedBox(width: SDSpacing.xxxs),
                Flexible(
                  child: Text(
                    tab["label"] as String,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
=======
        isScrollable: true,
        indicatorColor: Colors.transparent,
        tabs: _tabsData
            .map((tab) => Tab(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _tabController.animateTo(_tabsData.indexOf(tab)),
                    icon: Icon(tab["icon"] as IconData,
                        color: Colors.white, size: 16),
                    label: Text(tab["label"] as String,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ))
            .toList(),
>>>>>>> 9a877c0 (🚀 Optimisation géolocalisation et intégration API Maps)
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
          Text('Erreur: $error', style: SDTypography.bodyMedium.copyWith(color: SDColors.error500)),
          SizedBox(height: SDSpacing.sm),
          ElevatedButton(
            onPressed: () => BlocProvider.of<HomePageBlocM>(context)
                .add(LoadCategorieDataM()),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
