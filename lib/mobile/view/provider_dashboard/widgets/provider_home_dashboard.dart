import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/app_image.dart';

/// Accueil prestataire — layout aligné maquette Figma (mobile: stack vertical).
class ProviderHomeDashboard extends StatelessWidget {
  final String fullName;
  final String? photoUrl;
  final String metier;
  final String location;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final bool isAvailable;
  /// Si true, affiche l’indicateur « local » (legacy). Sinon sync serveur.
  final bool availabilityLocalOnly;
  final ValueChanged<bool> onAvailabilityChanged;

  final int demandesRecues;
  final int commandesEnCours;
  final int enAttente;
  final double revenusMois;
  final bool isLoadingStats;

  final List<int> weeklyActivity;
  final List<Map<String, dynamic>> recentMissions;
  final List<Map<String, dynamic>> recentReviews;
  final double soldeDisponible;
  final double soldeEnAttente;
  final int unreadMessages;

  final VoidCallback onRefresh;
  final VoidCallback onOpenStats;
  final VoidCallback onOpenServices;
  final VoidCallback onOpenMessages;
  final VoidCallback onOpenPayments;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenMissions;
  final VoidCallback onWithdraw;
  final VoidCallback onSwitchToClient;
  final VoidCallback onOpenNotifications;
  final int unreadNotifications;

  const ProviderHomeDashboard({
    super.key,
    required this.fullName,
    this.photoUrl,
    required this.metier,
    required this.location,
    required this.rating,
    required this.reviewCount,
    required this.isVerified,
    required this.isAvailable,
    this.availabilityLocalOnly = false,
    required this.onAvailabilityChanged,
    required this.demandesRecues,
    required this.commandesEnCours,
    required this.enAttente,
    required this.revenusMois,
    required this.isLoadingStats,
    required this.weeklyActivity,
    required this.recentMissions,
    this.recentReviews = const [],
    required this.soldeDisponible,
    required this.soldeEnAttente,
    required this.unreadMessages,
    required this.onRefresh,
    required this.onOpenStats,
    required this.onOpenServices,
    required this.onOpenMessages,
    required this.onOpenPayments,
    required this.onOpenCalendar,
    required this.onOpenMissions,
    required this.onWithdraw,
    required this.onSwitchToClient,
    required this.onOpenNotifications,
    this.unreadNotifications = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: SDColors.white,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => onRefresh(),
          color: SDColors.primary600,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                const SizedBox(height: 16),
                _buildProfileHeader(),
                const SizedBox(height: 20),
                _buildKpiGrid(),
                const SizedBox(height: 24),
                _buildWeeklyActivity(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildRecentRequests(),
                const SizedBox(height: 20),
                _buildRevenueCard(),
                if (recentReviews.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildRecentReviews(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Text(
          'Tableau de bord',
          style: SDTypography.titleMedium.copyWith(
            color: SDColors.neutral900,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        _IconCircle(
          icon: Icons.notifications_none_rounded,
          onTap: onOpenNotifications,
          badge: unreadNotifications,
        ),
        const SizedBox(width: 8),
        _IconCircle(
          icon: Icons.close_rounded,
          onTap: onSwitchToClient,
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            ClipOval(
              child: photoUrl != null && photoUrl!.startsWith('http')
                  ? AppImage(
                      imageUrl: photoUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      color: SDColors.neutral200,
                      child: const Icon(Icons.person_outline_rounded,
                          color: SDColors.neutral900, size: 30),
                    ),
            ),
            if (isVerified)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: SDColors.primary600,
                    shape: BoxShape.circle,
                    border: Border.all(color: SDColors.white, width: 2),
                  ),
                  child: const Icon(Icons.check, color: SDColors.white, size: 12),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      fullName,
                      style: SDTypography.titleMedium.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: SDColors.primary600, size: 18),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                metier,
                style: SDTypography.bodyMedium.copyWith(
                  color: SDColors.primary700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${rating.toStringAsFixed(1)} ($reviewCount avis)',
                    style: SDTypography.bodySmall.copyWith(color: SDColors.neutral600),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.place_outlined,
                      size: 14, color: SDColors.neutral900),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      location,
                      style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: SDColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SDColors.neutral200),
            boxShadow: [
              BoxShadow(
                color: SDColors.neutral900.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                availabilityLocalOnly ? 'Dispo*' : 'Dispo',
                style: SDTypography.labelSmall.copyWith(
                  color: SDColors.neutral600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Switch.adaptive(
                value: isAvailable,
                activeThumbColor: SDColors.white,
                activeTrackColor: SDColors.primary600,
                onChanged: onAvailabilityChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Text(
                isAvailable ? 'Oui' : 'Non',
                style: SDTypography.labelSmall.copyWith(
                  color: isAvailable ? SDColors.primary700 : SDColors.neutral500,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
              if (availabilityLocalOnly)
                Text(
                  'local',
                  style: SDTypography.labelSmall.copyWith(
                    color: SDColors.neutral400,
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiGrid() {
    final revenueFmt = NumberFormat('#,###', 'fr_FR').format(revenusMois.round());
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.inbox_outlined,
                iconColor: SDColors.neutral900,
                iconBg: SDColors.neutral100,
                label: 'Demandes reçues',
                value: isLoadingStats ? '—' : '$demandesRecues',
                subtitle: 'Ce mois',
                subtitleColor: SDColors.neutral600,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                icon: Icons.pending_actions_outlined,
                iconColor: SDColors.neutral900,
                iconBg: SDColors.neutral100,
                label: 'Commandes en cours',
                value: isLoadingStats ? '—' : '$commandesEnCours',
                subtitle: 'En attente : $enAttente',
                subtitleColor: SDColors.neutral600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.payments_outlined,
                iconColor: SDColors.neutral900,
                iconBg: SDColors.neutral100,
                label: 'Revenus du mois',
                value: isLoadingStats ? '—' : '$revenueFmt FCFA',
                subtitle: 'Solde & gains',
                subtitleColor: SDColors.neutral600,
                valueFontSize: 15,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                icon: Icons.star_border_rounded,
                iconColor: SDColors.neutral900,
                iconBg: SDColors.neutral100,
                label: 'Note moyenne',
                value: rating > 0 ? rating.toStringAsFixed(1).replaceAll('.', ',') : '—',
                subtitle: '$reviewCount avis',
                subtitleColor: SDColors.neutral600,
                showStars: true,
                starRating: rating,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyActivity() {
    final days = const ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final values = List<int>.generate(
      7,
      (i) => i < weeklyActivity.length ? weeklyActivity[i] : 0,
    );
    final hasData = values.any((v) => v > 0);
    final maxV = values.fold<int>(1, (a, b) => a > b ? a : b);
    final highlight = hasData
        ? values.indexOf(values.reduce((a, b) => a > b ? a : b))
        : -1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Activité de la semaine',
              style: SDTypography.titleSmall.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onOpenStats,
              child: Text(
                'Voir le détail ›',
                style: SDTypography.labelMedium.copyWith(
                  color: SDColors.primary700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          decoration: BoxDecoration(
            color: SDColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SDColors.neutral200),
          ),
          child: !hasData
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      Icon(Icons.bar_chart_rounded,
                          size: 36,
                          color: SDColors.neutral900.withOpacity(0.25)),
                      const SizedBox(height: 8),
                      Text(
                        'Aucune activité cette semaine',
                        style: SDTypography.bodyMedium
                            .copyWith(color: SDColors.neutral500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '0 mission sur les 7 derniers jours',
                        style: SDTypography.labelSmall
                            .copyWith(color: SDColors.neutral400),
                      ),
                    ],
                  ),
                )
              : SizedBox(
                  height: 156,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(7, (i) {
                      final isHi = i == highlight && values[i] > 0;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              const labelSlot = 22.0;
                              final tipSlot = isHi ? 26.0 : 0.0;
                              final maxBar =
                                  (constraints.maxHeight - labelSlot - tipSlot)
                                      .clamp(8.0, 120.0);
                              final h = ((values[i] / maxV) * maxBar)
                                  .clamp(4.0, maxBar);
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (isHi)
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 4),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: SDColors.neutral900,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${values[i]}',
                                          style:
                                              SDTypography.labelSmall.copyWith(
                                            color: SDColors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 280),
                                    height: h,
                                    decoration: BoxDecoration(
                                      color: isHi
                                          ? SDColors.primary700
                                          : SDColors.primary200,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    days[i],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: SDTypography.labelSmall.copyWith(
                                      color: SDColors.neutral500,
                                      fontWeight: isHi
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      );
                    }),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: SDTypography.titleSmall.copyWith(
            color: SDColors.neutral900,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                icon: Icons.handyman_outlined,
                label: 'Gérer mes\nservices',
                onTap: onOpenServices,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Voir mes\nmessages',
                onTap: onOpenMessages,
                badge: unreadMessages,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Mes\npaiements',
                onTap: onOpenPayments,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.calendar_month_outlined,
                label: 'Mon\ncalendrier',
                onTap: onOpenCalendar,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Demandes récentes',
              style: SDTypography.titleSmall.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onOpenMissions,
              child: Text(
                'Voir tout ›',
                style: SDTypography.labelMedium.copyWith(
                  color: SDColors.primary700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentMissions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: SDColors.neutral50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SDColors.neutral200),
            ),
            child: Text(
              'Aucune demande récente pour le moment.',
              style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral500),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...recentMissions.take(3).map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MissionRow(mission: m, onTap: onOpenMissions),
              )),
      ],
    );
  }

  Widget _buildRevenueCard() {
    final fmt = NumberFormat('#,###', 'fr_FR');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Mes revenus',
              style: SDTypography.titleSmall.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onOpenPayments,
              child: Text(
                'Voir tout ›',
                style: SDTypography.labelMedium.copyWith(
                  color: SDColors.primary700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SDColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SDColors.neutral200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Solde disponible',
                style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
              ),
              const SizedBox(height: 4),
              Text(
                '${fmt.format(soldeDisponible.round())} FCFA',
                style: SDTypography.titleLarge.copyWith(
                  color: SDColors.primary700,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'En attente : ${fmt.format(soldeEnAttente.round())} FCFA',
                style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onWithdraw,
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Retirer mes gains'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SDColors.primary600,
                    foregroundColor: SDColors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentReviews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Avis clients récents',
          style: SDTypography.titleSmall.copyWith(
            color: SDColors.neutral900,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ...recentReviews.take(3).map((avis) {
          final auteur = avis['utilisateur'] ?? avis['auteur'] ?? {};
          final name = auteur is Map
              ? '${auteur['prenom'] ?? ''} ${auteur['nom'] ?? ''}'.trim()
              : '';
          final note = (avis['note'] is num)
              ? (avis['note'] as num).toDouble()
              : double.tryParse('${avis['note']}') ?? 0;
          final commentaire =
              (avis['commentaire'] ?? avis['contenu'] ?? '').toString();
          final initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SDColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SDColors.neutral200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: SDColors.primary50,
                        child: Text(
                          initial,
                          style: SDTypography.labelLarge.copyWith(
                            color: SDColors.primary700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isNotEmpty ? name : 'Client',
                              style: SDTypography.labelLarge.copyWith(
                                color: SDColors.neutral900,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < note.round()
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 14,
                                  color: const Color(0xFFFBBF24),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        note > 0 ? note.toStringAsFixed(1) : '—',
                        style: SDTypography.labelSmall
                            .copyWith(color: SDColors.neutral500),
                      ),
                    ],
                  ),
                  if (commentaire.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      commentaire,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: SDTypography.bodyMedium.copyWith(
                        color: SDColors.neutral700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final String subtitle;
  final Color subtitleColor;
  final double valueFontSize;
  final bool showStars;
  final double starRating;

  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.subtitleColor,
    this.valueFontSize = 22,
    this.showStars = false,
    this.starRating = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SDColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: SDColors.neutral900.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: SDTypography.labelSmall.copyWith(color: SDColors.neutral500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SDTypography.titleMedium.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w800,
              fontSize: valueFontSize,
            ),
          ),
          if (showStars) ...[
            const SizedBox(height: 4),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < starRating.round()
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 12,
                  color: const Color(0xFFFBBF24),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: SDTypography.labelSmall.copyWith(
              color: subtitleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SDColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SDColors.neutral200),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: SDColors.neutral900, size: 24),
                  if (badge > 0)
                    Positioned(
                      right: -10,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: SDColors.error500,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$badge',
                          style: SDTypography.labelSmall.copyWith(
                            color: SDColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: SDTypography.labelSmall.copyWith(
                  color: SDColors.neutral800,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  final Map<String, dynamic> mission;
  final VoidCallback onTap;

  const _MissionRow({required this.mission, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statut = (mission['statut'] ?? mission['status'] ?? '').toString();
    final title = (mission['titre'] ??
            mission['service'] ??
            mission['typeService'] ??
            'Mission')
        .toString();
    final lieu = (mission['adresse'] ??
            mission['localisation'] ??
            mission['lieu'] ??
            'Abidjan')
        .toString();
    final when = _formatWhen(mission['date'] ?? mission['createdAt'] ?? mission['datePrestation']);
    final confirmed = statut.toUpperCase().contains('CONFIRM') ||
        statut.toUpperCase() == 'ACCEPTEE' ||
        statut.toUpperCase() == 'EN_COURS' ||
        statut.toUpperCase() == 'TERMINEE';
    final badgeLabel = confirmed ? 'Confirmé' : 'En attente';
    final badgeBg = confirmed ? SDColors.primary50 : SDColors.secondary50;
    final badgeFg = confirmed ? SDColors.primary700 : SDColors.secondary600;

    return Material(
      color: SDColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SDColors.neutral200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: SDColors.neutral100,
                child: Icon(Icons.person_outline_rounded,
                    color: SDColors.neutral900, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lieu,
                      style: SDTypography.labelLarge.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$title · $when',
                      style: SDTypography.bodySmall.copyWith(
                        color: SDColors.neutral500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeLabel,
                  style: SDTypography.labelSmall.copyWith(
                    color: badgeFg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: SDColors.neutral400),
            ],
          ),
        ),
      ),
    );
  }

  String _formatWhen(dynamic raw) {
    if (raw == null) return 'À planifier';
    try {
      final d = DateTime.parse(raw.toString()).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final day = DateTime(d.year, d.month, d.day);
      final time = DateFormat('HH:mm').format(d);
      if (day == today) return 'Aujourd\'hui $time';
      if (day == today.add(const Duration(days: 1))) return 'Demain $time';
      return DateFormat('d MMM HH:mm', 'fr_FR').format(d);
    } catch (_) {
      return raw.toString();
    }
  }
}

class _IconCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  const _IconCircle({
    required this.icon,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: SDColors.neutral100,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, color: SDColors.neutral900, size: 20),
            ),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: SDColors.error500,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$badge',
                textAlign: TextAlign.center,
                style: SDTypography.labelSmall.copyWith(
                  color: SDColors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
