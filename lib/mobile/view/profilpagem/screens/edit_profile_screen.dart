import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../data/models/utilisateur.dart';
import '../../../../design_system/design_system.dart';
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
    return const Icon(Icons.person, size: 60, color: SDColors.neutral900);
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
        appBar: SDAppBarIconThemed(
          style: SDAppBarIconStyles.onLightSurface,
          bar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: SDColors.white,
          surfaceTintColor: Colors.transparent,
          foregroundColor: SDColors.neutral900,
          title: Text(
            'Modifier le profil',
            style: SDTypography.titleLarge.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w800,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: SDColors.neutral200),
          ),
        ),
        ),
        body: BlocConsumer<EditProfileBloc, EditProfileState>(
          listener: (context, state) {
            if (state is EditProfileSuccess) {
              try {
                final raw = state.updatedUser;
                final userMap = raw['utilisateur'] is Map<String, dynamic>
                    ? raw['utilisateur'] as Map<String, dynamic>
                    : raw;
                final updated = Utilisateur.fromJson(userMap);
                context.read<AuthCubit>().updateUtilisateur(updated);
              } catch (_) {
                // Fallback : fusion locale des champs édités
                final auth = context.read<AuthCubit>().state;
                if (auth is AuthAuthenticated) {
                  final u = auth.utilisateur;
                  context.read<AuthCubit>().updateUtilisateur(
                        Utilisateur(
                          idutilisateur: u.idutilisateur,
                          nom: _nomController.text.trim(),
                          prenom: _prenomController.text.trim(),
                          telephone: _telephoneController.text.trim(),
                          email: _emailController.text.trim(),
                          genre: _genreController.text.trim().isNotEmpty
                              ? _genreController.text.trim()
                              : u.genre,
                          dateNaissance:
                              _dateNaissanceController.text.trim().isNotEmpty
                                  ? _dateNaissanceController.text.trim()
                                  : u.dateNaissance,
                          photoProfil: u.photoProfil,
                          password: u.password,
                          note: u.note,
                          tokens: u.tokens,
                          token: u.token,
                          createdAt: u.createdAt,
                          updatedAt: u.updatedAt,
                          role: u.role,
                          verifie: u.verifie,
                        ),
                      );
                }
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: SDColors.neutral900,
                ),
              );
              Navigator.pop(context, true);
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
              return Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(SDColors.primary600),
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
                            backgroundColor: SDColors.neutral100,
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
                                  color: SDColors.neutral900,
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
                        color: SDColors.neutral500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Champ Nom
                    TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom',
                        hintText: 'Ex. Koné',
                        prefixIcon: Icon(Icons.person, color: SDColors.neutral900),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: SDColors.neutral900),
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
                        hintText: 'Ex. Aïcha',
                        prefixIcon:
                            Icon(Icons.person_outline, color: SDColors.neutral900),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: SDColors.neutral900),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Champ Téléphone
                    TextFormField(
                      controller: _telephoneController,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone *',
                        prefixIcon: Icon(Icons.phone, color: SDColors.neutral900),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: SDColors.neutral900),
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
                        labelText: 'Email',
                        hintText: 'nom@exemple.com',
                        prefixIcon: Icon(Icons.email, color: SDColors.neutral900),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: SDColors.neutral900),
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
                            Icon(Icons.person_outline, color: SDColors.neutral900),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: SDColors.neutral900),
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
                            Icon(Icons.calendar_today, color: SDColors.neutral900),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: SDColors.neutral900),
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
                              side: const BorderSide(color: SDColors.neutral500),
                            ),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SDColors.neutral900,
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
