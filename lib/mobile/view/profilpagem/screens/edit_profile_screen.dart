import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart';
import '../profilpageblocm/edit_profile_bloc.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? initialUserData;

  const EditProfileScreen({
    Key? key,
    this.initialUserData,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _genreController = TextEditingController();
  final _dateNaissanceController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.initialUserData != null) {
      _nomController.text = widget.initialUserData!['nom'] ?? '';
      _prenomController.text = widget.initialUserData!['prenom'] ?? '';
      _telephoneController.text = widget.initialUserData!['telephone'] ?? '';
      _emailController.text = widget.initialUserData!['email'] ?? '';
      _genreController.text = widget.initialUserData!['genre'] ?? '';
      _dateNaissanceController.text =
          widget.initialUserData!['datedenaissance'] ?? '';
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _genreController.dispose();
    _dateNaissanceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
      );
    }
  }

  // Méthode pour obtenir l'image de profil
  ImageProvider? _getProfileImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    }

    final photoProfil = widget.initialUserData?['photoProfil'];
    if (photoProfil != null &&
        photoProfil is String &&
        photoProfil.isNotEmpty) {
      return NetworkImage(photoProfil);
    }

    return null;
  }

  // Méthode pour obtenir l'icône de profil
  Widget? _getProfileIcon() {
    if (_selectedImage != null) {
      return null; // Afficher l'image sélectionnée
    }

    final photoProfil = widget.initialUserData?['photoProfil'];
    if (photoProfil != null &&
        photoProfil is String &&
        photoProfil.isNotEmpty) {
      return null; // Afficher l'image réseau
    }

    // Afficher l'icône par défaut
    return const Icon(Icons.person, size: 60, color: Colors.green);
  }

  void _updateProfile() {
    if (_formKey.currentState!.validate()) {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthAuthenticated) {
        context.read<EditProfileBloc>().add(
              UpdateProfile(
                userId: authState.utilisateur.idutilisateur,
                nom: _nomController.text.trim(),
                prenom: _prenomController.text.trim(),
                telephone: _telephoneController.text.trim(),
                email: _emailController.text.trim(),
                genre: _genreController.text.trim().isNotEmpty
                    ? _genreController.text.trim()
                    : null,
                datedenaissance: _dateNaissanceController.text.trim().isNotEmpty
                    ? _dateNaissanceController.text.trim()
                    : null,
                photoProfil: _selectedImage,
                token: authState.token,
              ),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditProfileBloc(apiClient: ApiClient()),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          title: const Text('Modifier le profil'),
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(44),
              bottomRight: Radius.circular(44),
            ),
          ),
        ),
        body: BlocConsumer<EditProfileBloc, EditProfileState>(
          listener: (context, state) {
            if (state is EditProfileSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context, true); // Retourner avec succès
            } else if (state is EditProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is EditProfileLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo de profil
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.green.shade100,
                            backgroundImage: _getProfileImage(),
                            child: _getProfileIcon(),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Appuyez sur l\'icône caméra pour changer la photo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Champ Nom
                    TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom *',
                        prefixIcon: Icon(Icons.person, color: Colors.green),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Champ Prénom
                    TextFormField(
                      controller: _prenomController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom',
                        prefixIcon:
                            Icon(Icons.person_outline, color: Colors.green),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Champ Téléphone
                    TextFormField(
                      controller: _telephoneController,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone *',
                        prefixIcon: Icon(Icons.phone, color: Colors.green),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le téléphone est requis';
                        }
                        if (value.trim().length < 8) {
                          return 'Le téléphone doit contenir au moins 8 chiffres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Champ Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        prefixIcon: Icon(Icons.email, color: Colors.green),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'L\'email est requis';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Format d\'email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Champ Genre
                    TextFormField(
                      controller: _genreController,
                      decoration: const InputDecoration(
                        labelText: 'Genre',
                        prefixIcon:
                            Icon(Icons.person_outline, color: Colors.green),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                        hintText: 'Homme, Femme, Autre...',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Champ Date de naissance
                    TextFormField(
                      controller: _dateNaissanceController,
                      decoration: const InputDecoration(
                        labelText: 'Date de naissance',
                        prefixIcon:
                            Icon(Icons.calendar_today, color: Colors.green),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                        hintText: 'JJ/MM/AAAA',
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Boutons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Colors.grey),
                            ),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Sauvegarder'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
