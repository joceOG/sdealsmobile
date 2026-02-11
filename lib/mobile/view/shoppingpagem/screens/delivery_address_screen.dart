import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:sdealsmobile/mobile/view/common/utils/app_snackbar.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/models/cart_model.dart';
import '../shoppingpageblocm/shoppingPageBlocM.dart';
import '../shoppingpageblocm/shoppingPageEventM.dart';
import '../shoppingpageblocm/shoppingPageStateM.dart';
// ✅ Design System
import '../../../../design_system/design_system.dart';

/// 📍 Écran de gestion de l'adresse de livraison
class DeliveryAddressScreen extends StatefulWidget {
  final DeliveryAddress? currentAddress;
  final Function(DeliveryAddress)? onAddressSaved;

  const DeliveryAddressScreen({
    super.key,
    this.currentAddress,
    this.onAddressSaved,
  });

  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs pour les champs de formulaire
  late TextEditingController _nomController;
  late TextEditingController _telephoneController;
  late TextEditingController _adresseController;
  late TextEditingController _villeController;
  late TextEditingController _codePostalController;
  late TextEditingController _paysController;
  late TextEditingController _instructionsController;

  @override
  void initState() {
    super.initState();

    // Initialiser les contrôleurs avec les valeurs existantes si disponibles
    final addr = widget.currentAddress;
    _nomController = TextEditingController(text: addr?.nom ?? '');
    _telephoneController = TextEditingController(text: addr?.telephone ?? '');
    _adresseController = TextEditingController(text: addr?.adresse ?? '');
    _villeController = TextEditingController(text: addr?.ville ?? '');
    _codePostalController = TextEditingController(text: addr?.codePostal ?? '');
    _paysController =
        TextEditingController(text: addr?.pays ?? 'République du Congo');
    _instructionsController =
        TextEditingController(text: addr?.instructions ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _codePostalController.dispose();
    _paysController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      // Récupérer l'ID utilisateur
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthAuthenticated) {
        // Dispatch l'événement au BLoC
        context.read<ShoppingPageBlocM>().add(
              UpdateDeliveryAddressEvent(
                userId: authState.utilisateur.idutilisateur,
                nom: _nomController.text.trim(),
                telephone: _telephoneController.text.trim(),
                adresse: _adresseController.text.trim(),
                ville: _villeController.text.trim(),
                codePostal: _codePostalController.text.trim(),
                pays: _paysController.text.trim(),
                instructions: _instructionsController.text.trim().isNotEmpty
                    ? _instructionsController.text.trim()
                    : null,
              ),
            );

        // Créer l'objet DeliveryAddress pour le callback
        final address = DeliveryAddress(
          nom: _nomController.text.trim(),
          telephone: _telephoneController.text.trim(),
          adresse: _adresseController.text.trim(),
          ville: _villeController.text.trim(),
          codePostal: _codePostalController.text.trim(),
          pays: _paysController.text.trim(),
          instructions: _instructionsController.text.trim().isNotEmpty
              ? _instructionsController.text.trim()
              : null,
        );

        // Callback optionnel
        if (widget.onAddressSaved != null) {
          widget.onAddressSaved!(address);
        }

        // Feedback et retour
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: SDColors.white),
                SizedBox(width: SDSpacing.xs),
                Text('Adresse de livraison enregistrée',
                    style: SDTypography.bodyMedium.copyWith(color: SDColors.white)),
              ],
            ),
            backgroundColor: SDColors.success500,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.of(context).pop(address);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Adresse de livraison',
          style: SDTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: SDColors.white),
        ),
        backgroundColor: SDColors.primary600,
        elevation: 0,
      ),
      body: BlocListener<ShoppingPageBlocM, ShoppingPageStateM>(
        listener: (context, state) {
          if (state.cartError != null) {
            AppSnackBar.error(context, state.cartError!);
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(SDSpacing.sm),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec icône
                Container(
                  padding: EdgeInsets.all(SDSpacing.sm),
                  decoration: BoxDecoration(
                    color: SDColors.success50,
                    borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(SDSpacing.xs),
                        decoration: BoxDecoration(
                          color: SDColors.success100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: SDColors.success700,
                          size: 32,
                        ),
                      ),
                      SizedBox(width: SDSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Livraison à domicile',
                              style: SDTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: SDSpacing.xxxs),
                            Text(
                              'Remplissez vos coordonnées de livraison',
                              style: SDTypography.bodySmall.copyWith(
                                color: SDColors.neutral500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: SDSpacing.md),

                // Formulaire
                _buildTextField(
                  controller: _nomController,
                  label: 'Nom complet',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer votre nom';
                    }
                    return null;
                  },
                ),
                SizedBox(height: SDSpacing.sm),

                _buildTextField(
                  controller: _telephoneController,
                  label: 'Téléphone',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer votre numéro de téléphone';
                    }
                    if (value.trim().length < 9) {
                      return 'Numéro de téléphone invalide';
                    }
                    return null;
                  },
                ),
                SizedBox(height: SDSpacing.sm),

                _buildTextField(
                  controller: _adresseController,
                  label: 'Adresse complète',
                  icon: Icons.home,
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer votre adresse';
                    }
                    return null;
                  },
                ),
                SizedBox(height: SDSpacing.sm),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _villeController,
                        label: 'Ville',
                        icon: Icons.location_city,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Requis';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: SDSpacing.xs),
                    Expanded(
                      child: _buildTextField(
                        controller: _codePostalController,
                        label: 'Code postal',
                        icon: Icons.markunread_mailbox,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SDSpacing.sm),

                _buildTextField(
                  controller: _paysController,
                  label: 'Pays',
                  icon: Icons.flag,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer votre pays';
                    }
                    return null;
                  },
                ),
                SizedBox(height: SDSpacing.sm),

                _buildTextField(
                  controller: _instructionsController,
                  label: 'Instructions de livraison (optionnel)',
                  icon: Icons.note,
                  maxLines: 3,
                  hintText:
                      'Ex: Appartement 3, 2ème étage, sonnez au portail...',
                ),
                SizedBox(height: SDSpacing.lg),

                // Bouton de sauvegarde
                BlocBuilder<ShoppingPageBlocM, ShoppingPageStateM>(
                  builder: (context, state) {
                    final isLoading = state.isCartLoading;
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _saveAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SDColors.success500,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                          ),
                          elevation: 2,
                        ),
                        child: isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      SDColors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save, color: SDColors.white),
                                  SizedBox(width: SDSpacing.xs),
                                  Text(
                                    'Enregistrer l\'adresse',
                                    style: SDTypography.labelMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: SDColors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: SDTypography.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: SDTypography.bodyMedium,
        hintText: hintText,
        hintStyle: SDTypography.bodyMedium.copyWith(color: SDColors.neutral400),
        prefixIcon: Icon(icon, color: SDColors.primary600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
          borderSide: BorderSide(color: SDColors.neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
          borderSide: BorderSide(color: SDColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
          borderSide: BorderSide(color: SDColors.primary600, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
          borderSide: BorderSide(color: SDColors.error500),
        ),
        filled: true,
        fillColor: SDColors.neutral50,
      ),
    );
  }
}
