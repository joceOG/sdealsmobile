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
      color: isActive ? SDColors.neutral900 : SDColors.neutral700,
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
                  color: isActive ? SDColors.neutral900 : SDColors.neutral800,
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
            color: isActive ? SDColors.neutral900 : SDColors.neutral700,
          ),
        );
      },
    );
  }

  void _showPublishOptions() {
    final auth = context.read<AuthCubit>().state;
    final roles = auth is AuthAuthenticated ? auth.roles : const <String>[];
    final isProvider = roles.contains('PRESTATAIRE');
    final isFreelance = roles.contains('FREELANCE');
    final isSeller = roles.contains('VENDEUR');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: SDColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
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
                const SizedBox(height: 18),
                Text(
                  'Que souhaitez-vous publier ?',
                  style: SDTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: SDColors.neutral900,
                    fontSize: 22,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choisissez une catégorie pour continuer — métiers, freelance ou boutique.',
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                _buildPartnerCard(
                  icon: Icons.handyman_rounded,
                  iconColor: SDColors.primary500,
                  title: isProvider ? 'Espace Métiers' : 'Métiers',
                  benefit: isProvider
                      ? 'Gérer missions, planning et profil prestataire'
                      : 'Recevez des demandes près de chez vous',
                  ctaLabel: isProvider
                      ? 'Gérer mon espace'
                      : 'Proposer un service',
                  alreadyPartner: isProvider,
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _openProviderPublishFlow();
                  },
                ),
                _buildPartnerCard(
                  icon: Icons.laptop_mac_rounded,
                  iconColor: SDColors.info600,
                  title: isFreelance ? 'Espace Freelance' : 'Freelance',
                  benefit: isFreelance
                      ? 'Mettre à jour compétences et offres'
                      : 'Vendez vos compétences digitales',
                  ctaLabel: isFreelance
                      ? 'Gérer mon profil'
                      : 'Devenir freelance',
                  alreadyPartner: isFreelance,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openFreelancePublishFlow(already: isFreelance);
                  },
                ),
                _buildPartnerCard(
                  icon: Icons.shopping_bag_rounded,
                  iconColor: SDColors.primary600,
                  title: isSeller ? 'Espace Boutique' : 'Boutique',
                  benefit: isSeller
                      ? 'Gérer produits et commandes'
                      : 'Vendez vos produits partout en CI',
                  ctaLabel:
                      isSeller ? 'Gérer ma boutique' : 'Ouvrir une boutique',
                  alreadyPartner: isSeller,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openSellerPublishFlow(already: isSeller);
                  },
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(
                    'Fermer',
                    style: SDTypography.labelMedium.copyWith(
                      color: SDColors.neutral500,
                      fontWeight: FontWeight.w600,
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
      context.push('/login');
      return;
    }

    final userId = authState.utilisateur.idutilisateur;
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      context.push('/serviceProviderRegistration');
      return;
    }

    // Rôle déjà présent → dashboard directement
    if (authState.roles.contains('PRESTATAIRE')) {
      if (!mounted) return;
      context.read<AuthCubit>().switchActiveRole('PRESTATAIRE');
      context.push('/providermain', extra: authState.utilisateur);
      return;
    }

    final existingProvider =
        await _apiClient.getPrestataireByUserId(userId, authState.token);

    if (!mounted) return;
    if (existingProvider != null) {
      context.read<AuthCubit>().switchActiveRole('PRESTATAIRE');
      context.push('/providermain', extra: authState.utilisateur);
      return;
    }

    // Landing courte existante (catégories vides OK — CTA inscription reste)
    context.push('/serviceProviderWelcome', extra: <dynamic>[]);
  }

  void _openFreelancePublishFlow({required bool already}) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      context.push('/login');
      return;
    }
    if (already) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vous êtes déjà freelance. L’espace de gestion arrive bientôt.',
          ),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FreelanceRegistrationScreen(),
      ),
    );
  }

  void _openSellerPublishFlow({required bool already}) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      context.push('/login');
      return;
    }
    if (already) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vous avez déjà une boutique. L’espace de gestion arrive bientôt.',
          ),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SellerRegistrationScreen(),
      ),
    );
  }

  Widget _buildPartnerCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String benefit,
    required String ctaLabel,
    required bool alreadyPartner,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: SDColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: alreadyPartner ? SDColors.primary200 : SDColors.neutral200,
            width: alreadyPartner ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color.lerp(iconColor, SDColors.white, 0.22)!,
                        iconColor,
                      ],
                      center: const Alignment(-0.2, -0.25),
                      radius: 0.95,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: SDColors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: SDTypography.titleSmall.copyWith(
                                color: SDColors.neutral900,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (alreadyPartner) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: SDColors.primary50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Actif',
                                style: SDTypography.labelSmall.copyWith(
                                  color: SDColors.primary700,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        benefit,
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.neutral600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ctaLabel,
                        style: SDTypography.labelMedium.copyWith(
                          color: iconColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
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
