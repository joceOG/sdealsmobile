import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/app_image.dart';

/// Accueil prestataire — maquette « Mon activité » (action d'abord, stats discrètes).
class ProviderHomeDashboard extends StatelessWidget {
  const ProviderHomeDashboard({
    super.key,
    required this.fullName,
    this.photoUrl,
    required this.metier,
    required this.location,
    required this.isVerified,
    required this.isAvailable,
    this.availabilityLocalOnly = false,
    required this.onAvailabilityChanged,
    required this.pendingMissions,
    this.nextIntervention,
    required this.demandesRecues,
    required this.missionsEnCours,
    required this.isLoadingStats,
    required this.unreadMessages,
    required this.onRefresh,
    required this.onOpenStats,
    required this.onOpenServices,
    required this.onOpenMessages,
    required this.onOpenPlanning,
    required this.onOpenProfile,
    required this.onOpenMissions,
    required this.onOpenMission,
    required this.expertMenuAction,
    required this.onOpenNotifications,
    this.unreadNotifications = 0,
  });

  final String fullName;
  final String? photoUrl;
  final String metier;
  final String location;
  final bool isVerified;
  final bool isAvailable;
  final bool availabilityLocalOnly;
  final ValueChanged<bool> onAvailabilityChanged;

  final List<Map<String, dynamic>> pendingMissions;
  final Map<String, dynamic>? nextIntervention;

  final int demandesRecues;
  final int missionsEnCours;
  final bool isLoadingStats;

  final int unreadMessages;
  final int unreadNotifications;

  final VoidCallback onRefresh;
  final VoidCallback onOpenStats;
  final VoidCallback onOpenServices;
  final VoidCallback onOpenMessages;
  final VoidCallback onOpenPlanning;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenMissions;
  final ValueChanged<Map<String, dynamic>> onOpenMission;
  final Widget expertMenuAction;
  final VoidCallback onOpenNotifications;

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
                const SizedBox(height: 14),
                _buildAvailabilityBar(),
                const SizedBox(height: 22),
                _buildToProcessSection(),
                const SizedBox(height: 22),
                _buildNextInterventionSection(),
                const SizedBox(height: 22),
                _buildQuickAccessGrid(),
                const SizedBox(height: 22),
                _buildMonthSummary(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mon activité',
                style: SDTypography.titleLarge.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Espace prestataire',
                style: SDTypography.bodySmall.copyWith(
                  color: SDColors.neutral500,
                ),
              ),
            ],
          ),
        ),
        _IconCircle(
          icon: Icons.notifications_none_rounded,
          onTap: onOpenNotifications,
          badge: unreadNotifications,
        ),
        const SizedBox(width: 8),
        expertMenuAction,
      ],
    );
  }

  Widget _buildProfileHeader() {
    final subtitle = [
      metier,
      if (location.trim().isNotEmpty) location.trim(),
    ].join(' • ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            ClipOval(
              child: photoUrl != null && photoUrl!.startsWith('http')
                  ? AppImage(
                      imageUrl: photoUrl!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 52,
                      height: 52,
                      color: SDColors.primary50,
                      alignment: Alignment.center,
                      child: Text(
                        _initials(fullName),
                        style: SDTypography.labelLarge.copyWith(
                          color: SDColors.primary700,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
            ),
            if (isVerified)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: SDColors.primary600,
                    shape: BoxShape.circle,
                    border: Border.all(color: SDColors.white, width: 2),
                  ),
                  child: const Icon(Icons.check, color: SDColors.white, size: 10),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fullName,
                style: SDTypography.titleSmall.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: SDTypography.bodySmall.copyWith(
                  color: SDColors.neutral600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityBar() {
    final label = isAvailable
        ? 'Disponible pour des demandes'
        : 'Indisponible pour le moment';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SDColors.primary50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SDColors.primary100),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isAvailable ? SDColors.primary600 : SDColors.neutral400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: SDTypography.bodyMedium.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (availabilityLocalOnly)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                'local',
                style: SDTypography.labelSmall.copyWith(
                  color: SDColors.neutral400,
                  fontSize: 9,
                ),
              ),
            ),
          Switch.adaptive(
            value: isAvailable,
            activeThumbColor: SDColors.white,
            activeTrackColor: SDColors.primary600,
            onChanged: onAvailabilityChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildToProcessSection() {
    final count = pendingMissions.length;
    final featured = count > 0 ? pendingMissions.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                'À traiter',
                maxLines: 2,
                style: SDTypography.titleSmall.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: SDColors.primary600,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: SDTypography.labelSmall.copyWith(
                    color: SDColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
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
        if (featured == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SDColors.neutral50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SDColors.neutral200),
            ),
            child: Text(
              'Aucune demande à traiter pour le moment.',
              style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral500),
            ),
          )
        else
          _PendingRequestCard(
            mission: featured,
            onView: () => onOpenMission(featured),
          ),
      ],
    );
  }

  Widget _buildNextInterventionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prochaine intervention',
          style: SDTypography.titleSmall.copyWith(
            color: SDColors.neutral900,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (nextIntervention == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SDColors.neutral50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SDColors.neutral200),
            ),
            child: Text(
              'Aucune intervention planifiée.',
              style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral500),
            ),
          )
        else
          _NextInterventionCard(
            mission: nextIntervention!,
            onTap: () => onOpenMission(nextIntervention!),
          ),
      ],
    );
  }

  Widget _buildQuickAccessGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accès rapides',
          style: SDTypography.titleSmall.copyWith(
            color: SDColors.neutral900,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAccessTile(
                icon: Icons.handyman_outlined,
                label: 'Mes services',
                onTap: onOpenServices,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAccessTile(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Messages',
                onTap: onOpenMessages,
                badge: unreadMessages,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickAccessTile(
                icon: Icons.calendar_month_outlined,
                label: 'Planning',
                onTap: onOpenPlanning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAccessTile(
                icon: Icons.person_outline_rounded,
                label: 'Mon profil',
                onTap: onOpenProfile,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthSummary() {
    final demandes = isLoadingStats ? '—' : '$demandesRecues';
    final enCours = isLoadingStats ? '—' : '$missionsEnCours';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                'Ce mois-ci',
                maxLines: 2,
                style: SDTypography.titleSmall.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onOpenStats,
              child: Text(
                'Statistiques ›',
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: SDColors.primary50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SDColors.primary100),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _MonthStat(
                    value: demandes,
                    label: 'Demandes reçues',
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: SDColors.primary100,
                ),
                Expanded(
                  child: _MonthStat(
                    value: enCours,
                    label: 'Mission en cours',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.elementAt(1)[0]}'.toUpperCase();
  }
}

class _PendingRequestCard extends StatelessWidget {
  const _PendingRequestCard({
    required this.mission,
    required this.onView,
  });

  final Map<String, dynamic> mission;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final title = prestationServiceTitle(mission);
    final client = prestationClientName(mission);
    final lieu = prestationLocationLabel(mission);
    final when = _relativeTime(
      mission['createdAt'] ?? mission['dateCommande'],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SDColors.primary50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Nouvelle demande',
                  style: SDTypography.labelSmall.copyWith(
                    color: SDColors.primary700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                when,
                style: SDTypography.labelSmall.copyWith(
                  color: SDColors.neutral500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: SDTypography.titleSmall.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 16, color: SDColors.neutral500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  client,
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.place_outlined,
                  size: 16, color: SDColors.neutral500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  lieu,
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SDButton(
            text: 'Voir la demande',
            fullWidth: true,
            onPressed: onView,
          ),
        ],
      ),
    );
  }

  String _relativeTime(dynamic raw) {
    if (raw == null) return '';
    final d = DateTime.tryParse(raw.toString())?.toLocal();
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return DateFormat('d MMM', 'fr_FR').format(d);
  }
}

class _NextInterventionCard extends StatelessWidget {
  const _NextInterventionCard({
    required this.mission,
    required this.onTap,
  });

  final Map<String, dynamic> mission;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = prestationServiceTitle(mission);
    final lieu = prestationLocationLabel(mission);
    final raw = mission['datePrestation'] ?? mission['date'];
    final day = DateTime.tryParse('$raw')?.toLocal();
    final dayNum = day != null ? DateFormat('d').format(day) : '—';
    final month = day != null ? DateFormat('MMM', 'fr_FR').format(day).toUpperCase() : '';
    final weekdayTime = _weekdayAndTime(day, mission['heureDebut']);
    final statut = (mission['statut'] ?? mission['status'] ?? '').toString();
    final statusLabel = _statusLabel(statut);

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
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: SDColors.primary50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      dayNum,
                      style: SDTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: SDColors.neutral900,
                      ),
                    ),
                    if (month.isNotEmpty)
                      Text(
                        month,
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.neutral500,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: SDTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: SDColors.neutral900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.event_outlined,
                            size: 14, color: SDColors.neutral500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            weekdayTime,
                            style: SDTypography.labelSmall.copyWith(
                              color: SDColors.neutral600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 14, color: SDColors.neutral500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            lieu,
                            style: SDTypography.labelSmall.copyWith(
                              color: SDColors.neutral600,
                            ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: SDColors.primary600),
                ),
                child: Text(
                  statusLabel,
                  style: SDTypography.labelSmall.copyWith(
                    color: SDColors.primary700,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: SDColors.neutral400),
            ],
          ),
        ),
      ),
    );
  }

  String _weekdayAndTime(DateTime? day, dynamic heureDebut) {
    if (day == null) return 'Date à confirmer';
    final weekday = DateFormat('EEEE', 'fr_FR').format(day);
    final cap = weekday.isNotEmpty
        ? '${weekday[0].toUpperCase()}${weekday.substring(1)}'
        : weekday;
    final h = heureDebut?.toString().trim();
    if (h != null && h.isNotEmpty) return '$cap • $h';
    return cap;
  }

  String _statusLabel(String statut) {
    switch (statut.toUpperCase()) {
      case 'ACCEPTEE':
      case 'CONFIRMEE':
        return 'Confirmée';
      case 'EN_COURS':
        return 'En cours';
      default:
        return displayOrFallback(statut, 'Planifiée');
    }
  }
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SDColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SDColors.neutral200),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 168;
              final leading = Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: SDColors.primary50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: SDColors.primary700, size: 20),
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: SDColors.error500,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$badge',
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
              final text = Text(
                label,
                textAlign: stacked ? TextAlign.center : TextAlign.start,
                style: SDTypography.labelMedium.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
                maxLines: 2,
              );
              if (stacked) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    leading,
                    const SizedBox(height: 8),
                    text,
                  ],
                );
              }
              return Row(
                children: [
                  leading,
                  const SizedBox(width: 8),
                  Expanded(child: text),
                  const Icon(Icons.chevron_right,
                      size: 18, color: SDColors.neutral400),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MonthStat extends StatelessWidget {
  const _MonthStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: SDTypography.titleLarge.copyWith(
            color: SDColors.primary700,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: SDTypography.labelSmall.copyWith(
            color: SDColors.neutral600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({
    required this.icon,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SDColors.neutral50,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: SDColors.neutral900, size: 22),
              if (badge > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: SDColors.error500,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
