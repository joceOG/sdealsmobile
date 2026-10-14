import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/services/protected_action_intent.dart';
import 'package:sdealsmobile/mobile/view/common/auth_completion.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/app_image.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/models/freelance_model.dart';
import 'package:sdealsmobile/mobile/view/chatpagem/screens/chatPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/chatpagem/chatpageblocm/chatPageBlocM.dart';
import 'package:sdealsmobile/mobile/data/models/conversation_model.dart';
import 'package:sdealsmobile/data/utils/conversation_id.dart';
import 'package:sdealsmobile/design_system/design_system.dart';

// ignore_for_file: unused_import

// ─────────────────────────────────────────────────────────────────────────────
// Écran « Détail d'une réalisation »
// ─────────────────────────────────────────────────────────────────────────────

/// Affiche une réalisation du portfolio d'un freelance :
/// galerie agrandissable, description du projet, contributions, tags + CTA.
class PortfolioDetailScreen extends StatefulWidget {
  final PortfolioItem item;
  final FreelanceModel freelance;

  /// Tous les items du portfolio (pour naviguer entre eux si désiré).
  final List<PortfolioItem> allItems;

  const PortfolioDetailScreen({
    super.key,
    required this.item,
    required this.freelance,
    this.allItems = const [],
  });

  @override
  State<PortfolioDetailScreen> createState() => _PortfolioDetailScreenState();
}

class _PortfolioDetailScreenState extends State<PortfolioDetailScreen> {
  late final PageController _pageCtrl;
  int _currentPage = 0;

  List<String> get _images => widget.item.allImages;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── AppBar ─────────────────────────────────────────────────────
            _AppBar(freelanceName: widget.freelance.name),
            // ── Corps scrollable ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Galerie principale + vignettes
                    _GallerySection(
                      images: _images,
                      pageCtrl: _pageCtrl,
                      currentPage: _currentPage,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                    ),
                    const SizedBox(height: 20),
                    // Contenu textuel
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre
                          if (widget.item.title.isNotEmpty) ...[
                            Text(
                              widget.item.title,
                              style: SDTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                color: SDColors.neutral900,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          // Chip catégorie
                          if (widget.item.category.isNotEmpty) ...[
                            _CategoryChip(label: widget.item.category),
                            const SizedBox(height: 16),
                          ],
                          // Carte freelance
                          _FreelancerMiniCard(
                            freelance: widget.freelance,
                            onProfile: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(height: 20),
                          // Le projet
                          if (widget.item.description.isNotEmpty) ...[
                            _Section(
                              title: 'Le projet',
                              child: Text(
                                widget.item.description,
                                style: SDTypography.bodyMedium
                                    .copyWith(color: SDColors.neutral700),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          // Ma contribution
                          if (widget.item.contributions.isNotEmpty) ...[
                            _Section(
                              title: 'Ma contribution',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: widget.item.contributions
                                    .map((c) => _ContributionRow(label: c))
                                    .toList(),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          // Tags
                          if (widget.item.tags.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.item.tags
                                  .map((t) => _TagChip(label: t))
                                  .toList(),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ],
                      ),
                    ),
                    // Espace pour le bottom nav
                    SizedBox(
                        height: SDResponsive.systemBottomInset(context) + 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // ── CTA ───────────────────────────────────────────────────────────────
      bottomNavigationBar: _ContactCta(freelance: widget.freelance),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppBar
// ─────────────────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final String freelanceName;
  const _AppBar({required this.freelanceName});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SDColors.white,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: SDColors.neutral900,
          ),
          Expanded(
            child: Text(
              'Réalisation',
              style: SDTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: SDColors.neutral900,
              ),
            ),
          ),
          IconButton(
            onPressed: () {}, // partage futur
            icon: const Icon(Icons.share_outlined),
            color: SDColors.neutral700,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Galerie
// ─────────────────────────────────────────────────────────────────────────────

class _GallerySection extends StatelessWidget {
  final List<String> images;
  final PageController pageCtrl;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const _GallerySection({
    required this.images,
    required this.pageCtrl,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    final total = images.length;

    return Column(
      children: [
        // ── Image principale
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // PageView pour swiper entre images
              PageView.builder(
                controller: pageCtrl,
                itemCount: total,
                onPageChanged: onPageChanged,
                itemBuilder: (_, i) => AppImage(
                  imageUrl: images[i],
                  fit: BoxFit.cover,
                ),
              ),
              // Bouton plein écran (haut droit)
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => _openFullscreen(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: SDColors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.open_in_full_rounded,
                      size: 18,
                      color: SDColors.neutral800,
                    ),
                  ),
                ),
              ),
              // Compteur (bas droit)
              if (total > 1)
                Positioned(
                  bottom: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: SDColors.neutral900.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${currentPage + 1}\u00a0/\u00a0$total',
                      style: SDTypography.labelSmall.copyWith(
                        color: SDColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // ── Bande de vignettes
        if (total > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: total,
              itemBuilder: (_, i) {
                final selected = i == currentPage;
                return GestureDetector(
                  onTap: () => pageCtrl.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    width: 90,
                    margin: EdgeInsets.only(right: i < total - 1 ? 8 : 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? SDColors.primary600
                            : SDColors.neutral200,
                        width: selected ? 2.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.5),
                      child: AppImage(
                        imageUrl: images[i],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  void _openFullscreen(BuildContext context) {
    if (images.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FullscreenGallery(
          images: images,
          initialPage: currentPage,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Visionneuse plein écran
// ─────────────────────────────────────────────────────────────────────────────

class _FullscreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialPage;
  const _FullscreenGallery({required this.images, this.initialPage = 0});

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late int _page;
  late final PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage;
    _ctrl = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => InteractiveViewer(
              child: Center(
                child: AppImage(
                  imageUrl: widget.images[i],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // Bouton fermer
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 8,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
          // Compteur
          if (widget.images.length > 1)
            Positioned(
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              left: 0,
              right: 0,
              child: Text(
                '${_page + 1} / ${widget.images.length}',
                textAlign: TextAlign.center,
                style: SDTypography.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets utilitaires
// ─────────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: SDTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: SDColors.neutral900,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip({required this.label});

  static IconData _icon(String l) {
    final n = l.toLowerCase();
    if (n.contains('design') || n.contains('graphi') || n.contains('créa'))
      return Icons.palette_outlined;
    if (n.contains('dev') || n.contains('code') || n.contains('tech'))
      return Icons.code_rounded;
    if (n.contains('market')) return Icons.campaign_outlined;
    if (n.contains('vidéo') || n.contains('video')) return Icons.play_circle_outline_rounded;
    if (n.contains('photo')) return Icons.photo_camera_outlined;
    if (n.contains('audio') || n.contains('son')) return Icons.music_note_outlined;
    if (n.contains('rédac') || n.contains('content')) return Icons.article_outlined;
    if (n.contains('data') || n.contains('analys')) return Icons.analytics_outlined;
    return Icons.work_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: SDColors.primary50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SDColors.primary200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(label), size: 15, color: SDColors.primary600),
          const SizedBox(width: 6),
          Text(
            label,
            style: SDTypography.labelSmall.copyWith(
              color: SDColors.primary700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: SDColors.neutral50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Text(
        label,
        style: SDTypography.labelSmall.copyWith(
          color: SDColors.neutral700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Ligne de contribution avec icône contextuelle.
class _ContributionRow extends StatelessWidget {
  final String label;
  const _ContributionRow({required this.label});

  static IconData _icon(String l) {
    final n = l.toLowerCase();
    if (n.contains('logo') || n.contains('design') || n.contains('concept'))
      return Icons.edit_outlined;
    if (n.contains('couleur') || n.contains('palette') || n.contains('typo'))
      return Icons.palette_outlined;
    if (n.contains('déclin') || n.contains('support') || n.contains('marque'))
      return Icons.layers_outlined;
    if (n.contains('photo') || n.contains('image')) return Icons.photo_camera_outlined;
    if (n.contains('vidéo') || n.contains('video') || n.contains('montage'))
      return Icons.play_circle_outline_rounded;
    if (n.contains('code') || n.contains('dev') || n.contains('intégr'))
      return Icons.code_rounded;
    if (n.contains('text') || n.contains('rédac') || n.contains('copyw'))
      return Icons.article_outlined;
    if (n.contains('stratég') || n.contains('analys'))
      return Icons.analytics_outlined;
    return Icons.check_circle_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: SDColors.primary50,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child:
                Icon(_icon(label), size: 18, color: SDColors.primary600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                label,
                style: SDTypography.bodyMedium
                    .copyWith(color: SDColors.neutral800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini-carte du freelance (photo + nom + métier + lien profil).
class _FreelancerMiniCard extends StatelessWidget {
  final FreelanceModel freelance;
  final VoidCallback? onProfile;
  const _FreelancerMiniCard({required this.freelance, this.onProfile});

  @override
  Widget build(BuildContext context) {
    final jobLabel = freelance.job.isNotEmpty ? freelance.job : null;
    final skillLabel =
        freelance.skills.isNotEmpty ? freelance.skills.first : null;
    final subtitle = [jobLabel, skillLabel]
        .whereType<String>()
        .take(2)
        .join(' · ');

    final photoUrl = freelance.imagePath.startsWith('http')
        ? freelance.imagePath
        : '';

    return Row(
      children: [
        // Avatar
        ClipOval(
          child: SizedBox(
            width: 52,
            height: 52,
            child: photoUrl.isNotEmpty
                ? AppImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    width: 52,
                    height: 52,
                  )
                : Container(
                    color: SDColors.primary100,
                    alignment: Alignment.center,
                    child: Text(
                      freelance.name.isNotEmpty
                          ? freelance.name.characters.first.toUpperCase()
                          : '?',
                      style: SDTypography.titleSmall.copyWith(
                        color: SDColors.primary700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        // Nom + sous-titre
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                freelance.name,
                style: SDTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: SDColors.neutral900,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SDTypography.bodySmall
                      .copyWith(color: SDColors.neutral500),
                ),
              ],
            ],
          ),
        ),
        // Lien "Voir le profil"
        GestureDetector(
          onTap: onProfile,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Voir le profil',
                style: SDTypography.labelSmall.copyWith(
                  color: SDColors.primary600,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: SDColors.primary600),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bouton CTA bas de page
// ─────────────────────────────────────────────────────────────────────────────

class _ContactCta extends StatelessWidget {
  final FreelanceModel freelance;
  const _ContactCta({required this.freelance});

  @override
  Widget build(BuildContext context) {
    final sysBottom = SDResponsive.systemBottomInset(context);
    final firstName = freelance.name.split(' ').first;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + sysBottom),
      decoration: BoxDecoration(
        color: SDColors.white,
        border: const Border(top: BorderSide(color: SDColors.neutral100)),
        boxShadow: [
          BoxShadow(
            color: SDColors.neutral900.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: () => _contact(context),
        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
        label: Text('Contacter $firstName'),
        style: FilledButton.styleFrom(
          backgroundColor: SDColors.primary700,
          minimumSize: const Size(double.infinity, SDSpacing.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SDSpacing.radiusButton),
          ),
        ),
      ),
    );
  }

  Future<void> _contact(BuildContext context) async {
    final destId = freelance.utilisateurId ?? freelance.id;
    final ready = await ensureAuthenticatedForAction(
      context: context,
      type: ProtectedActionType.startConversation,
      originRoute: 'portfolioDetail',
      technicalId: destId,
      explanation: 'Connectez-vous pour contacter ce freelance',
    );
    if (!ready || !context.mounted) return;
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return;

    final currentId = auth.utilisateur.idutilisateur;
    if (destId == currentId) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vous ne pouvez pas vous envoyer un message.')),
      );
      return;
    }

    final convId = buildConversationId(currentId, destId);
    final photoUrl = freelance.imagePath.startsWith('http')
        ? freelance.imagePath
        : '';

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => ChatPageBlocM(userId: currentId),
          child: ChatPageScreenM(
            conversationId: convId,
            participantId: destId,
            participantName: freelance.name,
            participantImage: photoUrl,
            type: ConversationType.freelance,
          ),
        ),
      ),
    );
  }
}
