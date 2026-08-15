import 'package:flutter/material.dart';
import 'package:sdealsmobile/mobile/view/seller_registration/screens/steps/seller_shop_info_step.dart';
import 'package:sdealsmobile/mobile/view/seller_registration/screens/steps/seller_personal_info_step.dart';
import 'package:sdealsmobile/mobile/view/seller_registration/screens/steps/seller_products_step.dart';
import 'package:sdealsmobile/mobile/view/seller_registration/screens/steps/seller_verification_step.dart';
import 'package:sdealsmobile/mobile/view/seller_registration/screens/steps/seller_payment_step.dart';
import '../../../../design_system/design_system.dart';

class SellerFormScreen extends StatefulWidget {
  final Set<String>? preSelectedCategories;
  final Set<String>? preSelectedProducts;

  const SellerFormScreen({
    Key? key,
    this.preSelectedCategories,
    this.preSelectedProducts,
  }) : super(key: key);

  @override
  _SellerFormScreenState createState() => _SellerFormScreenState();
}

class _SellerFormScreenState extends State<SellerFormScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Données du formulaire
  final Map<String, dynamic> formData = {};

  // Liste des étapes
  late List<Step> _formSteps;

  @override
  void initState() {
    super.initState();
    // Initialiser les données pré-sélectionnées
    if (widget.preSelectedCategories != null) {
      formData['categories'] = widget.preSelectedCategories!.toList();
    } else {
      formData['categories'] = <String>[];
    }
    
    // Note: preSelectedProducts pourrait être utilisé ailleurs ou stocké, 
    // mais le modèle de données actuel des étapes semble utiliser 'categories'.
    // J'ajoute une clé générique pour conserver l'info.
    if (widget.preSelectedProducts != null) {
       formData['initialProducts'] = widget.preSelectedProducts;
    }

    _buildFormSteps();
  }

  void _updateFormData(Map<String, dynamic> newData) {
    setState(() {
      formData.addAll(newData);
    });
  }

  void _buildFormSteps() {
    _formSteps = [
      Step(
        title: const Text('Boutique'),
        content: SellerShopInfoStep(
          formData: formData,
          updateFormData: _updateFormData,
        ),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Vendeur'),
        content: SellerPersonalInfoStep(
          formData: formData,
          updateFormData: _updateFormData,
        ),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Produits'),
        content: SellerProductsStep(
          formData: formData,
          updateFormData: _updateFormData,
        ),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Vérification'),
        content: SellerVerificationStep(
          formData: formData,
          updateFormData: _updateFormData,
        ),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Paiement'),
        content: SellerPaymentStep(
          formData: formData,
          updateFormData: _updateFormData,
        ),
        isActive: _currentStep >= 4,
        state: _currentStep > 4 ? StepState.complete : StepState.indexed,
      ),
    ];
  }

  void _nextStep() {
    if (_currentStep < _formSteps.length - 1) {
      // Validation simple: on suppose que les Steps enfants gèrent leur validation interne via le Form parent
      // ou sauvegardent leurs données via updateFormData.
      // Ici on force la validation du Form global qui englobe le Step courant.
      if (_formKey.currentState!.validate()) {
          setState(() {
            _currentStep++;
            _buildFormSteps(); // Rebuild pour mettre à jour les états 'isActive'/'state'
          });
      }
    } else {
      // Soumettre le formulaire
      _submitForm();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _buildFormSteps();
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // Afficher un dialogue de confirmation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Félicitations !', style: SDTypography.titleLarge),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Votre boutique a été créée avec succès.',
                style: SDTypography.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Vos documents sont en cours de vérification. Vous recevrez une notification dès que votre compte sera validé (généralement sous 24h).',
                style: SDTypography.bodySmall.copyWith(color: SDColors.neutral600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Retourner à la page d'accueil ou Dashboard
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text(
                'ACCÉDER À MA BOUTIQUE',
                style: SDTypography.labelLarge.copyWith(color: SDColors.secondary700),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: SDWhiteAppBar.appBar(
        title: 'Création de Boutique',
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.horizontal, // Horizontal pour gagner de la place vu qu'il y a 5 étapes
          physics: const ClampingScrollPhysics(),
          currentStep: _currentStep,
          onStepContinue: _nextStep,
          onStepCancel: _previousStep,
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 24.0, bottom: 24.0),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: SDColors.neutral300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('RETOUR', style: SDTypography.titleMedium.copyWith(color: SDColors.neutral700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                      child: ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SDColors.secondary700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          _currentStep < _formSteps.length - 1 ? 'SUIVANT' : 'TERMINER',
                          style: SDTypography.titleMedium.copyWith(color: SDColors.white),
                        ),
                      ),
                  ),
                ],
              ),
            );
          },
          steps: _formSteps,
        ),
      ),
    );
  }
}
