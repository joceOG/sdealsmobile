import 'package:flutter/material.dart';
import 'package:sdealsmobile/mobile/view/homepagem/screens/homePageScreenM.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/mobile/view/profilpagem/profilpageblocm/profilPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/profilpagem/screens/profilPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/explorer/screens/explorer_page_screen.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/nav_badge.dart';
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

  void _updateBottomNavVisibility(bool visible) {
    if (_isBottomNavVisible != visible) {
      setState(() {
        _isBottomNavVisible = visible;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Récupérer l'utilisateur connecté depuis AuthCubit
    final authState = context.watch<AuthCubit>().state;
    final String? userId = authState is AuthAuthenticated
        ? authState.utilisateur.idutilisateur
        : null;

    // ✅ NOUVEAU : Redirection automatique selon le rôle actif
    if (authState is AuthAuthenticated) {
      final activeRole = authState.activeRole;
      if (activeRole == 'PRESTATAIRE') {
        // Rediriger vers l'interface prestataire
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
        child: HomePageScreenM(onScrollUpdate: _updateBottomNavVisibility),
      ),
      const ExplorerPageScreen(),
      const ChatPageScreenM(), // ✅ Provider déplacé au niveau du Scaffold pour accès global (Badge)
      BlocProvider(
          create: (_) => ProfilPageBlocM(), child: ProfilPageScreenM()),
    ];

    return BlocProvider(
      create: (_) => ChatPageBlocM(userId: userId),
      child: Scaffold(
        body: Center(child: _pageList[_currentIndex]),
        bottomNavigationBar: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isBottomNavVisible ? null : 0,
          child: _isBottomNavVisible
              ? _buildBottomNavBar()
              : const SizedBox.shrink(),
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
            offset: const Offset(0, -14),
            child: GestureDetector(
              onTap: _showPublishOptions,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: SDColors.primary700,
                  shape: BoxShape.circle,
                  border: Border.all(color: SDColors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: SDColors.primary700.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: SDColors.white,
                  size: 30,
                ),
              ),
            ),
          ),
          Text(
            'Publier',
            style: SDTypography.labelMedium.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w600,
              fontSize: 11,
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SDColors.neutral300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Que voulez-vous faire ?',
                style: SDTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _buildPublishActionTile(
                icon: Icons.handyman_rounded,
                title: 'Proposer un service (Metiers)',
                subtitle: 'Inscription ou publication cote prestataire',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/serviceProviderRegistration');
                },
              ),
              _buildPublishActionTile(
                icon: Icons.work_outline_rounded,
                title: 'Devenir freelance',
                subtitle: 'Publiez vos competences en freelance',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    this.context,
                    MaterialPageRoute(
                      builder: (_) => const FreelanceRegistrationScreen(),
                    ),
                  );
                },
              ),
              _buildPublishActionTile(
                icon: Icons.storefront_outlined,
                title: 'Vendre un produit',
                subtitle: 'Creez votre espace vendeur',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    this.context,
                    MaterialPageRoute(
                      builder: (_) => const SellerRegistrationScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPublishActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: SDColors.neutral50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: SDColors.neutral200),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: SDColors.primary50,
          child: Icon(icon, color: SDColors.primary700),
        ),
        title: Text(
          title,
          style: SDTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle, style: SDTypography.bodySmall),
        trailing: const Icon(Icons.chevron_right),
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
