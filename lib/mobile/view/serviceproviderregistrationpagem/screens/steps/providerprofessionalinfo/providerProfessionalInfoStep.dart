import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sdealsmobile/data/models/service.dart';
import 'package:sdealsmobile/mobile/view/serviceproviderregistrationpagem/screens/steps/providerprofessionalinfo/providerprofessionalinfobloc/providerProfessionalInfoBloc.dart';
import 'package:sdealsmobile/mobile/view/serviceproviderregistrationpagem/screens/steps/providerprofessionalinfo/providerprofessionalinfobloc/providerProfessionalInfoEvent.dart';
import 'package:sdealsmobile/mobile/view/serviceproviderregistrationpagem/screens/steps/providerprofessionalinfo/providerprofessionalinfobloc/providerProfessionalInfoState.dart';

class ProviderProfessionalInfoStep extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onDataChanged;

  const ProviderProfessionalInfoStep({
    Key? key,
    required this.formData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<ProviderProfessionalInfoStep> createState() =>
      _ProviderProfessionalInfoStepState();
}

class _ProviderProfessionalInfoStepState
    extends State<ProviderProfessionalInfoStep> {
  late final ProviderProfessionalInfoBloc _bloc;
  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _anneeExperienceController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _businessController = TextEditingController();
  final TextEditingController _rayonInterventionController =
      TextEditingController();
  final TextEditingController _localisationController = TextEditingController();

  String? _selectedCategorie;
  String? _selectedService; // en réalité un Service
  List<String> _selectedSpecialite = [];
  List<String> _selectedZoneIntervention = [];
  LatLng? _selectedLocalisationMaps;

  // Spécialités statiques
  final Map<String, List<String>> _metierSpecialites = {
    'Plombier': [
      'Installation sanitaire',
      'Réparation de fuites',
      'Débouchage'
    ],
    'Électricien': ['Installation électrique', 'Dépannage', 'Câblage'],
    'Menuisier': ['Meubles sur mesure', 'Pose de parquet', 'Réparation'],
    'Peintre': ['Intérieur', 'Extérieur', 'Décoration'],
    'Maçon': ['Construction', 'Rénovation', 'Carrelage'],
  };

  final List<String> _availableAreas = [
    'Abidjan',
    'Abobo',
    'Adjamé',
    'Cocody',
    'Koumassi',
    'Marcory',
    'Plateau',
    'Port-Bouët',
    'Treichville',
    'Yopougon'
  ];

  List<String> _currentSpecialties = [];

  @override
  void initState() {
    super.initState();
    _bloc = ProviderProfessionalInfoBloc();
    _bloc.add(LoadCategorieData());
    // tes autres init comme _initializeFormValues()
  }

  @override
  void dispose() {
    _bloc.close(); // important de fermer le bloc
    super.dispose();
  }

  void _initializeFormValues() {
    _serviceController.text = widget.formData['service'] ?? '';
    _anneeExperienceController.text =
        widget.formData['anneeExperience']?.toString() ?? '';
    _descriptionController.text = widget.formData['description'] ?? '';
    _rayonInterventionController.text =
        widget.formData['rayonIntervention']?.toString() ?? '';
    _localisationController.text = widget.formData['localisation'] ?? '';
    _selectedCategorie = widget.formData['categorie'];
    _selectedService = widget.formData['service'];
    _selectedSpecialite =
        List<String>.from(widget.formData['specialite'] ?? []);
    _selectedZoneIntervention =
        List<String>.from(widget.formData['zoneIntervention'] ?? []);

    if (_selectedService != null) {
      _updateSpecialties(_selectedService!);
    }

    if (widget.formData['localisationMaps'] != null) {
      _selectedLocalisationMaps = LatLng(
        widget.formData['localisationMaps']['latitude'],
        widget.formData['localisationMaps']['longitude'],
      );
    }
  }

  void _updateSpecialties(String metier) {
    setState(() {
      _currentSpecialties = _metierSpecialites[metier] ?? [];
    });
  }

  void _updateFormData() {
    Map<String, dynamic> updatedData = {
      'service': _serviceController.text,
      'categorie': _selectedCategorie,
      'service': _selectedService,
      'specialite': _selectedSpecialite,
      'anneeExperience': int.tryParse(_anneeExperienceController.text) ?? 0,
      'description': _descriptionController.text,
      'zoneIntervention': _selectedZoneIntervention,
      'rayonIntervention':
          double.tryParse(_rayonInterventionController.text) ?? 0.0,
      'localisation': _localisationController.text,
      'localisationMaps': _selectedLocalisationMaps != null
          ? {
              'latitude': _selectedLocalisationMaps!.latitude,
              'longitude': _selectedLocalisationMaps!.longitude,
            }
          : null,
    };
    widget.onDataChanged(updatedData);
  }

  void _showMapSelector() async {
    setState(() {
      _selectedLocalisationMaps = const LatLng(5.3599517, -4.0082563);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Localisation sélectionnée'),
        backgroundColor: Colors.green,
      ),
    );

    _updateFormData();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProviderProfessionalInfoBloc>.value(
      value: _bloc,
      child: BlocBuilder<ProviderProfessionalInfoBloc,
          ProviderProfessionalInfoState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informations professionnelles',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Nom entreprise
                TextFormField(
                  controller: _businessController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'entreprise/Activité *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  onChanged: (value) => _updateFormData(),
                ),
                const SizedBox(height: 16),

                // Catégorie générale (vient du Bloc)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Catégorie générale',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  value: _selectedCategorie,
                  hint: const Text('Sélectionner une catégorie'),
                  items: state.listItems.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat.idcategorie,
                      child: Text(cat.nomcategorie),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategorie = value;
                      _selectedService = null;
                      _selectedSpecialite = [];
                    });
                    if (value != null) {
                      context
                          .read<ProviderProfessionalInfoBloc>()
                          .add(LoadServiceData(value));
                    }
                    _updateFormData();
                  },
                ),
                const SizedBox(height: 16),

                // Métier (services selon la catégorie)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Métier',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                  value: _selectedService,
                  items: state.listItems2.map((Service s) {
                    return DropdownMenuItem<String>(
                      value: s.idservice,
                      child: Text(s.nomservice),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedService = value;
                      _selectedSpecialite = [];
                      if (value != null) _updateSpecialties(value);
                    });
                    _updateFormData();
                  },
                ),
                const SizedBox(height: 16),

                // Spécialités
                if (_selectedService != null &&
                    _currentSpecialties.isNotEmpty) ...[
                  const Text(
                    'Spécialités',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _currentSpecialties.map((specialty) {
                      final isSelected =
                          _selectedSpecialite.contains(specialty);
                      return FilterChip(
                        label: Text(specialty),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSpecialite.add(specialty);
                            } else {
                              _selectedSpecialite.remove(specialty);
                            }
                          });
                          _updateFormData();
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),

                // Années expérience
                TextFormField(
                  controller: _anneeExperienceController,
                  decoration: const InputDecoration(
                    labelText: 'Années d\'expérience',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.timeline),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _updateFormData(),
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description des services',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                  onChanged: (value) => _updateFormData(),
                ),
                const SizedBox(height: 16),

                // Zones d'intervention
                const Text('Zones d\'intervention'),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _availableAreas.map((area) {
                    final isSelected = _selectedZoneIntervention.contains(area);
                    return FilterChip(
                      label: Text(area),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedZoneIntervention.add(area);
                          } else {
                            _selectedZoneIntervention.remove(area);
                          }
                        });
                        _updateFormData();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Rayon
                TextFormField(
                  controller: _rayonInterventionController,
                  decoration: const InputDecoration(
                    labelText: 'Rayon d\'intervention (km)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.adjust),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _updateFormData(),
                ),
                const SizedBox(height: 16),

                // Localisation texte
                TextFormField(
                  controller: _localisationController,
                  decoration: const InputDecoration(
                    labelText: 'Localisation (ville/quartier)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  onChanged: (value) => _updateFormData(),
                ),
                const SizedBox(height: 16),

                // Maps
                ElevatedButton.icon(
                  onPressed: _showMapSelector,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                  ),
                  icon: const Icon(Icons.location_on, color: Colors.white),
                  label: Text(
                    _selectedLocalisationMaps != null
                        ? 'Localisation sélectionnée ✓'
                        : 'Sélectionner ma localisation précise',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (_selectedLocalisationMaps != null)
                  SizedBox(
                    height: 200,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _selectedLocalisationMaps!,
                        zoom: 14,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('selected_location'),
                          position: _selectedLocalisationMaps!,
                        ),
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
