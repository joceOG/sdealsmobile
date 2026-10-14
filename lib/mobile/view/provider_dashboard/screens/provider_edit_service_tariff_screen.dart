import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/categorie.dart';
import '../../../../data/models/service.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../data/utils/display_text.dart';
import '../../../../design_system/design_system.dart';
import '../../serviceproviderregistrationpagem/screens/steps/provider_pricing_step.dart';
import '../../serviceproviderregistrationpagem/screens/widgets/provider_category_picker_sheet.dart';
import '../../serviceproviderregistrationpagem/screens/widgets/provider_service_picker_sheet.dart';
import '../bloc/provider_profile_bloc.dart';
import '../bloc/provider_profile_event.dart';
import '../bloc/provider_profile_state.dart';

/// Résultat après enregistrement réussi sur l'écran Service et tarif.
class ProviderServiceTariffResult {
  const ProviderServiceTariffResult({
    required this.rate,
    required this.serviceId,
    required this.serviceName,
    this.categoryLabel,
    this.categoryId,
  });

  final double rate;
  final String serviceId;
  final String serviceName;
  final String? categoryLabel;
  final String? categoryId;
}

/// Un seul service catalogue + tarif [prixprestataire] (PUT prestataire).
class ProviderEditServiceTariffScreen extends StatefulWidget {
  const ProviderEditServiceTariffScreen({
    super.key,
    required this.prestataireId,
    required this.serviceName,
    this.serviceId,
    this.categoryLabel,
    this.categoryId,
    required this.initialDailyRate,
  });

  final String prestataireId;
  final String serviceName;
  final String? serviceId;
  final String? categoryLabel;
  final String? categoryId;
  final double? initialDailyRate;

  @override
  State<ProviderEditServiceTariffScreen> createState() =>
      _ProviderEditServiceTariffScreenState();
}

class _ProviderEditServiceTariffScreenState
    extends State<ProviderEditServiceTariffScreen> {
  final ApiClient _apiClient = ApiClient();
  late final TextEditingController _rateController;

  late String _serviceName;
  late String? _serviceId;
  late String? _categoryLabel;
  late String? _categoryId;

  late final String? _initialServiceId;
  late final double? _initialRate;

  bool _rateInvalid = false;
  bool _rateZero = false;
  bool _saving = false;
  bool _awaitingSave = false;

  @override
  void initState() {
    super.initState();
    _serviceName = widget.serviceName;
    _serviceId = widget.serviceId;
    _categoryLabel = widget.categoryLabel;
    _categoryId = widget.categoryId;
    _initialServiceId = widget.serviceId;

    final initial = widget.initialDailyRate;
    _initialRate = initial != null && initial > 0 ? initial : null;
    _rateController = TextEditingController(
      text: _initialRate != null
          ? NumberFormat('#,###', 'fr_FR')
              .format(_initialRate.round())
              .replaceAll(',', ' ')
          : '',
    );
    _rateController.addListener(_syncRateFlags);
  }

  @override
  void dispose() {
    _rateController.removeListener(_syncRateFlags);
    _rateController.dispose();
    super.dispose();
  }

  void _syncRateFlags() {
    if (_rateController.text.trim().isEmpty) {
      setState(() {
        _rateInvalid = false;
        _rateZero = false;
      });
      return;
    }
    final raw = _rateController.text.replaceAll(RegExp(r'\s'), '');
    final asInt = int.tryParse(raw);
    setState(() {
      _rateInvalid = asInt == null;
      _rateZero = asInt != null && asInt <= 0;
    });
  }

  bool get _dirty {
    final rate = parseProviderDailyRateText(_rateController.text);
    final rateChanged = rate?.toDouble() != _initialRate;
    final serviceChanged =
        (_serviceId ?? '') != (_initialServiceId ?? '');
    return rateChanged || serviceChanged;
  }

  String? _inlineRateError() {
    if (_rateInvalid) return 'Montant invalide';
    if (_rateZero) return 'Le tarif doit être supérieur à 0 FCFA';
    return null;
  }

  String _previewPrice() {
    final parsed = parseProviderDailyRateText(_rateController.text);
    if (parsed == null || parsed <= 0) return '—';
    return formatOptionalPrice(parsed.toDouble(), suffix: 'FCFA') ?? '—';
  }

  Future<List<Service>> _fetchServicesForCategory(String categoryId) async {
    final services = await _apiClient.fetchServices('Métiers');
    return services
        .where((s) => s.categorie?.idcategorie == categoryId)
        .toList();
  }

  Future<List<Categorie>> _fetchCategories() =>
      _apiClient.fetchCategorie('Métiers');

  Future<void> _openChangeCategory() async {
    final chosen = await ProviderCategoryPickerSheet.show(
      context,
      initialSelectedId: _categoryId,
      loadCategories: _fetchCategories,
    );
    if (chosen == null || !mounted) return;
    final cats = await _fetchCategories();
    String? label;
    for (final c in cats) {
      if (c.idcategorie == chosen) {
        label = c.nomcategorie;
        break;
      }
    }
    setState(() {
      _categoryId = chosen;
      if (label != null && label.isNotEmpty) _categoryLabel = label;
      _serviceId = null;
    });
    await _openServicePicker(forceCategoryId: chosen, categoryLabel: label);
  }

  Future<void> _openServicePicker({
    String? forceCategoryId,
    String? categoryLabel,
  }) async {
    var categoryId = forceCategoryId ?? _categoryId;
    var catLabel = categoryLabel ?? _categoryLabel ?? '';
    if (categoryId == null || categoryId.isEmpty) {
      await _openChangeCategory();
      return;
    }

    final chosen = await ProviderServicePickerSheet.show(
      context,
      categoryId: categoryId,
      categoryLabel: catLabel,
      initialSelectedId: _serviceId,
      loadServices: () => _fetchServicesForCategory(categoryId),
    );
    if (chosen == null || !mounted) return;

    final services = await _fetchServicesForCategory(categoryId);
    Service? match;
    for (final s in services) {
      if (s.idservice == chosen) {
        match = s;
        break;
      }
    }

    setState(() {
      _serviceId = chosen;
      if (match != null) {
        _serviceName = match.nomservice;
        final cat = match.categorie;
        if (cat != null) {
          _categoryId = cat.idcategorie;
          _categoryLabel = cat.nomcategorie;
        }
      }
    });
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter sans enregistrer ?'),
        content: const Text(
          'Les modifications non enregistrées seront perdues.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Rester'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    return leave == true;
  }

  Future<void> _onCancel() async {
    if (await _confirmLeave() && mounted) {
      Navigator.pop(context);
    }
  }

  void _save() {
    final rate = parseProviderDailyRateText(_rateController.text);
    if (rate == null) {
      setState(() {
        _rateInvalid = _rateController.text.trim().isNotEmpty;
        _rateZero = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indiquez un tarif valide')),
      );
      return;
    }
    if (rate <= 0) {
      setState(() => _rateZero = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le tarif doit être supérieur à 0 FCFA')),
      );
      return;
    }
    final effectiveServiceId = _serviceId ?? _initialServiceId;
    if (effectiveServiceId == null || effectiveServiceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un service')),
      );
      return;
    }

    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return;

    final body = <String, dynamic>{
      'prixprestataire': rate.toDouble(),
    };
    if (_serviceId != null &&
        _serviceId!.isNotEmpty &&
        _serviceId != _initialServiceId) {
      body['service'] = _serviceId;
    }

    setState(() => _saving = true);
    final bloc = context.read<ProviderProfileBloc>();
    bloc.setToken(auth.token);
    _awaitingSave = true;
    bloc.add(UpdateProviderProfile(widget.prestataireId, body));
  }

  void _onProfileUpdateState(ProviderProfileState state) {
    if (!_awaitingSave) return;
    if (state is ProviderProfileError) {
      setState(() {
        _saving = false;
        _awaitingSave = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    } else if (state is ProviderProfileLoaded) {
      final rate = parseProviderDailyRateText(_rateController.text);
      if (rate == null) return;
      setState(() {
        _saving = false;
        _awaitingSave = false;
      });
      Navigator.pop(
        context,
        ProviderServiceTariffResult(
          rate: rate.toDouble(),
          serviceId: _serviceId ?? _initialServiceId ?? '',
          serviceName: _serviceName,
          categoryLabel: _categoryLabel,
          categoryId: _categoryId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rateError = _inlineRateError();

    return BlocListener<ProviderProfileBloc, ProviderProfileState>(
      listener: (context, state) => _onProfileUpdateState(state),
      child: PopScope(
        canPop: !_dirty,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (await _confirmLeave() && mounted) {
            Navigator.pop(context);
          }
        },
        child: Scaffold(
          backgroundColor: SDColors.white,
          appBar: SDWhiteAppBar.appBar(title: 'Service et tarif'),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gérez votre activité et votre tarif.',
                        style: SDTypography.bodyMedium.copyWith(
                          color: SDColors.neutral600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Mon service',
                        style: SDTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: SDColors.neutral900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _serviceCard(),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _saving ? null : () => _openServicePicker(),
                          icon: const Icon(Icons.chevron_right, size: 18),
                          label: const Text('Modifier le service'),
                          iconAlignment: IconAlignment.end,
                          style: TextButton.styleFrom(
                            foregroundColor: SDColors.primary700,
                            textStyle: SDTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _saving ? null : _openChangeCategory,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: SDColors.neutral600,
                        ),
                        child: Text(
                          'Changer de catégorie',
                          style: SDTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Mon tarif',
                        style: SDTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: SDColors.neutral900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: SDColors.primary50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.payments_outlined,
                                color: SDColors.primary700, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Indiquez le tarif affiché sur votre profil.',
                                style: SDTypography.bodySmall.copyWith(
                                  color: SDColors.primary800,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tarif',
                        style: SDTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: SDColors.neutral900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _rateController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [ProviderFcfaDigitsFormatter()],
                        onChanged: (_) => setState(() {}),
                        style: SDTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: SDColors.neutral900,
                        ),
                        decoration: InputDecoration(
                          hintText: '15 000',
                          suffixText: 'FCFA',
                          suffixStyle: SDTypography.labelMedium.copyWith(
                            color: SDColors.neutral500,
                            fontWeight: FontWeight.w700,
                          ),
                          helperText: 'Montant en francs CFA.',
                          errorText: rateError,
                          filled: true,
                          fillColor: SDColors.neutral50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: SDColors.neutral200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: rateError != null
                                  ? SDColors.error500
                                  : SDColors.neutral200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: rateError != null
                                  ? SDColors.error500
                                  : SDColors.primary600,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Aperçu sur votre profil',
                        style: SDTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: SDColors.neutral900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _profilePreview(),
                      const SizedBox(height: 8),
                      Text(
                        'Les modifications seront appliquées après enregistrement.',
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    SDButton(
                      text: 'Enregistrer les modifications',
                      fullWidth: true,
                      onPressed: _saving ? null : _save,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _saving ? null : _onCancel,
                      child: Text(
                        'Annuler',
                        style: SDTypography.bodyMedium.copyWith(
                          color: SDColors.primary700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _serviceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: SDColors.primary50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.handyman_outlined,
                color: SDColors.primary700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _serviceName,
                  style: SDTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: SDColors.neutral900,
                  ),
                ),
                if (_categoryLabel != null &&
                    _categoryLabel!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _categoryLabel!,
                    style: SDTypography.bodySmall.copyWith(
                      color: SDColors.neutral600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profilePreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SDColors.primary50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SDColors.primary100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VOTRE ACTIVITÉ',
            style: SDTypography.labelSmall.copyWith(
              color: SDColors.primary800,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SDColors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.handyman_outlined,
                    color: SDColors.primary700, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _serviceName,
                      style: SDTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: SDColors.neutral900,
                      ),
                    ),
                    if (_categoryLabel != null &&
                        _categoryLabel!.trim().isNotEmpty)
                      Text(
                        _categoryLabel!,
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.neutral600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: SDColors.primary100),
          ),
          Text(
            _previewPrice(),
            style: SDTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: SDColors.neutral900,
            ),
          ),
        ],
      ),
    );
  }
}
