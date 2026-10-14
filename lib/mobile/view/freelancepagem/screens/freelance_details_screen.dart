import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/services/protected_action_intent.dart';
import 'package:sdealsmobile/mobile/view/common/auth_completion.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/app_image.dart';
import '../models/freelance_model.dart';
import '../../chatpagem/screens/chatPageScreenM.dart';
import '../../chatpagem/chatpageblocm/chatPageBlocM.dart';
import '../../../data/models/conversation_model.dart';
import '../../../../data/utils/conversation_id.dart';
import '../../../../design_system/design_system.dart';
import '../../historypagem/consultation_recorder.dart';
import 'portfolio_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fiche profil freelance  — Présentation · Réalisations · Avis
// ─────────────────────────────────────────────────────────────────────────────

class FreelanceDetailsScreen extends StatefulWidget {
  final FreelanceModel freelance;
  const FreelanceDetailsScreen({super.key, required this.freelance});

  @override
  State<FreelanceDetailsScreen> createState() => _FreelanceDetailsScreenState();
}

class _FreelanceDetailsScreenState extends State<FreelanceDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordVisit());
  }

  void _recordVisit() {
    if (!mounted) return;
    AuthCubit authCubit;
    try {
      authCubit = context.read<AuthCubit>();
    } catch (_) {
      return;
    }
    final auth = authCubit.state;
    if (auth is! AuthAuthenticated) return;
    ConsultationRecorder.recordProfileVisit(
      objetType: 'FREELANCE',
      objetId: f.id,
      titre: f.name,
      image: f.imagePath,
      categorie: f.job,
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  FreelanceModel get f => widget.freelance;

  void _openVerificationSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VerificationSheet(name: f.name),
    );
  }

  static String _formatRate(double rate) {
    final s = rate.toInt().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u00a0');
      buf.write(s[i]);
    }
    return '${buf.toString()}\u00a0FCFA\u00a0/ heure';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      body: NestedScrollView(
        headerSliverBuilder: _header,
        body: TabBarView(
          controller: _tab,
          physics: const ClampingScrollPhysics(),
          children: [
            _PresentationTab(
              freelance: f,
              onViewAllPortfolio: () => _tab.animateTo(1),
            ),
            _RealisationsTab(freelance: f),
            _AvisTab(freelance: f),
          ],
        ),
      ),
      bottomNavigationBar: _CtaBar(freelance: f),
    );
  }

  List<Widget> _header(BuildContext ctx, bool innerScrolled) {
    final hasRate = f.hourlyRate > 0;
    final hasRating = f.rating > 0;
    final isVerified = f.verificationDocuments?.isVerified ?? false;
    final hasJob = f.job.isNotEmpty && f.job != 'Non renseigné';
    final hasLocation = f.location.isNotEmpty;
    final imgUrl = f.imagePath.startsWith('http') ? f.imagePath : null;

    return [
      // ── SliverAppBar (héro + barre compacte) ─────────────────────────
      SliverAppBar(
        expandedHeight: 190,
        pinned: true,
        backgroundColor: SDColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: innerScrolled ? 1 : 0,
        shadowColor: SDColors.neutral200,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: innerScrolled ? SDColors.neutral900 : Colors.white,
          ),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        // Barre compacte : mini-photo + nom
        title: innerScrolled
            ? Row(children: [
                _MiniAvatar(freelance: f, imgUrl: imgUrl),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    f.name,
                    overflow: TextOverflow.ellipsis,
                    style: SDTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: SDColors.neutral900,
                    ),
                  ),
                ),
              ])
            : null,
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border_rounded,
                color: innerScrolled ? SDColors.neutral700 : Colors.white),
            onPressed: () {},
          ),
          if (!innerScrolled)
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white),
              onPressed: () {},
            ),
        ],
        flexibleSpace: FlexibleSpaceBar(
          collapseMode: CollapseMode.pin,
          background: _HeroBanner(freelance: f),
        ),
      ),

      // ── Identité : nom · job · localisation · stats · tags ────────────
      SliverToBoxAdapter(
        child: Container(
          color: SDColors.white,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom
              Text(
                f.name,
                style: SDTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  color: SDColors.neutral900,
                ),
              ),
              // Job (vert)
              if (hasJob) ...[
                const SizedBox(height: 2),
                Text(
                  f.job,
                  style: SDTypography.bodyMedium.copyWith(
                    color: SDColors.primary600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              // Localisation
              if (hasLocation) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: SDColors.neutral400),
                  const SizedBox(width: 4),
                  Text(
                    f.location,
                    style: SDTypography.bodySmall
                        .copyWith(color: SDColors.neutral600),
                  ),
                ]),
              ],
              const SizedBox(height: 12),
              // Stats : note + vérification
              Row(children: [
                if (hasRating) ...[
                  const Icon(Icons.star_rounded,
                      size: 16, color: Color(0xFFFBBF24)),
                  const SizedBox(width: 4),
                  Text(
                    f.rating.toStringAsFixed(1),
                    style: SDTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SDColors.neutral900,
                    ),
                  ),
                  if (f.completedJobs > 0)
                    Text(
                      '\u00a0·\u00a0${f.completedJobs}\u00a0avis',
                      style: SDTypography.labelSmall
                          .copyWith(color: SDColors.neutral500),
                    ),
                ],
                if (hasRating && isVerified) const SizedBox(width: 14),
                if (isVerified) ...[
                  const Icon(Icons.verified_rounded,
                      size: 16, color: SDColors.primary600),
                  const SizedBox(width: 4),
                  Text(
                    'Identité vérifiée',
                    style: SDTypography.labelSmall.copyWith(
                      color: SDColors.primary700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _openVerificationSheet(ctx),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.info_outline_rounded,
                          size: 14, color: SDColors.neutral400),
                    ),
                  ),
                ],
              ]),
              // Tags (mode de travail + langue)
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (f.workingHours.isNotEmpty)
                    _TagChip(
                      icon: Icons.computer_outlined,
                      label: f.workingHours,
                    ),
                  const _TagChip(
                    icon: Icons.language_outlined,
                    label: 'Français',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      // ── Prix ─────────────────────────────────────────────────────────
      if (hasRate)
        SliverToBoxAdapter(
          child: Container(
            color: SDColors.white,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1, color: SDColors.neutral100),
                const SizedBox(height: 18),
                Text(
                  _formatRate(f.hourlyRate),
                  style: SDTypography.displayMedium.copyWith(
                    color: SDColors.primary600,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tarif indiqué par l\'intervenant·e',
                  style: SDTypography.bodySmall
                      .copyWith(color: SDColors.neutral500),
                ),
              ],
            ),
          ),
        ),

      // ── TabBar (sticky) ───────────────────────────────────────────────
      SliverPersistentHeader(
        pinned: true,
        delegate: _TabBarDelegate(_tab),
      ),
    ];
  }
}

// ── Mini avatar (barre compacte) ──────────────────────────────────────────────

class _MiniAvatar extends StatelessWidget {
  final FreelanceModel freelance;
  final String? imgUrl;
  const _MiniAvatar({required this.freelance, this.imgUrl});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 30,
        height: 30,
        child: imgUrl != null
            ? AppImage(imageUrl: imgUrl!, fit: BoxFit.cover)
            : ColoredBox(
                color: SDColors.primary50,
                child: Center(
                  child: Text(
                    freelance.name.isNotEmpty
                        ? freelance.name[0].toUpperCase()
                        : '?',
                    style: SDTypography.labelSmall.copyWith(
                      color: SDColors.primary700,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

// ── Hero Banner ───────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final FreelanceModel freelance;
  const _HeroBanner({required this.freelance});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Fond botanique
        const _BotanicalBg(),
        // Photo profil (grand cercle, côté gauche)
        Positioned(
          left: 20,
          top: 0,
          bottom: 0,
          child: Center(
            child: _ProfileAvatar(freelance: freelance, size: 92),
          ),
        ),
        // Gradient bas pour transition vers le blanc
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.15),
                ],
                stops: const [0.6, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Fond botanique (CustomPainter) ────────────────────────────────────────────

class _BotanicalBg extends StatelessWidget {
  const _BotanicalBg();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _BotanicalPainter(), child: const SizedBox.expand());
}

class _BotanicalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..color = const Color(0xFF2D6A4F)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bg);

    void circle(double cx, double cy, double r, Color c) {
      canvas.drawCircle(Offset(size.width * cx, size.height * cy),
          size.width * r, Paint()..color = c);
    }

    // Grands cercles clairs
    circle(0.9, -0.05, 0.44, const Color(0xFF52B788).withOpacity(0.42));
    circle(1.05, 0.72, 0.30, const Color(0xFF1B4332).withOpacity(0.55));
    circle(0.55, 1.15, 0.22, const Color(0xFF74C69D).withOpacity(0.30));

    // Feuille (ellipse inclinée)
    canvas.save();
    canvas.translate(size.width * 0.72, size.height * 0.32);
    canvas.rotate(-0.55);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset.zero,
          width: size.width * 0.36,
          height: size.height * 0.26),
      Paint()..color = const Color(0xFF40916C).withOpacity(0.55),
    );
    canvas.restore();

    // Petit cercle haut gauche
    circle(0.18, 0.08, 0.10, const Color(0xFF95D5B2).withOpacity(0.22));
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Photo avatar (grand) ──────────────────────────────────────────────────────

class _ProfileAvatar extends StatelessWidget {
  final FreelanceModel freelance;
  final double size;
  const _ProfileAvatar({required this.freelance, required this.size});

  @override
  Widget build(BuildContext context) {
    final imgUrl =
        freelance.imagePath.startsWith('http') ? freelance.imagePath : null;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        color: SDColors.primary50,
      ),
      clipBehavior: Clip.antiAlias,
      child: imgUrl != null
          ? AppImage(imageUrl: imgUrl, fit: BoxFit.cover)
          : Center(
              child: Text(
                freelance.name.isNotEmpty
                    ? freelance.name.trim()[0].toUpperCase()
                    : '?',
                style: SDTypography.titleLarge.copyWith(
                  color: SDColors.primary700,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
    );
  }
}

// ── Tag chip (À distance, Français…) ─────────────────────────────────────────

class _TagChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TagChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: SDColors.neutral50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: SDColors.neutral600),
        const SizedBox(width: 6),
        Text(
          label,
          style: SDTypography.labelSmall.copyWith(
            color: SDColors.neutral700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ]),
    );
  }
}

// ── TabBar delegate (sticky) ──────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController controller;
  const _TabBarDelegate(this.controller);

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: const BoxDecoration(
        color: SDColors.white,
        border: Border(bottom: BorderSide(color: SDColors.neutral100)),
      ),
      child: TabBar(
        controller: controller,
        labelColor: SDColors.primary600,
        unselectedLabelColor: SDColors.neutral500,
        indicatorColor: SDColors.primary600,
        indicatorWeight: 2.5,
        labelStyle:
            SDTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: SDTypography.labelMedium,
        tabs: const [
          Tab(text: 'Présentation'),
          Tab(text: 'Réalisations'),
          Tab(text: 'Avis'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Présentation
// ─────────────────────────────────────────────────────────────────────────────

class _PresentationTab extends StatelessWidget {
  final FreelanceModel freelance;
  final VoidCallback onViewAllPortfolio;
  const _PresentationTab(
      {required this.freelance, required this.onViewAllPortfolio});

  void _openPortfolioDetail(BuildContext context, PortfolioItem item) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PortfolioDetailScreen(
        item: item,
        freelance: freelance,
        allItems: freelance.portfolioItems,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final hasDesc = freelance.description.isNotEmpty;
    final skills = freelance.skills.where((s) => s.trim().isNotEmpty).toList();
    final portfolio = freelance.portfolioItems
        .where((p) => p.imageUrl.startsWith('http'))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // À propos
        if (hasDesc) ...[
          _SectionTitle('À propos'),
          const SizedBox(height: 10),
          Text(
            freelance.description,
            style: SDTypography.bodyMedium
                .copyWith(color: SDColors.neutral700, height: 1.65),
          ),
          const SizedBox(height: 24),
        ],
        // Services proposés
        if (skills.isNotEmpty) ...[
          _SectionTitle('Services proposés'),
          const SizedBox(height: 10),
          ...skills.take(4).map((s) => _ServiceProposedRow(skill: s)),
          const SizedBox(height: 24),
        ],
        // Réalisations (aperçu 2 photos)
        if (portfolio.isNotEmpty) ...[
          Row(children: [
            Expanded(child: _SectionTitle('Réalisations')),
            GestureDetector(
              onTap: onViewAllPortfolio,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  'Tout voir',
                  style: SDTypography.labelSmall.copyWith(
                    color: SDColors.primary600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded,
                    size: 14, color: SDColors.primary600),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: portfolio.take(2).toList().asMap().entries.map((e) {
              final item = e.value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: e.key > 0 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => _openPortfolioDetail(context, item),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: AppImage(
                                imageUrl: item.imageUrl, fit: BoxFit.cover),
                          ),
                        ),
                        if (item.title.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SDTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: SDColors.neutral800,
                            ),
                          ),
                        ],
                        if (item.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SDTypography.bodySmall
                                .copyWith(color: SDColors.neutral500),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

// ── Ligne service proposé ─────────────────────────────────────────────────────

class _ServiceProposedRow extends StatelessWidget {
  final String skill;
  const _ServiceProposedRow({required this.skill});

  IconData _icon() {
    final s = skill.toLowerCase();
    if (s.contains('logo') || s.contains('graphi') || s.contains('identit'))
      return Icons.draw_outlined;
    if (s.contains('vid') || s.contains('montage'))
      return Icons.play_circle_outline_rounded;
    if (s.contains('photo')) return Icons.photo_camera_outlined;
    if (s.contains('web') || s.contains('site')) return Icons.web_outlined;
    if (s.contains('code') || s.contains('dev')) return Icons.code_rounded;
    if (s.contains('market') || s.contains('communi'))
      return Icons.campaign_outlined;
    if (s.contains('design') || s.contains('ui') || s.contains('ux'))
      return Icons.palette_outlined;
    if (s.contains('réseaux') || s.contains('social'))
      return Icons.phone_iphone_rounded;
    if (s.contains('rédac') || s.contains('texte'))
      return Icons.article_outlined;
    return Icons.work_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SDColors.neutral100),
      ),
      child: Row(children: [
        Icon(_icon(), size: 20, color: SDColors.primary600),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            skill,
            style: SDTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: SDColors.neutral900,
            ),
          ),
        ),
        const Icon(Icons.chevron_right_rounded,
            size: 20, color: SDColors.neutral400),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Réalisations
// ─────────────────────────────────────────────────────────────────────────────

class _RealisationsTab extends StatelessWidget {
  final FreelanceModel freelance;
  const _RealisationsTab({required this.freelance});

  void _openPortfolioDetail(BuildContext context, PortfolioItem item) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PortfolioDetailScreen(
        item: item,
        freelance: freelance,
        allItems: freelance.portfolioItems,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = freelance.portfolioItems
        .where((p) => p.imageUrl.startsWith('http'))
        .toList();
    final skills = freelance.skills.where((s) => s.trim().isNotEmpty).toList();
    final isVerified = freelance.verificationDocuments?.isVerified ?? false;
    final hasRating = freelance.rating > 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // ── Portfolio items
        if (portfolio.isNotEmpty) ...[
          Row(children: [
            Expanded(child: _SectionTitle('Réalisations')),
            GestureDetector(
              onTap: () {},
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  'Tout voir',
                  style: SDTypography.labelSmall.copyWith(
                    color: SDColors.primary600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded,
                    size: 14, color: SDColors.primary600),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          ...portfolio.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: GestureDetector(
                  onTap: () => _openPortfolioDetail(context, item),
                  child: _PortfolioItemCard(item: item),
                ),
              )),
          const SizedBox(height: 4),
        ],

        // ── Conditions de collaboration
        _SectionTitle('Conditions de collaboration'),
        const SizedBox(height: 12),
        _ConditionItem(
          icon: Icons.computer_outlined,
          label: 'Travail à distance',
        ),
        _ConditionItem(
          icon: Icons.description_outlined,
          label: 'Brief et périmètre à définir ensemble',
        ),
        _ConditionItem(
          icon: Icons.schedule_outlined,
          label: 'Délais et budget confirmés avant démarrage',
        ),
        const SizedBox(height: 24),

        // ── Compétences
        if (skills.isNotEmpty) ...[
          _SectionTitle('Compétences'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: SDColors.neutral100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        s,
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.neutral700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
        ],

        // ── Confiance et avis
        _SectionTitle('Confiance et avis'),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vérification
            if (isVerified)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SDColors.primary50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SDColors.primary100),
                  ),
                  child: Row(children: [
                    const Icon(Icons.verified_rounded,
                        size: 16, color: SDColors.primary600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Identité vérifiée',
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.primary700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          _showVerificationSheet(context, freelance.name),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.info_outline_rounded,
                            size: 14, color: SDColors.primary400),
                      ),
                    ),
                  ]),
                ),
              ),
            if (isVerified && hasRating) const SizedBox(width: 10),
            // Note globale
            if (hasRating)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SDColors.neutral50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SDColors.neutral200),
                ),
                child: Column(children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded,
                        size: 18, color: Color(0xFFFBBF24)),
                    const SizedBox(width: 4),
                    Text(
                      '${freelance.rating.toStringAsFixed(1)}\u00a0/\u00a05',
                      style: SDTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: SDColors.neutral900,
                      ),
                    ),
                  ]),
                  if (freelance.completedJobs > 0)
                    Text(
                      '${freelance.completedJobs}\u00a0avis',
                      style: SDTypography.labelSmall
                          .copyWith(color: SDColors.neutral500),
                    ),
                ]),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Placeholder avis
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SDColors.neutral50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Les avis clients apparaîtront ici dès la première mission terminée.',
            style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
          ),
        ),
        const SizedBox(height: 24),

        // ── Signaler ce profil
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SDColors.neutral100),
          ),
          child: ListTile(
            leading: const Icon(Icons.flag_outlined,
                size: 20, color: SDColors.neutral500),
            title: Text(
              'Signaler ce profil',
              style:
                  SDTypography.bodyMedium.copyWith(color: SDColors.neutral700),
            ),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: SDColors.neutral400),
            dense: true,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

// ── Panneau vérification (top-level pour usage cross-widget) ─────────────────

/// Ouvre le panneau « Informations de vérification » depuis n'importe quel widget.
void _showVerificationSheet(BuildContext context, String name) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _VerificationSheet(name: name),
  );
}

/// Bottom sheet : statut vérifié et signification, sans exposer de document KYC.
class _VerificationSheet extends StatelessWidget {
  final String name;
  const _VerificationSheet({required this.name});

  @override
  Widget build(BuildContext context) {
    final sysBottom = SDResponsive.systemBottomInset(context);
    return Container(
      decoration: const BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: SDColors.neutral200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // En-tête
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informations de v\u00e9rification',
                        style: SDTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: SDColors.neutral900,
                        ),
                      ),
                      if (name.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(name,
                            style: SDTypography.bodySmall
                                .copyWith(color: SDColors.neutral500)),
                      ],
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.close_rounded,
                        size: 22, color: SDColors.neutral600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Corps scrollable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carte verte « Identit\u00e9 v\u00e9rifi\u00e9e »
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: SDColors.primary50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SDColors.primary100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: SDColors.primary600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.verified_rounded,
                              size: 24, color: SDColors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Identit\u00e9 v\u00e9rifi\u00e9e',
                                style: SDTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: SDColors.primary800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'La v\u00e9rification d\u2019identit\u00e9 de ce profil est valid\u00e9e.',
                                style: SDTypography.bodySmall.copyWith(
                                  color: SDColors.primary700,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Disclaimer
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 18, color: SDColors.neutral500),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ce statut concerne l\u2019identit\u00e9, pas la qualit\u00e9 des prestations.',
                              style: SDTypography.bodySmall.copyWith(
                                color: SDColors.neutral700,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Les documents personnels restent confidentiels.',
                              style: SDTypography.bodySmall.copyWith(
                                color: SDColors.neutral500,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Bouton « Compris »
          const Divider(height: 1, color: SDColors.neutral100),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + sysBottom),
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: SDColors.primary600,
                minimumSize:
                    const Size(double.infinity, SDSpacing.minTouchTarget),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SDSpacing.radiusButton),
                ),
              ),
              child: const Text('Compris'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carte portfolio (grand format) ────────────────────────────────────────────

class _PortfolioItemCard extends StatelessWidget {
  final PortfolioItem item;
  const _PortfolioItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: AppImage(imageUrl: item.imageUrl, fit: BoxFit.cover),
          ),
        ),
        if (item.title.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            item.title,
            style: SDTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: SDColors.neutral900,
            ),
          ),
        ],
        if (item.description.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            item.description,
            style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
          ),
        ],
      ],
    );
  }
}

// ── Ligne condition de collaboration ─────────────────────────────────────────

class _ConditionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ConditionItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: SDColors.neutral50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: SDColors.neutral100),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: SDColors.neutral600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral700),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Avis
// ─────────────────────────────────────────────────────────────────────────────

class _AvisTab extends StatelessWidget {
  final FreelanceModel freelance;
  const _AvisTab({required this.freelance});

  @override
  Widget build(BuildContext context) {
    final hasRating = freelance.rating > 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        if (hasRating) ...[
          Row(children: [
            const Icon(Icons.star_rounded, size: 22, color: Color(0xFFFBBF24)),
            const SizedBox(width: 6),
            Text(
              '${freelance.rating.toStringAsFixed(1)}\u00a0/\u00a05',
              style: SDTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: SDColors.neutral900,
              ),
            ),
            if (freelance.completedJobs > 0)
              Text(
                '\u00a0·\u00a0${freelance.completedJobs}\u00a0avis',
                style:
                    SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
              ),
          ]),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SDColors.neutral50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            const Icon(Icons.rate_review_outlined,
                size: 40, color: SDColors.neutral300),
            const SizedBox(height: 10),
            Text(
              'Aucun avis pour le moment',
              style: SDTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: SDColors.neutral700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Les avis clients apparaîtront ici dès la première mission terminée.',
              textAlign: TextAlign.center,
              style:
                  SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
            ),
          ]),
        ),
      ],
    );
  }
}

// ── Titre de section ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: SDTypography.titleSmall.copyWith(
        fontWeight: FontWeight.w800,
        color: SDColors.neutral900,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barre CTA — Appeler / Contacter
// ─────────────────────────────────────────────────────────────────────────────

class _CtaBar extends StatelessWidget {
  final FreelanceModel freelance;
  const _CtaBar({required this.freelance});

  @override
  Widget build(BuildContext context) {
    final hasPhone =
        freelance.phoneNumber != null && freelance.phoneNumber!.isNotEmpty;
    final sysBottom = SDResponsive.systemBottomInset(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
          SDSpacing.sm, SDSpacing.xs, SDSpacing.sm, SDSpacing.xs + sysBottom),
      decoration: BoxDecoration(
        color: SDColors.white,
        border: const Border(top: BorderSide(color: SDColors.neutral100)),
        boxShadow: [
          BoxShadow(
            color: SDColors.neutral900.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(children: [
        if (hasPhone) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _call(context),
              icon: const Icon(Icons.phone_outlined, size: 18),
              label: const Text('Appeler'),
              style: OutlinedButton.styleFrom(
                foregroundColor: SDColors.primary700,
                side: const BorderSide(color: SDColors.primary700, width: 1.5),
                minimumSize:
                    const Size(double.infinity, SDSpacing.minTouchTarget),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SDSpacing.radiusButton),
                ),
              ),
            ),
          ),
          const SizedBox(width: SDSpacing.xs),
        ],
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _contact(context),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text('Contacter'),
            style: FilledButton.styleFrom(
              backgroundColor: SDColors.primary700,
              minimumSize:
                  const Size(double.infinity, SDSpacing.minTouchTarget),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SDSpacing.radiusButton),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _call(BuildContext context) async {
    final ready = await ensureAuthenticatedForAction(
      context: context,
      type: ProtectedActionType.callProvider,
      originRoute: 'freelanceDetails',
      technicalId: freelance.id,
      explanation: 'Connectez-vous pour appeler ce freelance',
    );
    if (!ready || !context.mounted) return;
    final result = await DialerSession.openOnce(freelance.phoneNumber);
    if (!context.mounted) return;
    await showDialerFeedback(context, result);
  }

  Future<void> _contact(BuildContext context) async {
    final ready = await ensureAuthenticatedForAction(
      context: context,
      type: ProtectedActionType.startConversation,
      originRoute: 'freelanceDetails',
      technicalId: freelance.utilisateurId,
      explanation: 'Connectez-vous pour contacter ce freelance',
    );
    if (!ready || !context.mounted) return;
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;

    final destId = freelance.utilisateurId;
    if (destId == null || destId.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profil incomplet, contact indisponible.')),
      );
      return;
    }

    final currentId = authState.utilisateur.idutilisateur;
    if (destId == currentId) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vous ne pouvez pas vous envoyer un message.')),
      );
      return;
    }

    final convId = buildConversationId(currentId, destId);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => ChatPageBlocM(userId: currentId),
          child: ChatPageScreenM(
            conversationId: convId,
            participantId: destId,
            participantName: freelance.name,
            participantImage: freelance.imagePath.startsWith('http')
                ? freelance.imagePath
                : '',
            type: ConversationType.freelance,
          ),
        ),
      ),
    );
  }
}
