import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/mobile/view/serviceproviderregistrationpagem/screens/steps/provider_personal_info_step.dart';
import 'package:sdealsmobile/mobile/view/serviceproviderregistrationpagem/screens/steps/provider_pricing_step.dart';

import '../serviceproviderregistrationoageblocm/serviceProviderRegistrationPageBlocM.dart';
import '../serviceproviderregistrationoageblocm/serviceProviderRegistrationPageEventM.dart';
import '../serviceproviderregistrationoageblocm/serviceProviderRegistrationPageStateM.dart';

class ServiceProviderRegistrationScreenM extends StatefulWidget {
  const ServiceProviderRegistrationScreenM({Key? key}) : super(key: key);

  @override
  State<ServiceProviderRegistrationScreenM> createState() =>
      _ServiceProviderRegistrationScreenMState();
}

class _ServiceProviderRegistrationScreenMState
    extends State<ServiceProviderRegistrationScreenM> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // ✅ FORMULAIRE SIMPLIFIÉ - Compatible avec le backend
  final Map<String, dynamic> formData = {
    // ÉTAPE 1 : Infos de base (6 champs)
    'fullName': '',
    'phone': '',
    'email': '', // OPTIONNEL maintenant
    'category': 'Plombier',
    'service': '', // Service spécifique
    'serviceAreas': <String>[],

    // ÉTAPE 2 : Tarification (3 champs)
    'dailyRate': 0.0, // Tarif par jour (plus simple que horaire)
    'profileImage': null, // Photo optionnelle
    'description': '', // Description optionnelle

    // CHAMPS REQUIS POUR LE BACKEND (ajoutés automatiquement)
    'localisation': '', // Sera rempli avec la première zone
    'localisationmaps': {'latitude': 0.0, 'longitude': 0.0}, // GPS par défaut
    'prixprestataire': 0.0, // Sera rempli avec dailyRate
    'position': null, // Position exacte de l'utilisateur
    'address': '', // Adresse de la position

    // CHAMPS OBLIGATOIRES SUPPRIMÉS (seront optionnels plus tard)
    'password': '', // Gardé pour compatibilité
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
  }

  void _initializeSteps() {
    // ✅ SIMPLIFIÉ : 2 étapes seulement au lieu de 5
    _steps = [
      Step(
        title: const Text('Informations de base'),
        content: ProviderPersonalInfoStep(
          formData: formData,
          onDataChanged: _updateFormData,
        ),
        isActive: _currentStep >= 0,
      ),
      Step(
        title: const Text('Tarification'),
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
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // ✅ Préparer les données pour le backend
      final backendData = _prepareBackendData();

      // ✅ Injecter l'userId existant s'il est connecté
      final auth = context.read<AuthCubit>().state;
      if (auth is AuthAuthenticated) {
        backendData['existingUserId'] = auth.utilisateur.idutilisateur;
      }

      context.read<ServiceProviderRegistrationBlocM>().add(
            SubmitServiceProviderRegistrationEvent(formData: backendData),
          );
    }
  }

  // ✅ Mapper les données simplifiées vers le format backend
  Map<String, dynamic> _prepareBackendData() {
    // Note: Le service sera récupéré côté backend en fonction de la catégorie
    // Pour l'instant, on utilise un service par défaut qui sera géré par le backend

    return {
      // Champs utilisateur (inchangés)
      'fullName': formData['fullName'],
      'phone': formData['phone'],
      'email': formData['email'],
      'password': formData['password'],

      // Champs prestataire (mappés pour le backend)
      'service':
          formData['service'] ?? '', // Service sélectionné par l'utilisateur
      'category': formData['category'] ?? '', // Catégorie sélectionnée
      'prixprestataire': formData['dailyRate'],
      'localisation': formData['serviceAreas'].isNotEmpty
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

      // Champs optionnels avec valeurs par défaut
      'note': 'Profil créé via inscription simplifiée',
      'verifier': false,
      'specialite': [formData['category']],
      'anneeExperience': '0',
      'rayonIntervention': 10, // 10 km par défaut
      'tarifHoraireMin': formData['dailyRate'] / 8, // Estimation horaire
      'tarifHoraireMax': formData['dailyRate'] / 6, // Estimation horaire

      // Champs optionnels vides
      'numeroCNI': '',
      'numeroRCCM': '',
      'numeroAssurance': '',
      'nbMission': 0,
      'revenus': 0,
      'clients': [],

      // Source pour traçabilité
      'source': 'sdealsmobile',
      'status': 'pending',
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ServiceProviderRegistrationBlocM,
        ServiceProviderRegistrationStateM>(
      listener: (context, state) {
        if (state is ServiceProviderRegistrationLoading) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Envoi en cours...")));
        } else if (state is ServiceProviderRegistrationSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));

          // ✅ NOUVEAU : Mettre à jour les rôles de l'utilisateur connecté
          final auth = context.read<AuthCubit>().state;
          if (auth is AuthAuthenticated) {
            final currentRoles = List<String>.from(auth.roles);

            // Ajouter le rôle PRESTATAIRE s'il n'existe pas déjà
            if (!currentRoles.contains('PRESTATAIRE')) {
              currentRoles.add('PRESTATAIRE');

              // Mettre à jour AuthCubit avec les nouveaux rôles
              context.read<AuthCubit>().setRoles(
                    roles: currentRoles,
                    activeRole:
                        'PRESTATAIRE', // Basculer automatiquement vers le rôle prestataire
                  );

              print("✅ Rôle PRESTATAIRE ajouté à l'utilisateur: $currentRoles");
            }
          }

          Future.delayed(const Duration(seconds: 2), () {
            final auth = context.read<AuthCubit>().state;
            if (auth is AuthAuthenticated) {
              // Utiliser GoRouter pour la navigation
              context.push('/providermain', extra: auth.utilisateur);
            }
          });
        } else if (state is ServiceProviderRegistrationFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Devenir prestataire'),
          backgroundColor: Colors.green.shade700,
        ),
        body: Form(
          key: _formKey,
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            steps: _steps,
            onStepContinue: () {
              setState(() {
                if (_currentStep < _steps.length - 1) {
                  _currentStep++;
                } else {
                  _submitForm();
                }
              });
            },
            onStepCancel: () {
              setState(() {
                if (_currentStep > 0) {
                  _currentStep--;
                }
              });
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          _currentStep == _steps.length - 1
                              ? 'Soumettre'
                              : 'Suivant',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: details.onStepCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Précédent',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
