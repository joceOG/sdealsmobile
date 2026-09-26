import 'package:flutter/material.dart';
import 'package:sdealsmobile/mobile/view/homepagem/screens/homePageScreenM.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/mobile/view/profilpagem/profilpageblocm/profilPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/profilpagem/screens/profilPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/explorer/screens/explorer_page_screen.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/nav_badge.dart';
import '../../data/services/authCubit.dart';
import '../../data/services/auth_professional_access.dart';
import 'common/auth_completion.dart';
import 'package:go_router/go_router.dart';

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
  late final ChatPageBlocM _chatBloc;

  late final VoidCallback _showHomeTab;

  @override
  void initState() {
    super.initState();
    _showHomeTab = () {
      if (!mounted || _currentIndex == 0) return;
      setState(() => _currentIndex = 0);
    };
    ClientShellSelection.bind(_showHomeTab);
    // Source de vérité : AuthCubit — injecter l'id dès la création (évite la race
    // post-frame où LoadConversations partait avec userId vide).
    final authState = context.read<AuthCubit>().state;
    final initialId = authState is AuthAuthenticated
        ? authState.utilisateur.idutilisateur.trim()
        : '';
    _chatBloc = ChatPageBlocM(
      userId: initialId.isNotEmpty ? initialId : null,
    );
  }

  @override
  void dispose() {
    ClientShellSelection.unbind(_showHomeTab);
    _chatBloc.close();
    super.dispose();
  }

  void _updateBottomNavVisibility(bool visible) {
    if (_isBottomNavVisible != visible) {
      setState(() {
        _isBottomNavVisible = visible;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    // ✅ NOUVEAU : Redirection automatique selon le rôle actif
    if (authState is AuthAuthenticated) {
      final activeRole = authState.activeRole;
      if (activeRole == 'PRESTATAIRE' && authState.canOperatePrestataire) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.push('/providermain', extra: authState.utilisateur);
        });
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
    }

    // ✅ Pages client principales
    final List<Widget> _pageList = [
      BlocProvider(
        create: (_) => HomePageBlocM(),
        child: HomePageScreenM(
          onScrollUpdate: _updateBottomNavVisibility,
          bottomNavVisible: _isBottomNavVisible,
          onOpenExplorer: () {
            if (!mounted || _currentIndex == 1) return;
            setState(() => _currentIndex = 1);
          },
        ),
      ),
      const ExplorerPageScreen(),
      const ChatPageScreenM(),
      BlocProvider(
          create: (_) => ProfilPageBlocM(), child: ProfilPageScreenM()),
    ];

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, newAuthState) {
        final newId = newAuthState is AuthAuthenticated
            ? newAuthState.utilisateur.idutilisateur.trim()
            : '';
        _chatBloc.setUserId(newId);
      },
      child: BlocProvider.value(
        value: _chatBloc,
        child: Scaffold(
          body: _pageList[_currentIndex],
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
            child: SizedBox(
              height: 64,
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
          onTap: () => setState(() => _currentIndex = index),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: SDSpacing.minTouchTarget,
            ),
            child: Column(
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: SDTypography.caption.copyWith(
                      color: color,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatIconWithBadge(bool isActive) {
    return BlocBuilder<ChatPageBlocM, ChatPageStateM>(
      builder: (context, chatState) {
        int unreadCount = 0;
        if (chatState.conversations != null &&
            chatState.conversations.isNotEmpty) {
          try {
            unreadCount = chatState.conversations.where((c) => c.unread).length;
          } catch (e) {
            unreadCount = 0;
          }
        }

        return NavBadge(
          count: unreadCount,
          child: Icon(
            isActive ? Icons.chat_bubble : Icons.chat_bubble_outline,
            size: SDSpacing.iconStandard,
            color: isActive ? SDColors.primary600 : SDColors.neutral600,
          ),
        );
      },
    );
  }
}
