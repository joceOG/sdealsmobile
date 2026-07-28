import 'package:flutter/material.dart';
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import '../../../../../design_system/colors.dart';
import '../../../../../design_system/typography.dart';

class ProfessionalInfoStep extends StatefulWidget {
  final Map<String, dynamic> formData;

  const ProfessionalInfoStep({Key? key, required this.formData}) : super(key: key);

  @override
  _ProfessionalInfoStepState createState() => _ProfessionalInfoStepState();
}

class _ProfessionalInfoStepState extends State<ProfessionalInfoStep> {
  final TextEditingController _skillsController = TextEditingController();
  String? _selectedExperienceLevel;
  String? _selectedCategory;
  final Set<String> _selectedSkills = {};

  bool _loadingCategories = true;
  String? _categoriesError;
  List<Categorie> _categoriesFromApi = [];

  // Niveaux d'expérience
  final List<String> _experienceLevels = [
    'Débutant',
    'Intermédiaire',
    'Expert'
  ];

  @override
  void initState() {
    super.initState();
    _selectedExperienceLevel = widget.formData['experienceLevel'];
    _selectedCategory = widget.formData['mainCategory'];

    if (widget.formData['skills'] != null) {
      _selectedSkills.addAll(Set<String>.from(widget.formData['skills']));
    }

    if (widget.formData['selectedCategories'] != null &&
        widget.formData['selectedCategories'].isNotEmpty &&
        _selectedCategory == null) {
      _selectedCategory = widget.formData['selectedCategories'].first;
      widget.formData['mainCategory'] = _selectedCategory;
    }

    _loadFreelanceCategories();
  }

  Future<void> _loadFreelanceCategories() async {
    setState(() {
      _loadingCategories = true;
      _categoriesError = null;
    });
    try {
      final list = await ApiClient().fetchCategorie('Freelance');
      list.sort((a, b) => a.nomcategorie.compareTo(b.nomcategorie));
      if (!mounted) return;
      setState(() {
        _categoriesFromApi = list;
        _loadingCategories = false;
        _syncSelectedCategoryWithApi();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCategories = false;
        _categoriesError = 'Impossible de charger les catégories. Réessayez.';
      });
    }
  }

  void _syncSelectedCategoryWithApi() {
    if (_categoriesFromApi.isEmpty) return;
    final names = _categoriesFromApi.map((c) => c.nomcategorie).toSet();
    if (_selectedCategory != null && !names.contains(_selectedCategory)) {
      _selectedCategory = null;
      widget.formData.remove('mainCategory');
      widget.formData.remove('mainCategoryId');
    }
  }

  /// Suggestions de compétences selon le nom de catégorie (backend Freelance).
  List<String> _suggestedSkillsForCategory(String? nom) {
    if (nom == null || nom.isEmpty) return [];
    final n = nom.toLowerCase();
    if (n.contains('tech') || n.contains('cloud') || n.contains(' ia')) {
      return ['JavaScript', 'Python', 'React', 'Flutter', 'Node.js', 'API', 'SQL'];
    }
    if (n.contains('btp') || n.contains('ingenier')) {
      return ['AutoCAD', 'BIM', 'Plans', 'Chantier', 'Normes'];
    }
    if (n.contains('juridique') || n.contains('administratif')) {
      return ['Contrats', 'RGPD', 'Formalités', 'Droit des affaires'];
    }
    if (n.contains('finance') || n.contains('audit')) {
      return ['Comptabilité', 'Excel', 'Analyse financière', 'Reporting'];
    }
    if (n.contains('marketing') || n.contains('ventes')) {
      return ['SEO', 'SEA', 'Réseaux sociaux', 'Copywriting', 'Analytics'];
    }
    if (n.contains('design') || n.contains('creativ')) {
      return ['Figma', 'Photoshop', 'UI/UX', 'Branding', 'Illustration'];
    }
    if (n.contains('redaction') || n.contains('langues')) {
      return ['Rédaction web', 'SEO', 'Traduction', 'Relecture'];
    }
    if (n.contains('audio') || n.contains('video') || n.contains('animation')) {
      return ['Montage', 'Motion design', 'Voix off', 'After Effects'];
    }
    if (n.contains('conseil') || n.contains('formation')) {
      return ['Coaching', 'Formation', 'Gestion de projet', 'Pédagogie'];
    }
    if (n.contains('logistique') || n.contains('services')) {
      return ['Logistique', 'Sourcing', 'E-commerce', 'Organisation'];
    }
    return ['Communication', 'Organisation', 'Relation client', 'Qualité'];
  }

  @override
  void dispose() {
    _skillsController.dispose();
    super.dispose();
  }

  void _addSkill() {
    if (_skillsController.text.isNotEmpty) {
      setState(() {
        _selectedSkills.add(_skillsController.text.trim());
        widget.formData['skills'] = _selectedSkills.toList();
        _skillsController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggested = _suggestedSkillsForCategory(_selectedCategory);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💼 Profil professionnel',
            style: SDTypography.titleLarge,
          ),
          const SizedBox(height: 24),

          TextFormField(
            initialValue: widget.formData['professionalTitle'] ?? '',
            decoration: const InputDecoration(
              labelText: 'Titre professionnel *',
              hintText: 'Ex: Développeur Full-Stack, Designer UI/UX',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ce champ est obligatoire';
              }
              return null;
            },
            onChanged: (value) {
              widget.formData['professionalTitle'] = value;
            },
          ),
          const SizedBox(height: 16),

          if (_loadingCategories)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Chargement des catégories…'),
                ],
              ),
            )
          else if (_categoriesError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_categoriesError!, style: TextStyle(color: Colors.red.shade700)),
                  TextButton.icon(
                    onPressed: _loadFreelanceCategories,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            ),

          if (!_loadingCategories && _categoriesFromApi.isNotEmpty)
            DropdownButtonFormField<String>(
              value: _selectedCategory != null &&
                      _categoriesFromApi.any((c) => c.nomcategorie == _selectedCategory)
                  ? _selectedCategory
                  : null,
              decoration: const InputDecoration(
                labelText: 'Catégorie principale *',
                border: OutlineInputBorder(),
              ),
              items: _categoriesFromApi.map((c) {
                return DropdownMenuItem(
                  value: c.nomcategorie,
                  child: Text(c.nomcategorie, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez sélectionner une catégorie';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                  widget.formData['mainCategory'] = value;
                  Categorie? match;
                  for (final c in _categoriesFromApi) {
                    if (c.nomcategorie == value) {
                      match = c;
                      break;
                    }
                  }
                  if (match != null) {
                    widget.formData['mainCategoryId'] = match.idcategorie;
                  }
                });
              },
            ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _selectedExperienceLevel,
            decoration: const InputDecoration(
              labelText: 'Niveau d\'expérience *',
              border: OutlineInputBorder(),
            ),
            items: _experienceLevels.map((level) {
              return DropdownMenuItem(
                value: level,
                child: Text(level),
              );
            }).toList(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez sélectionner un niveau d\'expérience';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                _selectedExperienceLevel = value;
                widget.formData['experienceLevel'] = value;
              });
            },
          ),
          const SizedBox(height: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Compétences',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skillsController,
                      decoration: const InputDecoration(
                        hintText: 'Ajouter une compétence',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addSkill,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SDColors.primary700,
                      foregroundColor: SDColors.white,
                      padding: const EdgeInsets.all(14),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (suggested.isNotEmpty) ...[
                Text(
                  'Compétences suggérées pour $_selectedCategory:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: suggested.map((skill) {
                    final isSelected = _selectedSkills.contains(skill);
                    return ActionChip(
                      label: Text(skill),
                      backgroundColor: isSelected ? Colors.green.shade100 : null,
                      side: BorderSide(
                        color: isSelected ? Colors.green.shade700 : Colors.grey.shade300,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.green.shade700 : null,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isSelected) {
                            _selectedSkills.remove(skill);
                          } else {
                            _selectedSkills.add(skill);
                          }
                          widget.formData['skills'] = _selectedSkills.toList();
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              Text(
                'Compétences sélectionnées:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedSkills.isEmpty
                    ? [
                        Chip(
                          label: const Text('Aucune compétence'),
                          backgroundColor: Colors.grey.shade200,
                        )
                      ]
                    : _selectedSkills.map((skill) {
                        return Chip(
                          label: Text(skill),
                          backgroundColor: SDColors.primary100,
                          deleteIconColor: SDColors.primary700,
                          onDeleted: () {
                            setState(() {
                              _selectedSkills.remove(skill);
                              widget.formData['skills'] = _selectedSkills.toList();
                            });
                          },
                        );
                      }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextFormField(
            initialValue: widget.formData['portfolioUrl'] ?? '',
            decoration: const InputDecoration(
              labelText: 'URL du Portfolio (optionnel)',
              hintText: 'https://votre-portfolio.com',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
            onChanged: (value) {
              widget.formData['portfolioUrl'] = value;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            initialValue: widget.formData['bio'] ?? '',
            decoration: const InputDecoration(
              labelText: 'Description / Bio *',
              hintText: 'Présentez-vous en quelques lignes...',
              border: OutlineInputBorder(),
              helperText: 'Max. 500 caractères',
            ),
            maxLines: 4,
            maxLength: 500,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ce champ est obligatoire';
              }
              return null;
            },
            onChanged: (value) {
              widget.formData['bio'] = value;
            },
          ),
        ],
      ),
    );
  }
}
