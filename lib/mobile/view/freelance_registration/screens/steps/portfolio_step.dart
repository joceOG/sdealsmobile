import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../../design_system/colors.dart';
import '../../../../../design_system/typography.dart';

class PortfolioStep extends StatefulWidget {
  final Map<String, dynamic> formData;

  const PortfolioStep({Key? key, required this.formData}) : super(key: key);

  @override
  _PortfolioStepState createState() => _PortfolioStepState();
}

class _PortfolioStepState extends State<PortfolioStep> {
  final List<Map<String, dynamic>> _portfolioItems = [];
  final ImagePicker _picker = ImagePicker();
  final int _maxProjects = 5;

  final TextEditingController _linkedInController = TextEditingController();
  final TextEditingController _githubController = TextEditingController();
  final TextEditingController _behanceController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialiser avec les données existantes si disponibles
    _linkedInController.text = widget.formData['linkedIn'] ?? '';
    _githubController.text = widget.formData['github'] ?? '';
    _behanceController.text = widget.formData['behance'] ?? '';

    if (widget.formData['portfolioItems'] != null) {
      // Convertir les données de portfolio existantes
      final List<dynamic> items = widget.formData['portfolioItems'];
      for (var item in items) {
        _portfolioItems.add(Map<String, dynamic>.from(item));
      }
    }
  }

  @override
  void dispose() {
    _linkedInController.dispose();
    _githubController.dispose();
    _behanceController.dispose();
    super.dispose();
  }

  Future<void> _addProject() async {
    if (_portfolioItems.length >= _maxProjects) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 projets peuvent être ajoutés'),
          backgroundColor: SDColors.warning500,
        ),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ProjectDialog(),
    );

    if (result != null) {
      setState(() {
        _portfolioItems.add(result);
        widget.formData['portfolioItems'] = _portfolioItems;
      });
    }
  }

  void _removeProject(int index) {
    setState(() {
      _portfolioItems.removeAt(index);
      widget.formData['portfolioItems'] = _portfolioItems;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎓 Portfolio & Références',
            style: SDTypography.titleLarge,
          ),
          const SizedBox(height: 16),

          // Explication
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SDColors.success50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SDColors.success100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: SDColors.success700),
                    const SizedBox(width: 8),
                    const Text(
                      'Pourquoi ajouter un portfolio ?',
                      style: SDTypography.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Les freelances avec un portfolio complet reçoivent 75% plus de propositions de projets que ceux sans portfolio.',
                  style: SDTypography.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text('• Ajoutez vos meilleurs travaux', style: SDTypography.bodySmall),
                Text('• Décrivez vos réalisations et votre rôle', style: SDTypography.bodySmall),
                Text('• Incluez des images si pertinent', style: SDTypography.bodySmall),
                Text('• Mettez en avant les résultats obtenus', style: SDTypography.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Projets de portfolio
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Échantillons de travail (3-5 max)',
                style: SDTypography.titleMedium,
              ),
              ElevatedButton.icon(
                onPressed: _addProject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SDColors.secondary500,
                  foregroundColor: SDColors.white,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un projet'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Liste des projets
          if (_portfolioItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SDColors.neutral100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SDColors.neutral300),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.work_outline,
                    size: 40,
                    color: SDColors.neutral400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aucun projet ajouté',
                    style: SDTypography.bodyLarge.copyWith(
                      color: SDColors.neutral600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez vos meilleurs travaux pour attirer plus de clients',
                    textAlign: TextAlign.center,
                    style: SDTypography.bodySmall.copyWith(
                      color: SDColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),

          // Affichage des projets
          ...List.generate(_portfolioItems.length, (index) {
            final item = _portfolioItems[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['title'] ?? 'Projet sans titre',
                            style: SDTypography.titleMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: SDColors.error500),
                          onPressed: () => _removeProject(index),
                          tooltip: 'Supprimer ce projet',
                        ),
                      ],
                    ),
                    const Divider(),
                    if (item['imagePath'] != null)
                      Container(
                        height: 120,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(item['imagePath'])),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    Text('Description: ${item['description']}'),
                    if (item['role'] != null && item['role'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('Votre rôle: ${item['role']}'),
                      ),
                    if (item['url'] != null && item['url'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('URL: ${item['url']}'),
                      ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Réseaux sociaux et profils
          const Text(
            'Réseaux sociaux professionnels',
            style: SDTypography.titleMedium,
          ),
          const SizedBox(height: 16),

          // LinkedIn
          TextFormField(
            controller: _linkedInController,
            decoration: const InputDecoration(
              labelText: 'LinkedIn (optionnel)',
              hintText: 'https://linkedin.com/in/votreprofil',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
            keyboardType: TextInputType.url,
            onChanged: (value) {
              widget.formData['linkedIn'] = value;
            },
          ),
          const SizedBox(height: 16),

          // GitHub
          TextFormField(
            controller: _githubController,
            decoration: const InputDecoration(
              labelText: 'GitHub (optionnel)',
              hintText: 'https://github.com/votreprofil',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.code),
              helperText: 'Recommandé pour les développeurs',
            ),
            keyboardType: TextInputType.url,
            onChanged: (value) {
              widget.formData['github'] = value;
            },
          ),
          const SizedBox(height: 16),

          // Behance/Dribbble
          TextFormField(
            controller: _behanceController,
            decoration: const InputDecoration(
              labelText: 'Behance/Dribbble (optionnel)',
              hintText: 'https://behance.net/votreprofil',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.brush),
              helperText: 'Recommandé pour les designers',
            ),
            keyboardType: TextInputType.url,
            onChanged: (value) {
              widget.formData['behance'] = value;
            },
          ),
        ],
      ),
    );
  }
}

class ProjectDialog extends StatefulWidget {
  @override
  _ProjectDialogState createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<ProjectDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _projectImage;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _projectImage = pickedFile;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _roleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un projet'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image du projet
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: SDColors.neutral200,
                  borderRadius: BorderRadius.circular(8),
                  image: _projectImage != null
                      ? DecorationImage(
                          image: FileImage(File(_projectImage!.path)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _projectImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: SDColors.neutral600,
                          ),
                          const SizedBox(height: 8),
                          const Text('Ajouter une image'),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // Titre du projet
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre du projet *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Description du projet
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Rôle dans le projet
            TextField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: 'Votre rôle',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // URL du projet
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL (optionnel)',
                border: OutlineInputBorder(),
                hintText: 'https://',
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ANNULER'),
        ),
        ElevatedButton(
          onPressed: () {
            // Vérifier les champs obligatoires
            if (_titleController.text.isEmpty ||
                _descriptionController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Veuillez remplir tous les champs obligatoires'),
                  backgroundColor: SDColors.error500,
                ),
              );
              return;
            }

            // Retourner les données du projet
            Navigator.pop(
              context,
              {
                'title': _titleController.text,
                'description': _descriptionController.text,
                'role': _roleController.text,
                'url': _urlController.text,
                'imagePath': _projectImage?.path,
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: SDColors.secondary500,
          ),
          child: const Text('AJOUTER'),
        ),
      ],
    );
  }
}
