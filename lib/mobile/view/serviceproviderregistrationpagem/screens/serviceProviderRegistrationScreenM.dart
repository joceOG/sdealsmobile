import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';
import 'package:sdealsmobile/mobile/view/serviceproviderregistrationpagem/screens/steps/provider_activity_details_step.dart';
import 'package:sdealsmobile/mobile/view/serviceproviderregistrationpagem/screens/steps/provider_personal_info_step.dart';
import 'package:sdealsmobile/mobile/view/serviceproviderregistrationpagem/screens/steps/provider_pricing_step.dart';

import '../serviceproviderregistrationoageblocm/serviceProviderRegistrationPageBlocM.dart';
import '../serviceproviderregistrationoageblocm/serviceProviderRegistrationPageEventM.dart';
import '../serviceproviderregistrationoageblocm/serviceProviderRegistrationPageStateM.dart';
import '../../../../../design_system/design_system.dart';
import '../../common/utils/app_snackbar.dart';

class ServiceProviderRegistrationScreenM extends StatefulWidget {
  const ServiceProviderRegistrationScreenM({Key? key}) : super(key: key);

  @override
  State<ServiceProviderRegistrationScreenM> createState() =>
      _ServiceProviderRegistrationScreenMState();
}

class _ServiceProviderRegistrationScreenMState
    extends State<ServiceProviderRegistrationScreenM> {
  int _currentStep = 0;
  bool _formUnlocked = false;
  bool _success = false;

  final Map<String, dynamic> formData = {
    'fullName': '',
    'phone': '',
    'email': '',
    'category': null,
    'categoryName': '',
    'service': null,
    'serviceName': '',
    'serviceAreas': <String>[],
    'dailyRate': 0.0,
    'profileImage': null,
    'description': '',
    'localisation': '',
    'localisationmaps': {'latitude': 0.0, 'longitude': 0.0},
    'prixprestataire': 0.0,
    'position': null,
    'address': '',
    'password': '',
    'confirmPassword': '',
    'requirePassword': true,
  };

  static const _stepLabels = [
    'Informations de base',
    'Détails d’activité',
    'Tarification',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthAuthenticated) {
        setState(() {
          _formUnlocked = true;
          formData['fullName'] = joinPersonName(
            prenom: authState.utilisateur.prenom,
            nom: authState.utilisateur.nom,
            fallback: '',
          );
          formData['phone'] = authState.utilisateur.telephone ?? '';
          formData['email'] = authState.utilisateur.email ?? '';
          formData['requirePassword'] = false;
        });
      } else {
        setState(() => formData['requirePassword'] = true);
      }
    });
  }

  void _updateFormData(Map<String, dynamic> newData) {
    formData.addAll(newData);
  }

  bool _validateStep1() {
    final name = (formData['fullName'] as String?)?.trim() ?? '';
    final phone = (formData['phone'] as String?)?.trim() ?? '';
    if (name.isEmpty) {
      _showError('Veuillez renseigner votre nom complet');
      return false;
    }
    if (phone.isEmpty) {
      _showError('Veuillez renseigner votre numéro de téléphone');
      return false;
    }
    if (formData['requirePassword'] == true) {
      final password = (formData['password'] as String?)?.trim() ?? '';
      final confirm = (formData['confirmPassword'] as String?)?.trim() ?? '';
      if (password.length < 6) {
        _showError('Mot de passe requis (6 caractères minimum)');
        return false;
      }
      if (password != confirm) {
        _showError('Les mots de passe ne correspondent pas');
        return false;
      }
    }
    if (formData['category'] == null) {
      _showError('Veuillez sélectionner votre catégorie');
      return false;
    }
    if (formData['service'] == null) {
      _showError('Veuillez sélectionner votre service');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    final areas = formData['serviceAreas'] as List?;
    if (areas == null || areas.isEmpty) {
      _showError('Veuillez sélectionner au moins une zone d’intervention');
      return false;
    }
    return true;
  }

  bool _validateStep3() {
    final rate = formData['dailyRate'];
    if (rate == null ||
        (rate is num && rate <= 0) ||
        (rate is String && (double.tryParse(rate) ?? 0) <= 0)) {
      _showError('Veuillez renseigner votre tarif journalier');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    AppSnackBar.error(context, message, duration: const Duration(seconds: 3));
  }

  void _goNext() {
    if (_currentStep == 0) {
      if (!_validateStep1()) return;
      setState(() => _currentStep = 1);
      return;
    }
    if (_currentStep == 1) {
      if (!_validateStep2()) return;
      setState(() => _currentStep = 2);
      return;
    }
    _submitForm();
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _submitForm() {
    if (!_validateStep3()) return;

    final backendData = _prepareBackendData();
    final auth = context.read<AuthCubit>().state;
    String? token;
    if (auth is AuthAuthenticated) {
      backendData['existingUserId'] = auth.utilisateur.idutilisateur;
      token = auth.token;
    }

    context.read<ServiceProviderRegistrationBlocM>().add(
          SubmitServiceProviderRegistrationEvent(
            formData: backendData,
            token: token,
          ),
        );
  }

  Map<String, dynamic> _prepareBackendData() {
    final daily = (formData['dailyRate'] as num?)?.toDouble() ?? 0.0;
    return {
      'fullName': formData['fullName'],
      'phone': formData['phone'],
      'email': formData['email'],
      'password': formData['password'],
      'service': formData['service'] ?? '',
      'category': formData['categoryName'] ?? formData['category'] ?? '',
      'prixprestataire': daily,
      'localisation': (formData['serviceAreas'] as List?)?.isNotEmpty == true
          ? formData['serviceAreas'][0]
          : 'Abidjan',
      'localisationmaps': formData['position'] != null
          ? {
              'latitude': formData['position'].latitude,
              'longitude': formData['position'].longitude,
            }
          : formData['localisationmaps'],
      'description': formData['description'],
      'zoneIntervention': formData['serviceAreas'],
      'note': 0,
      'verifier': false,
      'specialite': [formData['categoryName'] ?? formData['category'] ?? ''],
      'anneeExperience': '0',
      'rayonIntervention': 10,
      'tarifHoraireMin': daily / 8,
      'tarifHoraireMax': daily / 6,
      'numeroCNI': '',
      'numeroRCCM': '',
      'numeroAssurance': '',
      'nbMission': 0,
      'nbAvis': 0,
      'revenus': 0,
      'clients': [],
      'source': 'sdealsmobile',
      if (formData['profileImage'] != null &&
          (formData['profileImage'] as String).trim().isNotEmpty)
        'profileImage': formData['profileImage'],
    };
  }

  void _openProviderSpace() {
    final auth = context.read<AuthCubit>().state;
    if (auth is AuthAuthenticated) {
      context.push('/providermain', extra: auth.utilisateur);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _formUnlocked = true;
    }

    if (!_formUnlocked && authState is! AuthAuthenticated) {
      return Scaffold(
        backgroundColor: SDColors.white,
        appBar: SDWhiteAppBar.appBar(
          centerTitle: true,
          title: 'Créer mon profil prestataire',
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: SDColors.primary50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.handyman_rounded,
                      size: 56, color: SDColors.primary600),
                ),
                const SizedBox(height: 24),
                Text(
                  'Connexion requise',
                  style: SDTypography.titleLarge
                      .copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Vous devez être connecté pour créer votre profil prestataire.',
                  style: SDTypography.bodyMedium
                      .copyWith(color: SDColors.neutral600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SDButton(
                  text: 'Se connecter',
                  fullWidth: true,
                  onPressed: () => context.push('/login'),
                ),
                const SizedBox(height: 12),
                SDButton(
                  text: 'Créer un compte',
                  type: SDButtonType.outlined,
                  fullWidth: true,
                  onPressed: () => context.push('/register'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return BlocListener<ServiceProviderRegistrationBlocM,
        ServiceProviderRegistrationStateM>(
      listener: (context, state) {
        if (state is ServiceProviderRegistrationSuccess) {
          final auth = context.read<AuthCubit>().state;
          if (auth is AuthAuthenticated) {
            final currentRoles = List<String>.from(auth.roles);
            if (!currentRoles.contains('PRESTATAIRE')) {
              currentRoles.add('PRESTATAIRE');
              context.read<AuthCubit>().setRoles(
                    roles: currentRoles,
                    activeRole: 'PRESTATAIRE',
                  );
            }
          }
          setState(() => _success = true);
        } else if (state is ServiceProviderRegistrationFailure) {
          AppSnackBar.error(context, state.error);
        }
      },
      child: _success ? _buildSuccess() : _buildWizard(),
    );
  }

  Widget _buildSuccess() {
    return Scaffold(
      backgroundColor: SDColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: SDColors.primary600,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: SDColors.white, size: 52),
              ),
              const SizedBox(height: 28),
              Text(
                'Félicitations !',
                style: SDTypography.displaySmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: SDColors.neutral900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Votre profil prestataire a été créé avec succès.\nVous pourrez bientôt recevoir des demandes.',
                textAlign: TextAlign.center,
                style: SDTypography.bodyMedium.copyWith(
                  color: SDColors.neutral600,
                  height: 1.45,
                ),
              ),
              const Spacer(),
              SDButton(
                text: 'Accéder à mon espace prestataire',
                icon: Icons.arrow_forward_rounded,
                iconRight: true,
                fullWidth: true,
                onPressed: _openProviderSpace,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWizard() {
    final bottomPad = SDResponsive.scrollPaddingBelowCta(context, ctaHeight: SDCtaBarHeight.withBack);
    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: SDWhiteAppBar.appBar(
        centerTitle: false,
        title: 'Créer mon profil',
        titleStyle: SDTypography.titleLarge,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: _StepProgress(
              currentStep: _currentStep,
              labels: _stepLabels,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(20, 4, 20, bottomPad),
              physics: const BouncingScrollPhysics(),
              child: _buildStepBody(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_currentStep) {
      case 0:
        return ProviderPersonalInfoStep(
          key: const ValueKey('provider_step_1'),
          formData: formData,
          onDataChanged: _updateFormData,
        );
      case 1:
        return ProviderActivityDetailsStep(
          key: const ValueKey('provider_step_2'),
          formData: formData,
          onDataChanged: _updateFormData,
        );
      default:
        return ProviderPricingStep(
          key: const ValueKey('provider_step_3'),
          formData: formData,
          onDataChanged: _updateFormData,
          onEditSummary: () => setState(() => _currentStep = 0),
        );
    }
  }

  Widget _buildBottomBar() {
    final isLast = _currentStep == 2;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: SDColors.white,
        boxShadow: [
          BoxShadow(
            color: SDColors.neutral900.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BlocBuilder<ServiceProviderRegistrationBlocM,
              ServiceProviderRegistrationStateM>(
            builder: (context, state) {
              final loading = state is ServiceProviderRegistrationLoading;
              return SDButton(
                text: isLast ? 'Créer mon profil prestataire' : 'Continuer',
                icon: isLast
                    ? Icons.check_rounded
                    : Icons.arrow_forward_rounded,
                iconRight: true,
                fullWidth: true,
                isLoading: loading,
                onPressed: loading ? null : _goNext,
              );
            },
          ),
          if (_currentStep > 0) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: _goBack,
              child: Text(
                'Retour',
                style: SDTypography.labelMedium.copyWith(
                  color: SDColors.neutral600,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  final int currentStep;
  final List<String> labels;

  /// Libellés courts pour petits écrans (< 360 dp).
  static const List<String> _shortLabels = ['Infos', 'Activité', 'Tarifs'];

  const _StepProgress({
    required this.currentStep,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLabels = SDResponsive.isCompact(context) ? _shortLabels : labels;
    return Column(
      children: [
        Row(
          children: List.generate(effectiveLabels.length * 2 - 1, (i) {
            if (i.isOdd) {
              final after = i ~/ 2;
              final done = currentStep > after;
              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: done ? SDColors.primary600 : SDColors.neutral200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }
            final step = i ~/ 2;
            final active = currentStep >= step;
            return Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? SDColors.primary600 : SDColors.neutral100,
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? SDColors.primary600 : SDColors.neutral300,
                ),
              ),
              child: Text(
                '${step + 1}',
                style: SDTypography.labelSmall.copyWith(
                  color: active ? SDColors.white : SDColors.neutral500,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(effectiveLabels.length, (i) {
            final active = currentStep == i;
            return Expanded(
              child: Text(
                effectiveLabels[i],
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: SDTypography.labelSmall.copyWith(
                  color: active ? SDColors.primary700 : SDColors.neutral500,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
