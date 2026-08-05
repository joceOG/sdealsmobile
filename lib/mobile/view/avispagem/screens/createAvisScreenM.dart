import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../avispageblocm/avisPageBlocM.dart';
import '../avispageblocm/avisPageEventM.dart';
import '../avispageblocm/avisPageStateM.dart';
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
  final _commentaireController = TextEditingController();
  int _note = 0;

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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildObjetInfo(),
                const SizedBox(height: 32),
                _buildRatingSection(),
                const SizedBox(height: 28),
                _buildCommentaireField(),
                const SizedBox(height: 32),
                _buildSubmitButton(state),
              ],
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
    final labels = ['', 'Mauvais', 'Passable', 'Bien', 'Très bien', 'Excellent'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Votre note',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final star = index + 1;
            return GestureDetector(
              onTap: () => setState(() => _note = star),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  star <= _note ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 44,
                ),
              ),
            );
          }),
        ),
        if (_note > 0) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              labels[_note],
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // 💬 CHAMP COMMENTAIRE (optionnel)
  Widget _buildCommentaireField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Commentaire ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            children: [
              TextSpan(
                text: '(optionnel)',
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _commentaireController,
          decoration: InputDecoration(
            hintText: 'Décrivez votre expérience…',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          maxLines: 4,
          maxLength: 1000,
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
    if (_note == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez une note (1 à 5 étoiles)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final commentaire = _commentaireController.text.trim();
    context.read<AvisPageBlocM>().add(CreateAvisM(
      objetType: widget.objetType,
      objetId: widget.objetId,
      note: _note,
      commentaire: commentaire.isNotEmpty ? commentaire : null,
    ));
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
    _commentaireController.dispose();
    super.dispose();
  }
}



