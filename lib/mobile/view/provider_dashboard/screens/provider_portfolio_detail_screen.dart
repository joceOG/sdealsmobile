import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../common/widgets/app_image.dart';
import '../models/provider_portfolio.dart';

/// Détail / galerie d’une réalisation prestataire (sans dépendance freelance).
class ProviderPortfolioDetailScreen extends StatefulWidget {
  const ProviderPortfolioDetailScreen({
    super.key,
    required this.entry,
    this.allEntries = const [],
  });

  final ProviderPortfolioEntry entry;
  final List<ProviderPortfolioEntry> allEntries;

  @override
  State<ProviderPortfolioDetailScreen> createState() =>
      _ProviderPortfolioDetailScreenState();
}

class _ProviderPortfolioDetailScreenState
    extends State<ProviderPortfolioDetailScreen> {
  late final PageController _pageController;
  int _index = 0;

  List<String> get _images => widget.entry.imageUrls;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.entry.hasDisplayTitle
        ? widget.entry.title!.trim()
        : null;
    final description = widget.entry.description?.trim();

    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: SDWhiteAppBar.appBar(
        title: title ?? 'Réalisation',
      ),
      body: Column(
        children: [
          Expanded(
            child: _images.isEmpty
                ? const Center(child: Text('Aucune image'))
                : PageView.builder(
                    controller: _pageController,
                    itemCount: _images.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (_, i) => InteractiveViewer(
                      child: Center(
                        child: AppImage(
                          imageUrl: _images[i],
                          fit: BoxFit.contain,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),
          ),
          if (_images.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${_index + 1} / ${_images.length}',
                style: SDTypography.bodySmall.copyWith(
                  color: SDColors.neutral600,
                ),
              ),
            ),
          if (description != null && description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Text(
                description,
                style: SDTypography.bodyMedium.copyWith(
                  color: SDColors.neutral700,
                  height: 1.45,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
