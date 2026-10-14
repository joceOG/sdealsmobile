import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../servicerequestcubit/service_request_cubit.dart';
import '../../chatpagem/screens/chatPageScreenM.dart';
import '../../../data/models/conversation_model.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../data/utils/display_text.dart';
import '../../../../design_system/design_system.dart';
import '../../jobpagem/utils/navigation_helper.dart';

class ServiceRequestSummaryScreen extends StatelessWidget {
  final String requestId;
  final String token;
  const ServiceRequestSummaryScreen(
      {super.key, required this.requestId, required this.token});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ServiceRequestCubit()..getById(token: token, id: requestId),
      child: Scaffold(
        backgroundColor: SDColors.neutral50,
        appBar: AppBar(
          backgroundColor: SDColors.primary50,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: SDColors.neutral900,
          title: Text(
            'Ma demande',
            style: SDTypography.titleMedium.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: BlocBuilder<ServiceRequestCubit, ServiceRequestState>(
          builder: (context, state) {
            if (state is ServiceRequestLoading ||
                state is ServiceRequestInitial) {
              return const Center(
                  child: CircularProgressIndicator(color: SDColors.primary600));
            } else if (state is ServiceRequestError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 64, color: SDColors.error500),
                    SizedBox(height: SDSpacing.md),
                    Text('Erreur: ${state.message}',
                        style: SDTypography.bodyMedium),
                  ],
                ),
              );
            } else if (state is ServiceRequestDetailLoaded) {
              final data = state.data;
              return _buildContent(context, data);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data) {
    final status =
        (data['statut'] ?? data['status'] ?? 'EN_ATTENTE').toString();
    final adresse = data['adresse']?.toString() ?? '';
    final ville = data['ville']?.toString() ?? '';
    final notes = data['notesClient']?.toString() ?? '';
    final photosAvant = data['photosAvant'] as List<dynamic>? ?? [];
    final photosApres = data['photosApres'] as List<dynamic>? ?? [];
    final prestataire = data['prestataire'];
    final prestataireId =
        prestataire is Map ? prestataire['_id']?.toString() : null;
    final user = prestataire is Map ? prestataire['utilisateur'] : null;
    final prestataireName = user is Map
        ? personNameFromMap(Map<String, dynamic>.from(user),
            fallback: 'Prestataire')
        : 'Prestataire';
    final service = data['service'];
    final title = service is Map
        ? (service['nomservice'] ?? service['nom'] ?? 'Demande').toString()
        : (data['serviceName']?.toString().trim().isNotEmpty == true
            ? data['serviceName'].toString()
            : 'Demande');
    final metier = prestataire is Map && prestataire['service'] is Map
        ? (prestataire['service']['nomservice'] ??
                prestataire['service']['nom'])
            ?.toString()
        : null;
    final photo = user is Map ? user['photoProfil']?.toString() : null;
    final sent = data['createdAt'] ?? data['date'];
    final slot = data['datePrestation']?.toString();
    final amount = data['montant'];
    final statusInfo = _getStatusInfo(status);
    final pending = status.toUpperCase() == 'EN_ATTENTE' ||
        status.toUpperCase() == 'PENDING';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            children: [
              Text(
                title,
                style: SDTypography.titleLarge.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: _DetailStatusChip(
                  label: pending
                      ? 'En attente de réponse'
                      : statusInfo['label'] as String,
                  pending: pending,
                ),
              ),
              if (sent != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Envoyée le ${_formatSent(sent.toString())}',
                  style: SDTypography.bodySmall
                      .copyWith(color: SDColors.neutral500),
                ),
              ],
              const SizedBox(height: 16),
              _providerRow(
                context,
                name: prestataireName,
                metier: metier,
                photo: photo,
                providerId: prestataireId,
                providerData: prestataire is Map
                    ? Map<String, dynamic>.from(prestataire)
                    : null,
              ),
              const SizedBox(height: 18),
              Text(
                'Votre besoin',
                style: SDTypography.titleSmall
                    .copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                notes.trim().isEmpty ? 'Aucun détail ajouté.' : notes,
                style: SDTypography.bodyMedium
                    .copyWith(color: SDColors.neutral700),
              ),
              const SizedBox(height: 16),
              _fact(
                Icons.place_outlined,
                'Lieu d’intervention',
                [
                  if (ville.isNotEmpty || adresse.isNotEmpty)
                    [ville, adresse].where((e) => e.isNotEmpty).join(' · ')
                  else
                    'À préciser',
                ].first,
              ),
              _fact(
                Icons.calendar_today_outlined,
                'Créneau',
                slot == null || slot.isEmpty ? 'À convenir' : _formatSent(slot),
              ),
              _fact(
                Icons.payments_outlined,
                'Tarif',
                amount == null ? 'À convenir' : '$amount FCFA',
              ),
              const SizedBox(height: 8),
              Text(
                'Suivi de la demande',
                style: SDTypography.titleSmall
                    .copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              _followStep(
                done: true,
                icon: Icons.check_circle,
                title: 'Demande envoyée',
                subtitle: sent == null ? null : _formatSent(sent.toString()),
              ),
              _followStep(
                done: !pending,
                icon: pending ? Icons.schedule : Icons.check_circle,
                title: pending
                    ? 'Réponse du professionnel attendue'
                    : statusInfo['label'] as String,
                subtitle: null,
              ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SDColors.primary50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: SDColors.primary700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _followNote(status),
                        style: SDTypography.bodySmall
                            .copyWith(color: SDColors.primary800),
                      ),
                    ),
                  ],
                ),
              ),
              if (photosAvant.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildPhotosSection('Photos avant', photosAvant),
              ],
              if (photosApres.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildPhotosSection('Photos après', photosApres),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: prestataireId == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatPageScreenM(
                                  participantId: prestataireId,
                                  participantName: prestataireName,
                                  type: ConversationType.prestataire,
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Écrire au professionnel'),
                    style: FilledButton.styleFrom(
                      backgroundColor: SDColors.primary600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Retour à mes demandes'),
                ),
                if (pending)
                  TextButton(
                    onPressed: () => _confirmAndCancel(context),
                    child: Text(
                      'Annuler la demande',
                      style: SDTypography.labelMedium
                          .copyWith(color: SDColors.error500),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _providerRow(
    BuildContext context, {
    required String name,
    required String? metier,
    required String? photo,
    required String? providerId,
    required Map<String, dynamic>? providerData,
  }) {
    return Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 48,
            height: 48,
            child: photo != null && photo.startsWith('http')
                ? Image.network(photo, fit: BoxFit.cover)
                : ColoredBox(
                    color: SDColors.neutral100,
                    child: Icon(Icons.person, color: SDColors.neutral400),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: SDTypography.titleSmall
                    .copyWith(fontWeight: FontWeight.w800),
              ),
              if (metier != null && metier.isNotEmpty)
                Text(
                  metier,
                  style: SDTypography.bodySmall
                      .copyWith(color: SDColors.neutral500),
                ),
            ],
          ),
        ),
        if (providerId != null)
          TextButton(
            onPressed: () => NavigationHelper.navigateToProviderProfile(
              context,
              providerId: providerId,
              providerData: providerData,
            ),
            child: const Text('Voir le profil >'),
          ),
      ],
    );
  }

  Widget _fact(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: SDColors.primary700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: SDTypography.labelMedium
                      .copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  value,
                  style: SDTypography.bodySmall
                      .copyWith(color: SDColors.neutral600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _followStep({
    required bool done,
    required IconData icon,
    required String title,
    required String? subtitle,
  }) {
    final color = done ? SDColors.primary700 : SDColors.neutral400;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: SDTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w700)),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: SDTypography.bodySmall
                        .copyWith(color: SDColors.neutral500),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _followNote(String status) {
    switch (status.toUpperCase()) {
      case 'ACCEPTEE':
        return 'Le professionnel a accepté la demande.';
      case 'EN_COURS':
      case 'IN_PROGRESS':
        return 'L’intervention est en cours.';
      case 'TERMINEE':
      case 'DONE':
      case 'COMPLETED':
        return 'L’intervention est terminée.';
      case 'ANNULEE':
      case 'CANCELLED':
      case 'CANCELED':
        return 'La demande a été annulée.';
      case 'REFUSEE':
        return 'Le professionnel a refusé la demande.';
      default:
        return 'L’intervention n’est pas encore confirmée.';
    }
  }

  String _formatSent(String raw) {
    try {
      final date = DateTime.parse(raw).toLocal();
      return DateFormat('d MMMM à HH:mm', 'fr_FR').format(date);
    } catch (_) {
      return raw;
    }
  }

  Widget _buildPhotosSection(String title, List<dynamic> photos) {
    return Container(
      padding: EdgeInsets.all(SDSpacing.md),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: SDColors.neutral200.withOpacity(0.5),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library, color: SDColors.primary600),
              SizedBox(width: SDSpacing.xs),
              Text(
                title,
                style: SDTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: SDSpacing.sm),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photoUrl = photos[index]?.toString() ?? '';
                return Container(
                  width: 120,
                  margin: EdgeInsets.only(right: SDSpacing.xs),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(SDSpacing.borderRadiusMedium),
                    border: Border.all(color: SDColors.neutral200),
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(SDSpacing.borderRadiusMedium),
                    child: CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: SDColors.neutral100,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: SDColors.primary600,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: SDColors.neutral100,
                        child: Icon(Icons.error, color: SDColors.error500),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la commande'),
        content: const Text(
          'Voulez-vous vraiment annuler cette demande de service ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: SDColors.error500),
            child: const Text('Oui, annuler',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final auth = context.read<AuthCubit>().state;
    final authToken = auth is AuthAuthenticated ? auth.token : token;
    if (authToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connexion requise pour annuler',
            style: SDTypography.bodyMedium.copyWith(color: SDColors.white),
          ),
          backgroundColor: SDColors.error500,
        ),
      );
      return;
    }

    try {
      await ApiClient().updatePrestationStatus(
        token: authToken,
        prestationId: requestId,
        newStatus: 'ANNULEE',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Commande annulée',
            style: SDTypography.bodyMedium.copyWith(color: SDColors.white),
          ),
          backgroundColor: SDColors.success500,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible d\'annuler : $e',
            style: SDTypography.bodyMedium.copyWith(color: SDColors.white),
          ),
          backgroundColor: SDColors.error500,
        ),
      );
    }
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status.toUpperCase()) {
      case 'EN_ATTENTE':
      case 'PENDING':
        return {'label': 'En attente'};
      case 'ACCEPTEE':
        return {'label': 'Acceptée'};
      case 'REFUSEE':
        return {'label': 'Refusée'};
      case 'EN_COURS':
      case 'IN_PROGRESS':
        return {'label': 'En cours'};
      case 'TERMINEE':
      case 'DONE':
      case 'COMPLETED':
        return {'label': 'Terminée'};
      case 'ANNULEE':
      case 'CANCELLED':
      case 'CANCELED':
        return {'label': 'Annulée'};
      case 'LITIGE':
        return {'label': 'Litige'};
      default:
        return {'label': status};
    }
  }
}

class _DetailStatusChip extends StatelessWidget {
  const _DetailStatusChip({required this.label, required this.pending});

  final String label;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final bg = pending ? SDColors.warning100 : SDColors.primary50;
    final fg = pending ? SDColors.warning700 : SDColors.primary700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(pending ? Icons.schedule : Icons.check_circle,
              size: 14, color: fg),
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
