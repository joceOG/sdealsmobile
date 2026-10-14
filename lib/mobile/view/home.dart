import 'package:flutter/material.dart';
import 'package:sdealsmobile/mobile/view/homepagem/screens/homePageScreenM.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/mobile/view/profilpagem/profilpageblocm/profilPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/profilpagem/screens/profilPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/explorer/screens/explorer_page_screen.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/nav_badge.dart';
import '../../data/services/authCubit.dart';
import '../../data/services/startup_trace.dart';
import '../../data/services/auth_professional_access.dart';
import 'common/auth_completion.dart' show ClientShellProfileTab, ClientShellSelection;
import 'common/role_shell_navigation.dart';
import '../../data/models/utilisateur.dart';

import 'chatpagem/chatpageblocm/chatPageBlocM.dart';
import 'chatpagem/chatpageblocm/chatPageStateM.dart';
import 'chatpagem/screens/chatPageScreenM.dart';
import 'homepagem/homepageblocm/homePageBlocM.dart';

// ✅ Design System
import '../../design_system/design_system.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;
  bool _isBottomNavVisible = true;
  ChatPageBlocM? _chatBloc;
  final List<bool> _tabReady = [true, false, false, false];

  late final VoidCallback _showHomeTab;
  late final VoidCallback _showProfileTab;

  @override
  void initState() {
    super.initState();
    StartupTrace.mark('Home.init');
    _showHomeTab = () {
      if (!mounted || _currentIndex == 0) return;
      setState(() => _currentIndex = 0);
    };
    _showProfileTab = () {
      if (!mounted) return;
      _openTab(3);
    };
    ClientShellSelection.bind(_showHomeTab);
    ClientShellProfileTab.bind(_showProfileTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(const AssetImage('assets/profil_vide.png'), context);
    });
  }

  void _ensureChatBloc() {
    if (_chatBloc != null) return;
    final authState = context.read<AuthCubit>().state;
    final initialId = authState is AuthAuthenticated
        ? authState.utilisateur.idutilisateur.trim()
        : '';
    _chatBloc = ChatPageBlocM(
      userId: initialId.isNotEmpty ? initialId : null,
    );
  }

  void _openTab(int index) {
    ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
    setState(() {
      _currentIndex = index;
      _tabReady[index] = true;
      if (index == 2) _ensureChatBloc();
    });
  }

  @override
  void dispose() {
    ClientShellSelection.unbind(_showHomeTab);
    ClientShellProfileTab.unbind(_showProfileTab);
    _chatBloc?.close();
    super.dispose();
  }

  void _updateBottomNavVisibility(bool visible) {
    if (_isBottomNavVisible != visible) {
      setState(() {
        _isBottomNavVisible = visible;
      });
    }
  }

  /// Retour Android sur un onglet racine autre qu'Accueil : on revient à
  /// Accueil dans le même shell (même route, onglets conservés).
  /// Sur Accueil, [PopScope.canPop] vaut true : sortie normale.
  void _onShellPopInvoked(bool didPop, Object? _) {
    if (didPop || !mounted || _currentIndex == 0) return;
    setState(() => _currentIndex = 0);
  }

  bool _providerRedirectScheduled = false;

  /// Rôle actif PRESTATAIRE : remplace la pile par `/providermain` (go).
  /// Uniquement quand Home est la route visible : un login, une action
  /// reprise ou un dialogue au-dessus ne sont pas écrasés ; Home se
  /// reconstruit quand sa route redevient courante.
  void _scheduleProviderRedirect(Utilisateur utilisateur) {
    if (_providerRedirectScheduled) return;
    _providerRedirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _providerRedirectScheduled = false;
      if (!mounted) return;
      if (ModalRoute.of(context)?.isCurrent == false) return;
      goToProviderShell(
        context,
        utilisateur: utilisateur,
        switchRole: false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    // ✅ NOUVEAU : Redirection automatique selon le rôle actif
    if (authState is AuthAuthenticated) {
      final activeRole = authState.activeRole;
      if (activeRole == 'PRESTATAIRE' && authState.canOperatePrestataire) {
        // Dépendance isCurrent : rebuild quand une route au-dessus se ferme.
        final isCurrent = ModalRoute.isCurrentOf(context) ?? true;
        if (isCurrent) {
          _scheduleProviderRedirect(authState.utilisateur);
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      }
    }

    // ✅ Pages client — Accueil immédiat, les autres onglets au premier affichage.
    final chat = _chatBloc;
    final pages = <Widget>[
      BlocProvider(
        create: (_) => HomePageBlocM(),
        child: HomePageScreenM(
          onScrollUpdate: _updateBottomNavVisibility,
          bottomNavVisible: _isBottomNavVisible,
          onOpenExplorer: () => _openTab(1),
        ),
      ),
      if (_tabReady[1]) const ExplorerPageScreen() else const SizedBox.shrink(),
      if (_tabReady[2] && chat != null)
        TickerMode(
          enabled: _currentIndex == 2,
          child: BlocProvider.value(
            value: chat,
            child: const ChatPageScreenM(),
          ),
        )
      else
        const SizedBox.shrink(),
      if (_tabReady[3])
        TickerMode(
          enabled: _currentIndex == 3,
          child: BlocProvider(
            create: (_) => ProfilPageBlocM(),
            child: const ProfilPageScreenM(),
          ),
        )
      else
        const SizedBox.shrink(),
    ];

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, newAuthState) {
        final newId = newAuthState is AuthAuthenticated
            ? newAuthState.utilisateur.idutilisateur.trim()
            : '';
        _chatBloc?.setUserId(newId);
      },
      child: PopScope(
        canPop: _currentIndex == 0,
        onPopInvokedWithResult: _onShellPopInvoked,
        child: Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          bottomNavigationBar: AnimatedContainer(
            duration: SDClientMotion.stateChange,
            curve: SDClientMotion.stateCurve,
            height: _isBottomNavVisible ? null : 0,
            child: _isBottomNavVisible
                ? _buildBottomNavBar()
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: SDColors.white,
        border: Border(
          top: BorderSide(color: SDColors.neutral200),
        ),
      ),
      child: Builder(
        builder: (context) {
          // Politique unifiée : SDResponsive.systemBottomInset couvre padding,
          // viewPadding, FlutterView et systemGestureInsets (cas EMUI mesuré :
          // la barre 3-boutons n'apparaît QUE dans gestureInsets = 38.7 dp).
          final double bottomSafe = SDResponsive.systemBottomInset(context);
          return Padding(
            padding: EdgeInsets.only(bottom: bottomSafe),
            child: Row(
                children: [
                  _buildNavItem(
                    index: 0,
                    label: 'Accueil',
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                  ),
                  _buildNavItem(
                    index: 1,
                    label: 'Explorer',
                    icon: Icons.search_outlined,
                    activeIcon: Icons.search,
                  ),
                  _buildNavItem(
                    index: 2,
                    label: 'Messagerie',
                    icon: Icons.chat_bubble_outline,
                    activeIcon: Icons.chat_bubble,
                    withChatBadge: true,
                  ),
                  _buildNavItem(
                    index: 3,
                    label: 'Profil',
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                  ),
                ],
              ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    bool withChatBadge = false,
  }) {
    final bool isActive = _currentIndex == index;
    final color = isActive ? SDColors.primary600 : SDColors.neutral600;
    final iconWidget = Icon(
      isActive ? activeIcon : icon,
      size: SDSpacing.iconStandard,
      color: color,
    );

    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: label,
        child: InkWell(
          onTap: () => _openTab(index),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: SDSpacing.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: SDClientMotion.stateChange,
                  switchInCurve: SDClientMotion.stateCurve,
                  switchOutCurve: SDClientMotion.stateCurve,
                  child: KeyedSubtree(
                    key: ValueKey<bool>(isActive),
                    child: AnimatedContainer(
                      duration: SDClientMotion.resolve(
                        context,
                        SDClientMotion.stateChange,
                      ),
                      curve: SDClientMotion.stateCurve,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? SDColors.primary50 : SDColors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: withChatBadge
                          ? _buildChatIconWithBadge(isActive)
                          : iconWidget,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: SDTypography.caption.copyWith(
                    color: color,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: 0,
                    height: 1.15,
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

  Widget _buildChatIconWithBadge(bool isActive) {
    final icon = Icon(
      isActive ? Icons.chat_bubble : Icons.chat_bubble_outline,
      size: SDSpacing.iconStandard,
      color: isActive ? SDColors.primary600 : SDColors.neutral600,
    );
    final bloc = _chatBloc;
    if (bloc == null) return icon;
    return BlocProvider.value(
      value: bloc,
      child: BlocBuilder<ChatPageBlocM, ChatPageStateM>(
        builder: (context, chatState) {
          var unreadCount = 0;
          if (chatState.conversations.isNotEmpty) {
            unreadCount = chatState.conversations.where((c) => c.unread).length;
          }
          return NavBadge(count: unreadCount, child: icon);
        },
      ),
    );
  }
}
