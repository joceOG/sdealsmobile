import 'package:flutter/material.dart';
import 'package:sdealsmobile/design_system/colors.dart';
import 'package:sdealsmobile/design_system/typography.dart';
import 'package:sdealsmobile/design_system/spacing.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/screens/searchPageScreenM.dart';

class JobAppBar extends StatelessWidget {
  final int providerCount;

  const JobAppBar({
    Key? key,
    required this.providerCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(SDSpacing.lg),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(SDSpacing.xl),
        border: Border.all(color: SDColors.primary100, width: 1),
        boxShadow: [
          BoxShadow(
            color: SDColors.neutral900.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '👋 Bonjour !',
            style: SDTypography.titleMedium.copyWith(
              color: SDColors.primary600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: SDSpacing.xs),
          Text(
            'De quoi avez-vous besoin ?',
            style: SDTypography.displayMedium.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: SDSpacing.lg),
          // Search Bar
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SearchPageScreenM()),
              );
            },
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: SDColors.neutral50,
                borderRadius: BorderRadius.circular(SDSpacing.md),
                border: Border.all(color: SDColors.neutral200),
              ),
              child: Row(
                children: [
                  SizedBox(width: SDSpacing.md),
                  Icon(Icons.search, color: SDColors.primary600),
                  SizedBox(width: SDSpacing.sm),
                  Expanded(
                    child: Text(
                      'Rechercher un service, prestataire...',
                      style: SDTypography.bodyMedium.copyWith(
                        color: SDColors.neutral400,
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(SDSpacing.xs),
                    padding: EdgeInsets.all(SDSpacing.xs),
                    decoration: BoxDecoration(
                      color: SDColors.primary600,
                      borderRadius: BorderRadius.circular(SDSpacing.sm),
                    ),
                    child: Icon(Icons.tune, color: SDColors.white, size: 20),
                  ),
                  SizedBox(width: SDSpacing.xs),
                ],
              ),
            ),
          ),
          SizedBox(height: SDSpacing.md),
          // Stats rapides
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  icon: Icons.person,
                  label: '$providerCount prestataires',
                  color: SDColors.primary600,
                  context: context,
                ),
              ),
              SizedBox(width: SDSpacing.xs),
              Expanded(
                child: _buildStatChip(
                  icon: Icons.location_on,
                  label: 'À proximité',
                  color: SDColors.primary600,
                  context: context,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
    required BuildContext context,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: SDSpacing.sm, vertical: SDSpacing.sm),
      decoration: BoxDecoration(
        color: SDColors.primary50,
        borderRadius: BorderRadius.circular(SDSpacing.sm),
        border: Border.all(color: SDColors.primary100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: SDTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
