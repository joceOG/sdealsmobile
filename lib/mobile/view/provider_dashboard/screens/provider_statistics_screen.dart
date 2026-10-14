import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../data/services/authCubit.dart';
import '../../../../design_system/design_system.dart';
import '../bloc/provider_statistics_bloc.dart';
import '../bloc/provider_statistics_event.dart';
import '../bloc/provider_statistics_state.dart';
import '../models/provider_statistics_aggregator.dart';
import '../models/provider_statistics_period.dart';

/// Statistiques prestataire — agrégation réelle sur la période sélectionnée.
class ProviderStatisticsScreen extends StatefulWidget {
  final String? prestataireDocId;
  const ProviderStatisticsScreen({super.key, this.prestataireDocId});

  @override
  State<ProviderStatisticsScreen> createState() =>
      _ProviderStatisticsScreenState();
}

class _ProviderStatisticsScreenState extends State<ProviderStatisticsScreen> {
  String? _prestataireId;
  ProviderStatsPeriodPreset _preset = ProviderStatsPeriodPreset.thisMonth;
  final _money = NumberFormat('#,###', 'fr_FR');
  final _timeFmt = DateFormat('HH:mm', 'fr_FR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return;
    _prestataireId = widget.prestataireDocId;
    if (_prestataireId == null || _prestataireId!.isEmpty) return;
    context.read<ProviderStatisticsBloc>().setToken(auth.token);
    context.read<ProviderStatisticsBloc>().add(
          LoadProviderStatistics(_prestataireId!, periodPreset: _preset),
        );
  }

  void _refresh() => _load();

  Future<void> _pickPeriod() async {
    final chosen = await showModalBottomSheet<ProviderStatsPeriodPreset>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final p in ProviderStatsPeriodPreset.values)
              ListTile(
                title: Text(ProviderStatsPeriod.resolve(p).presetLabel),
                onTap: () => Navigator.pop(ctx, p),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || chosen == _preset) return;
    setState(() => _preset = chosen);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: SDWhiteAppBar.appBar(title: 'Statistiques'),
      body: BlocBuilder<ProviderStatisticsBloc, ProviderStatisticsState>(
        builder: (context, state) {
          if (state is ProviderStatisticsLoading ||
              state is ProviderStatisticsInitial) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (state is ProviderStatisticsError) {
            return _errorBody(state.message);
          }
          if (state is ProviderPeriodStatisticsLoaded) {
            return _loadedBody(state.data);
          }
          return _errorBody('Données indisponibles pour cette vue.');
        },
      ),
    );
  }

  Widget _errorBody(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 48),
        Icon(Icons.error_outline, size: 56, color: SDColors.neutral400),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral600),
        ),
        const SizedBox(height: 20),
        Center(child: SDButton(text: 'Réessayer', onPressed: _refresh)),
      ],
    );
  }

  Widget _loadedBody(ProviderPeriodStatistics data) {
    final period = data.period;
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Comprendre votre activité',
            style: SDTypography.bodyMedium.copyWith(
              color: SDColors.neutral600,
            ),
          ),
          const SizedBox(height: 16),
          _periodSelector(period),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  period.rangeLabelFr,
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Actualiser',
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, size: 20),
                color: SDColors.neutral600,
              ),
              Text(
                'Mis à jour à ${_timeFmt.format(data.loadedAt)}',
                style: SDTypography.labelSmall.copyWith(
                  color: SDColors.neutral500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Sur la période',
            style: SDTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: SDColors.neutral900,
            ),
          ),
          const SizedBox(height: 12),
          _kpiGrid(data),
          if (data.paiementsRecus.isAvailable) ...[
            const SizedBox(height: 8),
            Text(
              'Paiements reçus : montants encaissés (missions terminées et payées). '
              'Distinct du solde disponible et du bénéfice.',
              style: SDTypography.bodySmall.copyWith(
                color: SDColors.neutral500,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 28),
          Text(
            'Demandes reçues',
            style: SDTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: SDColors.neutral900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Répartition sur la période (date de réception)',
            style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
          ),
          const SizedBox(height: 12),
          _demandesSection(data),
          const SizedBox(height: 28),
          Text(
            'Avis reçus',
            style: SDTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: SDColors.neutral900,
            ),
          ),
          const SizedBox(height: 12),
          _reviewsSection(data.reviews),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  size: 16, color: SDColors.neutral500),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Les chiffres correspondent à la période sélectionnée.',
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral500,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _periodSelector(ProviderStatsPeriod period) {
    return Material(
      color: SDColors.neutral50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _pickPeriod,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SDColors.neutral200),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_outlined,
                  color: SDColors.neutral600, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  period.presetLabel,
                  style: SDTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: SDColors.neutral900,
                  ),
                ),
              ),
              const Icon(Icons.expand_more, color: SDColors.neutral500),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiGrid(ProviderPeriodStatistics data) {
    final tiles = <Widget>[
      _kpiTile(
        icon: Icons.description_outlined,
        label: 'Demandes reçues',
        value: '${data.demandesRecues}',
      ),
      _kpiTile(
        icon: Icons.task_alt_outlined,
        label: 'Missions terminées',
        value: '${data.missionsTerminees}',
      ),
      _kpiTile(
        icon: Icons.cancel_outlined,
        label: 'Annulations',
        value: '${data.annulations}',
      ),
    ];
    if (data.paiementsRecus.isAvailable) {
      tiles.add(
        _kpiTile(
          icon: Icons.payments_outlined,
          label: 'Paiements reçus',
          value:
              '${_money.format(data.paiementsRecus.amountFcfa!.round())} FCFA',
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: tiles,
    );
  }

  Widget _kpiTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const Spacer(),
          Text(
            value,
            style: SDTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: SDColors.neutral900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: SDTypography.bodySmall.copyWith(
              color: SDColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _demandesSection(ProviderPeriodStatistics data) {
    if (!data.demandesDistributionReliable) {
      return _infoCard(
        'Répartition indisponible',
        'Les dates de réception ne permettent pas une répartition fiable sur la période.',
      );
    }
    if (data.demandesRecues == 0) {
      return _infoCard(
        'Aucune demande',
        'Aucune demande reçue sur cette période.',
      );
    }

    final maxCount = data.demandesBuckets.fold<int>(
      0,
      (a, b) => a > b.count ? a : b.count,
    );
    final maxV = maxCount > 0 ? maxCount.toDouble() : 1.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Column(
        children: [
          ...data.demandesBuckets.map((b) {
            final ratio = (b.count / maxV).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(
                      b.label,
                      style: SDTypography.labelSmall.copyWith(
                        color: SDColors.neutral600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 10,
                        backgroundColor: SDColors.primary50,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          SDColors.primary600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${b.count}',
                    style: SDTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 1, color: SDColors.neutral100),
          const SizedBox(height: 10),
          Text(
            '${data.demandesRecues} demande${data.demandesRecues > 1 ? 's' : ''} au total',
            style: SDTypography.bodySmall.copyWith(
              color: SDColors.neutral600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewsSection(ReviewsPeriodSummary reviews) {
    if (reviews.count == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: SDColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SDColors.neutral200),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: SDColors.primary50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_outline, color: SDColors.primary700),
            ),
            const SizedBox(height: 12),
            Text(
              'Aucun avis sur cette période',
              style: SDTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: SDColors.neutral900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'La note moyenne apparaîtra après un avis.',
              textAlign: TextAlign.center,
              style: SDTypography.bodySmall.copyWith(
                color: SDColors.neutral500,
              ),
            ),
          ],
        ),
      );
    }

    final avg = reviews.averageNote != null
        ? reviews.averageNote!.toStringAsFixed(1)
        : '—';
    return _infoCard(
      '${reviews.count} avis',
      'Note moyenne sur la période : $avg / 5',
    );
  }

  Widget _infoCard(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: SDTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: SDColors.neutral900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: SDTypography.bodySmall.copyWith(color: SDColors.neutral600),
          ),
        ],
      ),
    );
  }
}
