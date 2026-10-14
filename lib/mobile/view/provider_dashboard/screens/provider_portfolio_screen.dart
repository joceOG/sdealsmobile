import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../design_system/design_system.dart';
import '../../common/widgets/app_image.dart';
import '../models/provider_portfolio.dart';
import 'provider_portfolio_detail_screen.dart';

/// Galerie « Mes réalisations » — espace prestataire (données API réelles).
class ProviderPortfolioScreen extends StatefulWidget {
  const ProviderPortfolioScreen({
    super.key,
    required this.prestataireId,
    this.capabilities = ProviderPortfolioCapabilities.readOnlyPrestataire,
  });

  final String prestataireId;
  final ProviderPortfolioCapabilities capabilities;

  @override
  State<ProviderPortfolioScreen> createState() =>
      _ProviderPortfolioScreenState();
}

class _ProviderPortfolioScreenState extends State<ProviderPortfolioScreen> {
  final ApiClient _api = ApiClient();

  bool _loading = true;
  String? _error;
  ProviderPortfolioData? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthCubit>().state;
      final token =
          auth is AuthAuthenticated && auth.token.isNotEmpty ? auth.token : null;
      final response = await _api.get(
        '/prestataire/${widget.prestataireId}',
        token: token,
      );
      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode}');
      }
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        throw Exception('Réponse invalide');
      }
      final parsed = parseProviderPortfolioFromPrestataireJson(
        body,
        capabilities: widget.capabilities,
      );
      if (!mounted) return;
      setState(() {
        _data = parsed;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger vos réalisations.';
        _loading = false;
      });
    }
  }

  void _openEntry(ProviderPortfolioEntry entry) {
    final list = _data?.entries ?? const [];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderPortfolioDetailScreen(
          entry: entry,
          allEntries: list,
        ),
      ),
    );
  }

  void _onAdd() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'L’ajout de réalisations sera disponible lorsque le serveur '
          'enregistrera le portfolio prestataire.',
        ),
      ),
    );
  }

  void _onEntryMenu(ProviderPortfolioEntry entry) {
    if (!widget.capabilities.canEdit && !widget.capabilities.canDelete) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.capabilities.canEdit)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Modifier'),
                onTap: () => Navigator.pop(ctx),
              ),
            if (widget.capabilities.canDelete)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: SDColors.error500),
                title: const Text('Supprimer'),
                onTap: () => Navigator.pop(ctx),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: SDWhiteAppBar.appBar(title: 'Mes réalisations'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral600),
          ),
          const SizedBox(height: 16),
          Center(
            child: SDButton(text: 'Réessayer', onPressed: _load),
          ),
        ],
      );
    }

    final data = _data!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Présentez votre travail en images.',
          style: SDTypography.bodyMedium.copyWith(
            color: SDColors.neutral600,
          ),
        ),
        if (widget.capabilities.canAdd) ...[
          const SizedBox(height: 16),
          SDButton(
            text: 'Ajouter une réalisation',
            fullWidth: true,
            icon: Icons.add,
            onPressed: _onAdd,
          ),
        ],
        const SizedBox(height: 20),
        if (data.isEmpty) ...[
          _emptyState(),
        ] else ...[
          Text(
            '${data.entries.length} réalisation${data.entries.length > 1 ? 's' : ''}',
            style: SDTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: SDColors.neutral900,
            ),
          ),
          const SizedBox(height: 12),
          _grid(data),
        ],
        const SizedBox(height: 20),
        _tipBanner(),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        color: SDColors.neutral50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Column(
        children: [
          const Icon(Icons.photo_library_outlined,
              size: 48, color: SDColors.neutral400),
          const SizedBox(height: 12),
          Text(
            'Aucune réalisation pour le moment',
            textAlign: TextAlign.center,
            style: SDTypography.bodyMedium.copyWith(
              color: SDColors.neutral600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(ProviderPortfolioData data) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: data.entries.length,
      itemBuilder: (context, index) {
        final entry = data.entries[index];
        return ProviderPortfolioEntryCard(
          entry: entry,
          photosOnly: data.photosOnly,
          showMenu: widget.capabilities.canMutate,
          onTap: () => _openEntry(entry),
          onMenu: () => _onEntryMenu(entry),
        );
      },
    );
  }

  Widget _tipBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SDColors.primary50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.image_outlined, color: SDColors.primary700, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Choisissez des photos nettes de vos travaux.',
              style: SDTypography.bodySmall.copyWith(
                color: SDColors.primary800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProviderPortfolioEntryCard extends StatelessWidget {
  const ProviderPortfolioEntryCard({
    required this.entry,
    required this.photosOnly,
    required this.showMenu,
    required this.onTap,
    required this.onMenu,
  });

  final ProviderPortfolioEntry entry;
  final bool photosOnly;
  final bool showMenu;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final url = entry.primaryImageUrl;
    final showTitle = entry.hasDisplayTitle;
    final showCount =
        !photosOnly && entry.photoCount > 1;

    return Material(
      color: SDColors.white,
      elevation: 1,
      shadowColor: SDColors.neutral900.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: url != null
                    ? AppImage(
                        imageUrl: url,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: SDColors.neutral100,
                        child: const Icon(Icons.broken_image_outlined,
                            color: SDColors.neutral400),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 6, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showTitle)
                          Text(
                            entry.title!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: SDTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: SDColors.neutral900,
                            ),
                          ),
                        if (showCount)
                          Text(
                            '${entry.photoCount} photos',
                            style: SDTypography.bodySmall.copyWith(
                              color: SDColors.neutral500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (showMenu)
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: onMenu,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
