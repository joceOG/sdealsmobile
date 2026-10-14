import 'package:flutter/material.dart';
import 'package:sdealsmobile/design_system/design_system.dart';

/// Textes des hubs univers. Un seul endroit : modifier ici met à jour
/// Métiers, Freelance et É-marché.
class UniverseHubCopy {
  const UniverseHubCopy({
    required this.title,
    required this.subtitle,
    required this.searchHint,
  });

  final String title;
  final String subtitle;
  final String searchHint;

  static const metiers = UniverseHubCopy(
    title: 'Métiers',
    subtitle: 'Des pros près de chez vous',
    searchHint: 'Quel service recherchez-vous ?',
  );

  static const freelance = UniverseHubCopy(
    title: 'Freelance',
    subtitle: 'Des talents pour vos projets',
    searchHint: 'Quel service recherchez-vous ?',
  );

  static const emarket = UniverseHubCopy(
    title: 'É-marché',
    subtitle: 'Des boutiques près de chez vous',
    searchHint: 'Que recherchez-vous ?',
  );
}

/// Header vert partagé (titre + sous-titre + fermer + recherche + filtre).
class UniverseHubHeader extends StatelessWidget {
  const UniverseHubHeader({
    super.key,
    required this.copy,
    required this.onSearch,
    this.onFilter,
    this.onClose,
    this.actions = const [],
    this.belowSearch,
  });

  final UniverseHubCopy copy;
  final VoidCallback onSearch;
  final VoidCallback? onFilter;
  final VoidCallback? onClose;
  final List<Widget> actions;
  final Widget? belowSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: SDColors.primary50,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6, right: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            copy.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SDTypography.displayMedium.copyWith(
                              color: SDColors.neutral900,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            copy.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: SDTypography.body.copyWith(
                              color: SDColors.neutral700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...actions,
                  SDCircleCloseButton(
                    onPressed:
                        onClose ?? () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: SDColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: SDColors.neutral200),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: onSearch,
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                color: SDColors.neutral600,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  copy.searchHint,
                                  style: SDTypography.bodyMedium.copyWith(
                                    color: SDColors.neutral500,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (onFilter != null) ...[
                    const SizedBox(width: 10),
                    Material(
                      color: SDColors.primary600,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: onFilter,
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.tune_rounded,
                            color: SDColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (belowSearch != null) ...[
                const SizedBox(height: 10),
                belowSearch!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
