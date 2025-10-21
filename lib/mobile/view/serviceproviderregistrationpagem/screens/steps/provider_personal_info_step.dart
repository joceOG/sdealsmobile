import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../../../../../data/services/api_client.dart';
import '../../../../../data/models/categorie.dart';
import '../../../../../data/models/service.dart';

class ProviderPersonalInfoStep extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onDataChanged;

  const ProviderPersonalInfoStep({
    Key? key,
    required this.formData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<ProviderPersonalInfoStep> createState() =>
      _ProviderPersonalInfoStepState();
}

class _ProviderPersonalInfoStepState extends State<ProviderPersonalInfoStep> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  File? _profileImage;
  String? _selectedCategory;
  String? _selectedService;
  List<String> _selectedAreas = [];

  // Position exacte
  LatLng? _selectedPosition;
  String? _selectedAddress;
  bool _isLoadingLocation = false;

  // Données réelles chargées depuis le backend
  List<Categorie> _categories = [];
  List<Service> _services = [];
  bool _isLoadingCategories = false;
  bool _isLoadingServices = false;
  final ApiClient _apiClient = ApiClient();

  // Zones disponibles
  final List<String> _availableAreas = [
    'Abidjan',
    'Abobo',
    'Adjamé',
    'Attécoubé',
    'Cocody',
    'Koumassi',
    'Marcory',
    'Plateau',
    'Port-Bouët',
    'Treichville',
    'Yopougon',
    'Bingerville',
    'Yamoussoukro',
    'Bouaké',
    'Daloa',
    'San Pedro',
    'Korhogo',
    'Anyama',
    'Divo'
  ];

  @override
  void initState() {
    super.initState();
    _initializeFormValues();
    _loadCategories();
  }

  // ✅ CHARGER LES VRAIES CATÉGORIES DEPUIS LE BACKEND
  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      print('🔄 Chargement des catégories pour le groupe "Métiers"...');
      final categories = await _apiClient.fetchCategorie("Métiers");

      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });

      print('✅ ${categories.length} catégories chargées depuis le backend');
    } catch (e) {
      print('❌ Erreur chargement catégories: $e');
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  // ✅ CHARGER LES SERVICES POUR UNE CATÉGORIE SPÉCIFIQUE
  Future<void> _loadServicesForCategory(String categoryId) async {
    setState(() {
      _isLoadingServices = true;
    });

    try {
      print('🔄 Chargement des services pour la catégorie: $categoryId');
      final services = await _apiClient.fetchServices("Métiers");

      // Filtrer les services par catégorie
      final filteredServices = services.where((service) {
        return service.categorie?.idcategorie == categoryId;
      }).toList();

      setState(() {
        _services = filteredServices;
        _isLoadingServices = false;
      });

      print('✅ ${filteredServices.length} services chargés pour la catégorie');
    } catch (e) {
      print('❌ Erreur chargement services: $e');
      setState(() {
        _isLoadingServices = false;
      });
    }
  }

  void _initializeFormValues() {
    _nameController.text = widget.formData['fullName'] ?? '';
    _phoneController.text = widget.formData['phone'] ?? '';
    _emailController.text = widget.formData['email'] ?? '';
    // Ne pas initialiser avec des valeurs mockées - attendre les vraies données
    _selectedCategory = null; // Sera défini après chargement des catégories
    _selectedService = null; // Sera défini après chargement des services
    _selectedAreas = List<String>.from(widget.formData['serviceAreas'] ?? []);

    if (widget.formData['profileImage'] != null) {
      _profileImage = File(widget.formData['profileImage']);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
      _updateFormData();
    }
  }

  void _updateFormData() {
    // Vérifier que les valeurs sélectionnées sont valides
    String? validCategory = _selectedCategory;
    String? validService = _selectedService;

    // Vérifier que la catégorie sélectionnée existe dans les catégories chargées
    if (_selectedCategory != null && _categories.isNotEmpty) {
      final categoryExists =
          _categories.any((c) => c.idcategorie == _selectedCategory);
      if (!categoryExists) {
        validCategory = null;
      }
    }

    // Vérifier que le service sélectionné existe dans les services chargés
    if (_selectedService != null && _services.isNotEmpty) {
      final serviceExists =
          _services.any((s) => s.idservice == _selectedService);
      if (!serviceExists) {
        validService = null;
      }
    }

    Map<String, dynamic> updatedData = {
      'fullName': _nameController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'category': validCategory,
      'service': validService,
      'serviceAreas': _selectedAreas,
      'profileImage': _profileImage?.path,
      'position': _selectedPosition,
      'address': _selectedAddress,
    };

    widget.onDataChanged(updatedData);
  }

  // Obtenir la position actuelle
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Vérifier les permissions
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
              content:
                  Text('Permission de localisation refusée définitivement')),
        );
        return;
      }

      // Obtenir la position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedPosition = LatLng(position.latitude, position.longitude);
        _selectedAddress = 'Position actuelle';
        _isLoadingLocation = false;
      });

      _updateFormData();
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur lors de la récupération de la position: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations de base',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Remplissez ces informations essentielles pour commencer',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Photo de profil (optionnelle)
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? const Icon(Icons.add_a_photo,
                            size: 30, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Photo de profil (optionnelle)',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Nom complet
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom complet *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre nom complet';
              }
              return null;
            },
            onChanged: (value) => _updateFormData(),
          ),
          const SizedBox(height: 16),

          // Téléphone
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Téléphone *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
              hintText: 'Ex: +225 07 XX XX XX XX',
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre numéro de téléphone';
              }
              return null;
            },
            onChanged: (value) => _updateFormData(),
          ),
          const SizedBox(height: 16),

          // Email (OPTIONNEL)
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email (optionnel)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
              hintText: 'Si vous avez un email',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Veuillez entrer un email valide';
                }
              }
              return null;
            },
            onChanged: (value) => _updateFormData(),
          ),
          const SizedBox(height: 20),

          // Catégorie de service
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Votre catégorie *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            value: _selectedCategory,
            items: _isLoadingCategories
                ? [
                    const DropdownMenuItem(
                        value: null, child: Text('Chargement...'))
                  ]
                : _categories.map((categorie) {
                    return DropdownMenuItem(
                      value: categorie.idcategorie,
                      child: Text(categorie.nomcategorie),
                    );
                  }).toList(),
            onChanged: _isLoadingCategories
                ? null
                : (value) {
                    setState(() {
                      _selectedCategory = value;
                      _selectedService =
                          null; // Réinitialiser le service quand la catégorie change
                    });
                    if (value != null) {
                      _loadServicesForCategory(value);
                    }
                    _updateFormData();
                  },
            validator: (value) =>
                value == null ? 'Veuillez sélectionner votre catégorie' : null,
          ),
          const SizedBox(height: 16),

          // Service spécifique
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Votre service *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.build_circle),
            ),
            value: _selectedService != null &&
                    _services.any((s) => s.idservice == _selectedService)
                ? _selectedService
                : null,
            items: _isLoadingServices
                ? [
                    const DropdownMenuItem(
                        value: null, child: Text('Chargement...'))
                  ]
                : _services.map((service) {
                    return DropdownMenuItem(
                      value: service.idservice,
                      child: Text(service.nomservice),
                    );
                  }).toList(),
            onChanged: _isLoadingServices
                ? null
                : (value) {
                    setState(() {
                      _selectedService = value;
                    });
                    _updateFormData();
                  },
            validator: (value) =>
                value == null ? 'Veuillez sélectionner votre service' : null,
          ),
          const SizedBox(height: 16),

          // Zones de service
          const Text(
            'Où travaillez-vous ? *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableAreas.map((zone) {
              final isSelected = _selectedAreas.contains(zone);
              return FilterChip(
                label: Text(zone),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedAreas.add(zone);
                    } else {
                      _selectedAreas.remove(zone);
                    }
                  });
                  _updateFormData();
                },
                selectedColor: Colors.green.shade700.withOpacity(0.3),
                checkmarkColor: Colors.green.shade700,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Position exacte
          const Text(
            'Votre position exacte *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                if (_selectedPosition != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedAddress ?? 'Position sélectionnée',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedPosition = null;
                            _selectedAddress = null;
                          });
                          _updateFormData();
                        },
                        icon: const Icon(Icons.close, color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lat: ${_selectedPosition!.latitude.toStringAsFixed(6)}, Lng: ${_selectedPosition!.longitude.toStringAsFixed(6)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ] else ...[
                  Row(
                    children: [
                      const Icon(Icons.location_off, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Aucune position sélectionnée',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                    icon: _isLoadingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(_isLoadingLocation
                        ? 'Récupération...'
                        : 'Utiliser ma position actuelle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Validation de la position
          if (_selectedPosition == null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Veuillez sélectionner votre position exacte pour continuer',
                      style: TextStyle(fontSize: 13, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Note simplifiée
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Profil de base créé ! Vous pourrez le compléter plus tard pour être vérifié.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
