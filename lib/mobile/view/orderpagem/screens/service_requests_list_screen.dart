import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import '../servicerequestcubit/service_request_cubit.dart';
import 'service_request_summary_screen.dart';
import '../../common/widgets/unauthenticated_banner.dart';

class ServiceRequestsListScreen extends StatelessWidget {
  const ServiceRequestsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    if (auth is! AuthAuthenticated) {
      return const UnauthenticatedBanner(
        appBarTitle: 'Commandes',
        icon: Icons.assignment_outlined,
        title: 'Vos commandes',
        description:
            'Connectez-vous pour consulter et suivre vos demandes de prestations.',
      );
    }
    return BlocProvider(
      create: (_) => ServiceRequestCubit()
        ..fetchMine(
          token: auth.token,
          utilisateurId: auth.utilisateur.idutilisateur,
        ),
      child: _OrdersBody(token: auth.token),
    );
  }
}

class _OrdersBody extends StatefulWidget {
  final String token;
  const _OrdersBody({required this.token});

  @override
  State<_OrdersBody> createState() => _OrdersBodyState();
}

class _OrdersBodyState extends State<_OrdersBody> {
  static const double _hPad = 20;

  /// null = toutes
  String? _filter;

  static const _filters = <({String? key, String label})>[
    (key: null, label: 'Toutes'),
    (key: 'EN_ATTENTE', label: 'En attente'),
    (key: 'EN_COURS', label: 'En cours'),
    (key: 'TERMINEE', label: 'Terminées'),
    (key: 'ANNULEE', label: 'Annulées'),
  ];

  bool _matchesFilter(String rawStatus) {
    if (_filter == null) return true;
    final s = rawStatus.toUpperCase();
    switch (_filter) {
      case 'EN_ATTENTE':
        return s == 'EN_ATTENTE' ||
            s == 'PENDING' ||
            s == 'ACCEPTEE' ||
            s == 'REFUSEE';
      case 'EN_COURS':
        return s == 'EN_COURS' || s == 'IN_PROGRESS';
      case 'TERMINEE':
        return s == 'TERMINEE' || s == 'DONE' || s == 'COMPLETED';
      case 'ANNULEE':
        return s == 'ANNULEE' || s == 'CANCELLED' || s == 'CANCELED';
      default:
        return s == _filter;
    }
  }

  String _statusLabel(String raw) {
    switch (raw.toUpperCase()) {
      case 'EN_ATTENTE':
      case 'PENDING':
        return 'En attente';
      case 'ACCEPTEE':
        return 'Acceptée';
      case 'EN_COURS':
      case 'IN_PROGRESS':
        return 'En cours';
      case 'TERMINEE':
      case 'DONE':
      case 'COMPLETED':
        return 'Terminée';
      case 'ANNULEE':
      case 'CANCELLED':
      case 'CANCELED':
        return 'Annulée';
      case 'REFUSEE':
        return 'Refusée';
      case 'LITIGE':
        return 'Litige';
      default:
        return raw;
    }
  }

  String _titleFor(Map<String, dynamic> it) {
    final service = it['service'];
    if (service is Map && service['nom'] != null) {
      return service['nom'].toString();
    }
    if (it['serviceName'] != null) return it['serviceName'].toString();
    if (it['notesClient'] != null &&
        it['notesClient'].toString().trim().isNotEmpty) {
      return it['notesClient'].toString();
    }
    return 'Demande de service';
  }

  String? _providerName(Map<String, dynamic> it) {
    final p = it['prestataire'];
    if (p is Map) {
      final u = p['utilisateur'] ?? p['user'];
      if (u is Map) {
        final nom = personNameFromMap(
          Map<String, dynamic>.from(u),
          fallback: 'Prestataire',
        );
        if (nom.isNotEmpty) return nom;
      }
      if (p['nom'] != null) return cleanDisplayPart(p['nom']);
    }
    return null;
  }

  String? _locationLine(Map<String, dynamic> it) {
    final parts = [
      it['adresse']?.toString(),
      it['ville']?.toString(),
    ].where((e) => e != null && e.trim().isNotEmpty).toList();
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  String? _dateLine(Map<String, dynamic> it) {
    final raw = it['datePrestation'] ?? it['createdAt'] ?? it['date'];
    if (raw == null) return null;
    try {
      final d = DateTime.parse(raw.toString()).toLocal();
      return DateFormat('d MMM yyyy · HH:mm', 'fr_FR').format(d);
    } catch (_) {
      return raw.toString();
    }
  }

  String? _priceLine(Map<String, dynamic> it) {
    final m = it['montant'] ?? it['prix'] ?? it['amount'];
    if (m == null) return null;
    final n = num.tryParse(m.toString());
    if (n == null) return null;
    return '${NumberFormat('#,###', 'fr_FR').format(n)} FCFA'
        .replaceAll(',', ' ');
  }

  String? _photoUrl(Map<String, dynamic> it) {
    final p = it['prestataire'];
    if (p is Map) {
      final u = p['utilisateur'] ?? p['user'];
      if (u is Map && u['photoProfil'] != null) {
        final url = u['photoProfil'].toString();
        if (url.startsWith('http')) return url;
      }
      if (p['photo'] != null) {
        final url = p['photo'].toString();
        if (url.startsWith('http')) return url;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.neutral50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, _hPad, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: SDColors.neutral900,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(_hPad, 4, _hPad, 12),
              child: Text(
                'Commandes',
                style: SDTypography.displayMedium.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final f = _filters[index];
                  final selected = _filter == f.key;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = f.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? SDColors.neutral900
                            : SDColors.neutral100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        f.label,
                        style: SDTypography.labelMedium.copyWith(
                          color: selected
                              ? SDColors.white
                              : SDColors.neutral700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<ServiceRequestCubit, ServiceRequestState>(
                builder: (context, state) {
                  if (state is ServiceRequestLoading ||
                      state is ServiceRequestInitial) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: SDColors.neutral900,
                      ),
                    );
                  }
                  if (state is ServiceRequestError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(_hPad),
                        child: Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: SDTypography.bodyMedium
                              .copyWith(color: SDColors.neutral600),
                        ),
                      ),
                    );
                  }
                  if (state is! ServiceRequestListLoaded) {
                    return const SizedBox.shrink();
                  }

                  final items = state.items
                      .where((it) => _matchesFilter(
                            it['status']?.toString() ??
                                it['statut']?.toString() ??
                                '',
                          ))
                      .toList();

                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'Aucune commande pour le moment.',
                        style: SDTypography.bodyMedium
                            .copyWith(color: SDColors.neutral500),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(_hPad, 4, _hPad, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final it = items[index];
                      return _OrderCard(
                        title: _titleFor(it),
                        provider: _providerName(it),
                        location: _locationLine(it),
                        date: _dateLine(it),
                        status: _statusLabel(
                          it['status']?.toString() ??
                              it['statut']?.toString() ??
                              '',
                        ),
                        price: _priceLine(it),
                        photoUrl: _photoUrl(it),
                        onTap: () {
                          final id = it['_id']?.toString() ?? it['id']?.toString();
                          if (id == null) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ServiceRequestSummaryScreen(
                                requestId: id,
                                token: widget.token,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String title;
  final String? provider;
  final String? location;
  final String? date;
  final String status;
  final String? price;
  final String? photoUrl;
  final VoidCallback onTap;

  const _OrderCard({
    required this.title,
    required this.status,
    required this.onTap,
    this.provider,
    this.location,
    this.date,
    this.price,
    this.photoUrl,
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SDColors.neutral200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: photoUrl != null
                      ? Image.network(
                          photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                        )
                      : _thumbPlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: SDTypography.titleSmall.copyWith(
                              color: SDColors.neutral900,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(label: status),
                      ],
                    ),
                    if (provider != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        provider!,
                        style: SDTypography.bodyMedium
                            .copyWith(color: SDColors.neutral700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (location != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: SDColors.neutral500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location!,
                              style: SDTypography.bodySmall
                                  .copyWith(color: SDColors.neutral500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (date != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: SDColors.neutral500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              date!,
                              style: SDTypography.bodySmall
                                  .copyWith(color: SDColors.neutral500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (price != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        price!,
                        style: SDTypography.titleSmall.copyWith(
                          color: SDColors.neutral900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, top: 2),
                child: Icon(
                  Icons.chevron_right,
                  color: SDColors.neutral400,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      color: SDColors.neutral100,
      child: const Icon(
        Icons.handyman_outlined,
        color: SDColors.neutral400,
        size: 28,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: SDColors.neutral100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: SDTypography.labelSmall.copyWith(
          color: SDColors.neutral800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
