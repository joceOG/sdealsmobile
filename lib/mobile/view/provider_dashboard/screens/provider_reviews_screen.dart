import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../data/utils/display_text.dart';
import '../../../../design_system/design_system.dart';

/// Avis reçus sur le profil prestataire — GET `/avis` + `/avis/stats/PRESTATAIRE/:id`.
class ProviderReviewsScreen extends StatefulWidget {
  const ProviderReviewsScreen({
    super.key,
    required this.prestataireId,
  });

  final String prestataireId;

  @override
  State<ProviderReviewsScreen> createState() => _ProviderReviewsScreenState();
}

class _ProviderReviewsScreenState extends State<ProviderReviewsScreen> {
  final ApiClient _api = ApiClient();

  bool _loading = true;
  String? _error;
  int _totalAvis = 0;
  double? _averageNote;
  List<Map<String, dynamic>> _reviews = [];
  int _page = 1;
  int _totalPages = 1;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _reviews = [];
      });
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) {
      setState(() {
        _loading = false;
        _error = 'Connexion requise';
      });
      return;
    }

    try {
      final statsRes = await _api.get(
        '/avis/stats/PRESTATAIRE/${widget.prestataireId}',
        token: auth.token,
      );
      if (statsRes.statusCode != 200) {
        throw ApiException.generic(statsRes.statusCode);
      }
      final stats = jsonDecode(statsRes.body) as Map<String, dynamic>;
      final total = (stats['totalAvis'] as num?)?.toInt() ?? 0;
      final avgRaw = stats['moyenneNote'];
      double? avg;
      if (avgRaw is num && total > 0) {
        avg = avgRaw.toDouble();
        if (avg <= 0) avg = null;
      }

      if (total == 0) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _totalAvis = 0;
          _averageNote = null;
          _reviews = [];
        });
        return;
      }

      await _fetchPage(auth.token, page: 1, replace: true, avg: avg, total: total);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ApiException.userFacing(e);
      });
    }
  }

  Future<void> _fetchPage(
    String token, {
    required int page,
    required bool replace,
    double? avg,
    int? total,
  }) async {
    final res = await _api.get(
      '/avis?objetType=PRESTATAIRE&objetId=${widget.prestataireId}'
      '&limit=20&page=$page&sortBy=createdAt&sortOrder=desc',
      token: token,
    );
    if (res.statusCode != 200) {
      throw ApiException.generic(res.statusCode);
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (body['avis'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];
    final pagination = body['pagination'];
    var pages = 1;
    if (pagination is Map) {
      pages = (pagination['pages'] as num?)?.toInt() ?? 1;
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadingMore = false;
      if (total != null) _totalAvis = total;
      if (avg != null) _averageNote = avg;
      _page = page;
      _totalPages = pages;
      _reviews = replace ? list : [..._reviews, ...list];
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _totalPages) return;
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return;
    setState(() => _loadingMore = true);
    try {
      await _fetchPage(auth.token, page: _page + 1, replace: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userFacing(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: SDWhiteAppBar.appBar(title: 'Avis reçus'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _reviews.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null && _reviews.isEmpty && _totalAvis == 0) {
      return _errorView(_error!);
    }
    if (_totalAvis == 0 && !_loading) {
      return _emptyView();
    }

    return RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      color: SDColors.primary600,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            'Les retours de vos clients',
            style: SDTypography.bodyMedium.copyWith(
              color: SDColors.neutral600,
            ),
          ),
          const SizedBox(height: 20),
          _summaryCard(),
          const SizedBox(height: 24),
          Text(
            'Les avis de vos clients',
            style: SDTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: SDColors.neutral900,
            ),
          ),
          const SizedBox(height: 12),
          if (_error != null && _reviews.isEmpty)
            _errorView(_error!, compact: true)
          else ...[
            for (final avis in _reviews) ...[
              _ReviewCard(avis: avis),
              const SizedBox(height: 12),
            ],
            if (_page < _totalPages)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: _loadingMore
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: _loadMore,
                          child: const Text('Charger plus d\'avis'),
                        ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _summaryCard() {
    final avg = _averageNote;
    final countLabel =
        _totalAvis == 1 ? '1 avis' : '$_totalAvis avis';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SDColors.primary50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SDColors.primary100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (avg != null)
            Text(
              '${avg.toStringAsFixed(1).replaceAll('.', ',')} / 5',
              style: SDTypography.displaySmall.copyWith(
                fontWeight: FontWeight.w800,
                color: SDColors.primary800,
              ),
            ),
          const SizedBox(height: 8),
          _StarRow(note: avg ?? 0, size: 22),
          const SizedBox(height: 8),
          Text(
            countLabel,
            style: SDTypography.bodyMedium.copyWith(
              color: SDColors.neutral700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tous les avis reçus',
            style: SDTypography.labelSmall.copyWith(
              color: SDColors.primary700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyView() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: SDColors.primary50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.rate_review_outlined,
                      size: 40,
                      color: SDColors.primary700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Aucun avis pour le moment',
                    style: SDTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: SDColors.neutral900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Les avis laissés par vos clients apparaîtront ici.',
                    style: SDTypography.bodyMedium.copyWith(
                      color: SDColors.neutral500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(color: SDColors.primary600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Retour à mon profil',
                style: SDTypography.labelLarge.copyWith(
                  color: SDColors.primary700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorView(String message, {bool compact = false}) {
    return Padding(
      padding: EdgeInsets.all(compact ? 8 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40, color: SDColors.neutral400),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral600),
          ),
          const SizedBox(height: 16),
          SDButton(text: 'Réessayer', onPressed: () => _load(refresh: true)),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.avis});

  final Map<String, dynamic> avis;

  @override
  Widget build(BuildContext context) {
    final author = avisAuthorLabel(avis);
    final initial = author.isNotEmpty ? author[0].toUpperCase() : 'C';
    final date = DateTime.tryParse('${avis['createdAt']}')?.toLocal();
    final dateStr = date != null
        ? DateFormat('d MMM yyyy', 'fr_FR').format(date)
        : '';
    final note = (avis['note'] as num?)?.toInt() ?? 0;
    final service = cleanDisplayPart(avis['titre']) ?? '';
    final comment = cleanDisplayPart(avis['commentaire']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: SDColors.primary50,
                child: Text(
                  initial,
                  style: SDTypography.labelLarge.copyWith(
                    color: SDColors.primary800,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      style: SDTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: SDColors.neutral900,
                      ),
                    ),
                    if (dateStr.isNotEmpty)
                      Text(
                        dateStr,
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.neutral500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _StarRow(note: note.toDouble(), size: 16),
          if (service.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              service,
              style: SDTypography.bodySmall.copyWith(
                color: SDColors.neutral600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '« $comment »',
              style: SDTypography.bodyMedium.copyWith(
                color: SDColors.neutral700,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String avisAuthorLabel(Map<String, dynamic> avis) {
  if (avis['anonyme'] == true) return 'Client';
  final auteur = avis['auteur'];
  if (auteur is Map) {
    final prenom = cleanDisplayPart(auteur['prenom']);
    final nom = cleanDisplayPart(auteur['nom']);
    if (prenom != null && nom != null && nom.isNotEmpty) {
      return '$prenom ${nom[0].toUpperCase()}.';
    }
    return joinPersonName(prenom: prenom, nom: nom, fallback: 'Client');
  }
  return 'Client';
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.note, this.size = 18});

  final double note;
  final double size;

  @override
  Widget build(BuildContext context) {
    final full = note.floor().clamp(0, 5);
    final half = (note - full) >= 0.25 && full < 5;
    return Row(
      children: List.generate(5, (i) {
        IconData icon;
        if (i < full) {
          icon = Icons.star_rounded;
        } else if (i == full && half) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        return Icon(
          icon,
          size: size,
          color: const Color(0xFFEAB308),
        );
      }),
    );
  }
}
