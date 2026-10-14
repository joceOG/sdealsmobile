import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/services/api_client.dart';
import '../../../../design_system/design_system.dart';
import '../screens/service_request_verify_screen.dart';
import 'service_request_draft.dart';
import 'service_request_flow_widgets.dart';

/// Ouvre le parcours « Demander un service » (étape 1 en bottom sheet).
Future<void> showServiceRequestSheet({
  required BuildContext context,
  required String token,
  required String utilisateurId,
  required String prestataireId,
  required String serviceId,
  required String serviceName,
  required String providerName,
  required num prix,
  String? providerPhotoUrl,
  String? providerMetier,
  ApiClient? apiClient,
}) {
  final requestContext = ServiceRequestContext(
    token: token,
    utilisateurId: utilisateurId,
    prestataireId: prestataireId,
    serviceId: serviceId,
    serviceName: serviceName,
    providerName: providerName,
    providerMetier: providerMetier ?? serviceName,
    providerPhotoUrl: providerPhotoUrl,
    prix: prix,
    apiClient: apiClient ?? ApiClient(),
  );

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ServiceRequestSheetStepOne(requestContext: requestContext),
  );
}

class ServiceRequestSheetStepOne extends StatefulWidget {
  final ServiceRequestContext requestContext;

  const ServiceRequestSheetStepOne({super.key, required this.requestContext});

  @override
  State<ServiceRequestSheetStepOne> createState() =>
      _ServiceRequestSheetStepOneState();
}

class _ServiceRequestSheetStepOneState extends State<ServiceRequestSheetStepOne> {
  final _adresseCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _precisionCtrl = TextEditingController();
  final _besoinCtrl = TextEditingController();

  @override
  void dispose() {
    _adresseCtrl.dispose();
    _villeCtrl.dispose();
    _precisionCtrl.dispose();
    _besoinCtrl.dispose();
    super.dispose();
  }

  void _warn(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: SDColors.warning500,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _goToVerify() {
    final draft = ServiceRequestDraft(
      besoin: _besoinCtrl.text,
      adresse: _adresseCtrl.text,
      ville: _villeCtrl.text,
      precisionLieu: _precisionCtrl.text,
    );
    final error = draft.validateForVerification();
    if (error != null) {
      _warn(error);
      return;
    }

    final ctx = widget.requestContext;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceRequestVerifyScreen(
          requestContext: ctx,
          draft: draft,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final ctx = widget.requestContext;

    return Container(
      decoration: const BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: bottomInset + 16,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: SDColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demander un service',
                        style: SDTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: SDColors.neutral900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Décrivez votre besoin à ce professionnel.',
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: SDColors.neutral500),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ServiceRequestProviderPreview(context: ctx),
            const SizedBox(height: 20),
            TextField(
              controller: _besoinCtrl,
              maxLines: 4,
              maxLength: ServiceRequestDraft.besoinMaxLength,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: serviceRequestFieldDecoration(
                label: 'Votre besoin *',
                hint:
                    'Ex. : Le robinet de ma cuisine fuit, même lorsqu\'il est fermé.',
                icon: Icons.edit_note_outlined,
              ).copyWith(
                counterText:
                    '${_besoinCtrl.text.length}/${ServiceRequestDraft.besoinMaxLength}',
              ),
              style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral900),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _adresseCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: serviceRequestFieldDecoration(
                label: 'Lieu d\'intervention *',
                hint: 'Ex. : Cocody · Angré',
                icon: Icons.place_outlined,
              ),
              style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral900),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _villeCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: serviceRequestFieldDecoration(
                label: 'Ville *',
                hint: 'Ex. : Abidjan',
                icon: Icons.location_city_outlined,
              ),
              style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral900),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _precisionCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: serviceRequestFieldDecoration(
                label: 'Précisions sur le lieu (facultatif)',
                hint: 'Ex. : Près du carrefour des Oscars',
                icon: Icons.my_location_outlined,
              ),
              style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral900),
            ),
            const SizedBox(height: 16),
            const ServiceRequestInfoBanner(
              message:
                  'Le tarif et le créneau seront à convenir avec le professionnel.',
            ),
            const SizedBox(height: 18),
            serviceRequestPrimaryButton(
              label: 'Vérifier ma demande',
              onPressed: _goToVerify,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
