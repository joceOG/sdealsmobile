import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/models/service.dart';
import 'package:sdealsmobile/data/models/professional_capabilities.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/services/freelance_hub_cache.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/common/auth_completion.dart';
import 'package:sdealsmobile/mobile/view/common/utils/app_snackbar.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/registration_wizard_chrome.dart';
import 'package:sdealsmobile/mobile/view/serviceproviderregistrationpagem/screens/widgets/provider_category_picker_sheet.dart';
import 'package:sdealsmobile/mobile/view/serviceproviderregistrationpagem/screens/widgets/provider_service_picker_sheet.dart';
import 'package:sdealsmobile/mobile/view/serviceproviderregistrationpagem/screens/widgets/provider_creation_status_presentation.dart';
import 'package:sdealsmobile/mobile/view/serviceproviderregistrationpagem/screens/widgets/provider_registration_success_view.dart';

/// Inscription freelance alignée sur le cadre Prestataire.
/// Contrat : POST /freelance (catégorie en libellé, pas d’offre créée).
class FreelanceFormScreen extends StatefulWidget {
  const FreelanceFormScreen({
    super.key,
    this.preSelectedCategories,
    this.preSelectedServices,
  });

  final Set<String>? preSelectedCategories;
  final Set<String>? preSelectedServices;

  @override
  State<FreelanceFormScreen> createState() => _FreelanceFormScreenState();
}

class _FreelanceFormScreenState extends State<FreelanceFormScreen> {
  static const _labels = ['Profil', 'Conditions', 'Compléments', 'Récap'];
  static const _levels = ['Débutant', 'Intermédiaire', 'Expert'];
  static const _hours = ['Temps plein', 'Temps partiel', 'Ponctuel'];
  static const _availability = ['Disponible', 'Occupé', 'En pause'];

  int _step = 0;
  bool _submitting = false;
  bool _created = false;
  bool _refreshing = false;
  bool _refreshFailed = false;
  ProfessionalProfileSnapshot? _snapshot;

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _job = TextEditingController();
  final _location = TextEditingController();
  final _bio = TextEditingController();
  final _hourly = TextEditingController();
  final _minBudget = TextEditingController();
  final _skillInput = TextEditingController();
  final _portfolioTitle = TextEditingController();

  String? _categoryId;
  String? _categoryName;
  String? _serviceId;
  String? _serviceName;
  List<Service> _services = [];
  String _level = 'Débutant';
  String _workingHours = 'Temps partiel';
  String _availabilityStatus = 'Disponible';
  final List<String> _skills = [];
  String? _photoPath;
  String? _cni1;
  String? _cni2;
  List<Categorie> _categories = [];
  bool _loadingCategories = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthCubit>().state;
    if (auth is AuthAuthenticated) {
      _name.text = joinPersonName(
        prenom: auth.utilisateur.prenom,
        nom: auth.utilisateur.nom,
        fallback: '',
      );
      _phone.text = auth.utilisateur.telephone;
    }
    final preset = widget.preSelectedCategories;
    if (preset != null && preset.isNotEmpty) {
      _categoryName = preset.first;
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _job.dispose();
    _location.dispose();
    _bio.dispose();
    _hourly.dispose();
    _minBudget.dispose();
    _skillInput.dispose();
    _portfolioTitle.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final list = await ApiClient().fetchCategorie('Freelance');
      if (!mounted) return;
      setState(() {
        _categories = list;
        _loadingCategories = false;
        if (_categoryId == null && _categoryName != null) {
          for (final c in list) {
            if (c.nomcategorie == _categoryName) {
              _categoryId = c.idcategorie;
              break;
            }
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCategories = false);
    }
  }

  int? get _hourlyValue {
    final raw = _hourly.text.replaceAll(RegExp(r'\s'), '');
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  bool _validateStep() {
    switch (_step) {
      case 0:
        if (_name.text.trim().isEmpty) {
          _err('Indiquez votre nom');
          return false;
        }
        if (_job.text.trim().isEmpty) {
          _err('Indiquez votre titre professionnel');
          return false;
        }
        if (_categoryName == null || _categoryName!.isEmpty) {
          _err('Choisissez une catégorie');
          return false;
        }
        if (_serviceId == null || _serviceId!.isEmpty) {
          _err('Choisissez un service');
          return false;
        }
        if (_location.text.trim().isEmpty) {
          _err('Indiquez votre localisation');
          return false;
        }
        return true;
      case 1:
        final rate = _hourlyValue;
        if (rate == null || rate <= 0) {
          _err('Indiquez un tarif horaire supérieur à 0');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _err(String message) => AppSnackBar.error(context, message);

  Future<void> _pickCategory() async {
    final chosen = await ProviderCategoryPickerSheet.show(
      context,
      initialSelectedId: () {
        for (final c in _categories) {
          if (c.nomcategorie == _categoryName) return c.idcategorie;
        }
        return null;
      }(),
      seedCategories: _categories,
      loadCategories: () => ApiClient().fetchCategorie('Freelance'),
    );
    if (chosen == null || !mounted) return;
    if (chosen != _categoryId) {
      setState(() {
        _serviceId = null;
        _serviceName = null;
        _services = [];
      });
    }
    final match = _categories.where((c) => c.idcategorie == chosen);
    setState(() {
      _categoryId = chosen;
      _categoryName = match.isEmpty ? _categoryName : match.first.nomcategorie;
    });
    if (match.isEmpty) {
      final list = await ApiClient().fetchCategorie('Freelance');
      if (!mounted) return;
      final again = list.where((c) => c.idcategorie == chosen);
      setState(() {
        _categories = list;
        if (again.isNotEmpty) {
          _categoryId = chosen;
          _categoryName = again.first.nomcategorie;
        }
      });
    }
  }

  Future<List<Service>> _servicesForCategory() async {
    final categoryId = _categoryId;
    if (categoryId == null || categoryId.isEmpty) return [];
    final all = await ApiClient().fetchServices('Freelance');
    return all.where((s) => s.categorie?.idcategorie == categoryId).toList();
  }

  Future<void> _pickService() async {
    final categoryId = _categoryId;
    if (categoryId == null || categoryId.isEmpty) return;
    final chosen = await ProviderServicePickerSheet.show(
      context,
      categoryId: categoryId,
      categoryLabel: _categoryName ?? '',
      initialSelectedId: _serviceId,
      seedServices: _services,
      loadServices: _servicesForCategory,
    );
    if (chosen == null || !mounted) return;
    var list = _services;
    var name = _serviceName;
    for (final s in list) {
      if (s.idservice == chosen) name = s.nomservice;
    }
    if (name == null || list.every((s) => s.idservice != chosen)) {
      list = await _servicesForCategory();
      if (!mounted) return;
      for (final s in list) {
        if (s.idservice == chosen) name = s.nomservice;
      }
    }
    setState(() {
      _services = list;
      _serviceId = chosen;
      _serviceName = name;
    });
  }

  Future<void> _pickImage(void Function(String) assign) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() => assign(file.path));
  }

  void _next() {
    if (_created || _submitting) return;
    if (!_validateStep()) return;
    if (_step < _labels.length - 1) {
      setState(() => _step++);
      return;
    }
    _submit();
  }

  Future<void> _submit() async {
    if (_created || _submitting) return;
    if (!_validateStep()) return;
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) {
      _err('Connectez-vous pour créer votre profil freelance');
      return;
    }
    setState(() => _submitting = true);
    try {
      final response = await ApiClient().sendAuthorizedMultipart(
        (access) async {
          final uri = Uri.parse('${ApiClient().apiUrl}/freelance');
          final request = http.MultipartRequest('POST', uri);
          if (access != null && access.isNotEmpty) {
            request.headers['Authorization'] = 'Bearer $access';
          }
          void field(String k, String v) => request.fields[k] = v;
          field('utilisateur', auth.utilisateur.idutilisateur);
          field('name', _name.text.trim());
          field('job', _job.text.trim());
          field('category', _categoryName!.trim());
          field('location', _location.text.trim());
          field('hourlyRate', '${_hourlyValue!}');
          field('description', _bio.text.trim());
          field('experienceLevel', _level);
          field('availabilityStatus', _availabilityStatus);
          field('workingHours', _workingHours);
          field('phoneNumber', _phone.text.trim());
          final skills = List<String>.from(_skills);
          final serviceLabel = _serviceName?.trim();
          if (serviceLabel != null &&
              serviceLabel.isNotEmpty &&
              !skills.contains(serviceLabel)) {
            skills.insert(0, serviceLabel);
          }
          field('skills', jsonEncode(skills));
          field('source', 'sdealsmobile');
          final budget = int.tryParse(_minBudget.text.replaceAll(RegExp(r'\s'), ''));
          if (budget != null && budget > 0) {
            field('minimumProjectBudget', '$budget');
          }
          final title = _portfolioTitle.text.trim();
          if (title.isNotEmpty) {
            field('portfolioItems', jsonEncode([
              {'title': title, 'description': ''},
            ]));
          }
          await _attach(request, 'profileImage', _photoPath);
          await _attach(request, 'cni1', _cni1);
          await _attach(request, 'cni2', _cni2);
          return request;
        },
        token: auth.token,
      );
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Mutation : le hub Freelance ne doit plus servir d'entrée antérieure.
        unawaited(FreelanceHubCache.shared.invalidateScope());
        setState(() {
          _created = true;
          _submitting = false;
        });
        await _refresh();
        return;
      }
      setState(() => _submitting = false);
      _err(_apiError(response));
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _err('Création non confirmée. Vérifiez la connexion puis réessayez.');
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _refreshing = true;
      _refreshFailed = false;
    });
    try {
      await context.read<AuthCubit>().refreshRoles();
      if (!mounted) return;
      final auth = context.read<AuthCubit>().state;
      setState(() {
        _refreshing = false;
        _snapshot = auth is AuthAuthenticated ? auth.professional?.freelance : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _refreshing = false;
        _refreshFailed = true;
      });
    }
  }

  String _apiError(dynamic response) {
    try {
      final body = jsonDecode(response.body as String);
      if (body is Map && body['error'] != null) {
        final msg = body['error'].toString();
        if (response.statusCode == 409) return msg;
        return msg;
      }
    } catch (_) {}
    if (response.statusCode == 409) {
      return 'Un profil freelance existe déjà pour ce compte.';
    }
    return 'La création du profil freelance a échoué.';
  }

  void _leaveToProfile() {
    context.go('/homepage');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ClientShellProfileTab.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_created) {
      final presentation = ProviderCreationStatusPresentation.resolve(
        snapshot: _snapshot,
        rolesRefreshFailed: _refreshFailed,
      );
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leaveToProfile();
        },
        child: ProviderRegistrationSuccessView(
          statusPresentation: presentation,
          pageTitle: 'Profil freelance',
          headline: 'Votre profil a été créé',
          subhead: 'Vos informations ont bien été enregistrées.',
          activityTitle: 'Votre expertise',
          primaryLabel: 'Service',
          secondaryLabel: 'Catégorie',
          serviceName: _serviceName ?? '—',
          zonesLabel: _categoryName ?? '—',
          refreshingStatus: _refreshing,
          onBackToProfile: _leaveToProfile,
        ),
      );
    }

    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: SDWhiteAppBar.appBar(
        title: 'Créer mon profil freelance',
        titleStyle: SDTypography.titleLarge,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: RegistrationStepProgress(currentStep: _step, labels: _labels),
          ),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: _body(),
            ),
          ),
          RegistrationWizardFooter(
            primaryLabel: _step == _labels.length - 1
                ? 'Créer mon profil freelance'
                : 'Continuer',
            loading: _submitting,
            onPrimary: _next,
            onBack: _step == 0 ? null : () => setState(() => _step--),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    switch (_step) {
      case 0:
        return _profileStep();
      case 1:
        return _conditionsStep();
      case 2:
        return _extrasStep();
      default:
        return _recap();
    }
  }

  Widget _profileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Profil professionnel'),
        Center(
          child: InkWell(
            onTap: () => _pickImage((p) => _photoPath = p),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: SDColors.neutral100,
              backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
              child: _photoPath == null
                  ? const Icon(Icons.person_outline, color: SDColors.neutral400, size: 32)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Photo de profil (facultative)',
            style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
          ),
        ),
        const SizedBox(height: 16),
        SDInput(label: 'Nom complet *', controller: _name, prefixIcon: Icons.badge_outlined),
        const SizedBox(height: 12),
        SDInput(
          label: 'Téléphone',
          controller: _phone,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        SDInput(
          label: 'Titre professionnel *',
          hint: 'Ex. Développeur, designer',
          controller: _job,
          prefixIcon: Icons.work_outline,
        ),
        const SizedBox(height: 12),
        _pickerTile(
          label: 'Catégorie *',
          value: _loadingCategories ? 'Chargement…' : (_categoryName ?? 'Choisir une catégorie'),
          filled: _categoryName != null,
          onTap: _loadingCategories ? null : _pickCategory,
        ),
        const SizedBox(height: 12),
        _pickerTile(
          label: 'Service *',
          value: _categoryId == null
              ? 'Sélectionnez d’abord une catégorie'
              : (_serviceName ?? 'Choisir un service'),
          filled: _serviceName != null,
          onTap: _categoryId == null ? null : _pickService,
        ),
        const SizedBox(height: 12),
        SDInput(
          label: 'Localisation *',
          hint: 'Ville ou quartier',
          controller: _location,
          prefixIcon: Icons.place_outlined,
        ),
      ],
    );
  }

  Widget _conditionsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Compétences et conditions'),
        _choice('Niveau d’expérience', _levels, _level, (v) => setState(() => _level = v)),
        const SizedBox(height: 12),
        _choice('Disponibilité', _hours, _workingHours, (v) => setState(() => _workingHours = v)),
        const SizedBox(height: 12),
        _choice(
          'Statut',
          _availability,
          _availabilityStatus,
          (v) => setState(() => _availabilityStatus = v),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SDInput(
                label: 'Compétence',
                controller: _skillInput,
                hint: 'Ajouter une compétence',
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Ajouter',
              onPressed: () {
                final value = _skillInput.text.trim();
                if (value.isEmpty) return;
                setState(() {
                  if (!_skills.contains(value)) _skills.add(value);
                  _skillInput.clear();
                });
              },
              icon: const Icon(Icons.add_circle_outline, color: SDColors.primary700),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: _skills
              .map((s) => Chip(
                    label: Text(s),
                    onDeleted: () => setState(() => _skills.remove(s)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        SDInput(
          label: 'Présentation',
          controller: _bio,
          maxLines: 4,
          maxLength: 500,
        ),
        const SizedBox(height: 12),
        SDInput(
          label: 'Tarif horaire (FCFA) *',
          controller: _hourly,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 12),
        SDInput(
          label: 'Budget minimum de projet (facultatif)',
          controller: _minBudget,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }

  Widget _extrasStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Compléments facultatifs'),
        Text(
          'Le portfolio et les pièces ne bloquent pas l’inscription. Elles restent privées lorsqu’il s’agit de documents.',
          style: SDTypography.bodySmall.copyWith(color: SDColors.neutral600, height: 1.35),
        ),
        const SizedBox(height: 12),
        SDInput(
          label: 'Titre d’une réalisation (facultatif)',
          controller: _portfolioTitle,
        ),
        const SizedBox(height: 12),
        _fileTile('Pièce d’identité — recto', _cni1, () => _pickImage((p) => _cni1 = p)),
        _fileTile('Pièce d’identité — verso', _cni2, () => _pickImage((p) => _cni2 = p)),
      ],
    );
  }

  Widget _recap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Récapitulatif'),
        _recapLine('Nom', _name.text, 0),
        _recapLine('Titre', _job.text, 0),
        _recapLine('Catégorie', _categoryName ?? '—', 0),
        _recapLine('Service', _serviceName ?? '—', 0),
        _recapLine('Localisation', _location.text, 0),
        _recapLine('Tarif horaire', '${_hourlyValue ?? '—'} FCFA', 1),
        _recapLine('Compétences', _skills.isEmpty ? '—' : _skills.join(', '), 1),
      ],
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          title,
          style: SDTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
        ),
      );

  Widget _choice(String label, List<String> values, String current, ValueChanged<String> onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SDTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((v) {
            final selected = v == current;
            return ChoiceChip(
              label: Text(v),
              selected: selected,
              onSelected: (_) => onPick(v),
              selectedColor: SDColors.primary50,
              labelStyle: SDTypography.labelMedium.copyWith(
                color: selected ? SDColors.primary800 : SDColors.neutral700,
                fontWeight: FontWeight.w700,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _pickerTile({
    required String label,
    required String value,
    required bool filled,
    required VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SDTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: SDColors.neutral200),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: SDTypography.bodyLarge.copyWith(
                color: filled ? SDColors.neutral900 : SDColors.neutral400,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fileTile(String label, String? path, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: SDTypography.bodyMedium),
      subtitle: Text(path == null ? 'Aucune pièce' : 'Fichier sélectionné'),
      trailing: const Icon(Icons.upload_file_outlined),
      onTap: onTap,
    );
  }

  Widget _recapLine(String label, String value, int editStep) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: SDTypography.labelSmall.copyWith(color: SDColors.neutral500)),
      subtitle: Text(value, style: SDTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
      trailing: TextButton(
        onPressed: () => setState(() => _step = editStep),
        child: const Text('Modifier'),
      ),
    );
  }
}

Future<void> _attach(http.MultipartRequest request, String field, String? path) async {
  if (path == null || path.isEmpty) return;
  final file = File(path);
  if (!await file.exists()) return;
  request.files.add(await http.MultipartFile.fromPath(field, path));
}
