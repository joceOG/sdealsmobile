import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/errors/api_exception.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/services/protected_action_intent.dart';
import 'package:sdealsmobile/mobile/data/models/conversation_model.dart';
import 'package:sdealsmobile/data/utils/conversation_id.dart';
import 'package:sdealsmobile/mobile/view/chatpagem/screens/chatPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/chatpagem/chatpageblocm/chatPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/common/auth_completion.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/app_image.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/models/freelance_model.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/screens/freelance_details_screen.dart';
import 'package:sdealsmobile/design_system/design_system.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Écran « Détail d'une offre freelance »
// ─────────────────────────────────────────────────────────────────────────────

/// Affiche le détail d'une offre (FreelanceService) :
/// exemples de réalisations, prix forfaitaire, livrables,
/// modalités et CTA « Contacter pour cette offre ».
class FreelanceServiceOfferDetailScreen extends StatefulWidget {
  final String offerId;

  const FreelanceServiceOfferDetailScreen({
    super.key,
    required this.offerId,
  });

  @override
  State<FreelanceServiceOfferDetailScreen> createState() =>
      _FreelanceServiceOfferDetailScreenState();
}

class _FreelanceServiceOfferDetailScreenState
    extends State<FreelanceServiceOfferDetailScreen> {
  final ApiClient _api = ApiClient();
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchFreelanceServiceById(widget.offerId);
  }

  // ── Helpers d'extraction ──────────────────────────────────────────────────

  String _title(Map<String, dynamic> o) {
    final override = o['titleOverride']?.toString().trim() ?? '';
    if (override.isNotEmpty) return override;
    final svc = o['service'];
    if (svc is Map) {
      final n = svc['nomservice']?.toString().trim() ?? '';
      if (n.isNotEmpty) return n;
    }
    return 'Offre freelance';
  }

  /// Fil d'Ariane : [catégorie, service]
  List<String> _breadcrumb(Map<String, dynamic> o) {
    final parts = <String>[];
    final svc = o['service'];
    if (svc is Map) {
      final cat = svc['categorie'];
      if (cat is Map) {
        final cn = cat['nomcategorie']?.toString().trim() ?? '';
        if (cn.isNotEmpty) parts.add(cn);
      }
      final sn = svc['nomservice']?.toString().trim() ?? '';
      if (sn.isNotEmpty) parts.add(sn);
    }
    return parts;
  }

  String? _cover(Map<String, dynamic> o) {
    final c = o['coverImage']?.toString().trim() ?? '';
    return c.startsWith('http') ? c : null;
  }

  List<String> _images(Map<String, dynamic> o) {
    final imgs = o['images'];
    if (imgs is List) {
      final urls =
          imgs.map((e) => e.toString()).where((u) => u.startsWith('http')).toList();
      if (urls.isNotEmpty) return urls;
    }
    final c = _cover(o);
    return c != null ? [c] : const [];
  }

  double? _price(Map<String, dynamic> o) {
    final p = o['startingPrice'];
    if (p is num) return p.toDouble();
    return double.tryParse('$p');
  }

  String _formatPrice(double p) {
    final s = p.toInt().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u00a0');
      buf.write(s[i]);
    }
    return '${buf.toString()}\u00a0FCFA';
  }

  String? _delivery(Map<String, dynamic> o) {
    final d = o['deliveryTime']?.toString().trim() ?? '';
    return d.isNotEmpty ? d : null;
  }

  int? _revisions(Map<String, dynamic> o) {
    final r = o['revisionsCount'];
    if (r is int) return r;
    if (r is num) return r.toInt();
    return int.tryParse('$r');
  }

  String? _description(Map<String, dynamic> o) {
    for (final k in ['descriptionCourte', 'description', 'about']) {
      final v = o[k]?.toString().trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return null;
  }

  List<String> _deliverables(Map<String, dynamic> o) {
    for (final k in ['livrables', 'inclus', 'deliverables', 'includes']) {
      final raw = o[k];
      if (raw is List && raw.isNotEmpty) {
        return raw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
      }
    }
    return const [];
  }

  List<Map<String, String>> _requirements(Map<String, dynamic> o) {
    for (final k in ['requirements', 'avantDeCommencer', 'beforeStart']) {
      final raw = o[k];
      if (raw is List && raw.isNotEmpty) {
        return raw.map<Map<String, String>>((e) {
          if (e is Map) {
            return {
              'title': e['title']?.toString() ?? e['label']?.toString() ?? '',
              'description': e['description']?.toString() ?? e['desc']?.toString() ?? '',
            };
          }
          return {'title': e.toString(), 'description': ''};
        }).toList();
      }
    }
    return const [];
  }

  String? _footer(Map<String, dynamic> o, String freelanceName) {
    final f = o['footerNote']?.toString().trim() ?? '';
    if (f.isNotEmpty) return f;
    if (freelanceName.isNotEmpty) {
      final firstName = freelanceName.split(' ').first;
      return 'Confirmez le périmètre et les modalités avec $firstName.';
    }
    return null;
  }

  // ── Freelance helpers ─────────────────────────────────────────────────────

  Map<String, dynamic>? _freelanceMap(Map<String, dynamic> o) {
    final f = o['freelance'];
    return f is Map ? Map<String, dynamic>.from(f) : null;
  }

  String _freelanceName(Map<String, dynamic>? f) {
    if (f == null) return '';
    final u = f['utilisateur'];
    if (u is Map) {
      final p = u['prenom']?.toString().trim() ?? '';
      final n = u['nom']?.toString().trim() ?? '';
      final joined = [p, n].where((s) => s.isNotEmpty).join(' ');
      if (joined.isNotEmpty) return joined;
    }
    return f['name']?.toString().trim() ?? '';
  }

  String? _freelancePhoto(Map<String, dynamic>? f) {
    if (f == null) return null;
    final u = f['utilisateur'];
    if (u is Map) {
      final p = u['photoProfil']?.toString().trim() ?? '';
      if (p.isNotEmpty) return p;
    }
    final ip = f['imagePath']?.toString().trim() ?? '';
    return ip.isNotEmpty ? ip : null;
  }

  String? _freelanceJob(Map<String, dynamic>? f) {
    if (f == null) return null;
    final j = f['job']?.toString().trim() ?? '';
    return j.isNotEmpty ? j : null;
  }

  String? _freelanceId(Map<String, dynamic>? f) =>
      f?['_id']?.toString() ?? f?['id']?.toString();

  String? _freelanceUserId(Map<String, dynamic>? f) {
    if (f == null) return null;
    final u = f['utilisateur'];
    if (u is Map) return u['_id']?.toString();
    return f['utilisateurId']?.toString() ?? _freelanceId(f);
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _openFreelanceProfile(String freelanceId) async {
    try {
      final raw = await _api.getFreelanceById(freelanceId);
      if (!mounted) return;
      final model =
          FreelanceModel.fromBackend(Map<String, dynamic>.from(raw));
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FreelanceDetailsScreen(freelance: model),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userFacing(e))),
      );
    }
  }

  Future<void> _contact(
    BuildContext context,
    String destId,
    String name,
    String? photoUrl,
  ) async {
    final ready = await ensureAuthenticatedForAction(
      context: context,
      type: ProtectedActionType.startConversation,
      originRoute: 'offreDetail',
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
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => ChatPageBlocM(userId: currentId),
          child: ChatPageScreenM(
            conversationId: convId,
            participantId: destId,
            participantName: name,
            participantImage: photoUrl ?? '',
            type: ConversationType.freelance,
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (ctx, snap) {
          // ── Chargement ──────────────────────────────────────────────────
          if (snap.connectionState == ConnectionState.waiting) {
            return const SafeArea(
              child: Center(child: CircularProgressIndicator()),
            );
          }
          // ── Erreur ──────────────────────────────────────────────────────
          if (snap.hasError || !snap.hasData) {
            return SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: SDColors.error500),
                      const SizedBox(height: 16),
                      Text(
                        "Impossible de charger l\u2019offre.",
                        textAlign: TextAlign.center,
                        style: SDTypography.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      SDButton(
                        text: 'Réessayer',
                        onPressed: () => setState(() {
                          _future =
                              _api.fetchFreelanceServiceById(widget.offerId);
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // ── Données disponibles ──────────────────────────────────────────
          final offer = snap.data!;
          final title = _title(offer);
          final crumbs = _breadcrumb(offer);
          final images = _images(offer);
          final priceNum = _price(offer);
          final delivery = _delivery(offer);
          final revisions = _revisions(offer);
          final desc = _description(offer);
          final deliverables = _deliverables(offer);
          final requirements = _requirements(offer);
          final freelance = _freelanceMap(offer);
          final flName = _freelanceName(freelance);
          final flPhoto = _freelancePhoto(freelance);
          final flJob = _freelanceJob(freelance);
          final flId = _freelanceId(freelance);
          final flUserId = _freelanceUserId(freelance) ?? flId;
          final footerNote = _footer(offer, flName);
          final sysBottom = SDResponsive.systemBottomInset(ctx);
          final firstName = flName.split(' ').first;

          return Column(
            children: [
              // ── AppBar ─────────────────────────────────────────────────
              SafeArea(
                bottom: false,
                child: _OfferAppBar(
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
              // ── Corps scrollable ───────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fil d'Ariane
                            if (crumbs.isNotEmpty) ...[
                              Text(
                                crumbs.join(' · '),
                                style: SDTypography.caption.copyWith(
                                  color: SDColors.primary600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                            // Titre
                            Text(
                              title,
                              style: SDTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.w900,
                                color: SDColors.neutral900,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      // Image principale
                      if (images.isNotEmpty)
                        _OfferGallery(images: images),
                      const SizedBox(height: 16),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Mini-carte freelance
                            if (flName.isNotEmpty)
                              _FreelanceMiniCard(
                                name: flName,
                                job: flJob,
                                photoUrl: flPhoto,
                                onProfile: flId == null
                                    ? null
                                    : () => _openFreelanceProfile(flId),
                              ),
                            const SizedBox(height: 16),
                            // Boîte prix
                            if (priceNum != null && priceNum > 0)
                              _PriceBox(
                                price: _formatPrice(priceNum),
                                delivery: delivery,
                                revisions: revisions,
                              ),
                            const SizedBox(height: 20),
                            // Ce que vous recevez
                            if (deliverables.isNotEmpty) ...[
                              _SectionHeader('Ce que vous recevez'),
                              const SizedBox(height: 10),
                              _DeliverablesBox(items: deliverables),
                              const SizedBox(height: 20),
                            ],
                            // À propos de l'offre
                            if (desc != null && desc.isNotEmpty) ...[
                              _SectionHeader("À propos de l\u2019offre"),
                              const SizedBox(height: 8),
                              Text(
                                desc,
                                style: SDTypography.bodyMedium.copyWith(
                                  color: SDColors.neutral700,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            // Avant de commencer
                            if (requirements.isNotEmpty) ...[
                              _SectionHeader('Avant de commencer'),
                              const SizedBox(height: 10),
                              _RequirementsBox(items: requirements),
                              const SizedBox(height: 20),
                            ],
                            // Note de pied
                            if (footerNote != null) ...[
                              Text(
                                footerNote,
                                style: SDTypography.bodySmall.copyWith(
                                  color: SDColors.neutral500,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            // Lien question
                            GestureDetector(
                              onTap: flUserId == null
                                  ? null
                                  : () => _contact(
                                        ctx,
                                        flUserId,
                                        flName,
                                        flPhoto,
                                      ),
                              child: Text(
                                'Une question sur cette offre ?',
                                style: SDTypography.bodySmall.copyWith(
                                  color: SDColors.primary600,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: SDColors.primary600,
                                ),
                              ),
                            ),
                            SizedBox(height: sysBottom + 80),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ── CTA fixe ──────────────────────────────────────────────
              _ContactCta(
                freelanceName: firstName,
                onContact: flUserId == null
                    ? null
                    : () => _contact(ctx, flUserId, flName, flPhoto),
                systemBottomInset: sysBottom,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets locaux
// ─────────────────────────────────────────────────────────────────────────────

class _OfferAppBar extends StatelessWidget {
  final VoidCallback onBack;
  const _OfferAppBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SDColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: SDColors.neutral900,
          ),
          Expanded(
            child: Text(
              'Offre freelance',
              style: SDTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: SDColors.neutral900,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined),
            color: SDColors.neutral700,
          ),
        ],
      ),
    );
  }
}

/// Galerie d'images de l'offre avec bouton ↗ et légende.
class _OfferGallery extends StatefulWidget {
  final List<String> images;
  const _OfferGallery({required this.images});

  @override
  State<_OfferGallery> createState() => _OfferGalleryState();
}

class _OfferGalleryState extends State<_OfferGallery> {
  int _page = 0;
  late final PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.images.length;

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: total,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => AppImage(
              imageUrl: widget.images[i],
              fit: BoxFit.cover,
            ),
          ),
          // Bouton plein écran
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => _FullscreenGallery(
                    images: widget.images,
                    initialPage: _page,
                  ),
                ),
              ),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: SDColors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.open_in_full_rounded,
                    size: 18, color: SDColors.neutral800),
              ),
            ),
          ),
          // Légende bas-gauche
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xCC000000), Colors.transparent],
                ),
              ),
              child: Text(
                'Exemples de réalisations',
                style: SDTypography.labelSmall.copyWith(
                  color: SDColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Compteur si plusieurs images
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
                  '${_page + 1} / $total',
                  style: SDTypography.labelSmall.copyWith(
                    color: SDColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Mini-carte du freelance.
class _FreelanceMiniCard extends StatelessWidget {
  final String name;
  final String? job;
  final String? photoUrl;
  final VoidCallback? onProfile;

  const _FreelanceMiniCard({
    required this.name,
    this.job,
    this.photoUrl,
    this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 52,
            height: 52,
            child: (photoUrl != null && photoUrl!.isNotEmpty)
                ? AppImage(
                    imageUrl: photoUrl!,
                    fit: BoxFit.cover,
                    width: 52,
                    height: 52,
                  )
                : Container(
                    color: SDColors.primary100,
                    alignment: Alignment.center,
                    child: Text(
                      name.isNotEmpty
                          ? name.characters.first.toUpperCase()
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: SDTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: SDColors.neutral900,
                ),
              ),
              if (job != null && job!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  job!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SDTypography.bodySmall
                      .copyWith(color: SDColors.neutral500),
                ),
              ],
            ],
          ),
        ),
        if (onProfile != null)
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

/// Boîte verte de prix avec méta-infos (livraison + retouches).
class _PriceBox extends StatelessWidget {
  final String price;
  final String? delivery;
  final int? revisions;

  const _PriceBox({required this.price, this.delivery, this.revisions});

  @override
  Widget build(BuildContext context) {
    final hasMeta = (delivery != null) || (revisions != null);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SDColors.primary50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SDColors.primary100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            price,
            style: SDTypography.displaySmall.copyWith(
              color: SDColors.primary700,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Forfait pour cette offre',
            style:
                SDTypography.bodySmall.copyWith(color: SDColors.primary600),
          ),
          if (hasMeta) ...[
            const SizedBox(height: 12),
            const Divider(color: SDColors.primary100, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                if (delivery != null)
                  Expanded(
                    child: _MetaRow(
                      icon: Icons.schedule_outlined,
                      label:
                          'Livraison estimée :',
                      value: delivery!,
                    ),
                  ),
                if (delivery != null && revisions != null)
                  const SizedBox(width: 16),
                if (revisions != null)
                  Expanded(
                    child: _MetaRow(
                      icon: Icons.edit_outlined,
                      label: '$revisions ${revisions == 1 ? 'série de retouches incluse' : 'séries de retouches incluses'}',
                      value: '',
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetaRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: SDColors.primary600),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: SDTypography.bodySmall.copyWith(
                color: SDColors.neutral700,
              ),
              children: [
                TextSpan(text: label),
                if (value.isNotEmpty)
                  TextSpan(
                    text: '\n$value',
                    style: SDTypography.labelSmall.copyWith(
                      color: SDColors.neutral900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

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

/// Liste de livrables avec coches vertes.
class _DeliverablesBox extends StatelessWidget {
  final List<String> items;
  const _DeliverablesBox({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SDColors.neutral100),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final last = e.key == items.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: last
                  ? null
                  : const Border(
                      bottom:
                          BorderSide(color: SDColors.neutral100)),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: SDColors.primary600,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      size: 14, color: SDColors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.value,
                    style: SDTypography.bodyMedium
                        .copyWith(color: SDColors.neutral800),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Liste des prérequis « Avant de commencer ».
class _RequirementsBox extends StatelessWidget {
  final List<Map<String, String>> items;
  const _RequirementsBox({required this.items});

  static IconData _icon(String title) {
    final n = title.toLowerCase();
    if (n.contains('brief') || n.contains('nom') || n.contains('marque'))
      return Icons.description_outlined;
    if (n.contains('délai') || n.contains('livraison') || n.contains('date'))
      return Icons.schedule_outlined;
    if (n.contains('budget') || n.contains('prix') || n.contains('paiement'))
      return Icons.payments_outlined;
    if (n.contains('photo') || n.contains('image') || n.contains('visuel'))
      return Icons.photo_outlined;
    return Icons.check_circle_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SDColors.neutral100),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          final last = e.key == items.length - 1;
          final title = item['title'] ?? '';
          final desc = item['description'] ?? '';
          return Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: last
                  ? null
                  : const Border(
                      bottom: BorderSide(color: SDColors.neutral100)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_icon(title),
                    size: 22, color: SDColors.neutral500),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: SDTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: SDColors.neutral900,
                        ),
                      ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          style: SDTypography.bodySmall.copyWith(
                            color: SDColors.neutral500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Bouton CTA bas de page.
class _ContactCta extends StatelessWidget {
  final String freelanceName;
  final VoidCallback? onContact;
  final double systemBottomInset;

  const _ContactCta({
    required this.freelanceName,
    required this.onContact,
    required this.systemBottomInset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + systemBottomInset),
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
        onPressed: onContact,
        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
        label: const Text('Contacter pour cette offre'),
        style: FilledButton.styleFrom(
          backgroundColor: SDColors.primary700,
          disabledBackgroundColor: SDColors.neutral300,
          minimumSize:
              const Size(double.infinity, SDSpacing.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SDSpacing.radiusButton),
          ),
        ),
      ),
    );
  }
}

/// Visionneuse plein écran.
class _FullscreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialPage;
  const _FullscreenGallery(
      {required this.images, this.initialPage = 0});

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
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 8,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              left: 0,
              right: 0,
              child: Text(
                '${_page + 1} / ${widget.images.length}',
                textAlign: TextAlign.center,
                style:
                    SDTypography.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
