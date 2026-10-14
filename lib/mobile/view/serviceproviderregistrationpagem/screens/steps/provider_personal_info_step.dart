import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../../design_system/design_system.dart';
import '../../../../../data/services/api_client.dart';
import '../../../../../data/models/categorie.dart';
import '../../../../../data/models/service.dart';
import '../widgets/provider_category_picker_sheet.dart';
import '../widgets/provider_service_picker_sheet.dart';

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
  String? _categoriesError;
  String? _servicesError;
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _initializeFormValues();
    _loadCategories();
  }

  Future<List<Categorie>> _fetchCategoriesFromApi() async {
    return _apiClient.fetchCategorie('Métiers');
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoriesError = null;
    });
    try {
      final categories = await _fetchCategoriesFromApi();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
      final cat = widget.formData['category'] as String?;
      if (cat != null && cat.isNotEmpty) {
        await _loadServicesForCategory(cat, resetService: false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingCategories = false;
        _categoriesError = 'Impossible de charger les catégories.';
      });
    }
  }

  Future<List<Service>> _fetchServicesForCategoryApi(String categoryId) async {
    final services = await _apiClient.fetchServices('Métiers');
    return services
        .where((s) => s.categorie?.idcategorie == categoryId)
        .toList();
  }

  Future<void> _loadServicesForCategory(
    String categoryId, {
    bool resetService = true,
  }) async {
    final keepServiceId = resetService ? null : _selectedService;
    setState(() {
      _isLoadingServices = true;
      _servicesError = null;
      if (resetService) _selectedService = null;
    });
    try {
      final filtered = await _fetchServicesForCategoryApi(categoryId);
      if (!mounted) return;
      setState(() {
        _services = filtered;
        _isLoadingServices = false;
        if (keepServiceId != null &&
            filtered.any((s) => s.idservice == keepServiceId)) {
          _selectedService = keepServiceId;
        } else if (resetService) {
          _selectedService = null;
        } else {
          final prev = widget.formData['service'] as String?;
          if (prev != null && filtered.any((s) => s.idservice == prev)) {
            _selectedService = prev;
          }
        }
      });
      _updateFormData();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingServices = false;
        _servicesError = 'Impossible de charger les services.';
      });
    }
  }

  Future<void> _openServicePicker() async {
    final categoryId = _selectedCategory;
    if (categoryId == null || categoryId.isEmpty) return;

    final chosen = await ProviderServicePickerSheet.show(
      context,
      categoryId: categoryId,
      categoryLabel: _categoryDisplayLabel() ?? '',
      initialSelectedId: _selectedService,
      seedServices: _services,
      loadServices: () => _fetchServicesForCategoryApi(categoryId),
    );
    if (chosen == null || !mounted) return;

    if (chosen == _selectedService) {
      if (_services.isEmpty) {
        await _loadServicesForCategory(categoryId, resetService: false);
      }
      return;
    }

    setState(() => _selectedService = chosen);
    if (_services.isEmpty) {
      await _loadServicesForCategory(categoryId, resetService: false);
      if (mounted) setState(() => _selectedService = chosen);
    }
    _updateFormData();
  }

  String? _serviceDisplayLabel() {
    if (_selectedService != null) {
      for (final s in _services) {
        if (s.idservice == _selectedService) return s.nomservice;
      }
    }
    final name = widget.formData['serviceName']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    return null;
  }

  Future<void> _openCategoryPicker() async {
    final chosen = await ProviderCategoryPickerSheet.show(
      context,
      initialSelectedId: _selectedCategory,
      seedCategories: _categories,
      loadCategories: _fetchCategoriesFromApi,
    );
    if (chosen == null || !mounted) return;

    if (chosen == _selectedCategory) {
      if (_categories.isEmpty) await _loadCategories();
      return;
    }

    setState(() => _selectedCategory = chosen);
    if (_categories.isEmpty) {
      await _loadCategories();
    }
    await _loadServicesForCategory(chosen, resetService: true);
  }

  String? _categoryDisplayLabel() {
    if (_selectedCategory != null) {
      for (final c in _categories) {
        if (c.idcategorie == _selectedCategory) return c.nomcategorie;
      }
    }
    final name = widget.formData['categoryName']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    return null;
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
        _buildCategoryPickerField(),
        SizedBox(height: SDSpacing.sm),
        _buildServicePickerField(),
        SizedBox(height: SDSpacing.sm),
        _InfoBanner(
          icon: Icons.filter_alt_outlined,
          text:
              'Les services proposés dépendent de la catégorie sélectionnée.',
        ),
      ],
    );
  }

  Widget _buildCategoryPickerField() {
    final label = _categoryDisplayLabel();
    final loading = _isLoadingCategories && _categories.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégorie *',
          style: SDTypography.labelLarge.copyWith(
            color: SDColors.neutral700,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: SDSpacing.xxs),
        Material(
          color: SDColors.white,
          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
          child: InkWell(
            onTap: loading ? null : _openCategoryPicker,
            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              decoration: BoxDecoration(
                border: Border.all(color: SDColors.neutral200),
                borderRadius:
                    BorderRadius.circular(SDSpacing.borderRadiusMedium),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.category_outlined,
                      color: SDColors.neutral500, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      loading
                          ? 'Chargement des catégories...'
                          : (label ?? 'Sélectionnez une catégorie'),
                      style: SDTypography.bodyLarge.copyWith(
                        fontSize: 16,
                        color: label != null && !loading
                            ? SDColors.neutral900
                            : SDColors.neutral400,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  if (loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.keyboard_arrow_down,
                        color: SDColors.neutral500),
                ],
              ),
            ),
          ),
        ),
        if (_categoriesError != null && _categories.isEmpty) ...[
          const SizedBox(height: 6),
          Text(
            _categoriesError!,
            style: SDTypography.bodySmall.copyWith(color: SDColors.error500),
          ),
          TextButton(
            onPressed: _loadCategories,
            child: Text(
              'Réessayer',
              style: SDTypography.labelLarge.copyWith(
                color: SDColors.primary700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildServicePickerField() {
    final label = _serviceDisplayLabel();
    final noCategory =
        _selectedCategory == null || _selectedCategory!.isEmpty;
    final loading = _isLoadingServices && _services.isEmpty && !noCategory;

    String placeholder;
    if (noCategory) {
      placeholder = 'Sélectionnez d’abord une catégorie';
    } else if (loading) {
      placeholder = 'Chargement des services...';
    } else {
      placeholder = 'Sélectionnez un service';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service *',
          style: SDTypography.labelLarge.copyWith(
            color: SDColors.neutral700,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: SDSpacing.xxs),
        Material(
          color: SDColors.white,
          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
          child: InkWell(
            onTap: (noCategory || loading) ? null : _openServicePicker,
            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              decoration: BoxDecoration(
                border: Border.all(color: SDColors.neutral200),
                borderRadius:
                    BorderRadius.circular(SDSpacing.borderRadiusMedium),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.build_outlined,
                      color: SDColors.neutral500, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label ?? placeholder,
                      style: SDTypography.bodyLarge.copyWith(
                        fontSize: 16,
                        color: label != null && !loading && !noCategory
                            ? SDColors.neutral900
                            : SDColors.neutral400,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  if (loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.keyboard_arrow_down,
                        color: SDColors.neutral500),
                ],
              ),
            ),
          ),
        ),
        if (_servicesError != null &&
            _services.isEmpty &&
            !noCategory) ...[
          const SizedBox(height: 6),
          Text(
            _servicesError!,
            style: SDTypography.bodySmall.copyWith(color: SDColors.error500),
          ),
          TextButton(
            onPressed: () {
              final cat = _selectedCategory;
              if (cat != null) {
                _loadServicesForCategory(cat, resetService: false);
              }
            },
            child: Text(
              'Réessayer',
              style: SDTypography.labelLarge.copyWith(
                color: SDColors.primary700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
