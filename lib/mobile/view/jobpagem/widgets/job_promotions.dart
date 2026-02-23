import 'package:flutter/material.dart';
import 'package:sdealsmobile/design_system/colors.dart';
import 'package:sdealsmobile/design_system/typography.dart';
import 'package:sdealsmobile/design_system/widgets/sd_card.dart';
import 'package:sdealsmobile/design_system/spacing.dart';

class JobPromotions extends StatelessWidget {
  const JobPromotions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Données simulées
    final List<Map<String, dynamic>> activePromotions = [
      {
        'title': '🎉 Première commande',
        'discount': '20%',
        'description': 'Économisez sur votre premier service',
        'code': 'FIRST20',
        'expiry': '31 Dec 2024',
        'color': SDColors.error500,
        'services': ['Ménage', 'Plomberie', 'Électricité']
      },
      {
        'title': '⚡ Service Express',
        'discount': '15%',
        'description': 'Réduction sur interventions urgentes',
        'code': 'EXPRESS15',
        'expiry': '15 Jan 2025',
        'color': SDColors.warning500,
        'services': ['Urgence', 'Dépannage']
      },
      {
        'title': '🏠 Pack Maison',
        'discount': '25%',
        'description': 'Combiné ménage + jardinage',
        'code': 'PACK25',
        'expiry': '28 Feb 2025',
        'color': SDColors.success600,
        'services': ['Ménage', 'Jardinage', 'Rénovation']
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.local_offer, color: SDColors.error500, size: 22),
                  SizedBox(width: SDSpacing.xs),
                  Flexible(
                    child: Text(
                      '🎁 Promotions du moment',
                      style: SDTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: SDColors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigation
              },
              child: Text(
                'Voir toutes',
                style: SDTypography.titleSmall.copyWith(
                  color: SDColors.primary600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: SDSpacing.md),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: activePromotions.length,
            itemBuilder: (context, index) {
              final promo = activePromotions[index];
              return Container(
                width: 280,
                margin: EdgeInsets.only(right: SDSpacing.md),
                child: SDCard(
                  padding: EdgeInsets.zero, // Custom gradient content
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(SDSpacing.md),
                      gradient: LinearGradient(
                        colors: [
                          (promo['color'] as Color).withOpacity(0.1),
                          (promo['color'] as Color).withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: EdgeInsets.all(SDSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                promo['title'],
                                style: SDTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: SDColors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: SDSpacing.sm),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: SDSpacing.sm,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: promo['color'],
                                borderRadius: BorderRadius.circular(SDSpacing.md),
                              ),
                              child: Text(
                                promo['discount'],
                                style: SDTypography.labelMedium.copyWith(
                                  color: SDColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          promo['description'],
                          style: SDTypography.bodySmall.copyWith(
                            color: SDColors.neutral500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.code, size: 14, color: promo['color']),
                            SizedBox(width: 4),
                            Text(
                              promo['code'],
                              style: SDTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: promo['color'],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Expire le ${promo['expiry']}',
                                style: SDTypography.labelSmall.copyWith(
                                  fontSize: 9,
                                  color: SDColors.neutral500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 6),
                            Flexible(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Code ${promo['code']} copié !'),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: SDColors.success600,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: promo['color'],
                                  foregroundColor: SDColors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  minimumSize: const Size(0, 24),
                                ),
                                child: Text(
                                  'Utiliser',
                                  style: TextStyle(fontSize: 9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
