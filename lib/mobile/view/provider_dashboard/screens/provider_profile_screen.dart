import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/provider_profile_bloc.dart';
import '../bloc/provider_profile_event.dart';
import '../bloc/provider_profile_state.dart';
import '../../../../data/services/authCubit.dart';

/// Écran profil prestataire : une seule vue défilante (pas d’onglets).
class ProviderProfileScreen extends StatefulWidget {
  final String? prestataireDocId;
  const ProviderProfileScreen({super.key, this.prestataireDocId});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  String? _prestataireId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _bootstrap() {
    if (!mounted) return;
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return;

    context.read<ProviderProfileBloc>().setToken(auth.token);
    _prestataireId = widget.prestataireDocId ?? auth.utilisateur.idutilisateur;
    if (_prestataireId != null && _prestataireId!.isNotEmpty) {
      context.read<ProviderProfileBloc>().add(LoadProviderProfile(_prestataireId!));
    }
  }

  void _refreshProfile() {
    if (_prestataireId == null || _prestataireId!.isEmpty) return;
    context.read<ProviderProfileBloc>().add(LoadProviderProfile(_prestataireId!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mon profil'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProfile,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: BlocBuilder<ProviderProfileBloc, ProviderProfileState>(
        builder: (context, state) {
          if (state is ProviderProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProviderProfileError) {
            return _buildErrorBody(state.message);
          }
          if (state is ProviderProfileLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                _refreshProfile();
                await Future<void>.delayed(const Duration(milliseconds: 200));
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHero(state)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStatsRow(state),
                          const SizedBox(height: 16),
                          _buildInfoCard(state),
                          const SizedBox(height: 16),
                          _buildServicesCard(state),
                          const SizedBox(height: 16),
                          _buildZoneCard(state),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text('Initialisation…'));
        },
      ),
    );
  }

  /// Évite tout débordement quand la zone disponible est très petite (ex. SliverFillRemaining).
  Widget _buildErrorBody(String message) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 56, color: Colors.red[300]),
                const SizedBox(height: 12),
                Text(
                  'Impossible de charger le profil',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _refreshProfile,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHero(ProviderProfileLoaded state) {
    final p = state.profile;
    final name = (p['fullName']?.toString().trim().isNotEmpty ?? false)
        ? p['fullName'].toString()
        : 'Prestataire';
    final status = p['status']?.toString() ?? '—';
    final verified = p['verifier'] == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade500, Colors.green.shade800],
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(Icons.handyman, size: 40, color: Colors.green.shade700),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                status,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 14,
                ),
              ),
              if (verified) ...[
                const SizedBox(width: 6),
                Icon(Icons.verified, color: Colors.amber.shade200, size: 18),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ProviderProfileLoaded state) {
    final s = state.stats;
    final missions = s['missionsCompleted'] ?? 0;
    final rating = (s['averageRating'] ?? 0).toString();
    final earnings = s['monthlyEarnings'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _statTile('Missions', '$missions', Icons.assignment_turned_in),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statTile('Note', rating, Icons.star, subtitle: '/5'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statTile('Revenus', '$earnings', Icons.payments, subtitle: 'FCFA'),
        ),
      ],
    );
  }

  Widget _statTile(String label, String value, IconData icon, {String? subtitle}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 22, color: Colors.green.shade700),
            const SizedBox(height: 4),
            Text(
              value + (subtitle ?? ''),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ProviderProfileLoaded state) {
    final p = state.profile;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            _infoRow('Email', p['email']?.toString() ?? '—'),
            _infoRow('Téléphone', p['phone']?.toString() ?? '—'),
            _infoRow('Bio', (p['bio']?.toString().isNotEmpty ?? false) ? p['bio'].toString() : '—'),
            _infoRow('Localisation', p['location']?.toString() ?? '—'),
            _infoRow('Rayon', '${p['serviceRadius'] ?? '—'} km'),
            _infoRow('Expérience', '${p['anneeExperience'] ?? '—'} ans'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesCard(ProviderProfileLoaded state) {
    final services = state.services;
    if (services.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Aucune spécialité renseignée',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spécialités',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: services
                  .map(
                    (s) => Chip(
                      label: Text(s),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneCard(ProviderProfileLoaded state) {
    final z = state.serviceZone;
    final addr = z['address']?.toString() ?? '—';
    final radius = z['radius'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zone d’intervention',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(addr, style: const TextStyle(fontWeight: FontWeight.w500)),
            if (radius != null) ...[
              const SizedBox(height: 4),
              Text('Rayon : $radius km', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}
