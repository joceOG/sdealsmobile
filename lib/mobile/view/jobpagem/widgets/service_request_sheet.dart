import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../data/services/api_client.dart';
import '../../../../design_system/design_system.dart';
import '../../orderpagem/screens/service_request_summary_screen.dart';
import 'metier_decorative_icon.dart';

/// Bottom sheet « Demander un service » (fiche prestataire).
Future<void> showServiceRequestSheet({
  required BuildContext context,
  required String token,
  required String utilisateurId,
  required String prestataireId,
  required String serviceId,
  required String serviceName,
  required String providerName,
  required num prix,
  ApiClient? apiClient,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ServiceRequestSheet(
      token: token,
      utilisateurId: utilisateurId,
      prestataireId: prestataireId,
      serviceId: serviceId,
      serviceName: serviceName,
      providerName: providerName,
      prix: prix,
      apiClient: apiClient ?? ApiClient(),
    ),
  );
}

class ServiceRequestSheet extends StatefulWidget {
  final String token;
  final String utilisateurId;
  final String prestataireId;
  final String serviceId;
  final String serviceName;
  final String providerName;
  final num prix;
  final ApiClient apiClient;

  const ServiceRequestSheet({
    super.key,
    required this.token,
    required this.utilisateurId,
    required this.prestataireId,
    required this.serviceId,
    required this.serviceName,
    required this.providerName,
    required this.prix,
    required this.apiClient,
  });

  @override
  State<ServiceRequestSheet> createState() => _ServiceRequestSheetState();
}

class _ServiceRequestSheetState extends State<ServiceRequestSheet> {
  final _adresseCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _precisionCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  bool _submitting = false;

  static const _green = Color(0xFF2E7D32);
  static const int _detailsMax = 300;

  @override
  void dispose() {
    _adresseCtrl.dispose();
    _villeCtrl.dispose();
    _precisionCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  String _formatPrice(num prix) {
    final formatted =
        NumberFormat('#,###', 'fr_FR').format(prix.toInt()).replaceAll(',', ' ');
    return '$formatted FCFA';
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _green),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _green, width: 2),
      ),
      alignLabelWithHint: true,
    );
  }

  Future<void> _submit() async {
    final adresse = _adresseCtrl.text.trim();
    final ville = _villeCtrl.text.trim();
    final details = _detailsCtrl.text.trim();
    final precision = _precisionCtrl.text.trim();

    void warn(String msg) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (adresse.isEmpty) {
      warn('Veuillez saisir une adresse');
      return;
    }
    if (ville.isEmpty) {
      warn('Veuillez saisir une ville');
      return;
    }
    if (details.isEmpty) {
      warn('Veuillez décrire votre demande');
      return;
    }

    final notes = [
      if (precision.isNotEmpty) 'Précision: $precision',
      details,
    ].join('\n');

    setState(() => _submitting = true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: _green),
                SizedBox(height: 16),
                Text('Envoi en cours...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final created = await widget.apiClient.createPrestation(
        token: widget.token,
        utilisateurId: widget.utilisateurId,
        prestataireId: widget.prestataireId,
        serviceId: widget.serviceId,
        adresse: adresse,
        ville: ville,
        notesClient: notes,
        montant: widget.prix > 0 ? widget.prix : null,
      );

      if (!mounted) return;
      Navigator.pop(context); // loader
      Navigator.pop(context); // sheet

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Demande envoyée avec succès'),
          backgroundColor: _green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      final requestId = created['_id']?.toString();
      if (requestId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceRequestSummaryScreen(
              requestId: requestId,
              token: widget.token,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.request_quote_rounded,
                    color: _green,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demander un service',
                        style: SDTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: SDColors.neutral900,
                        ),
                      ),
                      Text(
                        widget.providerName,
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.neutral600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Carte service + icône métier
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 52, bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.auto_awesome,
                            color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Service demandé',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.serviceName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (widget.prix > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatPrice(widget.prix),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: MetierDecorativeIcon(
                      serviceName: widget.serviceName,
                      size: 52,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _adresseCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: _fieldDecoration(
                label: 'Adresse *',
                hint: 'Ex : Cocody, Riviera 3',
                icon: Icons.place_outlined,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _villeCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _fieldDecoration(
                label: 'Ville *',
                hint: 'Ex : Abidjan',
                icon: Icons.location_city_outlined,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _precisionCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: _fieldDecoration(
                label: 'Précision (optionnel)',
                hint: 'Ex : Près du marché, immeuble X...',
                icon: Icons.my_location_outlined,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsCtrl,
              maxLines: 4,
              maxLength: _detailsMax,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: _fieldDecoration(
                label: 'Détails de votre demande *',
                hint:
                    'Décrivez votre besoin, la surface, les matériaux souhaités, etc.',
                icon: Icons.assignment_outlined,
              ).copyWith(
                counterText: '${_detailsCtrl.text.length}/$_detailsMax',
                counterStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bandeau info — texte fusionné (pas de titre gras séparé)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mise en relation gratuite. Le prix se discute ensuite (chat, appel ou sur place).',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _green.withValues(alpha: 0.5),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.send_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Envoyer la demande',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Recevez des offres de prestataires qualifiés',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'Vos informations sont sécurisées',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
