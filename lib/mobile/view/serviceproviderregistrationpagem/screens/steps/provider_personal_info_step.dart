import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../../../../../design_system/design_system.dart';
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
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  File? _profileImage;
  String? _selectedCategory;
  String? _selectedService;
  List<String> _selectedAreas = [];

  LatLng? _selectedPosition;
  String? _selectedAddress;
  bool _isLoadingLocation = false;

  List<Categorie> _categories = [];
  List<Service> _services = [];
  bool _isLoadingCategories = false;
  bool _isLoadingServices = false;
  final ApiClient _apiClient = ApiClient();

  final List<String> _availableAreas = [
    'Abidjan', 'Abobo', 'Adjamé', 'Attécoubé', 'Cocody',
    'Koumassi', 'Marcory', 'Plateau', 'Port-Bouët', 'Treichville',
    'Yopougon', 'Bingerville', 'Yamoussoukro', 'Bouaké', 'Daloa',
    'San Pedro', 'Korhogo', 'Anyama', 'Divo',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFormValues();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categories = await _apiClient.fetchCategorie('Métiers');
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _loadServicesForCategory(String categoryId) async {
    setState(() {
      _isLoadingServices = true;
      _selectedService = null;
    });
    try {
      final services = await _apiClient.fetchServices('Métiers');
      final filtered = services.where((s) => s.categorie?.idcategorie == categoryId).toList();
      setState(() {
        _services = filtered;
        _isLoadingServices = false;
      });
    } catch (e) {
      setState(() => _isLoadingServices = false);
    }
  }

  void _initializeFormValues() {
    _nameController.text = widget.formData['fullName'] ?? '';
    _phoneController.text = widget.formData['phone'] ?? '';
    _emailController.text = widget.formData['email'] ?? '';
    _selectedCategory = widget.formData['category'];
    _selectedService = widget.formData['service'];
    _selectedAreas = List<String>.from(widget.formData['serviceAreas'] ?? []);
    if (widget.formData['profileImage'] != null) {
      _profileImage = File(widget.formData['profileImage']);
    }
    if (widget.formData['position'] != null) {
      _selectedPosition = widget.formData['position'] as LatLng;
      _selectedAddress = widget.formData['address'];
    }
  }

  @override
  void didUpdateWidget(ProviderPersonalInfoStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Synchroniser quand le parent met à jour formData (pré-remplissage auth)
    final newName = widget.formData['fullName'] ?? '';
    final newPhone = widget.formData['phone'] ?? '';
    final newEmail = widget.formData['email'] ?? '';
    if (_nameController.text != newName) _nameController.text = newName;
    if (_phoneController.text != newPhone) _phoneController.text = newPhone;
    if (_emailController.text != newEmail) _emailController.text = newEmail;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _profileImage = File(image.path));
      _updateFormData();
    }
  }

  void _updateFormData() {
    final validCategory = (_selectedCategory != null &&
            _categories.any((c) => c.idcategorie == _selectedCategory))
        ? _selectedCategory
        : null;
    final validService = (_selectedService != null &&
            _services.any((s) => s.idservice == _selectedService))
        ? _selectedService
        : null;
    final categoryName = validCategory != null
        ? _categories.firstWhere((c) => c.idcategorie == validCategory,
                orElse: () => _categories.first)
            .nomcategorie
        : '';

    widget.onDataChanged({
      'fullName': _nameController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'confirmPassword': _confirmPasswordController.text,
      'category': validCategory,
      'categoryName': categoryName,
      'service': validService,
      'serviceAreas': _selectedAreas,
      'profileImage': _profileImage?.path,
      'position': _selectedPosition,
      'address': _selectedAddress,
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Permission de localisation refusée');
          setState(() => _isLoadingLocation = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack('Permission de localisation refusée définitivement');
        setState(() => _isLoadingLocation = false);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _selectedPosition = LatLng(position.latitude, position.longitude);
        _selectedAddress = 'Position actuelle';
        _isLoadingLocation = false;
      });
      _updateFormData();
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      _showSnack('Erreur lors de la récupération de la position');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Informations de base', style: SDTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
        SizedBox(height: SDSpacing.xs),
        Text('Remplissez ces informations essentielles pour commencer',
            style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral500)),
        SizedBox(height: SDSpacing.md),

        // Photo de profil
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: SDColors.neutral100,
                  backgroundImage:
                      _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null
                      ? Icon(Icons.add_a_photo_outlined, size: 28, color: SDColors.neutral500)
                      : null,
                ),
              ),
              SizedBox(height: SDSpacing.xs),
              Text('Photo de profil (optionnelle)',
                  style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500)),
            ],
          ),
        ),
        SizedBox(height: SDSpacing.md),

        // Nom complet
        SDInput(
          label: 'Nom complet *',
          hint: 'Ex: Kouamé Jean',
          controller: _nameController,
          prefixIcon: Icons.person_outline,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
          onChanged: (_) => _updateFormData(),
        ),
        SizedBox(height: SDSpacing.sm),

        // Téléphone
        SDInput(
          label: 'Téléphone *',
          hint: 'Ex: 07 XX XX XX XX',
          controller: _phoneController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
          onChanged: (_) => _updateFormData(),
        ),
        SizedBox(height: SDSpacing.sm),

        // Email optionnel
        SDInput(
          label: 'Email (optionnel)',
          hint: 'Ex: nom@exemple.com',
          controller: _emailController,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v != null && v.isNotEmpty && !v.contains('@')) {
              return 'Email invalide';
            }
            return null;
          },
          onChanged: (_) => _updateFormData(),
        ),
        // Mot de passe — obligatoire si nouveau compte (non connecté)
        if (widget.formData['requirePassword'] == true) ...[
          SizedBox(height: SDSpacing.sm),
          SDInput(
            label: 'Mot de passe *',
            hint: 'Au moins 6 caractères',
            controller: _passwordController,
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            onChanged: (_) => _updateFormData(),
          ),
          SizedBox(height: SDSpacing.sm),
          SDInput(
            label: 'Confirmer le mot de passe *',
            hint: 'Retapez le mot de passe',
            controller: _confirmPasswordController,
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            onChanged: (_) => _updateFormData(),
          ),
        ],
        SizedBox(height: SDSpacing.md),

        // Catégorie
        _buildDropdownField(
          label: 'Votre catégorie *',
          icon: Icons.category_outlined,
          isLoading: _isLoadingCategories,
          loadingLabel: 'Chargement des catégories...',
          value: _selectedCategory,
          items: _categories.map((c) => DropdownMenuItem(
                value: c.idcategorie,
                child: Text(c.nomcategorie),
              )).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
              _selectedService = null;
              _services = [];
            });
            if (value != null) _loadServicesForCategory(value);
            _updateFormData();
          },
          hint: 'Sélectionnez une catégorie',
        ),
        SizedBox(height: SDSpacing.sm),

        // Service
        _buildDropdownField(
          label: 'Votre service *',
          icon: Icons.build_outlined,
          isLoading: _isLoadingServices,
          loadingLabel: _selectedCategory == null
              ? 'Sélectionnez d\'abord une catégorie'
              : 'Chargement des services...',
          value: _selectedService != null &&
                  _services.any((s) => s.idservice == _selectedService)
              ? _selectedService
              : null,
          items: _services.map((s) => DropdownMenuItem(
                value: s.idservice,
                child: Text(s.nomservice),
              )).toList(),
          onChanged: _selectedCategory == null
              ? null
              : (value) {
                  setState(() => _selectedService = value);
                  _updateFormData();
                },
          hint: 'Sélectionnez un service',
        ),
        SizedBox(height: SDSpacing.md),

        // Zones d'intervention
        Text('Où travaillez-vous ? *',
            style: SDTypography.labelLarge.copyWith(
                color: SDColors.neutral700, fontWeight: FontWeight.w600)),
        SizedBox(height: SDSpacing.xs),
        Wrap(
          spacing: SDSpacing.xs,
          runSpacing: SDSpacing.xs,
          children: _availableAreas.map((zone) {
            final isSelected = _selectedAreas.contains(zone);
            return FilterChip(
              label: Text(zone,
                  style: SDTypography.bodySmall.copyWith(
                      color: isSelected ? SDColors.primary700 : SDColors.neutral700)),
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
              selectedColor: SDColors.primary50,
              checkmarkColor: SDColors.primary700,
              backgroundColor: SDColors.neutral50,
              side: BorderSide(
                  color: isSelected ? SDColors.primary300 : SDColors.neutral200),
            );
          }).toList(),
        ),
        SizedBox(height: SDSpacing.md),

        // Position GPS
        Text('Votre position *',
            style: SDTypography.labelLarge.copyWith(
                color: SDColors.neutral700, fontWeight: FontWeight.w600)),
        SizedBox(height: SDSpacing.xs),
        Container(
          padding: EdgeInsets.all(SDSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(
                color: _selectedPosition != null
                    ? SDColors.primary300
                    : SDColors.neutral200),
            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
            color: _selectedPosition != null ? SDColors.primary50 : SDColors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedPosition != null) ...[
                Row(
                  children: [
                    Icon(Icons.location_on, color: SDColors.primary600, size: 18),
                    SizedBox(width: SDSpacing.xs),
                    Expanded(
                      child: Text(_selectedAddress ?? 'Position sélectionnée',
                          style: SDTypography.bodySmall.copyWith(
                              color: SDColors.primary700,
                              fontWeight: FontWeight.w500)),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedPosition = null;
                          _selectedAddress = null;
                        });
                        _updateFormData();
                      },
                      icon: Icon(Icons.close, color: SDColors.neutral500, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: SDSpacing.xxs),
              ] else ...[
                Row(
                  children: [
                    Icon(Icons.location_off, color: SDColors.neutral400, size: 18),
                    SizedBox(width: SDSpacing.xs),
                    Text('Aucune position sélectionnée',
                        style: SDTypography.bodySmall.copyWith(
                            color: SDColors.neutral500)),
                  ],
                ),
                SizedBox(height: SDSpacing.xs),
              ],
              SDButton(
                text: _isLoadingLocation
                    ? 'Récupération...'
                    : 'Utiliser ma position actuelle',
                icon: _isLoadingLocation ? null : Icons.my_location,
                isLoading: _isLoadingLocation,
                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                fullWidth: true,
                type: _selectedPosition != null
                    ? SDButtonType.outlined
                    : SDButtonType.primary,
              ),
            ],
          ),
        ),
        SizedBox(height: SDSpacing.md),

        // Note info
        Container(
          padding: EdgeInsets.all(SDSpacing.sm),
          decoration: BoxDecoration(
            color: SDColors.primary50,
            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
            border: Border.all(color: SDColors.primary100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: SDColors.primary600, size: 18),
              SizedBox(width: SDSpacing.xs),
              Expanded(
                child: Text(
                  'Profil de base — vous pourrez le compléter pour être vérifié ✓',
                  style: SDTypography.bodySmall.copyWith(color: SDColors.primary700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required bool isLoading,
    required String loadingLabel,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?>? onChanged,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: SDTypography.labelLarge.copyWith(
                color: SDColors.neutral700, fontWeight: FontWeight.w600)),
        SizedBox(height: SDSpacing.xxs),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: SDColors.neutral200),
            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
            color: SDColors.white,
          ),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: SDSpacing.sm, vertical: SDSpacing.xs),
              prefixIcon: Icon(icon, color: SDColors.neutral500, size: 20),
            ),
            // Valider que value existe dans items avant de l'utiliser
            value: (!isLoading &&
                    value != null &&
                    items.any((item) => item.value == value))
                ? value
                : null,
            hint: Text(isLoading ? loadingLabel : hint,
                style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral400)),
            items: isLoading ? [] : items,
            onChanged: isLoading ? null : onChanged,
            validator: (v) => v == null ? 'Requis' : null,
            isExpanded: true,
            icon: isLoading
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.keyboard_arrow_down),
          ),
        ),
      ],
    );
  }
}
