import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import '../bloc/prestataire_finalization_bloc.dart';
import '../../../../data/services/authCubit.dart';

import 'package:geolocator/geolocator.dart';

class PrestataireFinalizationScreen extends StatefulWidget {
  final String? prestataireId;

  const PrestataireFinalizationScreen({Key? key, this.prestataireId})
      : super(key: key);

  @override
  _PrestataireFinalizationScreenState createState() =>
      _PrestataireFinalizationScreenState();
}

class _PrestataireFinalizationScreenState
    extends State<PrestataireFinalizationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final ImagePicker _picker = ImagePicker();

  // 🎯 DONNÉES DU FORMULAIRE
  final Map<String, dynamic> _formData = {
    // Documents obligatoires
    'cniRecto': null,
    'cniVerso': null,
    'selfie': null,
    'location': null,
    'address': '',

    // Documents optionnels
    'certificates': <File>[],
    'insurance': null,
    'portfolio': <File>[],
  };

  // 🎯 ÉTAPES DE FINALISATION
  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Documents d\'identité',
      'subtitle': 'CNI recto/verso et photo selfie',
      'required': true,
    },
    {
      'title': 'Localisation',
      'subtitle': 'Zone d\'intervention GPS',
      'required': true,
    },
    {
      'title': 'Documents optionnels',
      'subtitle': 'Certificats et assurance (optionnel)',
      'required': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PrestataireFinalizationBloc(),
      child: BlocListener<PrestataireFinalizationBloc,
          PrestataireFinalizationState>(
        listener: (context, state) {
          if (state is PrestataireFinalizationLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Finalisation en cours...')),
            );
          } else if (state is PrestataireFinalizationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // Rediriger vers le dashboard
            context.push('/homepage');
          } else if (state is PrestataireFinalizationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text('Finalisation du profil'),
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Column(
            children: [
              // 🎯 BARRE DE PROGRESSION
              _buildProgressBar(),

              // 🎯 CONTENU DES ÉTAPES
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  children: [
                    _buildIdentityStep(),
                    _buildLocationStep(),
                    _buildOptionalDocumentsStep(),
                  ],
                ),
              ),

              // 🎯 BOUTONS DE NAVIGATION
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // 🎯 BARRE DE PROGRESSION
  Widget _buildProgressBar() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: List.generate(_steps.length, (index) {
              final isActive = index <= _currentStep;
              final isCompleted = index < _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green
                            : isActive
                                ? Colors.green.shade600
                                : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : Icons.circle,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    if (index < _steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted ? Colors.green : Colors.grey[300],
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          SizedBox(height: 12),
          Text(
            _steps[_currentStep]['title'],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          Text(
            _steps[_currentStep]['subtitle'],
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 ÉTAPE 1: DOCUMENTS D'IDENTITÉ
  Widget _buildIdentityStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CNI Recto
          _buildDocumentCard(
            title: 'CNI Recto',
            subtitle: 'Photo du recto de votre carte d\'identité',
            icon: Icons.credit_card,
            isRequired: true,
            image: _formData['cniRecto'],
            onTap: () => _pickImage('cniRecto'),
          ),

          SizedBox(height: 16),

          // CNI Verso
          _buildDocumentCard(
            title: 'CNI Verso',
            subtitle: 'Photo du verso de votre carte d\'identité',
            icon: Icons.credit_card,
            isRequired: true,
            image: _formData['cniVerso'],
            onTap: () => _pickImage('cniVerso'),
          ),

          SizedBox(height: 16),

          // Selfie
          _buildDocumentCard(
            title: 'Photo Selfie',
            subtitle: 'Photo de vous-même pour vérification',
            icon: Icons.face,
            isRequired: true,
            image: _formData['selfie'],
            onTap: () => _pickImage('selfie'),
          ),

          SizedBox(height: 24),

          // Information importante
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade600),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ces documents sont obligatoires pour vérifier votre identité et activer votre compte prestataire.',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 ÉTAPE 2: LOCALISATION
  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zone d\'intervention',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Définissez votre zone d\'intervention pour recevoir des missions',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),

          SizedBox(height: 24),

          // Bouton de localisation
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.green.shade600,
                  size: 48,
                ),
                SizedBox(height: 12),
                Text(
                  'Activer la localisation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Nous avons besoin de votre position pour vous proposer des missions dans votre zone',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: Icon(Icons.my_location),
                  label: Text('Obtenir ma position'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Adresse manuelle
          TextField(
            decoration: InputDecoration(
              labelText: 'Adresse (optionnel)',
              hintText: 'Ex: Rue 123, Quartier ABC, Ville XYZ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.home),
            ),
            onChanged: (value) {
              setState(() {
                _formData['address'] = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // 🎯 ÉTAPE 3: DOCUMENTS OPTIONNELS
  Widget _buildOptionalDocumentsStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documents optionnels',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ces documents améliorent votre profil et augmentent vos chances d\'être sélectionné',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),

          SizedBox(height: 24),

          // Certificats
          _buildDocumentCard(
            title: 'Certificats/Diplômes',
            subtitle: 'Vos diplômes et certificats professionnels',
            icon: Icons.school,
            isRequired: false,
            image: _formData['certificates'].isNotEmpty
                ? _formData['certificates'].first
                : null,
            onTap: () => _pickMultipleImages('certificates'),
          ),

          SizedBox(height: 16),

          // Assurance
          _buildDocumentCard(
            title: 'Assurance professionnelle',
            subtitle: 'Votre attestation d\'assurance',
            icon: Icons.security,
            isRequired: false,
            image: _formData['insurance'],
            onTap: () => _pickImage('insurance'),
          ),

          SizedBox(height: 16),

          // Portfolio
          _buildDocumentCard(
            title: 'Portfolio',
            subtitle: 'Photos de vos réalisations',
            icon: Icons.photo_library,
            isRequired: false,
            image: _formData['portfolio'].isNotEmpty
                ? _formData['portfolio'].first
                : null,
            onTap: () => _pickMultipleImages('portfolio'),
          ),

          SizedBox(height: 24),

          // Information
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange.shade600),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ces documents sont optionnels mais recommandés pour améliorer votre profil.',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 CARTE DE DOCUMENT
  Widget _buildDocumentCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isRequired,
    required dynamic image,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: image != null ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: image != null ? Colors.green.shade300 : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: image != null
                    ? Colors.green.shade100
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: image != null
                  ? Icon(Icons.check_circle, color: Colors.green.shade600)
                  : Icon(icon, color: Colors.grey.shade600),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: image != null
                                ? Colors.green.shade700
                                : Colors.grey.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isRequired) ...[
                        SizedBox(width: 8),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'OBLIGATOIRE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // 🎯 BOUTONS DE NAVIGATION
  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: Text('Précédent'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed:
                  _currentStep < _steps.length - 1 ? _nextStep : _submitForm,
              child: Text(
                  _currentStep < _steps.length - 1 ? 'Suivant' : 'Finaliser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 MÉTHODES
  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _pickImage(String field) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _formData[field] = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection: $e')),
      );
    }
  }

  Future<void> _pickMultipleImages(String field) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _formData[field] = images.map((image) => File(image.path)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection: $e')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission de localisation refusée')),
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activez la localisation dans les paramètres'),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _formData['location'] = {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
        _formData['address'] =
            'Lat ${position.latitude.toStringAsFixed(4)}, Lng ${position.longitude.toStringAsFixed(4)}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Position GPS enregistrée'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur géolocalisation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _submitForm() {
    final auth = context.read<AuthCubit>().state;
    String? prestataireId = widget.prestataireId;
    String? authToken;

    if (auth is AuthAuthenticated) {
      authToken = auth.token;
    }

    if (prestataireId == null || authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ID prestataire non trouvé')),
      );
      return;
    }

    // 🎯 PRÉPARER LES DONNÉES
    final formData = Map<String, dynamic>.from(_formData);
    formData['prestataireId'] = prestataireId;
    formData['authToken'] = authToken;

    // 🎯 SOUMETTRE AU BLOC
    context.read<PrestataireFinalizationBloc>().add(
          SubmitFinalizationEvent(formData: formData),
        );
  }
}
