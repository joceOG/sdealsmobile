import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProviderQualificationsStep extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onDataChanged;

  const ProviderQualificationsStep({
    Key? key,
    required this.formData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<ProviderQualificationsStep> createState() => _ProviderQualificationsStepState();
}

class _ProviderQualificationsStepState extends State<ProviderQualificationsStep> {
  final TextEditingController _numeroAssuranceController = TextEditingController();
  final TextEditingController _numeroRCCMController = TextEditingController();
  
  List<File> _diplomeCertificat = [];
  File? _attestationAssurance;

  @override
  void initState() {
    super.initState();
    _initializeFormValues();
  }

  void _initializeFormValues() {
    _numeroAssuranceController.text = widget.formData['numeroAssurance'] ?? '';
    _numeroRCCMController.text = widget.formData['numeroRCCM'] ?? '';
    
    // Initialiser les certificats
    if (widget.formData['diplomeCertificat'] != null && widget.formData['diplomeCertificat'] is List) {
      _diplomeCertificat = (widget.formData['diplomeCertificat'] as List)
          .where((cert) => cert is String)
          .map((path) => File(path))
          .toList();
    }
    
    // Initialiser le document d'assurance
    if (widget.formData['attestationAssurance'] != null) {
      _attestationAssurance = File(widget.formData['attestationAssurance']);
    }
  }

  @override
  void dispose() {
    _numeroAssuranceController.dispose();
    _numeroRCCMController.dispose();
    super.dispose();
  }

  Future<void> _pickCertificateImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _diplomeCertificat.add(File(pickedFile.path));
      });
      
      _updateFormData();
    }
  }
  
  void _removeCertificate(int index) {
    setState(() {
      _diplomeCertificat.removeAt(index);
    });
    
    _updateFormData();
  }

  Future<void> _pickInsuranceDocument() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _attestationAssurance = File(pickedFile.path);
      });
      
      _updateFormData();
    }
  }

  void _updateFormData() {
    Map<String, dynamic> updatedData = {
      'diplomeCertificat': _diplomeCertificat.map((file) => file.path).toList(),
      'numeroAssurance': _numeroAssuranceController.text,
      'attestationAssurance': _attestationAssurance?.path ,
      'numeroRCCM': _numeroRCCMController.text,
    };
    
    widget.onDataChanged(updatedData);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Qualifications ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '(optionnel)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajoutez des certifications professionnelles pour augmenter votre visibilité et votre crédibilité.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Diplômes/Certificats
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Diplômes / Certificats',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              
              // Liste des certificats ajoutés
              if (_diplomeCertificat.isNotEmpty) ...[
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemCount: _diplomeCertificat.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _diplomeCertificat[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: () => _removeCertificate(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
              
              // Bouton pour ajouter un certificat
              ElevatedButton.icon(
                onPressed: _pickCertificateImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  minimumSize: const Size(double.infinity, 50),
                ),
                icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
                label: const Text(
                  'Ajouter un diplôme/certificat',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Assurance professionnelle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assurance professionnelle',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              
              // Numéro d'assurance
              TextFormField(
                controller: _numeroAssuranceController,
                decoration: const InputDecoration(
                  labelText: 'Numéro d\'assurance',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
                onChanged: (value) => _updateFormData(),
              ),
              const SizedBox(height: 16),
              
              // Document d'assurance
              InkWell(
                onTap: _pickInsuranceDocument,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _attestationAssurance != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _attestationAssurance!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.upload_file,
                              size: 40,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Ajouter votre attestation d\'assurance',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Registre du commerce
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registre du commerce',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _numeroRCCMController,
                decoration: const InputDecoration(
                  labelText: 'Numéro du registre du commerce',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                  hintText: 'Si applicable',
                ),
                onChanged: (value) => _updateFormData(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Avantage d'ajouter des qualifications
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Les avantages des certifications',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  '• 70% des clients préfèrent les prestataires certifiés',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  '• Un badge "Vérifié" sera affiché sur votre profil',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  '• Augmente vos chances d\'être mis en avant dans les recherches',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
