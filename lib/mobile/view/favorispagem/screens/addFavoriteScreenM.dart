import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../favorispageblocm/favoritePageBlocM.dart';
import '../favorispageblocm/favoritePageEventM.dart';
import '../favorispageblocm/favoritePageStateM.dart';
import '../../../../design_system/design_system.dart'; // ✅ Import DS

class AddFavoriteScreenM extends StatefulWidget {
  const AddFavoriteScreenM({super.key});

  @override
  State<AddFavoriteScreenM> createState() => _AddFavoriteScreenMState();
}

class _AddFavoriteScreenMState extends State<AddFavoriteScreenM> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageController = TextEditingController();
  final _prixController = TextEditingController();
  final _categorieController = TextEditingController();
  final _villeController = TextEditingController();
  final _paysController = TextEditingController();
  final _noteController = TextEditingController();
  final _listePersonnaliseeController = TextEditingController();
  final _notesPersonnellesController = TextEditingController();

  String _selectedObjetType = 'PRESTATAIRE';
  String _selectedDevise = 'FCFA';
  bool _alertePrix = false;
  bool _alerteDisponibilite = false;
  List<String> _tags = [];

  final List<String> _objetTypes = [
    'PRESTATAIRE',
    'VENDEUR',
    'FREELANCE',
    'ARTICLE',
    'SERVICE',
    'PRESTATION',
    'COMMANDE',
  ];

  final List<String> _devises = ['FCFA', 'EUR', 'USD'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: SDColors.primary600,
        title: Text('Ajouter un Favori', style: SDTypography.titleMedium.copyWith(color: SDColors.white)),
        centerTitle: true,
        iconTheme: IconThemeData(color: SDColors.white),
        actions: [
          TextButton(
            onPressed: _saveFavorite,
            child: Text(
              'Enregistrer',
              style: SDTypography.labelLarge.copyWith(color: SDColors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: BlocConsumer<FavoritePageBlocM, FavoritePageStateM>(
        listener: (context, state) {
          if (state.addError != null) {
          } else if (!state.isAdding && state.addError == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Favori ajouté avec succès !'),
                backgroundColor: SDColors.success,
              ),
            );
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📝 INFORMATIONS DE BASE
                  _buildSectionTitle('Informations de base'),
                  _buildTextField(
                    controller: _titreController,
                    label: 'Titre *',
                    hint: 'Nom du favori',
                    validator: (value) =>
                        value?.isEmpty == true ? 'Le titre est requis' : null,
                  ),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Description détaillée',
                    maxLines: 3,
                  ),
                  _buildDropdown(
                    label: 'Type d\'objet *',
                    value: _selectedObjetType,
                    items: _objetTypes,
                    onChanged: (value) =>
                        setState(() => _selectedObjetType = value!),
                  ),

                  const SizedBox(height: 24),

                  // 🖼️ IMAGE ET PRIX
                  _buildSectionTitle('Image et prix'),
                  _buildTextField(
                    controller: _imageController,
                    label: 'URL de l\'image',
                    hint: 'https://example.com/image.jpg',
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildTextField(
                          controller: _prixController,
                          label: 'Prix',
                          hint: '0',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdown(
                          label: 'Devise',
                          value: _selectedDevise,
                          items: _devises,
                          onChanged: (value) =>
                              setState(() => _selectedDevise = value!),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 🏷️ CATÉGORIE ET TAGS
                  _buildSectionTitle('Catégorie et tags'),
                  _buildTextField(
                    controller: _categorieController,
                    label: 'Catégorie',
                    hint: 'Ex: Électronique, Mode, etc.',
                  ),
                  _buildTagsField(),

                  const SizedBox(height: 24),

                  // 📍 LOCALISATION
                  _buildSectionTitle('Localisation'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _villeController,
                          label: 'Ville',
                          hint: 'Abidjan',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _paysController,
                          label: 'Pays',
                          hint: 'Côte d\'Ivoire',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ⭐ ÉVALUATION
                  _buildSectionTitle('Évaluation'),
                  _buildTextField(
                    controller: _noteController,
                    label: 'Note (1-5)',
                    hint: '4.5',
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 24),

                  // 🏷️ LISTE PERSONNALISÉE
                  _buildSectionTitle('Organisation'),
                  _buildTextField(
                    controller: _listePersonnaliseeController,
                    label: 'Liste personnalisée',
                    hint: 'Mes favoris, À acheter, etc.',
                  ),
                  _buildTextField(
                    controller: _notesPersonnellesController,
                    label: 'Notes personnelles',
                    hint: 'Vos notes privées...',
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),

                  // 🔔 ALERTES
                  _buildSectionTitle('Alertes'),
                  SwitchListTile(
                    title: const Text('Alerte prix'),
                    subtitle:
                        const Text('Notifier en cas de changement de prix'),
                    value: _alertePrix,
                    onChanged: (value) => setState(() => _alertePrix = value),
                  ),
                  SwitchListTile(
                    title: const Text('Alerte disponibilité'),
                    subtitle: const Text(
                        'Notifier en cas de changement de disponibilité'),
                    value: _alerteDisponibilite,
                    onChanged: (value) =>
                        setState(() => _alerteDisponibilite = value),
                  ),

                  const SizedBox(height: 32),

                  // 💾 BOUTONS D'ACTION
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: SDColors.neutral300),
                            foregroundColor: SDColors.neutral700,
                          ),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: state.isAdding ? null : _saveFavorite,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SDColors.primary600,
                            foregroundColor: SDColors.white,
                          ),
                          child: state.isAdding
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        SDColors.white),
                                  ),
                                )
                              : const Text('Enregistrer'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: SDTypography.titleMedium.copyWith(
          fontWeight: FontWeight.bold,
          color: SDColors.primary600,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: SDColors.neutral300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: SDColors.primary600),
          ),
          filled: true,
          fillColor: SDColors.neutral50,
          labelStyle: TextStyle(color: SDColors.neutral600),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: SDColors.neutral300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: SDColors.primary600),
          ),
          filled: true,
          fillColor: SDColors.neutral50,
          labelStyle: TextStyle(color: SDColors.neutral600),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTagsField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tags',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (_tags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  onDeleted: () {
                    setState(() {
                      _tags.remove(tag);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Ajouter un tag',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: SDColors.neutral300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: SDColors.primary600),
                    ),
                    filled: true,
                    fillColor: SDColors.neutral50,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty && !_tags.contains(value)) {
                      setState(() {
                        _tags.add(value);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  // Ajouter le dernier tag saisi
                  // TODO: Implémenter l'ajout de tag
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _saveFavorite() {
    if (_formKey.currentState!.validate()) {
      // Générer un ID temporaire pour l'objet
      final objetId = DateTime.now().millisecondsSinceEpoch.toString();

      context.read<FavoritePageBlocM>().add(AddFavoriteM(
            objetType: _selectedObjetType,
            objetId: objetId,
            titre: _titreController.text,
            description: _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
            image: _imageController.text.isEmpty ? null : _imageController.text,
            prix: _prixController.text.isEmpty
                ? null
                : double.tryParse(_prixController.text),
            devise: _selectedDevise,
            categorie: _categorieController.text.isEmpty
                ? null
                : _categorieController.text,
            tags: _tags.isEmpty ? null : _tags,
            ville: _villeController.text.isEmpty ? null : _villeController.text,
            pays: _paysController.text.isEmpty ? null : _paysController.text,
            note: _noteController.text.isEmpty
                ? null
                : double.tryParse(_noteController.text),
            listePersonnalisee: _listePersonnaliseeController.text.isEmpty
                ? null
                : _listePersonnaliseeController.text,
            notesPersonnelles: _notesPersonnellesController.text.isEmpty
                ? null
                : _notesPersonnellesController.text,
            alertePrix: _alertePrix,
            alerteDisponibilite: _alerteDisponibilite,
          ));
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    _prixController.dispose();
    _categorieController.dispose();
    _villeController.dispose();
    _paysController.dispose();
    _noteController.dispose();
    _listePersonnaliseeController.dispose();
    _notesPersonnellesController.dispose();
    super.dispose();
  }
}
