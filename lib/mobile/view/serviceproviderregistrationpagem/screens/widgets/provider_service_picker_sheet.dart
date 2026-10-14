import 'package:flutter/material.dart';

import 'package:sdealsmobile/data/models/service.dart';
import 'package:sdealsmobile/design_system/design_system.dart';

/// Sélecteur de service Métiers (panneau bas) — filtré par catégorie, taxonomie API.
class ProviderServicePickerSheet extends StatefulWidget {
  const ProviderServicePickerSheet({
    super.key,
    required this.categoryId,
    required this.categoryLabel,
    required this.initialSelectedId,
    required this.loadServices,
    this.seedServices = const [],
  });

  final String categoryId;
  final String categoryLabel;
  final String? initialSelectedId;
  final Future<List<Service>> Function() loadServices;
  final List<Service> seedServices;

  static Future<String?> show(
    BuildContext context, {
    required String categoryId,
    required String categoryLabel,
    required String? initialSelectedId,
    required Future<List<Service>> Function() loadServices,
    List<Service> seedServices = const [],
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) => ProviderServicePickerSheet(
        categoryId: categoryId,
        categoryLabel: categoryLabel,
        initialSelectedId: initialSelectedId,
        loadServices: loadServices,
        seedServices: seedServices,
      ),
    );
  }

  @override
  State<ProviderServicePickerSheet> createState() =>
      _ProviderServicePickerSheetState();
}

class _ProviderServicePickerSheetState extends State<ProviderServicePickerSheet> {
  static const double _hPad = 24;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<Service> _services = [];
  bool _loading = false;
  String? _error;
  String? _pendingId;

  @override
  void initState() {
    super.initState();
    _pendingId = _validPending(widget.initialSelectedId, widget.seedServices);
    if (widget.seedServices.isNotEmpty) {
      _services = List<Service>.from(widget.seedServices);
    } else {
      _fetch();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? _validPending(String? id, List<Service> list) {
    if (id == null || id.isEmpty) return null;
    if (list.any((s) => s.idservice == id)) return id;
    return null;
  }

  List<Service> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _services;
    return _services
        .where((s) => s.nomservice.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.loadServices();
      if (!mounted) return;
      setState(() {
        _services = list;
        _loading = false;
        _pendingId = _validPending(_pendingId, list) ??
            _validPending(widget.initialSelectedId, list);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les services.';
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
                              'Choisir un service',
                              style: SDTypography.displaySmall.copyWith(
                                color: SDColors.neutral900,
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Catégorie',
                              style: SDTypography.bodyMedium.copyWith(
                                color: SDColors.neutral600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.categoryLabel.isNotEmpty
                                  ? widget.categoryLabel
                                  : '—',
                              style: SDTypography.bodyLarge.copyWith(
                                fontSize: 16,
                                color: SDColors.primary700,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 12),
                  child: SDSearchInput(
                    hint: 'Rechercher un service',
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                Flexible(child: _buildBody()),
                Padding(
                  padding: EdgeInsets.fromLTRB(_hPad, 8, _hPad, 12 + bottom),
                  child: SDButton(
                    text: 'Confirmer le service',
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
    if (_services.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: 32),
        child: Center(
          child: Text(
            'Aucun service disponible pour cette catégorie.',
            textAlign: TextAlign.center,
            style: SDTypography.bodyLarge.copyWith(
              color: SDColors.neutral600,
            ),
          ),
        ),
      );
    }

    final visible = _filtered;
    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: 32),
        child: Center(
          child: Text(
            'Aucun service ne correspond à votre recherche.',
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
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: visible.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 1,
        color: SDColors.neutral100,
        indent: _hPad,
        endIndent: _hPad,
      ),
      itemBuilder: (context, index) {
        final service = visible[index];
        final selected = _pendingId == service.idservice;
        return Material(
          color: selected ? SDColors.primary50 : SDColors.white,
          child: InkWell(
            onTap: () => setState(() => _pendingId = service.idservice),
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
                        service.nomservice,
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
                    _ServiceRadioDot(selected: selected),
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

class _ServiceRadioDot extends StatelessWidget {
  const _ServiceRadioDot({required this.selected});

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
