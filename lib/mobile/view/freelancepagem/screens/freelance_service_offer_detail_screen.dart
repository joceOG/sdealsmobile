import 'package:flutter/material.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/app_image.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/models/freelance_model.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/screens/freelance_details_screen.dart';

import '../../../../design_system/design_system.dart';

/// Fiche d’une offre [FreelanceService] (catalogue groupe Freelance).
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

  String _displayTitle(Map<String, dynamic> offer) {
    final override = offer['titleOverride']?.toString().trim() ?? '';
    if (override.isNotEmpty) return override;
    final svc = offer['service'];
    if (svc is Map && svc['nomservice'] != null) {
      return svc['nomservice'].toString();
    }
    return 'Service';
  }

  String? _categoryLabel(Map<String, dynamic> offer) {
    final svc = offer['service'];
    if (svc is! Map) return null;
    final cat = svc['categorie'];
    if (cat is Map && cat['nomcategorie'] != null) {
      return cat['nomcategorie'].toString();
    }
    return null;
  }

  String _freelanceDisplayName(Map<String, dynamic>? freelance) {
    if (freelance == null) return 'Freelance';
    final u = freelance['utilisateur'];
    if (u is Map) {
      final p = u['prenom']?.toString().trim() ?? '';
      final n = u['nom']?.toString().trim() ?? '';
      final joined = [p, n].where((s) => s.isNotEmpty).join(' ');
      if (joined.isNotEmpty) return joined;
    }
    final name = freelance['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Freelance';
  }

  String? _freelanceAvatar(Map<String, dynamic>? freelance) {
    if (freelance == null) return null;
    final u = freelance['utilisateur'];
    if (u is Map && u['photoProfil'] != null) {
      final s = u['photoProfil'].toString();
      if (s.isNotEmpty) return s;
    }
    final ip = freelance['imagePath']?.toString();
    if (ip != null && ip.isNotEmpty) return ip;
    return null;
  }

  String? _freelanceId(Map<String, dynamic>? freelance) {
    if (freelance == null) return null;
    final id = freelance['_id'];
    if (id == null) return null;
    return id.toString();
  }

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
        SnackBar(content: Text('Impossible d’ouvrir le profil : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.neutral50,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(SDSpacing.md),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: SDColors.error500),
                    SizedBox(height: SDSpacing.sm),
                    Text(
                      'Impossible de charger l’offre.',
                      textAlign: TextAlign.center,
                      style: SDTypography.bodyLarge,
                    ),
                    SizedBox(height: SDSpacing.md),
                    SDButton(
                      text: 'Réessayer',
                      onPressed: () {
                        setState(() {
                          _future = _api.fetchFreelanceServiceById(widget.offerId);
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          final offer = snap.data!;
          final title = _displayTitle(offer);
          final cover = offer['coverImage']?.toString() ?? '';
          final price = offer['startingPrice'];
          final priceNum = price is num ? price.toDouble() : double.tryParse('$price');
          final delivery = offer['deliveryTime']?.toString() ?? '';
          final desc = offer['descriptionCourte']?.toString().trim() ?? '';
          final rating = offer['ratingAvg'];
          final ratingNum = rating is num ? rating.toDouble() : double.tryParse('$rating');
          final reviews = offer['reviewsCount'];
          final reviewsNum = reviews is int ? reviews : int.tryParse('$reviews');
          final orders = offer['orderCount'];
          final ordersNum = orders is int ? orders : int.tryParse('$orders');
          final category = _categoryLabel(offer);
          final freelance = offer['freelance'] is Map
              ? Map<String, dynamic>.from(offer['freelance'] as Map)
              : null;
          final freelanceId = _freelanceId(freelance);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: SDColors.primary600,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: SDColors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SDTypography.titleSmall.copyWith(
                      color: SDColors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: SDColors.neutral900.withOpacity(0.45),
                        ),
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (cover.startsWith('http'))
                        AppImage(
                          imageUrl: cover,
                          height: double.infinity,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(color: SDColors.primary400),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              SDColors.neutral900.withOpacity(0.65),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(SDSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (category != null) ...[
                        Text(
                          category,
                          style: SDTypography.labelMedium.copyWith(
                            color: SDColors.primary600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: SDSpacing.xs),
                      ],
                      if (priceNum != null && priceNum > 0)
                        Text(
                          'À partir de ${priceNum.toStringAsFixed(0)} FCFA',
                          style: SDTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        Text(
                          'Sur devis',
                          style: SDTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (delivery.isNotEmpty) ...[
                        SizedBox(height: SDSpacing.xs),
                        Row(
                          children: [
                            Icon(Icons.schedule,
                                size: 18, color: SDColors.neutral600),
                            SizedBox(width: SDSpacing.xs),
                            Expanded(
                              child: Text(
                                'Délai : $delivery',
                                style: SDTypography.bodyMedium.copyWith(
                                  color: SDColors.neutral700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (ratingNum != null && ratingNum > 0) ...[
                        SizedBox(height: SDSpacing.sm),
                        Row(
                          children: [
                            Icon(Icons.star_rounded,
                                color: Colors.amber.shade700, size: 22),
                            SizedBox(width: SDSpacing.xs),
                            Text(
                              ratingNum.toStringAsFixed(1),
                              style: SDTypography.titleSmall,
                            ),
                            if (reviewsNum != null && reviewsNum > 0)
                              Text(
                                ' ($reviewsNum avis)',
                                style: SDTypography.bodyMedium.copyWith(
                                  color: SDColors.neutral600,
                                ),
                              ),
                            if (ordersNum != null && ordersNum > 0) ...[
                              SizedBox(width: SDSpacing.sm),
                              Text(
                                '• $ordersNum commandes',
                                style: SDTypography.bodySmall.copyWith(
                                  color: SDColors.neutral600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      if (desc.isNotEmpty) ...[
                        SizedBox(height: SDSpacing.md),
                        Text(
                          'À propos',
                          style: SDTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: SDSpacing.xs),
                        Text(desc, style: SDTypography.bodyMedium),
                      ],
                      SizedBox(height: SDSpacing.lg),
                      Text(
                        'Prestataire',
                        style: SDTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: SDSpacing.sm),
                      Material(
                        color: SDColors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: freelanceId == null
                              ? null
                              : () => _openFreelanceProfile(freelanceId),
                          child: Padding(
                            padding: EdgeInsets.all(SDSpacing.sm),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: SDColors.neutral100,
                                  child: _freelanceAvatar(freelance) != null
                                      ? ClipOval(
                                          child: AppImage(
                                            imageUrl: _freelanceAvatar(freelance)!,
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Icon(Icons.person,
                                          color: SDColors.neutral500),
                                ),
                                SizedBox(width: SDSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _freelanceDisplayName(freelance),
                                        style: SDTypography.titleSmall.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Voir le profil complet',
                                        style: SDTypography.bodySmall.copyWith(
                                          color: SDColors.primary600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: SDColors.neutral400),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: SDSpacing.xl),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
