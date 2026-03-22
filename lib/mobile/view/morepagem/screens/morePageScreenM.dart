import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../morepageblocm/morePageBlocM.dart';
import '../../../../data/services/authCubit.dart';
import 'package:go_router/go_router.dart';
import '../../searchpagem/screens/searchPageScreenM.dart';
import '../../common/widgets/standard_screen_header.dart';

// ✅ Design System
import '../../../../design_system/design_system.dart';

class MorePageScreenM extends StatefulWidget {
  const MorePageScreenM({super.key});
  @override
  State<MorePageScreenM> createState() => _MorePagePageScreenStateM();
}

class _MorePagePageScreenStateM extends State<MorePageScreenM> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _headerSearchController = TextEditingController();

  @override
  void initState() {
    BlocProvider.of<MorePageBlocM>(context);
    super.initState();
  }

  @override
  void dispose() {
    _headerSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: SDColors.white,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: SDColors.primary600,
              ),
              child: Text(
                'Menu',
                style: SDTypography.titleLarge.copyWith(
                  color: SDColors.white,
                ),
              ),
            ),
            // Ajoute ici d'autres éléments de menu si besoin
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                SDSpacing.md,
                SDSpacing.sm,
                SDSpacing.md,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StandardScreenHeader(
                    title: 'Plus',
                    leading: SdCircleIconButton(
                      icon: Icons.menu_rounded,
                      tooltip: 'Menu',
                      onPressed: () =>
                          _scaffoldKey.currentState?.openDrawer(),
                    ),
                    actions: [
                      SdCircleIconButton(
                        icon: Icons.notifications_outlined,
                        tooltip: 'Notifications',
                        onPressed: () {},
                      ),
                    ],
                  ),
                  SizedBox(height: SDSpacing.md),
                  FreelanceStyleSearchBar(
                    controller: _headerSearchController,
                    hintText: 'Rechercher sur soutralideals',
                    onTunePressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SearchPageScreenM(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: SDSpacing.lg, vertical: SDSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: SDSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _AnimatedCardWithBadge(
                          icon: Icons.article_rounded,
                          label: 'Soutra News',
                          badge: 'Nouveau',
                          gradient: LinearGradient(
                            colors: [
                              SDColors.success500,
                              SDColors.success600
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: () {
                            // TODO: Naviguer vers Soutra News
                          },
                        ),
                      ),
                      SizedBox(width: SDSpacing.md),
                      Expanded(
                        child: _AnimatedCardWithBadge(
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Soutra Pay',
                          badge: 'Nouveau',
                          gradient: LinearGradient(
                            colors: [
                              SDColors.success500,
                              SDColors.success600
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: () {
                            // TODO: Naviguer vers Soutra Pay
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SDSpacing.md),
                  _buildPrestataireModeCard(),
                  SizedBox(height: SDSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 CARTE MODE PRESTATAIRE
  Widget _buildPrestataireModeCard() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        // Vérifier si l'utilisateur a le rôle PRESTATAIRE
        if (state is AuthAuthenticated && state.roles.contains('PRESTATAIRE')) {
          return _AnimatedCardWithBadge(
            icon: Icons.handyman,
            label: 'Mode Prestataire',
            badge: 'Disponible',
            gradient: LinearGradient(
              colors: [SDColors.primary500, SDColors.primary700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () => _switchToPrestataireMode(context),
          );
        }
        return SizedBox.shrink(); // Masquer si pas prestataire
      },
    );
  }

  // 🔄 SWITCH VERS MODE PRESTATAIRE
  void _switchToPrestataireMode(BuildContext context) {
    try {
      context.read<AuthCubit>().switchActiveRole('PRESTATAIRE');
      Future.delayed(const Duration(milliseconds: 100), () {
        context.push('/providermain');
      });
    } catch (e) {
      print('Erreur lors du switch vers prestataire: $e');
      context.push('/providermain');
    }
  }
}

class _AnimatedCardWithBadge extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final Gradient gradient;
  final VoidCallback? onTap;
  const _AnimatedCardWithBadge({
    required this.icon,
    required this.label,
    this.badge,
    required this.gradient,
    this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  State<_AnimatedCardWithBadge> createState() => _AnimatedCardWithBadgeState();
}

class _AnimatedCardWithBadgeState extends State<_AnimatedCardWithBadge> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 120),
              height: 100,
              decoration: BoxDecoration(
                gradient: widget.gradient,
                borderRadius: BorderRadius.circular(SDSpacing.xxxl),
                border: Border.all(color: SDColors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _pressed
                        ? SDColors.success500.withOpacity(0.25)
                        : SDColors.neutral900.withOpacity(0.10),
                    blurRadius: _pressed ? 24 : 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, color: SDColors.white, size: 32),
                  SizedBox(width: SDSpacing.sm),
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SDTypography.titleMedium.copyWith(
                        color: SDColors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.badge != null)
              Positioned(
                top: -12,
                right: 18,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: SDSpacing.sm, vertical: SDSpacing.xxxs),
                  decoration: BoxDecoration(
                    color: SDColors.error500,
                    borderRadius: BorderRadius.circular(SDSpacing.sm),
                    boxShadow: [
                      BoxShadow(
                        color: SDColors.error500.withOpacity(0.18),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.badge!,
                    style: SDTypography.labelSmall.copyWith(
                      color: SDColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Widget _buildCategoryItem(String title, String subtitle, String imagePath,
    {bool isPopular = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {},
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 100),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage(imagePath),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      Text(
                        subtitle,
                        style:
                            const TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isPopular)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Populaire',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildProviderItem(String name, String price, String imagePath,
    {bool isPopular = false}) {
  return Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    elevation: 2,
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {},
      child: Stack(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
            child: Column(
              children: [
                AnimatedScale(
                  scale: 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: CircleAvatar(
                    radius: 38,
                    backgroundImage: AssetImage(imagePath),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black),
                ),
                Text(
                  price,
                  style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ],
            ),
          ),
          if (isPopular)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Populaire',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
