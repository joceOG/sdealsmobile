import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../avispageblocm/avisPageBlocM.dart';
import '../avispageblocm/avisPageEventM.dart';
import '../avispageblocm/avisPageStateM.dart';
import 'package:sdealsmobile/data/models/avis.dart';
import '../../../../design_system/design_system.dart';

class CreateAvisScreenM extends StatefulWidget {
  final String objetType;
  final String objetId;
  final String objetNom;

  const CreateAvisScreenM({
    super.key,
    required this.objetType,
    required this.objetId,
    required this.objetNom,
  });

  @override
  State<CreateAvisScreenM> createState() => _CreateAvisScreenMState();
}

class _CreateAvisScreenMState extends State<CreateAvisScreenM> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _commentaireController = TextEditingController();

  int _note = 5;
  bool _recommande = true;
  bool _anonyme = false;
  List<String> _selectedTags = [];
  String? _selectedVille;

  final List<String> _availableTags = [
    'Excellent service',
    'Rapide',
    'Professionnel',
    'Bon rapport qualité-prix',
    'Recommandé',
    'Ponctuel',
    'Sympathique',
    'Expert',
  ];

  final List<String> _availableVilles = [
    'Abidjan',
    'Bouaké',
    'Daloa',
    'San-Pédro',
    'Korhogo',
    'Gagnoa',
    'Man',
    'Divo',
    'Anyama',
    'Abengourou',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SDWhiteAppBar.appBar(
        centerTitle: true,
        title: 'Donner un avis',
        actions: [
          BlocBuilder<AvisPageBlocM, AvisPageStateM>(
            builder: (context, state) {
              return TextButton(
                onPressed: state.isCreating ? null : _submitAvis,
                child: Text(
                  'Publier',
                  style: SDTypography.labelLarge.copyWith(
                    color: state.isCreating
                        ? SDColors.neutral400
                        : SDColors.primary700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<AvisPageBlocM, AvisPageStateM>(
        listener: (context, state) {
          if (state.createError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.createError!),
                backgroundColor: Colors.red,
              ),
            );
          } else if (!state.isCreating && state.avis != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Avis publié avec succès !'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations sur l'objet
                  _buildObjetInfo(),

                  const SizedBox(height: 24),

                  // Note
                  _buildRatingSection(),

                  const SizedBox(height: 24),

                  // Titre
                  _buildTitreField(),

                  const SizedBox(height: 16),

                  // Commentaire
                  _buildCommentaireField(),

                  const SizedBox(height: 24),

                  // Options
                  _buildOptionsSection(),

                  const SizedBox(height: 24),

                  // Tags
                  _buildTagsSection(),

                  const SizedBox(height: 24),

                  // Localisation
                  _buildLocationSection(),

                  const SizedBox(height: 32),

                  // Bouton de soumission
                  _buildSubmitButton(state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 📋 INFORMATIONS SUR L'OBJET
  Widget _buildObjetInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(
            _getObjetIcon(widget.objetType),
            color: Colors.green,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.objetNom,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getObjetTypeLabel(widget.objetType),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ⭐ SECTION DE NOTATION
  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Votre note',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                'Note: $_note/5',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _note = index + 1;
                    });
                  },
                  child: Icon(
                    index < _note ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
          ],
        ),
      ],
    );
  }

  // 📝 CHAMP TITRE
  Widget _buildTitreField() {
    return TextFormField(
      controller: _titreController,
      decoration: const InputDecoration(
        labelText: 'Titre de votre avis',
        hintText: 'Ex: Excellent service, très satisfait',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.title),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Veuillez saisir un titre';
        }
        if (value.trim().length < 5) {
          return 'Le titre doit contenir au moins 5 caractères';
        }
        return null;
      },
      maxLength: 100,
    );
  }

  // 💬 CHAMP COMMENTAIRE
  Widget _buildCommentaireField() {
    return TextFormField(
      controller: _commentaireController,
      decoration: const InputDecoration(
        labelText: 'Votre commentaire',
        hintText: 'Décrivez votre expérience en détail...',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.comment),
        alignLabelWithHint: true,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Veuillez saisir un commentaire';
        }
        if (value.trim().length < 20) {
          return 'Le commentaire doit contenir au moins 20 caractères';
        }
        return null;
      },
      maxLines: 5,
      maxLength: 1000,
    );
  }

  // ⚙️ SECTION OPTIONS
  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Options',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: const Text('Je recommande ce service'),
          subtitle:
              const Text('Cochez si vous recommandez ce service à d\'autres'),
          value: _recommande,
          onChanged: (value) {
            setState(() {
              _recommande = value ?? true;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Publier de manière anonyme'),
          subtitle: const Text('Votre nom ne sera pas affiché'),
          value: _anonyme,
          onChanged: (value) {
            setState(() {
              _anonyme = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  // 🏷️ SECTION TAGS
  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags (optionnel)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sélectionnez les mots-clés qui décrivent votre expérience',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
              selectedColor: Colors.green[100],
              checkmarkColor: Colors.green,
            );
          }).toList(),
        ),
      ],
    );
  }

  // 📍 SECTION LOCALISATION
  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Localisation (optionnel)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedVille,
          decoration: const InputDecoration(
            labelText: 'Ville',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_city),
          ),
          items: _availableVilles.map((ville) {
            return DropdownMenuItem(
              value: ville,
              child: Text(ville),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedVille = value;
            });
          },
        ),
      ],
    );
  }

  // 🚀 BOUTON DE SOUMISSION
  Widget _buildSubmitButton(AvisPageStateM state) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: state.isCreating ? null : _submitAvis,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: state.isCreating
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Publier mon avis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // 🚀 SOUMISSION DE L'AVIS
  void _submitAvis() {
    if (_formKey.currentState!.validate()) {
      final avisData = CreateAvisM(
        objetType: widget.objetType,
        objetId: widget.objetId,
        note: _note,
        titre: _titreController.text.trim(),
        commentaire: _commentaireController.text.trim(),
        recommande: _recommande,
        anonyme: _anonyme,
        tags: _selectedTags.isNotEmpty ? _selectedTags : null,
        localisation: _selectedVille != null
            ? LocalisationAvis(ville: _selectedVille, pays: 'Côte d\'Ivoire')
            : null,
      );

      context.read<AvisPageBlocM>().add(avisData);
    }
  }

  // 🎯 ICÔNES POUR LES TYPES D'OBJET
  IconData _getObjetIcon(String objetType) {
    switch (objetType) {
      case 'PRESTATAIRE':
        return Icons.build;
      case 'VENDEUR':
        return Icons.store;
      case 'FREELANCE':
        return Icons.work;
      case 'ARTICLE':
        return Icons.shopping_bag;
      case 'SERVICE':
        return Icons.design_services;
      case 'PRESTATION':
        return Icons.handyman;
      case 'COMMANDE':
        return Icons.receipt;
      default:
        return Icons.star;
    }
  }

  // 🏷️ LABELS POUR LES TYPES D'OBJET
  String _getObjetTypeLabel(String objetType) {
    switch (objetType) {
      case 'PRESTATAIRE':
        return 'Prestataire de service';
      case 'VENDEUR':
        return 'Vendeur';
      case 'FREELANCE':
        return 'Freelance';
      case 'ARTICLE':
        return 'Article';
      case 'SERVICE':
        return 'Service';
      case 'PRESTATION':
        return 'Prestation';
      case 'COMMANDE':
        return 'Commande';
      default:
        return 'Élément';
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }
}



