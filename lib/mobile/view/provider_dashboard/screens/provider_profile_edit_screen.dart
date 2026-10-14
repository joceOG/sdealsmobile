import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../data/models/utilisateur.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../data/utils/display_text.dart';
import '../../../../design_system/design_system.dart';
import '../bloc/provider_profile_bloc.dart';
import '../bloc/provider_profile_event.dart';
import '../bloc/provider_profile_state.dart';
import 'provider_edit_service_tariff_screen.dart';
import 'provider_edit_zone_screen.dart';
import 'provider_profile_enrichment.dart';

enum ProviderProfileEditIntent { auto, edit, complete }

/// Formulaire plein écran : modifier ou compléter la présentation publique (≠ dossier KYC).
class ProviderProfileEditScreen extends StatefulWidget {
  const ProviderProfileEditScreen({
    super.key,
    required this.prestataireId,
    required this.initial,
    this.intent = ProviderProfileEditIntent.auto,
  });

  final String prestataireId;
  final ProviderProfileLoaded initial;
  final ProviderProfileEditIntent intent;

  @override
  State<ProviderProfileEditScreen> createState() =>
      _ProviderProfileEditScreenState();
}

class _ProviderProfileEditScreenState extends State<ProviderProfileEditScreen> {
  late final TextEditingController _bioController;
  late final TextEditingController _descController;
  final ImagePicker _picker = ImagePicker();

  late String _initialBio;
  late String _initialDesc;
  late String? _photoUrl;
  File? _pickedImage;

  late String _serviceName;
  late String? _serviceId;
  late String? _categoryLabel;
  late String? _categoryId;
  late double? _dailyRate;
  late String _locationLabel;
  late double? _radiusKm;

  bool _initialized = false;
  bool _saving = false;
  bool _awaitingProfileReload = false;

  @override
  void initState() {
    super.initState();
    _hydrateFrom(widget.initial);
    _bioController = TextEditingController(text: _initialBio);
    _descController = TextEditingController(text: _initialDesc);
    for (final c in [_bioController, _descController]) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }
    _initialized = true;
  }

  void _hydrateFrom(ProviderProfileLoaded state) {
    final raw = state.profile['bio']?.toString() ?? '';
    final parts = ProviderProfileEnrichment.splitDescription(raw);
    _initialBio = parts.bio;
    _initialDesc = parts.description;

    _photoUrl = _resolvePhotoUrl(state);
    _serviceName = _metierFrom(state);
    _serviceId = _optionalId(state.profile['serviceId']);
    _categoryLabel = _categoryFrom(state);
    _categoryId = _optionalId(state.profile['categoryId']);
    _dailyRate = _asDouble(state.profile['prixprestataire']);
    _locationLabel = state.serviceZone['address']?.toString() ??
        state.profile['location']?.toString() ??
        '';
    final radius = state.serviceZone['radius'] ?? state.profile['serviceRadius'];
    _radiusKm = radius != null ? _asDouble(radius) : null;
  }

  double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.'));
  }

  String? _optionalId(dynamic v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  String _metierFrom(ProviderProfileLoaded state) {
    final serviceName = state.profile['serviceName']?.toString().trim() ?? '';
    if (serviceName.isNotEmpty) return serviceName;
    if (state.services.isNotEmpty) return state.services.first;
    final m = state.profile['metier']?.toString().trim() ?? '';
    return m.isNotEmpty ? m : 'Prestataire';
  }

  String? _categoryFrom(ProviderProfileLoaded state) {
    final c = state.profile['categoryLabel']?.toString().trim() ?? '';
    if (c.isEmpty) return null;
    if (c.toLowerCase() == _metierFrom(state).toLowerCase()) return null;
    return c;
  }

  String? _resolvePhotoUrl(ProviderProfileLoaded state) {
    final fromApi = safeImageUrl(state.profile['profileImage']);
    if (fromApi != null) return fromApi;
    final auth = context.read<AuthCubit>().state;
    if (auth is AuthAuthenticated) {
      return safeImageUrl(auth.utilisateur.photoProfil);
    }
    return null;
  }

  bool get _isCompleteMode {
    switch (widget.intent) {
      case ProviderProfileEditIntent.complete:
        return true;
      case ProviderProfileEditIntent.edit:
        return false;
      case ProviderProfileEditIntent.auto:
        return _missingKeys.isNotEmpty;
    }
  }

  bool get _hasPhotoUrl =>
      _pickedImage != null ||
      ProviderProfileEnrichment.hasProfilePhotoUrl(_photoUrl, null);

  List<String> get _missingKeys => ProviderProfileEnrichment.missingLabels(
        hasPhotoUrl: _pickedImage != null ||
            ProviderProfileEnrichment.hasProfilePhotoUrl(_photoUrl, null),
        bio: _bioController.text,
        description: _descController.text,
      );

  bool get _dirty {
    if (!_initialized) return false;
    if (_pickedImage != null) return true;
    return _bioController.text.trim() != _initialBio.trim() ||
        _descController.text.trim() != _initialDesc.trim();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _descController.dispose();
    super.dispose();
  }

  String _displayName() {
    final fromApi = widget.initial.profile['fullName']?.toString().trim() ?? '';
    if (fromApi.isNotEmpty) return fromApi;
    final auth = context.read<AuthCubit>().state;
    if (auth is AuthAuthenticated) {
      return joinPersonName(
        prenom: auth.utilisateur.prenom,
        nom: auth.utilisateur.nom,
        fallback: 'Prestataire',
      );
    }
    return 'Prestataire';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.elementAt(1)[0]}'.toUpperCase();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image != null && mounted) {
        setState(() => _pickedImage = File(image.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de choisir une photo : $e')),
      );
    }
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

  Future<void> _onCancelOrLater() async {
    if (await _confirmLeave() && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _openServiceTariff() async {
    final profileBloc = context.read<ProviderProfileBloc>();
    final result = await Navigator.push<ProviderServiceTariffResult>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: profileBloc,
          child: ProviderEditServiceTariffScreen(
            prestataireId: widget.prestataireId,
            serviceName: _serviceName,
            serviceId: _serviceId,
            categoryLabel: _categoryLabel,
            categoryId: _categoryId,
            initialDailyRate: _dailyRate,
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _dailyRate = result.rate;
        _serviceName = result.serviceName;
        _serviceId = result.serviceId;
        _categoryLabel = result.categoryLabel;
        _categoryId = result.categoryId;
      });
    }
  }

  Future<void> _openZone() async {
    final profileBloc = context.read<ProviderProfileBloc>();
    final result = await Navigator.push<(String, double?)?>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: profileBloc,
          child: ProviderEditZoneScreen(
            prestataireId: widget.prestataireId,
            initialLocation: _locationLabel,
            initialRadiusKm: _radiusKm,
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _locationLabel = result.$1;
        _radiusKm = result.$2;
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated || auth.token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expirée — reconnectez-vous'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final joined = ProviderProfileEnrichment.joinDescription(
      bio: _bioController.text,
      description: _descController.text,
    );

    final bloc = context.read<ProviderProfileBloc>();
    bloc.setToken(auth.token);
    _awaitingProfileReload = true;
    bloc.add(UpdateProviderProfile(
      widget.prestataireId,
      {'description': joined},
    ));
  }

  Future<void> _afterProfileSaved() async {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return;

    try {
      if (_pickedImage != null) {
        final u = auth.utilisateur;
        final api = ApiClient();
        final raw = await api.updateUserProfile(
          userId: u.idutilisateur,
          updateData: {
            'nom': u.nom,
            'prenom': u.prenom ?? '',
            'telephone': u.telephone,
            'email': u.email,
          },
          photoFile: _pickedImage,
          token: auth.token,
        );
        try {
          final userMap = raw['utilisateur'] is Map
              ? Map<String, dynamic>.from(raw['utilisateur'] as Map)
              : raw;
          if (mounted) {
            context.read<AuthCubit>().updateUtilisateur(Utilisateur.fromJson(userMap));
          }
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo non enregistrée : $e')),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _saving = false;
      _awaitingProfileReload = false;
      _initialBio = _bioController.text.trim();
      _initialDesc = _descController.text.trim();
      _pickedImage = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Présentation enregistrée'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final complete = _isCompleteMode;
    final missing = _missingKeys;
    final name = _displayName();
    final highlightPhoto = complete && missing.contains('photo');
    final highlightDesc = complete && missing.contains('description');

    return BlocListener<ProviderProfileBloc, ProviderProfileState>(
      listener: (context, state) {
        if (!_awaitingProfileReload) return;
        if (state is ProviderProfileError) {
          setState(() {
            _saving = false;
            _awaitingProfileReload = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is ProviderProfileLoaded) {
          _afterProfileSaved();
        }
      },
      child: PopScope(
        canPop: !_dirty,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (await _confirmLeave() && mounted) {
            Navigator.pop(context);
          }
        },
        child: Scaffold(
          backgroundColor: SDColors.white,
          appBar: SDWhiteAppBar.appBar(
            title: complete ? 'Compléter mon profil' : 'Modifier mon profil',
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!complete)
                        Text(
                          'Mettez à jour votre présentation.',
                          style: SDTypography.bodyMedium.copyWith(
                            color: SDColors.neutral600,
                          ),
                        ),
                      if (complete && missing.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _completionBanner(missing),
                      ],
                      const SizedBox(height: 20),
                      _photoSection(
                        name: name,
                        highlightMissing: highlightPhoto,
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Présentation',
                        style: SDTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: SDColors.neutral900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _labeledField(
                        label: 'Bio courte',
                        controller: _bioController,
                        maxLength: 80,
                        hint: 'Votre activité en quelques mots.',
                        helper: 'Votre activité en quelques mots.',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      _labeledField(
                        label: 'Description',
                        controller: _descController,
                        maxLength: 1000,
                        hint: 'Présentez votre travail et votre expérience…',
                        helper: 'Présentez votre travail et votre expérience.',
                        maxLines: 6,
                        highlightMissing: highlightDesc,
                        trailingBadge: highlightDesc ? _completeBadge() : null,
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Informations de l\'activité',
                        style: SDTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: SDColors.neutral900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _navTile(
                        icon: Icons.handyman_outlined,
                        title: 'Service et tarif',
                        subtitle: _serviceTariffSubtitle(),
                        onTap: _openServiceTariff,
                      ),
                      const SizedBox(height: 10),
                      _navTile(
                        icon: Icons.place_outlined,
                        title: 'Zone d\'intervention',
                        subtitle: _zoneSubtitle(),
                        onTap: _openZone,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'L\'enregistrement met à jour votre fiche publique. '
                        'La validation du dossier professionnel reste distincte.',
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.neutral500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    SDButton(
                      text: 'Enregistrer les modifications',
                      fullWidth: true,
                      onPressed: _saving ? null : _save,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _saving ? null : _onCancelOrLater,
                      child: Text(
                        complete ? 'Plus tard' : 'Annuler',
                        style: SDTypography.bodyMedium.copyWith(
                          color: SDColors.primary700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _completionBanner(List<String> keys) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SDColors.primary50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.assignment_turned_in_outlined,
              color: SDColors.primary700, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ProviderProfileEnrichment.missingBannerText(keys),
                  style: SDTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: SDColors.neutral900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ajoutez les informations manquantes.',
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _completeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: SDColors.neutral100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'À compléter',
        style: SDTypography.labelSmall.copyWith(
          color: SDColors.neutral600,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _photoSection({
    required String name,
    required bool highlightMissing,
  }) {
    final initials = _initials(name);
    ImageProvider? provider;
    if (_pickedImage != null) {
      provider = FileImage(_pickedImage!);
    } else if (_photoUrl != null) {
      provider = NetworkImage(_photoUrl!);
    }

    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: SDColors.primary50,
                backgroundImage: provider,
                child: provider == null
                    ? Text(
                        initials,
                        style: SDTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: SDColors.neutral900,
                        ),
                      )
                    : null,
              ),
              if (highlightMissing)
                Positioned(
                  top: 0,
                  right: -4,
                  child: _completeBadge(),
                ),
              Positioned(
                right: 4,
                bottom: 4,
                child: Material(
                  color: SDColors.primary600,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _pickImage,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.photo_camera_outlined,
                          size: 18, color: SDColors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _pickImage,
            child: Text(
              _hasPhotoUrl ? 'Changer la photo' : 'Ajouter une photo',
              style: SDTypography.bodyMedium.copyWith(
                color: SDColors.primary700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            'Photo du profil public',
            style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
          ),
        ],
      ),
    );
  }

  String _serviceTariffSubtitle() {
    final rate = formatOptionalPrice(_dailyRate, suffix: 'FCFA');
    final parts = <String>[_serviceName];
    if (rate != null) parts.add(rate);
    return parts.join(' • ');
  }

  String _zoneSubtitle() {
    final loc = _locationLabel.trim();
    if (loc.isEmpty) return 'Non renseignée';
    final r = _radiusKm;
    if (r != null && r > 0) {
      return '$loc • ${r.round()} km';
    }
    return loc;
  }

  Widget _labeledField({
    required String label,
    required TextEditingController controller,
    required int maxLength,
    required String hint,
    required String helper,
    int maxLines = 1,
    bool highlightMissing = false,
    Widget? trailingBadge,
  }) {
    final borderColor = highlightMissing
        ? SDColors.primary600
        : SDColors.neutral300;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: SDTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: SDColors.neutral900,
              ),
            ),
            if (trailingBadge != null) ...[
              const SizedBox(width: 8),
              trailingBadge,
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: highlightMissing ? 1.5 : 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: highlightMissing ? 1.5 : 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: highlightMissing ? SDColors.primary600 : SDColors.primary500,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _navTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: SDColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: SDColors.neutral200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: SDColors.neutral600, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: SDTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: SDColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: SDTypography.bodySmall.copyWith(
                        color: SDColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: SDColors.neutral400),
            ],
          ),
        ),
      ),
    );
  }
}
