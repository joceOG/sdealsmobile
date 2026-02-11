import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../servicerequestcubit/service_request_cubit.dart';
import '../../chatpagem/screens/chatPageScreenM.dart';
import '../../../data/models/conversation_model.dart';
import '../../../../design_system/design_system.dart';

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
          title: const Text('Suivi de commande'),
          backgroundColor: SDColors.primary600,
          foregroundColor: SDColors.white,
          elevation: 0,
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
                    Icon(Icons.error_outline, size: 64, color: SDColors.error500),
                    SizedBox(height: SDSpacing.md),
                    Text('Erreur: ${state.message}', style: SDTypography.bodyMedium),
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
    final status = data['statut']?.toString() ?? 'EN_ATTENTE';
    final adresse = data['adresse']?.toString() ?? '';
    final ville = data['ville']?.toString() ?? '';
    final notes = data['notesClient']?.toString() ?? '';
    final historiqueStatuts = data['historiqueStatuts'] as List<dynamic>? ?? [];
    final photosAvant = data['photosAvant'] as List<dynamic>? ?? [];
    final photosApres = data['photosApres'] as List<dynamic>? ?? [];
    final prestataire = data['prestataire'];
    final prestataireId = prestataire?['_id']?.toString();
    final prestataireName = prestataire?['utilisateur']?['nom']?.toString() ?? 'Prestataire';
    final utilisateur = data['utilisateur'];
    final utilisateurId = utilisateur?['_id']?.toString();

    return SingleChildScrollView(
      padding: EdgeInsets.all(SDSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec statut
          _buildStatusHeader(status),
          SizedBox(height: SDSpacing.md),
          
          // Timeline visuelle améliorée
          _buildTimelineSection(historiqueStatuts, status),
          SizedBox(height: SDSpacing.md),
          
          // Informations de la commande
          _buildInfoSection(adresse, ville, notes),
          SizedBox(height: SDSpacing.md),
          
          // Photos avant
          if (photosAvant.isNotEmpty) ...[
            _buildPhotosSection('Photos avant', photosAvant),
            SizedBox(height: SDSpacing.md),
          ],
          
          // Photos après
          if (photosApres.isNotEmpty) ...[
            _buildPhotosSection('Photos après', photosApres),
            SizedBox(height: SDSpacing.md),
          ],
          
          // Actions rapides
          _buildActionButtons(context, prestataireId, prestataireName, status),
          SizedBox(height: SDSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(String status) {
    final statusInfo = _getStatusInfo(status);
    return Container(
      padding: EdgeInsets.all(SDSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusInfo['color']!.withOpacity(0.1), SDColors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
        border: Border.all(color: statusInfo['color']!.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(SDSpacing.sm),
            decoration: BoxDecoration(
              color: statusInfo['color'],
              shape: BoxShape.circle,
            ),
            child: Icon(statusInfo['icon'], color: SDColors.white, size: 24),
          ),
          SizedBox(width: SDSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statut de la commande',
                  style: SDTypography.bodySmall.copyWith(color: SDColors.neutral600),
                ),
                SizedBox(height: SDSpacing.xxxs),
                Text(
                  statusInfo['label']!,
                  style: SDTypography.titleMedium.copyWith(
                    color: statusInfo['color'],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(List<dynamic> historiqueStatuts, String currentStatus) {
    final statusSteps = [
      {'key': 'EN_ATTENTE', 'label': 'En attente', 'icon': Icons.hourglass_empty},
      {'key': 'ACCEPTEE', 'label': 'Acceptée', 'icon': Icons.check_circle_outline},
      {'key': 'EN_COURS', 'label': 'En cours', 'icon': Icons.play_circle_outline},
      {'key': 'TERMINEE', 'label': 'Terminée', 'icon': Icons.done_all},
    ];

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
              Icon(Icons.timeline, color: SDColors.primary600),
              SizedBox(width: SDSpacing.xs),
              Text(
                'Timeline de la commande',
                style: SDTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: SDColors.neutral900,
                ),
              ),
            ],
          ),
          SizedBox(height: SDSpacing.md),
          ...statusSteps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final stepKey = step['key'] as String;
            final isCompleted = _isStatusCompleted(stepKey, currentStatus);
            final isCurrent = stepKey == currentStatus;
            final historiqueItem = historiqueStatuts.firstWhere(
              (h) => h['statut'] == stepKey,
              orElse: () => null,
            );
            final dateStr = historiqueItem?['date']?.toString();

            return _buildTimelineStep(
              step['label'] as String,
              step['icon'] as IconData,
              isCompleted,
              isCurrent,
              dateStr,
              index < statusSteps.length - 1,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(
    String label,
    IconData icon,
    bool isCompleted,
    bool isCurrent,
    String? dateStr,
    bool showLine,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? SDColors.primary600
                    : SDColors.neutral200,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrent ? SDColors.primary700 : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Icon(
                icon,
                color: isCompleted || isCurrent ? SDColors.white : SDColors.neutral400,
                size: 20,
              ),
            ),
            if (showLine)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? SDColors.primary600 : SDColors.neutral200,
                margin: EdgeInsets.symmetric(vertical: SDSpacing.xxxs),
              ),
          ],
        ),
        SizedBox(width: SDSpacing.sm),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: SDSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: SDTypography.bodyMedium.copyWith(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted || isCurrent
                        ? SDColors.neutral900
                        : SDColors.neutral500,
                  ),
                ),
                if (dateStr != null && (isCompleted || isCurrent)) ...[
                  SizedBox(height: SDSpacing.xxxs),
                  Text(
                    _formatDate(dateStr),
                    style: SDTypography.bodySmall.copyWith(
                      color: SDColors.neutral600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String adresse, String ville, String notes) {
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
              Icon(Icons.info_outline, color: SDColors.primary600),
              SizedBox(width: SDSpacing.xs),
              Text(
                'Informations',
                style: SDTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: SDSpacing.sm),
          if (adresse.isNotEmpty)
            _buildInfoRow(Icons.location_on, 'Adresse', adresse),
          if (ville.isNotEmpty)
            _buildInfoRow(Icons.location_city, 'Ville', ville),
          if (notes.isNotEmpty)
            _buildInfoRow(Icons.note, 'Notes', notes),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: SDSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: SDColors.neutral500),
          SizedBox(width: SDSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: SDTypography.bodySmall.copyWith(color: SDColors.neutral600),
                ),
                SizedBox(height: SDSpacing.xxxs),
                Text(
                  value,
                  style: SDTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                    borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                    border: Border.all(color: SDColors.neutral200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
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

  Widget _buildActionButtons(
    BuildContext context,
    String? prestataireId,
    String prestataireName,
    String status,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: prestataireId != null
              ? () {
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
                }
              : null,
          icon: Icon(Icons.chat_bubble_outline, color: SDColors.white),
          label: Text(
            'Contacter le prestataire',
            style: SDTypography.labelMedium.copyWith(color: SDColors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: SDColors.primary600,
            padding: EdgeInsets.symmetric(vertical: SDSpacing.sm),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
            ),
          ),
        ),
        if (status == 'EN_ATTENTE') ...[
          SizedBox(height: SDSpacing.sm),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Implémenter annulation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Annulation à implémenter',
                      style: SDTypography.bodyMedium.copyWith(color: SDColors.white)),
                  backgroundColor: SDColors.warning500,
                ),
              );
            },
            icon: Icon(Icons.cancel_outlined, color: SDColors.error500),
            label: Text(
              'Annuler la commande',
              style: SDTypography.labelMedium.copyWith(color: SDColors.error500),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: SDColors.error500),
              padding: EdgeInsets.symmetric(vertical: SDSpacing.sm),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'EN_ATTENTE':
        return {
          'label': 'En attente',
          'icon': Icons.hourglass_empty,
          'color': SDColors.warning500,
        };
      case 'ACCEPTEE':
        return {
          'label': 'Acceptée',
          'icon': Icons.check_circle,
          'color': SDColors.success500,
        };
      case 'REFUSEE':
        return {
          'label': 'Refusée',
          'icon': Icons.cancel,
          'color': SDColors.error500,
        };
      case 'EN_COURS':
        return {
          'label': 'En cours',
          'icon': Icons.play_circle,
          'color': SDColors.info500,
        };
      case 'TERMINEE':
        return {
          'label': 'Terminée',
          'icon': Icons.done_all,
          'color': SDColors.success500,
        };
      default:
        return {
          'label': status,
          'icon': Icons.info,
          'color': SDColors.neutral500,
        };
    }
  }

  bool _isStatusCompleted(String stepKey, String currentStatus) {
    final order = ['EN_ATTENTE', 'ACCEPTEE', 'EN_COURS', 'TERMINEE'];
    final currentIndex = order.indexOf(currentStatus);
    final stepIndex = order.indexOf(stepKey);
    return stepIndex >= 0 && currentIndex >= 0 && stepIndex < currentIndex;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return DateFormat('dd/MM/yyyy à HH:mm').format(date);
      } else if (difference.inHours > 0) {
        return 'Il y a ${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return 'Il y a ${difference.inMinutes}min';
      } else {
        return 'À l\'instant';
      }
    } catch (e) {
      return dateString;
    }
  }
}
