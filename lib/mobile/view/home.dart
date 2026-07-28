import 'package:flutter/material.dart';
import 'package:sdealsmobile/mobile/view/homepagem/screens/homePageScreenM.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/mobile/view/profilpagem/profilpageblocm/profilPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/profilpagem/screens/profilPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/explorer/screens/explorer_page_screen.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/nav_badge.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import '../../data/services/authCubit.dart'; // ✅ Import AuthCubit
import 'package:go_router/go_router.dart';

import 'chatpagem/chatpageblocm/chatPageBlocM.dart';
import 'chatpagem/chatpageblocm/chatPageStateM.dart';
import 'chatpagem/screens/chatPageScreenM.dart';
import 'homepagem/homepageblocm/homePageBlocM.dart';
import 'freelance_registration/screens/freelance_registration_screen.dart';
import 'seller_registration/screens/seller_registration_screen.dart';

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
  final ChatPageBlocM _chatBloc = ChatPageBlocM(userId: '');
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthAuthenticated) {
        _chatBloc.setUserId(authState.utilisateur.idutilisateur ?? '');
      }
    });
  }

  @override
  void dispose() {
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
      if (activeRole == 'PRESTATAIRE') {
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
            ? (newAuthState.utilisateur.idutilisateur ?? '')
            : '';
        _chatBloc.setUserId(newId);
      },
      child: BlocProvider.value(
        value: _chatBloc,
        child: Scaffold(
          body: _pageList[_currentIndex],
          bottomNavigationBar: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
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
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: SDColors.neutral900.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 78,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
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
              _buildPublishButton(),
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
    final iconWidget = Icon(
      isActive ? activeIcon : icon,
      size: 25,
      color: isActive ? SDColors.primary700 : SDColors.neutral700,
    );

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              withChatBadge ? _buildChatIconWithBadge(isActive) : iconWidget,
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SDTypography.labelMedium.copyWith(
                  color: isActive ? SDColors.primary700 : SDColors.neutral800,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPublishButton() {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, -16),
            child: Material(
              color: Colors.transparent,
              elevation: 6,
              shadowColor: SDColors.primary700.withOpacity(0.35),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _showPublishOptions,
                customBorder: const CircleBorder(),
                child: Ink(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [SDColors.primary600, SDColors.primary800],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: SDColors.white, width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: SDColors.primary700.withOpacity(0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: SDColors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          Text(
            'Publier',
            style: SDTypography.labelMedium.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatIconWithBadge(bool isActive) {
    return BlocBuilder<ChatPageBlocM, ChatPageStateM>(
      builder: (context, chatState) {
        int unreadCount = 0;
        if (chatState.conversations != null && chatState.conversations.isNotEmpty) {
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
            size: 25,
            color: isActive ? SDColors.primary700 : SDColors.neutral700,
          ),
        );
      },
    );
  }

  void _showPublishOptions() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: SDColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: [
            BoxShadow(
              color: SDColors.neutral900.withOpacity(0.12),
              blurRadius: 28,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: SDColors.neutral300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Que voulez-vous faire ?',
                  style: SDTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: SDColors.neutral900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choisissez comment vous lancer sur Soutrali Deals',
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                _buildPublishActionTile(
                  icon: Icons.handyman_rounded,
                  title: 'Proposer un service (Métiers)',
                  subtitle: 'Inscription ou publication côté prestataire',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _openProviderPublishFlow();
                  },
                ),
                _buildPublishActionTile(
                  icon: Icons.work_outline_rounded,
                  title: 'Devenir freelance',
                  subtitle: 'Publiez vos compétences en freelance',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FreelanceRegistrationScreen(),
                      ),
                    );
                  },
                ),
                _buildPublishActionTile(
                  icon: Icons.storefront_outlined,
                  title: 'Vendre un produit',
                  subtitle: 'Créez votre espace vendeur',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SellerRegistrationScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SDColors.primary700,
                    side: const BorderSide(color: SDColors.primary600, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(
                    'Annuler',
                    style: SDTypography.labelLarge.copyWith(
                      color: SDColors.primary700,
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

  Future<void> _openProviderPublishFlow() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      if (!mounted) return;
      context.push('/serviceProviderRegistration');
      return;
    }

    final userId = authState.utilisateur.idutilisateur;
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      context.push('/serviceProviderRegistration');
      return;
    }

    final existingProvider =
        await _apiClient.getPrestataireByUserId(userId, authState.token);

    if (!mounted) return;
    if (existingProvider != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vous avez deja un compte prestataire. Redirection vers votre dashboard.',
          ),
        ),
      );
      context.push('/providermain', extra: authState.utilisateur);
      return;
    }

    context.push('/serviceProviderRegistration');
  }

  Widget _buildPublishActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: SDColors.neutral50,
        elevation: 1,
        shadowColor: SDColors.neutral900.withOpacity(0.07),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: SDColors.neutral200),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: SDColors.primary50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: SDColors.primary700, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: SDTypography.titleSmall.copyWith(
                          color: SDColors.neutral900,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.neutral600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: SDColors.neutral400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/*

BottomNavigationBar(
backgroundColor: Colors.green,
selectedItemColor: Colors.white,
unselectedItemColor: Colors.black,
type: BottomNavigationBarType.fixed,
onTap: (index) => setState(() {
_currentIndex = index;
}),
currentIndex: _currentIndex,
items: const [
BottomNavigationBarItem(
icon: Icon(
Icons.home,
size: 30.0,
),
label: '',
),
BottomNavigationBarItem(
icon: Icon(
Icons.autorenew,
size: 30.0,
),
label: '',
),
BottomNavigationBarItem(
icon: Icon(
Icons.search,
size: 30.0,
),
label: '',
),
BottomNavigationBarItem(
icon: Icon(
Icons.shopping_bag,
size: 30.0,
),
label: '',
),
BottomNavigationBarItem(
icon: Icon(
Icons.more_horiz,
size: 30.0,
),
label: '',
),
],
),

*/
