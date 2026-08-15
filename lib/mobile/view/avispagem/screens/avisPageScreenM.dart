import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sdealsmobile/data/models/avis.dart';

import '../../../../design_system/design_system.dart';
import '../avispageblocm/avisPageBlocM.dart';
import '../avispageblocm/avisPageEventM.dart';
import '../avispageblocm/avisPageStateM.dart';
import 'avisDetailScreenM.dart';

/// Mes Avis — style Airbnb / Figma (titre à gauche comme les autres écrans).
class AvisPageScreenM extends StatefulWidget {
  const AvisPageScreenM({super.key});

  @override
  State<AvisPageScreenM> createState() => _AvisPageScreenMState();
}

class _AvisPageScreenMState extends State<AvisPageScreenM> {
  static const double _hPad = 20;

  /// 0 = Donnés, 1 = Reçus (UI Figma ; data reçus si API absente → vide).
  int _tab = 0;
  bool _searchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    context.read<AvisPageBlocM>().add(LoadAvisDataM());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Avis> _filterDonnes(List<Avis> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((a) {
      final hay = [
        a.titre ?? '',
        a.commentaire ?? '',
        a.objetType,
        a.auteur.fullName,
        a.localisation?.ville ?? '',
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.neutral50,
      body: SafeArea(
        child: BlocConsumer<AvisPageBlocM, AvisPageStateM>(
          listener: (context, state) {
            if (state.hasError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error ?? 'Erreur inconnue'),
                  backgroundColor: SDColors.error500,
                ),
              );
            }
          },
          builder: (context, state) {
            final donnes = _filterDonnes(state.avis ?? []);
            // Pas d’endpoint « reçus » dédié pour l’instant → liste vide.
            final recus = <Avis>[];
            final list = _tab == 0 ? donnes : recus;
            final donnesCount = (state.avis ?? []).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(context),
                _buildHeader(),
                if (_searchOpen) _buildSearchField(),
                _buildTabs(
                  donnesCount: donnesCount,
                  recusCount: recus.length,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: state.isLoading && state.avis == null
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          color: SDColors.primary600,
                          onRefresh: () async {
                            context
                                .read<AvisPageBlocM>()
                                .add(RefreshAvisM());
                          },
                          child: list.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.sizeOf(context).height *
                                              0.4,
                                      child: _buildEmptyState(),
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                      _hPad, 8, _hPad, 24),
                                  itemCount: list.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, i) =>
                                      _buildAvisCard(list[i]),
                                ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Écran poussé depuis Profil → retour + recherche (pas icône décorative).
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back, color: SDColors.neutral900),
            tooltip: 'Retour',
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) {
                  _searchController.clear();
                  _query = '';
                }
              });
            },
            icon: Icon(
              _searchOpen ? Icons.close : Icons.search,
              color: SDColors.neutral900,
            ),
            tooltip: _searchOpen ? 'Fermer la recherche' : 'Rechercher',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, 4, _hPad, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mes Avis & Évaluations',
            style: SDTypography.displayMedium.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Partagez votre expérience',
            style: SDTypography.bodyMedium.copyWith(
              color: SDColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 4),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (v) => setState(() => _query = v),
        style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral900),
        decoration: InputDecoration(
          hintText: 'Rechercher un avis…',
          hintStyle: SDTypography.bodyMedium.copyWith(
            color: SDColors.neutral500,
          ),
          prefixIcon: const Icon(Icons.search, color: SDColors.neutral500),
          filled: true,
          fillColor: SDColors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTabs({required int donnesCount, required int recusCount}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, 12, _hPad, 4),
      child: Row(
        children: [
          Expanded(
            child: _segment(
              label: 'Donnés ($donnesCount)',
              selected: _tab == 0,
              onTap: () => setState(() => _tab = 0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _segment(
              label: 'Reçus ($recusCount)',
              selected: _tab == 1,
              onTap: () => setState(() => _tab = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? SDColors.primary600 : SDColors.neutral100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: SDTypography.labelLarge.copyWith(
            color: selected ? SDColors.white : SDColors.neutral900,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAvisCard(Avis avis) {
    final title = (avis.titre != null && avis.titre!.isNotEmpty)
        ? avis.titre!
        : _fallbackTitle(avis);
    final subtitle = _subtitleFor(avis);
    final dateLabel = DateFormat('d MMM yyyy', 'fr_FR').format(avis.createdAt);

    return Material(
      color: SDColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _navigateToDetail(avis),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: SDColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SDColors.neutral200),
            boxShadow: [
              BoxShadow(
                color: SDColors.neutral900.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLeading(avis),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SDTypography.titleMedium.copyWith(
                              color: SDColors.neutral900,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SDTypography.bodyMedium.copyWith(
                              color: SDColors.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: SDColors.neutral500,
                      ),
                      onSelected: (value) {
                        if (value == 'detail') {
                          _navigateToDetail(avis);
                        } else if (value == 'delete') {
                          _showDeleteDialog(avis);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'detail',
                          child: Text('Voir le détail'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Supprimer'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ...List.generate(5, (i) {
                      return Icon(
                        i < avis.note
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 18,
                        color: SDColors.warning500,
                      );
                    }),
                    const SizedBox(width: 6),
                    Text(
                      avis.note.toStringAsFixed(1),
                      style: SDTypography.labelMedium.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (avis.commentaire != null &&
                    avis.commentaire!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    avis.commentaire!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: SDTypography.bodyMedium.copyWith(
                      color: SDColors.neutral900,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  dateLabel,
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(Avis avis) {
    final photo = avis.auteur.photoProfil;
    final media = avis.medias?.isNotEmpty == true ? avis.medias!.first.url : null;
    final isProduct = avis.objetType == 'ARTICLE' || avis.objetType == 'VENDEUR';

    if (isProduct && media != null && media.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Image.network(
            media,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _avatarFallback(avis),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: SDColors.neutral200,
      backgroundImage:
          photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
      child: photo == null || photo.isEmpty
          ? Text(
              avis.auteur.nom.isNotEmpty
                  ? avis.auteur.nom[0].toUpperCase()
                  : '?',
              style: SDTypography.titleMedium.copyWith(
                color: SDColors.neutral700,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }

  Widget _avatarFallback(Avis avis) {
    return ColoredBox(
      color: SDColors.neutral100,
      child: Center(
        child: Text(
          avis.auteur.nom.isNotEmpty ? avis.auteur.nom[0].toUpperCase() : '?',
          style: SDTypography.titleMedium.copyWith(
            color: SDColors.neutral600,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _fallbackTitle(Avis avis) {
    switch (avis.objetType) {
      case 'FREELANCE':
        return 'Prestation freelance';
      case 'ARTICLE':
        return 'Article marketplace';
      case 'VENDEUR':
        return 'Vendeur';
      default:
        return 'Service';
    }
  }

  String _subtitleFor(Avis avis) {
    final ville = avis.localisation?.ville;
    if (ville != null && ville.isNotEmpty) return ville;
    switch (avis.objetType) {
      case 'FREELANCE':
        return 'Freelance';
      case 'ARTICLE':
      case 'VENDEUR':
        return 'Vente & Achat';
      default:
        return 'Métiers';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: SDColors.neutral400,
            ),
            const SizedBox(height: 16),
            Text(
              _tab == 0 ? 'Aucun avis donné' : 'Aucun avis reçu',
              style: SDTypography.titleMedium.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _tab == 0
                  ? 'Vos avis sur les prestataires et produits apparaîtront ici.'
                  : 'Les avis reçus sur vos annonces apparaîtront ici.',
              style: SDTypography.bodyMedium.copyWith(
                color: SDColors.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(Avis avis) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => AvisPageBlocM(),
          child: AvisDetailScreenM(avis: avis),
        ),
      ),
    );
  }

  void _showDeleteDialog(Avis avis) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'avis'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cet avis ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AvisPageBlocM>().add(DeleteAvisM(avisId: avis.id));
            },
            child: Text(
              'Supprimer',
              style: SDTypography.labelLarge.copyWith(color: SDColors.error500),
            ),
          ),
        ],
      ),
    );
  }
}
