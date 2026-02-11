import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/design_system/colors.dart';
import 'package:sdealsmobile/design_system/typography.dart';
import 'package:sdealsmobile/design_system/spacing.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageEventM.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class JobQuickActions extends StatelessWidget {
  final LatLng? userLocation;
  final Function() onShowAroundMe;

  const JobQuickActions({
    Key? key,
    this.userLocation,
    required this.onShowAroundMe,
  }) : super(key: key);

  static const List<Map<String, dynamic>> quickActions = [
    {
      "icon": Icons.flash_on,
      "title": "Urgence",
      "subtitle": "24h/24",
      "color": SDColors.error500, // Red
      "action": "urgent"
    },
    {
      "icon": Icons.star,
      "title": "Top Rated",
      "subtitle": "Les meilleurs",
      "color": SDColors.warning500, // Amber
      "action": "toprated"
    },
    {
      "icon": Icons.location_on,
      "title": "Proche",
      "subtitle": "À proximité",
      "color": SDColors.info500, // Blue
      "action": "nearby"
    },
    {
      "icon": Icons.savings,
      "title": "Promo",
      "subtitle": "Économisez",
      "color": SDColors.success600, // Green dark
      "action": "promo"
    },
    {
      "icon": Icons.smart_toy,
      "title": "IA Conseil",
      "subtitle": "Assistant",
      "color": Color(0xFF9C27B0), // Purple (No consistent token for purple yet, keeping hex or using primary/secondary variant)
      "action": "ai"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Actions rapides',
                style: SDTypography.titleLarge.copyWith(
                  color: SDColors.black,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () {
                // TODO: Navigation vers la page complète des actions rapides
              },
              child: Text(
                'Voir tout',
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
          height: 95,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: quickActions.length,
            itemBuilder: (context, index) {
              final action = quickActions[index];
              return Padding(
                padding: EdgeInsets.only(right: SDSpacing.md),
                child: _buildQuickActionCard(
                  context: context,
                  icon: action['icon'],
                  title: action['title'],
                  subtitle: action['subtitle'],
                  color: action['color'],
                  onTap: () => _handleQuickAction(context, action['action']),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              SDColors.white,
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(SDSpacing.md),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(SDSpacing.sm),
              ),
              child: Icon(
                icon,
                color: color,
                size: 16,
              ),
            ),
            SizedBox(height: 2),
            Text(
              title,
              style: SDTypography.labelSmall.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: SDColors.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 1),
            Text(
              subtitle,
              style: SDTypography.labelSmall.copyWith(
                fontSize: 7,
                color: SDColors.neutral600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _handleQuickAction(BuildContext context, String action) {
    switch (action) {
      case 'urgent':
        if (userLocation != null) {
          context.read<JobPageBlocM>().add(LoadUrgentProvidersM(
            latitude: userLocation!.latitude,
            longitude: userLocation!.longitude,
            radius: 10.0,
          ));
        }
        break;
      case 'toprated':
        if (userLocation != null) {
          context.read<JobPageBlocM>().add(LoadNearbyProvidersM(
            latitude: userLocation!.latitude,
            longitude: userLocation!.longitude,
            radius: 5.0, // Default radius from parent was 5.0
          ));
        }
        break;
      case 'nearby':
        onShowAroundMe();
        break;
      case 'promo':
        // Navigation not yet implemented in original
        print('💰 Affichage promotions');
        break;
      case 'ai':
        // Navigation not yet implemented in original
        print('🤖 Ouverture assistant IA');
        break;
    }
  }
}
