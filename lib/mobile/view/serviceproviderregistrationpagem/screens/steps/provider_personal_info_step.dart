import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../../design_system/design_system.dart';
import '../../../../../data/services/api_client.dart';
import '../../../../../data/models/categorie.dart';
import '../../../../../data/models/service.dart';

/// Étape 1 Figma — identité + catégorie / service (sans zones / GPS).
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
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  File? _profileImage;
  String? _selectedCategory;
  String? _selectedService;

  List<Categorie> _categories = [];
  List<Service> _services = [];
  bool _isLoadingCategories = false;
  bool _isLoadingServices = false;
  final ApiClient _apiClient = ApiClient();

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
      final cat = widget.formData['category'] as String?;
      if (cat != null && cat.isNotEmpty) {
        await _loadServicesForCategory(cat);
      }
    } catch (_) {
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
      final filtered = services
          .where((s) => s.categorie?.idcategorie == categoryId)
          .toList();
      setState(() {
        _services = filtered;
        _isLoadingServices = false;
        final prev = widget.formData['service'] as String?;
        if (prev != null && filtered.any((s) => s.idservice == prev)) {
          _selectedService = prev;
        }
      });
      _updateFormData();
    } catch (_) {
      setState(() => _isLoadingServices = false);
    }
  }

  void _initializeFormValues() {
    _nameController.text = widget.formData['fullName'] ?? '';
    _phoneController.text = widget.formData['phone'] ?? '';
    _emailController.text = widget.formData['email'] ?? '';
    _selectedCategory = widget.formData['category'];
    _selectedService = widget.formData['service'];
    if (widget.formData['profileImage'] != null) {
      _profileImage = File(widget.formData['profileImage']);
    }
  }

  @override
  void didUpdateWidget(ProviderPersonalInfoStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newName = (widget.formData['fullName'] ?? '').toString();
    final newPhone = (widget.formData['phone'] ?? '').toString();
    final newEmail = (widget.formData['email'] ?? '').toString();
    if (_nameController.text.isEmpty && newName.isNotEmpty) {
      _nameController.text = newName;
    }
    if (_phoneController.text.isEmpty && newPhone.isNotEmpty) {
      _phoneController.text = newPhone;
    }
    if (_emailController.text.isEmpty && newEmail.isNotEmpty) {
      _emailController.text = newEmail;
    }
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
        ? _categories
            .firstWhere((c) => c.idcategorie == validCategory,
                orElse: () => _categories.first)
            .nomcategorie
        : '';
    final serviceName = validService != null
        ? _services
            .firstWhere((s) => s.idservice == validService,
                orElse: () => _services.first)
            .nomservice
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
      'serviceName': serviceName,
      'profileImage': _profileImage?.path,
    });
  }

  @override
  Widget build(BuildContext context) {
    final connected = widget.formData['requirePassword'] != true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: SDColors.neutral100,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? const Icon(Icons.person_outline_rounded,
                              size: 40, color: SDColors.neutral400)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: SDColors.primary600,
                          shape: BoxShape.circle,
                          border: Border.all(color: SDColors.white, width: 2),
                        ),
                        child: const Icon(Icons.photo_camera_outlined,
                            size: 14, color: SDColors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Text(
                  'Ajouter une photo',
                  style: SDTypography.labelMedium.copyWith(
                    color: SDColors.primary700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: SDSpacing.md),
        SDInput(
          label: 'Nom complet *',
          hint: 'Ex. Kouadio Jean',
          controller: _nameController,
          prefixIcon: Icons.person_outline,
          onChanged: (_) => _updateFormData(),
        ),
        SizedBox(height: SDSpacing.sm),
        SDInput(
          label: 'Téléphone *',
          hint: 'Ex: 07 XX XX XX XX',
          controller: _phoneController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          onChanged: (_) => _updateFormData(),
        ),
        SizedBox(height: SDSpacing.sm),
        SDInput(
          label: 'Email (optionnel)',
          hint: 'exemple@email.com',
          controller: _emailController,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => _updateFormData(),
        ),
        if (connected) ...[
          SizedBox(height: SDSpacing.sm),
          _InfoBanner(
            icon: Icons.info_outline_rounded,
            text:
                'Vous êtes déjà connecté — les champs mot de passe ne sont pas demandés.',
          ),
        ],
        if (widget.formData['requirePassword'] == true) ...[
          SizedBox(height: SDSpacing.sm),
          SDInput(
            label: 'Mot de passe *',
            hint: 'Créez un mot de passe',
            helperText: '6 caractères minimum',
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
        SizedBox(height: SDSpacing.lg),
        Text(
          'Votre activité',
          style: SDTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: SDColors.neutral900,
          ),
        ),
        SizedBox(height: SDSpacing.sm),
        _buildDropdownField(
          label: 'Catégorie *',
          icon: Icons.category_outlined,
          isLoading: _isLoadingCategories,
          loadingLabel: 'Chargement des catégories...',
          value: _selectedCategory,
          items: _categories
              .map((c) => DropdownMenuItem(
                    value: c.idcategorie,
                    child: Text(c.nomcategorie),
                  ))
              .toList(),
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
        _buildDropdownField(
          label: 'Service *',
          icon: Icons.build_outlined,
          isLoading: _isLoadingServices,
          loadingLabel: _selectedCategory == null
              ? 'Sélectionnez d’abord une catégorie'
              : 'Chargement des services...',
          value: _selectedService != null &&
                  _services.any((s) => s.idservice == _selectedService)
              ? _selectedService
              : null,
          items: _services
              .map((s) => DropdownMenuItem(
                    value: s.idservice,
                    child: Text(s.nomservice),
                  ))
              .toList(),
          onChanged: _selectedCategory == null
              ? null
              : (value) {
                  setState(() => _selectedService = value);
                  _updateFormData();
                },
          hint: 'Sélectionnez un service',
        ),
        SizedBox(height: SDSpacing.sm),
        _InfoBanner(
          icon: Icons.filter_alt_outlined,
          text:
              'Les services proposés dépendent de la catégorie sélectionnée.',
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
            value: (!isLoading &&
                    value != null &&
                    items.any((item) => item.value == value))
                ? value
                : null,
            hint: Text(isLoading ? loadingLabel : hint,
                style: SDTypography.bodyMedium
                    .copyWith(color: SDColors.neutral400)),
            items: isLoading ? [] : items,
            onChanged: isLoading ? null : onChanged,
            isExpanded: true,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.keyboard_arrow_down),
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBanner({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SDColors.primary50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SDColors.primary100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: SDColors.primary700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: SDTypography.bodySmall.copyWith(
                color: SDColors.primary800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
