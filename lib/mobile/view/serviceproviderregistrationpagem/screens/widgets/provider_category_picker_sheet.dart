import 'package:flutter/material.dart';

import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/design_system/design_system.dart';

/// Sélecteur de catégorie Métiers (panneau bas) — taxonomie API uniquement.
class ProviderCategoryPickerSheet extends StatefulWidget {
  const ProviderCategoryPickerSheet({
    super.key,
    required this.initialSelectedId,
    required this.loadCategories,
    this.seedCategories = const [],
  });

  final String? initialSelectedId;
  final Future<List<Categorie>> Function() loadCategories;
  final List<Categorie> seedCategories;

  static Future<String?> show(
    BuildContext context, {
    required String? initialSelectedId,
    required Future<List<Categorie>> Function() loadCategories,
    List<Categorie> seedCategories = const [],
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) => ProviderCategoryPickerSheet(
        initialSelectedId: initialSelectedId,
        loadCategories: loadCategories,
        seedCategories: seedCategories,
      ),
    );
  }

  @override
  State<ProviderCategoryPickerSheet> createState() =>
      _ProviderCategoryPickerSheetState();
}

class _ProviderCategoryPickerSheetState
    extends State<ProviderCategoryPickerSheet> {
  static const double _hPad = 24;

  List<Categorie> _categories = [];
  bool _loading = false;
  String? _error;
  String? _pendingId;

  @override
  void initState() {
    super.initState();
    _pendingId = _validPending(widget.initialSelectedId, widget.seedCategories);
    if (widget.seedCategories.isNotEmpty) {
      _categories = List<Categorie>.from(widget.seedCategories);
    } else {
      _fetch();
    }
  }

  String? _validPending(String? id, List<Categorie> list) {
    if (id == null || id.isEmpty) return null;
    if (list.any((c) => c.idcategorie == id)) return id;
    return null;
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.loadCategories();
      if (!mounted) return;
      setState(() {
        _categories = list;
        _loading = false;
        _pendingId = _validPending(_pendingId, list) ??
            _validPending(widget.initialSelectedId, list);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les catégories.';
      });
    }
  }

  void _confirm() {
    final id = _pendingId;
    if (id == null || id.isEmpty) return;
    Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxHeight: maxH),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: SDColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SDColors.neutral200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(_hPad, 16, 12, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choisir une catégorie',
                              style: SDTypography.displaySmall.copyWith(
                                color: SDColors.neutral900,
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Métiers',
                              style: SDTypography.bodyMedium.copyWith(
                                color: SDColors.neutral600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fermer',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded,
                            color: SDColors.neutral900),
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(child: _buildBody()),
                Padding(
                  padding: EdgeInsets.fromLTRB(_hPad, 8, _hPad, 12 + bottom),
                  child: SDButton(
                    text: 'Confirmer la catégorie',
                    fullWidth: true,
                    onPressed:
                        _pendingId != null && !_loading ? _confirm : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(color: SDColors.primary600),
        ),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: SDTypography.bodyLarge.copyWith(
                color: SDColors.neutral600,
              ),
            ),
            const SizedBox(height: 16),
            SDButton(
              text: 'Réessayer',
              type: SDButtonType.outlined,
              onPressed: _fetch,
            ),
          ],
        ),
      );
    }
    if (_categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: 32),
        child: Center(
          child: Text(
            'Aucune catégorie disponible pour le moment.',
            textAlign: TextAlign.center,
            style: SDTypography.bodyLarge.copyWith(
              color: SDColors.neutral600,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _categories.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 1,
        color: SDColors.neutral100,
        indent: _hPad,
        endIndent: _hPad,
      ),
      itemBuilder: (context, index) {
        final cat = _categories[index];
        final selected = _pendingId == cat.idcategorie;
        return Material(
          color: selected ? SDColors.primary50 : SDColors.white,
          child: InkWell(
            onTap: () => setState(() => _pendingId = cat.idcategorie),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _hPad,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        cat.nomcategorie,
                        style: SDTypography.bodyLarge.copyWith(
                          fontSize: 16,
                          color: selected
                              ? SDColors.primary800
                              : SDColors.neutral900,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _RadioDot(selected: selected),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? SDColors.primary600 : SDColors.neutral400,
          width: 2,
        ),
      ),
      child: selected
          ? Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: SDColors.primary600,
              ),
            )
          : null,
    );
  }
}
