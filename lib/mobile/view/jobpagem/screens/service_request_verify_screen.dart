import 'package:flutter/material.dart';
import '../../../../design_system/design_system.dart';
import '../../orderpagem/screens/service_request_summary_screen.dart';
import '../widgets/service_request_draft.dart';
import '../widgets/service_request_flow_widgets.dart';

/// Étape 2 — Vérifier avant envoi API.
class ServiceRequestVerifyScreen extends StatefulWidget {
  final ServiceRequestContext requestContext;
  final ServiceRequestDraft draft;

  const ServiceRequestVerifyScreen({
    super.key,
    required this.requestContext,
    required this.draft,
  });

  @override
  State<ServiceRequestVerifyScreen> createState() =>
      _ServiceRequestVerifyScreenState();
}

class _ServiceRequestVerifyScreenState extends State<ServiceRequestVerifyScreen> {
  bool _submitting = false;

  Future<void> _send() async {
    setState(() => _submitting = true);
    try {
      final created = await submitServiceRequest(
        context: widget.requestContext,
        draft: widget.draft,
      );
      if (!mounted) return;
      final requestId = created['_id']?.toString() ?? '';
      final nav = Navigator.of(context);
      nav.pop(); // fermer vérification
      nav.pop(); // fermer le bottom sheet
      nav.push(
        MaterialPageRoute(
          builder: (_) => ServiceRequestSentScreen(
            requestContext: widget.requestContext,
            draft: widget.draft,
            requestId: requestId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: SDColors.error500,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctx = widget.requestContext;
    final draft = widget.draft;

    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: AppBar(
        backgroundColor: SDColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: SDColors.neutral900,
          onPressed: _submitting ? null : () => Navigator.pop(context),
        ),
        title: Text(
          'Vérifier ma demande',
          style: SDTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: SDColors.neutral900,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vérifiez les informations avant l\'envoi.',
                      style: SDTypography.bodyMedium.copyWith(
                        color: SDColors.neutral600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ServiceRequestProviderPreview(context: ctx),
                    const SizedBox(height: 24),
                    ServiceRequestRecapSection(
                      title: 'Besoin',
                      value: draft.besoin.trim(),
                    ),
                    const SizedBox(height: 20),
                    ServiceRequestRecapSection(
                      title: 'Lieu d\'intervention',
                      value: draft.lieuAffiche,
                    ),
                    if (draft.precisionLieu.trim().isNotEmpty) ...[
                      const SizedBox(height: 20),
                      ServiceRequestRecapSection(
                        title: 'Précisions sur le lieu',
                        value: draft.precisionLieu.trim(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: _submitting ? null : () => Navigator.pop(context),
                      icon: Icon(Icons.edit_outlined,
                          size: 18, color: SDColors.primary700),
                      label: Text(
                        'Modifier les informations',
                        style: SDTypography.labelLarge.copyWith(
                          color: SDColors.primary700,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const ServiceRequestInfoBanner(
                      message:
                          'Cette demande ne confirme pas encore une intervention.',
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  serviceRequestPrimaryButton(
                    label: 'Envoyer la demande',
                    trailingIcon: Icons.arrow_forward_rounded,
                    onPressed: _submitting ? null : _send,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Vous recevrez la réponse du professionnel.',
                    textAlign: TextAlign.center,
                    style: SDTypography.labelSmall.copyWith(
                      color: SDColors.neutral500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_submitting) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: CircularProgressIndicator(
                        color: SDColors.primary700,
                        strokeWidth: 2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Étape 3 — Succès (uniquement après API 201).
class ServiceRequestSentScreen extends StatelessWidget {
  final ServiceRequestContext requestContext;
  final ServiceRequestDraft draft;
  final String requestId;

  const ServiceRequestSentScreen({
    super.key,
    required this.requestContext,
    required this.draft,
    required this.requestId,
  });

  String _besoinShort() {
    final t = draft.besoin.trim();
    if (t.length <= 80) return t;
    return '${t.substring(0, 77)}…';
  }

  @override
  Widget build(BuildContext context) {
    final name = requestContext.providerName;

    return Scaffold(
      backgroundColor: SDColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: SDColors.primary50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 40,
                          color: SDColors.primary700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Demande envoyée',
                        style: SDTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: SDColors.neutral900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Votre demande a été transmise à $name.',
                        textAlign: TextAlign.center,
                        style: SDTypography.bodyMedium.copyWith(
                          color: SDColors.neutral600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: SDColors.primary50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: SDColors.primary100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule,
                                size: 16, color: SDColors.primary700),
                            const SizedBox(width: 6),
                            Text(
                              'En attente de réponse',
                              style: SDTypography.labelMedium.copyWith(
                                color: SDColors.primary700,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: SDColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: SDColors.neutral200),
                          boxShadow: [
                            BoxShadow(
                              color: SDColors.neutral900.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ServiceRequestProviderPreview(
                                context: requestContext),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Divider(height: 1),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.build_outlined,
                                    size: 18, color: SDColors.neutral600),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _besoinShort(),
                                    style: SDTypography.bodySmall.copyWith(
                                      color: SDColors.neutral800,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.place_outlined,
                                    size: 18, color: SDColors.neutral600),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    draft.lieuAffiche,
                                    style: SDTypography.bodySmall.copyWith(
                                      color: SDColors.neutral800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const ServiceRequestInfoBanner(
                        message:
                            'L\'intervention sera confirmée après son accord.',
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    serviceRequestPrimaryButton(
                      label: 'Voir ma demande',
                      onPressed: requestId.isEmpty
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ServiceRequestSummaryScreen(
                                    requestId: requestId,
                                    token: requestContext.token,
                                  ),
                                ),
                              );
                            },
                    ),
                    const SizedBox(height: 10),
                    serviceRequestOutlineButton(
                      label: 'Retour au profil',
                      onPressed: () => Navigator.of(context).pop(),
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
}
