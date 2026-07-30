import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
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

  final Map<String, dynamic> formData = {
    'fullName': '',
    'phone': '',
    'email': '',
    'category': null,
    'categoryName': '',
    'service': null,
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
    'birthDate': null,
    'gender': 'Homme',
    'businessName': '',
    'specialties': <String>[],
    'yearsOfExperience': 0,
    'serviceDescription': '',
    'serviceRadius': 0.0,
    'location': null,
    'minimumHourlyRate': 0.0,
    'maximumHourlyRate': 0.0,
    'billingMode': 'Heure',
    'travelFees': false,
    'travelFeesAmount': 0.0,
    'idCardNumber': '',
    'idCardFront': null,
    'idCardBack': null,
    'certificates': <dynamic>[],
    'insurance': {'number': '', 'document': null},
    'businessRegistry': '',
  };

  late List<Step> _steps;

  @override
  void initState() {
    super.initState();
    _initializeSteps();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthAuthenticated) {
        final u = authState.utilisateur;
        setState(() {
          formData['fullName'] =
              '${u.prenom ?? ''} ${u.nom ?? ''}'.trim();
          formData['phone'] = u.telephone ?? '';
          formData['email'] = u.email ?? '';
          formData['requirePassword'] = false;
        });
      } else {
        setState(() => formData['requirePassword'] = true);
      }
    });
  }

  void _initializeSteps() {
    final stepTitleStyle = SDTypography.titleSmall.copyWith(
      color: SDColors.neutral900,
      fontWeight: FontWeight.w600,
    );
    _steps = [
      Step(
        title: Text('Informations de base', style: stepTitleStyle),
        content: ProviderPersonalInfoStep(
          formData: formData,
          onDataChanged: _updateFormData,
        ),
        isActive: _currentStep >= 0,
      ),
      Step(
        title: Text('Tarification', style: stepTitleStyle),
        content: ProviderPricingStep(
          formData: formData,
          onDataChanged: _updateFormData,
        ),
        isActive: _currentStep >= 1,
      ),
    ];
  }

  void _updateFormData(Map<String, dynamic> newData) {
    setState(() {
      formData.addAll(newData);
      _initializeSteps();
    });
  }

  /// Valide les champs obligatoires de l'étape 1 avant de passer à l'étape 2.
  bool _validateStep1() {
    final name = (formData['fullName'] as String?)?.trim() ?? '';
    final phone = (formData['phone'] as String?)?.trim() ?? '';
    final category = formData['category'];
    final service = formData['service'];
    final areas = formData['serviceAreas'] as List?;

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
    if (category == null) {
      _showError('Veuillez sélectionner votre catégorie');
      return false;
    }
    if (service == null) {
      _showError('Veuillez sélectionner votre service');
      return false;
    }
    if (areas == null || areas.isEmpty) {
      _showError('Veuillez sélectionner au moins une zone d\'intervention');
      return false;
    }
    return true;
  }

  /// Valide les champs obligatoires de l'étape 2.
  bool _validateStep2() {
    final rate = formData['dailyRate'];
    if (rate == null || (rate is double && rate <= 0) || (rate is int && rate <= 0)) {
      _showError('Veuillez renseigner votre tarif journalier');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    AppSnackBar.error(context, message, duration: const Duration(seconds: 3));
  }

  void _submitForm() {
    if (!_validateStep2()) return;

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
    return {
      'fullName': formData['fullName'],
      'phone': formData['phone'],
      'email': formData['email'],
      'password': formData['password'],
      'service': formData['service'] ?? '',
      'category': formData['categoryName'] ?? formData['category'] ?? '',
      'prixprestataire': formData['dailyRate'],
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
      'tarifHoraireMin': formData['dailyRate'] / 8,
      'tarifHoraireMax': formData['dailyRate'] / 6,
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

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    // Guard : utilisateur non connecté
    if (authState is! AuthAuthenticated) {
      return Scaffold(
        backgroundColor: SDColors.neutral50,
        appBar: SDWhiteAppBar.appBar(
          centerTitle: false,
          title: 'Devenir prestataire',
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: SDColors.primary50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.handyman_rounded, size: 56, color: SDColors.primary600),
                ),
                const SizedBox(height: 24),
                Text(
                  'Connexion requise',
                  style: SDTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Vous devez être connecté pour créer votre profil prestataire.',
                  style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: SDButton(
                    text: 'Se connecter',
                    onPressed: () => context.push('/login'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SDButton(
                    text: 'Créer un compte',
                    type: SDButtonType.outlined,
                    onPressed: () => context.push('/register'),
                  ),
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
        if (state is ServiceProviderRegistrationLoading) {
          AppSnackBar.info(context, 'Envoi en cours…');
        } else if (state is ServiceProviderRegistrationSuccess) {
          AppSnackBar.success(context, state.message);

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

          Future.delayed(const Duration(seconds: 2), () {
            final auth = context.read<AuthCubit>().state;
            if (auth is AuthAuthenticated) {
              context.push('/providermain', extra: auth.utilisateur);
            }
          });
        } else if (state is ServiceProviderRegistrationFailure) {
          AppSnackBar.error(context, state.error);
        }
      },
      child: Scaffold(
        backgroundColor: SDColors.neutral50,
        appBar: SDWhiteAppBar.appBar(
          centerTitle: false,
          title: 'Devenir prestataire',
        ),
        body: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          steps: _steps,
          onStepContinue: () {
            if (_currentStep == 0) {
              if (_validateStep1()) {
                setState(() {
                  _currentStep = 1;
                  _initializeSteps();
                });
              }
            } else {
              _submitForm();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep--;
                _initializeSteps();
              });
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: BlocBuilder<ServiceProviderRegistrationBlocM,
                        ServiceProviderRegistrationStateM>(
                      builder: (context, state) {
                        final isLoading =
                            state is ServiceProviderRegistrationLoading;
                        return SDButton(
                          text: _currentStep == _steps.length - 1
                              ? 'Soumettre'
                              : 'Suivant',
                          isLoading: isLoading,
                          onPressed: isLoading ? null : details.onStepContinue,
                          fullWidth: true,
                        );
                      },
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: SDButton(
                        text: 'Précédent',
                        type: SDButtonType.outlined,
                        onPressed: details.onStepCancel,
                        fullWidth: true,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
