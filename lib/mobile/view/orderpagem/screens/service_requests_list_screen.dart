import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/jobPageScreenM.dart';
import '../servicerequestcubit/service_request_cubit.dart';
import 'service_request_summary_screen.dart';
import '../../common/widgets/unauthenticated_banner.dart';

class ServiceRequestsListScreen extends StatelessWidget {
  const ServiceRequestsListScreen({
    super.key,
    this.initialAchats = false,
  });

  /// `true` ouvre l’onglet Achats. Les autres points d’entrée restent sur Services.
  final bool initialAchats;

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
      child: _OrdersBody(
        key: ValueKey(initialAchats),
        token: auth.token,
        initialAchats: initialAchats,
      ),
    );
  }
}

class _OrdersBody extends StatefulWidget {
  final String token;
  final bool initialAchats;
  const _OrdersBody({
    super.key,
    required this.token,
    this.initialAchats = false,
  });

  @override
  State<_OrdersBody> createState() => _OrdersBodyState();
}

class _OrdersBodyState extends State<_OrdersBody> {
  static const double _hPad = 20;

  /// null = toutes
  String? _filter;
  late bool _achats = widget.initialAchats;

  static const _serviceFilters = <({String? key, String label})>[
    (key: null, label: 'Toutes'),
    (key: 'EN_ATTENTE', label: 'En attente'),
    (key: 'ACCEPTEE', label: 'Acceptées'),
  ];

  static const _achatFilters = <({String? key, String label})>[
    (key: null, label: 'Toutes'),
    (key: 'EN_COURS', label: 'En cours'),
  ];

  bool _matchesFilter(String rawStatus) {
    if (_filter == null) return true;
    final s = rawStatus.toUpperCase();
    switch (_filter) {
      case 'EN_ATTENTE':
        return s == 'EN_ATTENTE' || s == 'PENDING';
      case 'ACCEPTEE':
        return s == 'ACCEPTEE';
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
    if (service is Map) {
      final name = service['nomservice'] ?? service['nom'];
      if (name != null && name.toString().trim().isNotEmpty) {
        return name.toString();
      }
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

  String? _metier(Map<String, dynamic> it) {
    final p = it['prestataire'];
    if (p is Map) {
      final service = p['service'];
      if (service is Map) {
        final name = service['nomservice'] ?? service['nom'];
        if (name != null && name.toString().trim().isNotEmpty) {
          return name.toString();
        }
      }
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
      return DateFormat('d MMM · HH:mm', 'fr_FR').format(d);
    } catch (_) {
      return raw.toString();
    }
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
    final filters = _achats ? _achatFilters : _serviceFilters;
    return Scaffold(
      backgroundColor: SDColors.neutral50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColoredBox(
              color: SDColors.primary50,
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
                        Text(
                          _achats ? 'Mes commandes' : 'Mes demandes',
                          style: SDTypography.titleLarge.copyWith(
                            color: SDColors.neutral900,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(_hPad, 4, _hPad, 14),
                    child: _UniverseSwitch(
                      achats: _achats,
                      onChanged: (achats) => setState(() {
                        _achats = achats;
                        _filter = null;
                      }),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(_hPad, 14, _hPad, 10),
              child: Text(
                _achats
                    ? 'Vos achats E-marché'
                    : 'Vos échanges avec les professionnels',
                style: SDTypography.bodyMedium.copyWith(
                  color: SDColors.neutral700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                itemCount: filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final f = filters[index];
                  final selected = _filter == f.key;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = f.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? SDColors.primary700 : SDColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? SDColors.primary700
                              : SDColors.neutral200,
                        ),
                      ),
                      child: Text(
                        f.label,
                        style: SDTypography.labelMedium.copyWith(
                          color:
                              selected ? SDColors.white : SDColors.neutral800,
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

                  if (_achats) {
                    return const _PurchasesPane();
                  }

                  if (items.isEmpty) {
                    return _EmptyOrders(
                      showIllustration: state.items.isEmpty,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(_hPad, 4, _hPad, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final it = items[index];
                      final name = _providerName(it);
                      final metier = _metier(it);
                      final who = [
                        if (name != null && name.isNotEmpty) name,
                        if (metier != null && metier.isNotEmpty) metier,
                      ].join(' · ');
                      return _OrderCard(
                        title: _titleFor(it),
                        provider: who.isEmpty ? null : who,
                        location: _locationLine(it),
                        date: _dateLine(it),
                        status: _statusLabel(
                          it['status']?.toString() ??
                              it['statut']?.toString() ??
                              '',
                        ),
                        photoUrl: _photoUrl(it),
                        onTap: () {
                          final id =
                              it['_id']?.toString() ?? it['id']?.toString();
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
            if (!_achats)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const JobPageScreenM(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Trouver un professionnel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SDColors.primary700,
                        side: const BorderSide(color: SDColors.primary600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UniverseSwitch extends StatelessWidget {
  const _UniverseSwitch({required this.achats, required this.onChanged});

  final bool achats;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Row(
        children: [
          _seg(false, Icons.handyman_outlined, 'Services'),
          _seg(true, Icons.shopping_cart_outlined, 'Achats'),
        ],
      ),
    );
  }

  Widget _seg(bool value, IconData icon, String label) {
    final selected = achats == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: selected ? SDColors.primary700 : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? SDColors.white : SDColors.neutral700,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: SDTypography.labelMedium.copyWith(
                    color: selected ? SDColors.white : SDColors.neutral800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PurchasesPane extends StatelessWidget {
  const _PurchasesPane();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Le suivi de vos achats sera bientôt disponible.',
          textAlign: TextAlign.center,
          style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral500),
        ),
      ),
    );
  }
}

/// SD-ILL-005 uniquement lorsqu'il n'existe aucune commande.
/// Un filtre sans résultat conserve le texte, sans illustration.
class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({required this.showIllustration});

  final bool showIllustration;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showIllustration) ...[
                      const SDIllustration(
                        asset: SDIllustrations.ordersEmptyConnected,
                      ),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      'Aucune commande pour le moment.',
                      textAlign: TextAlign.center,
                      style: SDTypography.bodyMedium
                          .copyWith(color: SDColors.neutral500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String title;
  final String? provider;
  final String? location;
  final String? date;
  final String status;
  final String? photoUrl;
  final VoidCallback onTap;

  const _OrderCard({
    required this.title,
    required this.status,
    required this.onTap,
    this.provider,
    this.location,
    this.date,
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
              ClipOval(
                child: SizedBox(
                  width: 52,
                  height: 52,
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
                    Text(
                      title,
                      style: SDTypography.titleSmall.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (provider != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              provider!,
                              style: SDTypography.bodySmall
                                  .copyWith(color: SDColors.neutral600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(label: status),
                        ],
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _StatusChip(label: status),
                      ),
                    if (location != null || date != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (location != null)
                            Expanded(
                              child: Row(
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
                                          .copyWith(color: SDColors.neutral600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (date != null)
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 13,
                                    color: SDColors.neutral500,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      date!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: SDTypography.bodySmall
                                          .copyWith(color: SDColors.neutral500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Text(
                          'Voir la demande',
                          style: TextStyle(
                            color: SDColors.primary700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          color: SDColors.primary700,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
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
    final pending = label == 'En attente' || label == 'Refusée';
    final done = label == 'Terminée' || label == 'Annulée';
    final bg = pending
        ? SDColors.warning100
        : done
            ? SDColors.neutral100
            : SDColors.primary50;
    final fg = pending
        ? SDColors.warning700
        : done
            ? SDColors.neutral600
            : SDColors.primary700;
    final icon = label == 'Acceptée' || label == 'Terminée'
        ? Icons.check_circle
        : label == 'En attente'
            ? Icons.schedule
            : Icons.info_outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: SDTypography.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
