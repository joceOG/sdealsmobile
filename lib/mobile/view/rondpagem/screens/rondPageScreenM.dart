import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sdealsmobile/mobile/view/rondpagem/rondpageblocm/rondPageStateM.dart';
import '../rondpageblocm/rondPageBlocM.dart';
import '../rondpageblocm/rondPageEventM.dart';

// ✅ Design System
import '../../../../design_system/design_system.dart';

class RondPageScreenM extends StatefulWidget {
  const RondPageScreenM({super.key});
  @override
  State<RondPageScreenM> createState() => _RondPageScreenStateM();
}

class _RondPageScreenStateM extends State<RondPageScreenM> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _arrowPressed = false;
  int _prestatairePressed = -1;
  @override
  void initState() {
    BlocProvider.of<RondPageBlocM>(context);
    super.initState();
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
                gradient: SDGradients.primaryGradient,
              ),
              child: Text(
                'Menu',
                style: SDTypography.displayMedium.copyWith(
                  color: SDColors.white,
                ),
              ),
            ),
            // Ajoute ici d'autres éléments de menu si besoin
          ],
        ),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(170),
        child: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(44),
              bottomRight: Radius.circular(44),
            ),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: SDGradients.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: SDColors.neutral900.withOpacity(0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(44),
                bottomRight: Radius.circular(44),
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: SDSpacing.sm, vertical: SDSpacing.xxs),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            _scaffoldKey.currentState?.openDrawer();
                          },
                          child: Icon(Icons.menu,
                              color: SDColors.white, size: 32),
                        ),
                        IconButton(
                          icon: Icon(Icons.notifications,
                              color: SDColors.white, size: 32),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: SDSpacing.xxxs),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: SDAnimations.medium,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: child,
                    ),
                    child: Center(
                      child: Text(
                        'SOUTRALI DEALS',
                        style: SDTypography.titleLarge.copyWith(
                          color: SDColors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: SDSpacing.sm),
                    child: Align(
                      alignment: Alignment.center,
                      child: FractionallySizedBox(
                        widthFactor: 0.8,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: SDColors.white,
                            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                            border: Border.all(
                                color: SDColors.primary200, width: 1.4),
                            boxShadow: [
                              BoxShadow(
                                color: SDColors.primary500.withOpacity(0.07),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: SDSpacing.sm),
                              Material(
                                color: SDColors.primary600,
                                shape: const CircleBorder(),
                                elevation: 2,
                                child: Padding(
                                  padding: EdgeInsets.all(SDSpacing.xxs),
                                  child: Icon(Icons.search_rounded,
                                      color: SDColors.white, size: 22),
                                ),
                              ),
                              SizedBox(width: SDSpacing.sm),
                              Expanded(
                                child: TextField(
                                  style: SDTypography.bodyMedium,
                                  cursorColor: SDColors.primary600,
                                  decoration: InputDecoration(
                                    hintText: 'Rechercher sur soutralideals',
                                    hintStyle: SDTypography.bodyMedium.copyWith(
                                        color: SDColors.primary600,
                                        fontWeight: FontWeight.w500),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: SDSpacing.sm),
                                  ),
                                ),
                              ),
                              SizedBox(width: SDSpacing.sm),
                            ],
                          ),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(SDSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barre de recherche

              SizedBox(height: SDSpacing.lg),
              // Liste horizontale de freelances
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Freelances populaires',
                    style: SDTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: SDColors.neutral900,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Voir plus',
                      style: SDTypography.labelLarge.copyWith(
                        color: SDColors.primary600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: SDSpacing.sm),
              SizedBox(
                height: 200,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFreelanceCard('Aminata', 'Développeuse mobile & web',
                        'assets/profile_picture.jpg',
                        isTop: true, avatarSize: 48),
                    _buildFreelanceCard(
                        'Yao', 'Designer UI/UX', 'assets/esty.jpg',
                        avatarSize: 48),
                    _buildFreelanceCard(
                        'Fatou', 'Rédactrice SEO', 'assets/coiffuer2.jpeg',
                        avatarSize: 48),
                    _buildFreelanceCard(
                        'Marc', 'Photographe', 'assets/profile_picture.jpg',
                        avatarSize: 48),
                  ],
                ),
              ),
              SizedBox(height: SDSpacing.xl),
              // Section À la une
              Text(
                'À la une',
                style: SDTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: SDColors.neutral900,
                ),
              ),
              SizedBox(height: SDSpacing.sm),
              _buildFeaturedCard(),
              SizedBox(height: SDSpacing.xl),
              // Nouveaux freelances
              Text(
                'Nouveaux freelances',
                style: SDTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: SDColors.neutral900,
                ),
              ),
              SizedBox(height: SDSpacing.sm),
              SizedBox(
                height: 180,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFreelanceCard(
                        'Sali', 'Traductrice', 'assets/esty.jpg',
                        avatarSize: 40),
                    _buildFreelanceCard(
                        'Oumar', 'Développeur', 'assets/profile_picture.jpg',
                        avatarSize: 40),
                    _buildFreelanceCard(
                        'Léa', 'Community Manager', 'assets/coiffuer2.jpeg',
                        avatarSize: 40),
                  ],
                ),
              ),
              SizedBox(height: SDSpacing.xl),
              // Catégories populaires
              Text(
                'Catégories populaires',
                style: SDTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: SDColors.neutral900,
                ),
              ),
              SizedBox(height: SDSpacing.sm),
              Wrap(
                spacing: SDSpacing.sm,
                runSpacing: SDSpacing.sm,
                children: [
                  _buildCategoryChip('Développement', SDColors.primary600),
                  _buildCategoryChip('Design', SDColors.secondary500),
                  _buildCategoryChip('Rédaction', SDColors.info500),
                  _buildCategoryChip('Photo', SDColors.primary700),
                  _buildCategoryChip('Traduction', SDColors.success500),
                  _buildCategoryChip('Marketing', SDColors.error500),
                ],
              ),
              SizedBox(height: SDSpacing.xxxl),
              // Avis clients (carousel)
              Text(
                'Avis clients',
                style: SDTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: SDColors.neutral900,
                ),
              ),
              SizedBox(height: SDSpacing.sm),
              SizedBox(
                height: 170,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildReviewCard('"Super travail, rapide et efficace !"',
                        'Awa', 'assets/profile_picture.jpg'),
                    _buildReviewCard('"Très créatif, je recommande !"', 'Jean',
                        'assets/esty.jpg'),
                    _buildReviewCard('"Professionnelle et à l\'écoute."',
                        'Fatou', 'assets/coiffuer2.jpeg'),
                  ],
                ),
              ),
              SizedBox(height: SDSpacing.xxxl),
              // Statistiques animées
              Text(
                'Statistiques de la communauté',
                style: SDTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: SDColors.neutral900,
                ),
              ),
              SizedBox(height: SDSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                      'Freelances', '1 200+', Icons.people, SDColors.primary600),
                  _buildStatCard(
                      'Clients', '3 500+', Icons.emoji_people, SDColors.secondary500),
                  _buildStatCard('Projets', '8 000+', Icons.work, SDColors.info500),
                ],
              ),
              SizedBox(height: SDSpacing.xxxl),
              // Call-to-action secondaire
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SDColors.secondary500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                    ),
                    padding: EdgeInsets.symmetric(
                        horizontal: SDSpacing.xl, vertical: SDSpacing.sm),
                    elevation: 3,
                  ),
                  onPressed: () {},
                  icon: Icon(Icons.add_business, color: SDColors.white),
                  label: Text(
                    'Publier une mission',
                    style: SDTypography.labelLarge.copyWith(
                      color: SDColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: SDSpacing.xxxl),
              // Pourquoi choisir un freelance ?
              Text(
                'Pourquoi choisir un freelance ?',
                style: SDTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: SDColors.neutral900,
                ),
              ),
              SizedBox(height: SDSpacing.sm),
              _buildWhyFreelance(),
              SizedBox(height: SDSpacing.xxxl),
              // Bannière promotionnelle
              _buildPromoBanner(),
              SizedBox(height: SDSpacing.lg),
              // Bouton d'action
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SDColors.primary600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                    ),
                    padding: EdgeInsets.symmetric(
                        horizontal: SDSpacing.xl, vertical: SDSpacing.sm),
                    elevation: 4,
                  ),
                  onPressed: () {},
                  icon: Icon(Icons.people, color: SDColors.white),
                  label: Text(
                    'Voir tous les freelances',
                    style: SDTypography.labelLarge.copyWith(
                      color: SDColors.white,
                      fontWeight: FontWeight.bold,
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

  Widget _buildFreelanceCard(String name, String job, String imagePath,
      {bool isTop = false, double avatarSize = 40}) {
    return Padding(
      padding: EdgeInsets.only(right: SDSpacing.sm),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: SDAnimations.short,
          width: 130,
          decoration: BoxDecoration(
            color: SDColors.white,
            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
            boxShadow: [
              BoxShadow(
                color: SDColors.primary500.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: SDColors.primary500.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: SDSpacing.sm),
              Stack(
                children: [
                  CircleAvatar(
                    radius: avatarSize,
                    backgroundImage: AssetImage(imagePath),
                  ),
                  if (isTop)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: SDSpacing.xxs, vertical: 2),
                        decoration: BoxDecoration(
                          color: SDColors.secondary500,
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                        ),
                        child: Text(
                          'Top',
                          style: SDTypography.labelSmall.copyWith(
                            color: SDColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: SDSpacing.xs),
              Text(
                name,
                style: SDTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                job,
                style: SDTypography.bodySmall.copyWith(
                  color: SDColors.neutral500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: SDSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        gradient: SDGradients.primaryGradient,
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: SDColors.primary500.withOpacity(0.13),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: SDSpacing.lg),
          CircleAvatar(
            radius: 38,
            backgroundImage: AssetImage('assets/profile_picture.jpg'),
          ),
          SizedBox(width: SDSpacing.lg),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aminata - Développeuse',
                  style: SDTypography.titleMedium.copyWith(
                    color: SDColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: SDSpacing.xxs),
                Text(
                  'Spécialiste Flutter & mobile, 5 ans d\'expérience. Disponible pour vos projets !',
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: SDSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildReviewCard(String review, String name, String imagePath) {
    return Container(
      width: 210,
      margin: EdgeInsets.only(right: SDSpacing.sm),
      padding: EdgeInsets.all(SDSpacing.sm),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: SDColors.neutral900.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: AssetImage(imagePath),
          ),
          SizedBox(width: SDSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  review,
                  style: SDTypography.bodySmall.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: SDSpacing.xxs),
                Text(
                  '- ' + name,
                  style: SDTypography.labelSmall.copyWith(
                    color: SDColors.primary600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, Color color) {
    return Chip(
      label: Text(
        label,
        style: SDTypography.labelMedium.copyWith(
            color: SDColors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color,
      padding: EdgeInsets.symmetric(horizontal: SDSpacing.sm, vertical: SDSpacing.xxs),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
      elevation: 2,
      shadowColor: color.withOpacity(0.2),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return AnimatedContainer(
      duration: SDAnimations.long,
      curve: Curves.easeInOut,
      width: 100,
      height: 90,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: SDSpacing.xs),
          Text(
            value,
            style: SDTypography.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: SDTypography.bodySmall.copyWith(
              color: SDColors.neutral700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyFreelance() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SDSpacing.lg),
      decoration: BoxDecoration(
        color: SDColors.info100,
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('✔️ Flexibilité et réactivité',
              style: SDTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: SDSpacing.xs),
          Text('✔️ Tarifs compétitifs',
              style: SDTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: SDSpacing.xs),
          Text('✔️ Accès à des talents variés',
              style: SDTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: SDSpacing.xs),
          Text('✔️ Collaboration directe et rapide',
              style: SDTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: SDSpacing.lg, horizontal: SDSpacing.lg),
      decoration: BoxDecoration(
        gradient: SDGradients.primaryGradient,
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: SDColors.primary500.withOpacity(0.13),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: SDColors.white, size: 36),
          SizedBox(width: SDSpacing.lg),
          Expanded(
            child: Text(
              "Rejoignez la communauté et boostez votre activité dès aujourd'hui !",
              style: SDTypography.labelLarge.copyWith(
                color: SDColors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(SDSpacing.borderRadiusLarge)),
      ),
      isScrollControlled: true,
      builder: (context) {
        String selectedCategory = 'Tous';
        String selectedLocation = 'Abidjan';
        double minRating = 3;
        bool availableNow = false;
        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              left: SDSpacing.lg,
              right: SDSpacing.lg,
              top: SDSpacing.lg,
              bottom: MediaQuery.of(context).viewInsets.bottom + SDSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(bottom: SDSpacing.lg),
                    decoration: BoxDecoration(
                      color: SDColors.neutral300,
                      borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                    ),
                  ),
                ),
                Text('Filtrer les freelances',
                    style: SDTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold)),
                SizedBox(height: SDSpacing.lg),
                // Métier/catégorie
                Text('Catégorie',
                    style: SDTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
                SizedBox(height: SDSpacing.xs),
                DropdownButton<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  items: <String>[
                    'Tous',
                    'Développement',
                    'Design',
                    'Rédaction',
                    'Photo',
                    'Traduction',
                    'Marketing'
                  ]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedCategory = v!),
                ),
                SizedBox(height: SDSpacing.md),
                // Localisation
                Text('Localisation',
                    style: SDTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
                SizedBox(height: SDSpacing.xs),
                DropdownButton<String>(
                  value: selectedLocation,
                  isExpanded: true,
                  items: <String>[
                    'Abidjan',
                    'Bouaké',
                    'Yamoussoukro',
                    'San Pedro',
                    'Autre'
                  ]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedLocation = v!),
                ),
                SizedBox(height: SDSpacing.md),
                // Note minimale
                Text('Note minimale',
                    style: SDTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
                SizedBox(height: SDSpacing.xs),
                Slider(
                  value: minRating,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: minRating.toStringAsFixed(1),
                  activeColor: SDColors.primary600,
                  onChanged: (v) => setModalState(() => minRating = v),
                ),
                SizedBox(height: SDSpacing.md),
                // Disponibilité
                Row(
                  children: [
                    Checkbox(
                      value: availableNow,
                      activeColor: SDColors.primary600,
                      onChanged: (v) => setModalState(() => availableNow = v!),
                    ),
                    Text('Disponible maintenant', style: SDTypography.bodyMedium),
                  ],
                ),
                SizedBox(height: SDSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SDColors.primary600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                      ),
                      padding: EdgeInsets.symmetric(vertical: SDSpacing.sm),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      // Ici tu peux appliquer les filtres à ta recherche
                    },
                    child: Text('Appliquer les filtres',
                        style: SDTypography.labelLarge.copyWith(
                            color: SDColors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
