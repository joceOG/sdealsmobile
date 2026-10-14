import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../data/models/utilisateur.dart';
import '../../../../data/utils/display_text.dart';
import '../../../../design_system/design_system.dart';
import '../profilpageblocm/edit_profile_bloc.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? initialUserData;

  const EditProfileScreen({
    super.key,
    this.initialUserData,
  });

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
  bool _initialized = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
    for (final c in [
      _nomController,
      _prenomController,
      _telephoneController,
      _emailController,
      _genreController,
      _dateNaissanceController,
    ]) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }
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
    _initialized = true;
  }

  bool get _dirty {
    if (!_initialized) return false;
    if (_selectedImage != null) return true;
    final initial = widget.initialUserData ?? const {};
    bool changed(TextEditingController c, String key) =>
        c.text.trim() != (initial[key]?.toString().trim() ?? '');
    return changed(_nomController, 'nom') ||
        changed(_prenomController, 'prenom') ||
        changed(_telephoneController, 'telephone') ||
        changed(_emailController, 'email') ||
        changed(_genreController, 'genre') ||
        changed(_dateNaissanceController, 'datedenaissance');
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
      );
    }
  }

  ImageProvider? _getProfileImage() {
    if (_selectedImage != null) return FileImage(_selectedImage!);
    final photoProfil = safeImageUrl(widget.initialUserData?['photoProfil']);
    if (photoProfil != null &&
        (photoProfil.startsWith('http://') ||
            photoProfil.startsWith('https://'))) {
      return NetworkImage(photoProfil);
    }
    return null;
  }

  Widget? _getProfileIcon() {
    if (_getProfileImage() != null) return null;
    final prenom = widget.initialUserData?['prenom']?.toString();
    final nom = widget.initialUserData?['nom']?.toString() ?? '';
    final first = cleanDisplayPart(prenom);
    final last = cleanDisplayPart(nom);
    String letter(String? value) => (value == null || value.isEmpty)
        ? ''
        : value.characters.first.toUpperCase();
    final initials = '${letter(first)}${letter(last)}';
    return Text(
      initials.isEmpty ? '?' : initials,
      style: SDTypography.titleLarge.copyWith(
        color: SDColors.primary700,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: SDColors.white,
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SDColors.neutral200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SDColors.neutral200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SDColors.primary600, width: 1.4),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: SDTypography.titleSmall.copyWith(
          color: SDColors.neutral900,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  void _updateProfile() {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;
    setState(() => _submitting = true);
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

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter sans enregistrer ?'),
        content: const Text(
          'Les modifications non enregistrées seront perdues.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Rester'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    return leave == true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditProfileBloc(apiClient: ApiClient()),
      child: PopScope(
        canPop: !_dirty,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final navigator = Navigator.of(context);
          if (await _confirmLeave() && mounted) {
            navigator.pop();
          }
        },
        child: Scaffold(
          backgroundColor: SDColors.white,
          appBar: SDAppBarIconThemed(
            style: SDAppBarIconStyles.onLightSurface,
            bar: AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: SDColors.white,
              surfaceTintColor: Colors.transparent,
              foregroundColor: SDColors.neutral900,
              title: Text(
                'Modifier mon profil',
                style: SDTypography.titleLarge.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w800,
                ),
              ),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 1, color: SDColors.neutral200),
              ),
            ),
          ),
          body: BlocConsumer<EditProfileBloc, EditProfileState>(
            listener: (context, state) {
              if (state is EditProfileSuccess) {
                try {
                  final raw = state.updatedUser;
                  final userMap = raw['utilisateur'] is Map
                      ? Map<String, dynamic>.from(raw['utilisateur'] as Map)
                      : raw;
                  final updated = Utilisateur.fromJson(userMap);
                  context.read<AuthCubit>().updateUtilisateur(updated);
                } catch (_) {
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
                            telephoneVerified: u.telephoneVerified,
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
                setState(() => _submitting = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error),
                    backgroundColor: SDColors.error500,
                  ),
                );
              }
            },
            builder: (context, state) {
              final saving = _submitting || state is EditProfileLoading;
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        20,
                        20,
                        24 + MediaQuery.viewInsetsOf(context).bottom,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    radius: 48,
                                    backgroundColor: SDColors.primary100,
                                    backgroundImage: _getProfileImage(),
                                    child: _getProfileIcon(),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Material(
                                      color: SDColors.primary600,
                                      shape: const CircleBorder(),
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: saving ? null : _pickImage,
                                        child: const SizedBox(
                                          width: 36,
                                          height: 36,
                                          child: Icon(
                                            Icons.photo_camera_outlined,
                                            color: SDColors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton.icon(
                                onPressed: saving ? null : _pickImage,
                                icon: const Icon(Icons.photo_camera_outlined),
                                label: const Text('Changer la photo'),
                                style: TextButton.styleFrom(
                                  foregroundColor: SDColors.primary700,
                                  minimumSize: const Size(48, 48),
                                ),
                              ),
                            ),
                            Text(
                              'Photo visible sur votre profil',
                              textAlign: TextAlign.center,
                              style: SDTypography.bodySmall
                                  .copyWith(color: SDColors.neutral500),
                            ),
                            const SizedBox(height: 28),
                            _sectionTitle('Identité'),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final stacked = constraints.maxWidth < 360;
                                final prenom = TextFormField(
                                  controller: _prenomController,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: _fieldDecoration(
                                    label: 'Prénom',
                                    hint: 'Prénom',
                                  ),
                                );
                                final nom = TextFormField(
                                  controller: _nomController,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: _fieldDecoration(
                                    label: 'Nom',
                                    hint: 'Nom',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Le nom est requis';
                                    }
                                    return null;
                                  },
                                );
                                if (stacked) {
                                  return Column(
                                    children: [
                                      prenom,
                                      const SizedBox(height: 12),
                                      nom,
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: prenom),
                                    const SizedBox(width: 12),
                                    Expanded(child: nom),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            _sectionTitle('Coordonnées'),
                            TextFormField(
                              controller: _telephoneController,
                              decoration: _fieldDecoration(label: 'Téléphone'),
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
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              decoration: _fieldDecoration(
                                label: 'Adresse e-mail',
                                hint: 'nom@exemple.com',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'L\'email est requis';
                                }
                                if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(value)) {
                                  return 'Format d\'email invalide';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ces coordonnées servent à gérer votre compte.',
                              style: SDTypography.bodySmall
                                  .copyWith(color: SDColors.neutral500),
                            ),
                            const SizedBox(height: 24),
                            _sectionTitle('Informations complémentaires'),
                            TextFormField(
                              controller: _genreController,
                              decoration: _fieldDecoration(
                                label: 'Genre',
                                hint: 'Homme, Femme, Autre…',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _dateNaissanceController,
                              decoration: _fieldDecoration(
                                label: 'Date de naissance',
                                hint: 'JJ/MM/AAAA',
                                suffix: const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: SDColors.neutral500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            SDButton(
                              text: saving
                                  ? 'Enregistrement…'
                                  : 'Enregistrer les modifications',
                              fullWidth: true,
                              isLoading: saving,
                              onPressed: saving ? null : _updateProfile,
                            ),
                            TextButton(
                              onPressed: saving
                                  ? null
                                  : () async {
                                      final navigator = Navigator.of(context);
                                      if (await _confirmLeave() && mounted) {
                                        navigator.pop();
                                      }
                                    },
                              child: Text(
                                'Annuler',
                                style: SDTypography.labelMedium.copyWith(
                                  color: SDColors.primary700,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
