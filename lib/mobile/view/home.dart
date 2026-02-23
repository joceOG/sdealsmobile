import 'package:flutter/material.dart';
import 'package:sdealsmobile/mobile/view/homepagem/screens/homePageScreenM.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/mobile/view/profilpagem/profilpageblocm/profilPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/profilpagem/screens/profilPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/rondpagem/rondpageblocm/rondPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/rondpagem/screens/rondPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/screens/searchPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/searchpageblocm/searchPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/walletpagem/screens/walletPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/walletpagem/walletpageblocm/walletPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/nav_badge.dart';
import '../../data/services/authCubit.dart'; // ✅ Import AuthCubit
import 'package:go_router/go_router.dart';

import 'chatpagem/chatpageblocm/chatPageBlocM.dart';
import 'chatpagem/chatpageblocm/chatPageStateM.dart';
import 'chatpagem/screens/chatPageScreenM.dart';
import 'homepagem/homepageblocm/homePageBlocM.dart';
import 'morepagem/morepageblocm/morePageBlocM.dart';
import 'morepagem/screens/morePageScreenM.dart';
import 'orderpagem/orderpageblocm/commande_bloc.dart';
import 'orderpagem/screens/orderPageScreenM.dart';

// ✅ Design System
import '../../design_system/design_system.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

int _currentIndex = 0;

class _HomeState extends State<Home> {
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

    // ✅ Créer la liste des pages avec l'userId
    final List<Widget> _pageList = [
      BlocProvider(
        create: (_) => HomePageBlocM(),
        child: HomePageScreenM(onScrollUpdate: _updateBottomNavVisibility),
      ),
      BlocProvider(
          create: (_) => WalletPageBlocM(), child: WalletPageScreenM()),
      const ChatPageScreenM(), // ✅ Provider déplacé au niveau du Scaffold pour accès global (Badge)
      BlocProvider(create: (_) => CommandeBloc(), child: OrderPageScreenM()),
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
          child: _isBottomNavVisible ? Container(
          decoration: BoxDecoration(
            color: SDColors.white,
            boxShadow: [
              BoxShadow(
                color: SDColors.neutral900.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: SDColors.white,
              selectedItemColor: SDColors.primary600,
              unselectedItemColor: SDColors.neutral500,
              selectedLabelStyle: SDTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: SDTypography.labelSmall,
              currentIndex: _currentIndex,
              elevation: 0,
              onTap: (index) => setState(() => _currentIndex = index),
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined, size: 24),
                  activeIcon: Icon(Icons.home, size: 24),
                  label: 'Accueil',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet_outlined, size: 24),
                  activeIcon: Icon(Icons.account_balance_wallet, size: 24),
                  label: 'Wallet',
                ),
                BottomNavigationBarItem(
                  icon: _buildChatIconWithBadge(false),
                  activeIcon: _buildChatIconWithBadge(true),
                  label: 'Chat',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_bag_outlined, size: 24),
                  activeIcon: Icon(Icons.shopping_bag, size: 24),
                  label: 'Commandes',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_circle_outlined, size: 24),
                  activeIcon: Icon(Icons.account_circle, size: 24),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ) : null,
        ),
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
            isActive ? Icons.chat : Icons.chat_outlined,
            size: 24,
          ),
        );
      },
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
