import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../../design_system/colors.dart';
import '../../../../../design_system/typography.dart';

class SellerVerificationStep extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) updateFormData;

  const SellerVerificationStep({
    Key? key,
    required this.formData,
    required this.updateFormData,
  }) : super(key: key);

  @override
  _SellerVerificationStepState createState() => _SellerVerificationStepState();
}

class _SellerVerificationStepState extends State<SellerVerificationStep> {
  XFile? _idFrontImage;
  XFile? _idBackImage;
  XFile? _businessRegistrationImage;
  XFile? _businessLicenseImage;
  
  String? _selectedBusinessType;
  bool _showBusinessDocs = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.formData.containsKey('idFrontPath')) {
      _idFrontImage = XFile(widget.formData['idFrontPath']);
    }
    
    if (widget.formData.containsKey('idBackPath')) {
      _idBackImage = XFile(widget.formData['idBackPath']);
    }
    
    if (widget.formData.containsKey('businessRegistrationPath')) {
      _businessRegistrationImage = XFile(widget.formData['businessRegistrationPath']);
    }
    
    if (widget.formData.containsKey('businessLicensePath')) {
      _businessLicenseImage = XFile(widget.formData['businessLicensePath']);
    }
    
    // Déterminer si c'est une entreprise pour afficher les champs supplémentaires
    if (widget.formData.containsKey('businessType')) {
      _selectedBusinessType = widget.formData['businessType'];
      _showBusinessDocs = _selectedBusinessType == 'Entreprise';
    }
  }

  Future<void> _pickImage(String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        switch (type) {
          case 'idFront':
            _idFrontImage = image;
            widget.updateFormData({'idFrontPath': image.path});
            break;
          case 'idBack':
            _idBackImage = image;
            widget.updateFormData({'idBackPath': image.path});
            break;
          case 'businessRegistration':
            _businessRegistrationImage = image;
            widget.updateFormData({'businessRegistrationPath': image.path});
            break;
          case 'businessLicense':
            _businessLicenseImage = image;
            widget.updateFormData({'businessLicensePath': image.path});
            break;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(),
        const SizedBox(height: 24),
        const Text(
          'Documents d\'identité',
          style: SDTypography.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Veuillez fournir une pièce d\'identité valide (CNI, Passeport, etc.)',
            style: SDTypography.bodyMedium.copyWith(
            color: SDColors.neutral500,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildImageUploader(
                title: 'CNI Recto *',
                image: _idFrontImage,
                onTap: () => _pickImage('idFront'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildImageUploader(
                title: 'CNI Verso *',
                image: _idBackImage,
                onTap: () => _pickImage('idBack'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Les photos doivent être claires et lisibles',
          style: SDTypography.bodySmall.copyWith(
            color: SDColors.neutral600,
            fontStyle: FontStyle.italic,
          ),
        ),
        if (_showBusinessDocs) ...[
          const SizedBox(height: 32),
          const Text(
            'Documents d\'entreprise',
            style: SDTypography.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Documents justifiant votre activité commerciale (Registre de commerce, etc.)',
            style: SDTypography.bodyMedium.copyWith(
              color: SDColors.neutral500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildImageUploader(
                  title: 'Registre du Commerce *',
                  image: _businessRegistrationImage,
                  onTap: () => _pickImage('businessRegistration'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildImageUploader(
                  title: 'Patente *',
                  image: _businessLicenseImage,
                  onTap: () => _pickImage('businessLicense'),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        _buildComplianceAgreement(),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SDColors.info50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SDColors.info200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info,
                color: SDColors.info700,
              ),
              const SizedBox(width: 8),
              const Text(
                'Pourquoi avons-nous besoin de ces documents?',
                style: SDTypography.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Ces documents nous permettent de :'
          ),
          const SizedBox(height: 4),
          const Text('• Vérifier votre identité pour la sécurité des acheteurs'),
          const Text('• Confirmer que vous êtes légalement autorisé à vendre'),
          const Text('• Respecter les réglementations locales sur le commerce'),
          const SizedBox(height: 8),
          Text(
            'Vos documents sont stockés de manière sécurisée et confidentielle conformément à notre politique de confidentialité.',
            style: SDTypography.bodyMedium.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploader({
    required String title,
    required XFile? image,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: SDTypography.titleMedium,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: SDColors.neutral100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SDColors.neutral300),
              image: image != null
                  ? DecorationImage(
                      image: FileImage(File(image.path)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: image == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 40,
                        color: SDColors.neutral400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cliquez pour ajouter',
                        style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
                      ),
                    ],
                  )
                : Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(), // Pour permettre au stack de prendre la taille du parent
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: SDColors.white,
                        ),
                        onPressed: onTap,
                        style: IconButton.styleFrom(
                          backgroundColor: SDColors.neutral900.withOpacity(0.54),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildComplianceAgreement() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SDColors.neutral100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'En soumettant ces documents, vous confirmez que :',
            style: SDTypography.titleSmall,
          ),
          const SizedBox(height: 8),
          const Text('• Toutes les informations fournies sont exactes et véridiques'),
          const Text('• Vous êtes légalement autorisé à vendre les produits proposés'),
          const Text('• Vous acceptez les conditions générales de SoutraliDeals'),
          const Text('• Vous respecterez les politiques de la marketplace'),
        ],
      ),
    );
  }
}
