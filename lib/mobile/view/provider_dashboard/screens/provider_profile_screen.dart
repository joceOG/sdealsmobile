import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/provider_profile_bloc.dart';
import '../bloc/provider_profile_event.dart';
import '../bloc/provider_profile_state.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../data/utils/display_text.dart';
import '../../../../design_system/design_system.dart';

/// Profil = fiche éditable (pas un 2ᵉ dashboard).
/// Dispo + KPI ops restent sur Accueil uniquement.
class ProviderProfileScreen extends StatefulWidget {
  final String? prestataireDocId;
  final bool embeddedInTab;

  const ProviderProfileScreen({
    super.key,
    this.prestataireDocId,
    this.embeddedInTab = false,
  });

  @override
  ProviderProfileScreenState createState() => ProviderProfileScreenState();
}

class ProviderProfileScreenState extends State<ProviderProfileScreen> {
  String? _prestataireId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void didUpdateWidget(covariant ProviderProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.prestataireDocId;
    if (next != null &&
        next.isNotEmpty &&
        next != oldWidget.prestataireDocId) {
      _prestataireId = next;
      _refreshProfile();
    }
  }

  void _bootstrap() {
    if (!mounted) return;
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return;

    context.read<ProviderProfileBloc>().setToken(auth.token);
    // Attendre le vrai docId prestataire (comme Planning).
    _prestataireId = widget.prestataireDocId;
    if (_prestataireId != null && _prestataireId!.isNotEmpty) {
      _refreshProfile();
    }
  }

  void _refreshProfile() {
    if (_prestataireId == null || _prestataireId!.isEmpty) return;
    context
        .read<ProviderProfileBloc>()
        .add(LoadProviderProfile(_prestataireId!));
  }

  /// AppBar parent.
  void openEdit() => _showEditSheet();

  void _showEditSheet() {
    if (_prestataireId == null || _prestataireId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil prestataire non chargé')),
      );
      return;
    }

    final currentState = context.read<ProviderProfileBloc>().state;
    String currentBio = '';
    if (currentState is ProviderProfileLoaded) {
      currentBio = (currentState.profile['bio'] ?? '').toString();
    }

    final bioController = TextEditingController(text: currentBio);
    final descriptionController = TextEditingController(text: currentBio);
    var saving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Modifier le profil'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: bioController,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      border: OutlineInputBorder(),
                      hintText: 'Présentez-vous brièvement',
                    ),
                    maxLines: 3,
                    maxLength: 280,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      hintText: 'Détails de vos services',
                    ),
                    maxLines: 5,
                    maxLength: 1000,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () {
                        final auth = context.read<AuthCubit>().state;
                        if (auth is! AuthAuthenticated ||
                            auth.token.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Session expirée — reconnectez-vous'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        setDialogState(() => saving = true);
                        final bloc = context.read<ProviderProfileBloc>();
                        bloc.setToken(auth.token);
                        bloc.add(UpdateProviderProfile(
                          _prestataireId!,
                          {
                            'bio': bioController.text.trim(),
                            'description': descriptionController.text.trim(),
                          },
                        ));
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mise à jour du profil…'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: SDColors.primary600,
                  foregroundColor: SDColors.white,
                ),
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Enregistrer'),
              ),
            ],
          );
        },
      ),
    );
  }

  int _completionPercent(ProviderProfileLoaded state) {
    final p = state.profile;
    var score = 0;
    const total = 7;
    if ((p['profileImage'] ?? '').toString().startsWith('http')) score++;
    if ((p['bio'] ?? '').toString().trim().isNotEmpty) score++;
    if ((p['phone'] ?? '').toString().trim().isNotEmpty) score++;
    if ((p['location'] ?? '').toString().trim().isNotEmpty) score++;
    if (state.services.isNotEmpty) score++;
    final years = _asNum(p['anneeExperience']);
    if (years != null && years > 0) score++;
    if (p['verifier'] == true) score++;
    return ((score / total) * 100).round();
  }

  num? _asNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString().replaceAll(',', '.'));
  }

  String _authDisplayName() {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return '';
    return joinPersonName(
      prenom: auth.utilisateur.prenom,
      nom: auth.utilisateur.nom,
      fallback: '',
    );
  }

  String? _authPhoto() {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return null;
    return auth.utilisateur.photoProfil;
  }

  String _displayName(ProviderProfileLoaded state) {
    final fromApi = state.profile['fullName']?.toString().trim() ?? '';
    if (fromApi.isNotEmpty) return fromApi;
    final fromAuth = _authDisplayName();
    return fromAuth.isNotEmpty ? fromAuth : 'Prestataire';
  }

  String _metier(ProviderProfileLoaded state) {
    if (state.services.isNotEmpty) return state.services.first;
    final m = state.profile['metier']?.toString().trim() ?? '';
    return m.isNotEmpty ? m : 'Prestataire';
  }

  @override
  Widget build(BuildContext context) {
    final waitingId =
        _prestataireId == null || _prestataireId!.isEmpty;

    final body = BlocBuilder<ProviderProfileBloc, ProviderProfileState>(
      builder: (context, state) {
        if (waitingId ||
            state is ProviderProfileLoading ||
            state is ProviderProfileUpdated) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        if (state is ProviderProfileError) {
          return _buildErrorBody(state.message);
        }
        if (state is ProviderProfileLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              _refreshProfile();
              await Future<void>.delayed(const Duration(milliseconds: 250));
            },
            color: SDColors.primary600,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Pas de sous-titre H1 (AppBar = Profil).
                SliverToBoxAdapter(child: _buildIdentity(state)),
                if (_completionPercent(state) < 100)
                  SliverToBoxAdapter(child: _buildCompletion(state)),
                if ((state.profile['bio'] ?? '')
                    .toString()
                    .trim()
                    .isNotEmpty)
                  SliverToBoxAdapter(child: _buildAbout(state)),
                SliverToBoxAdapter(child: _buildServices(state)),
                SliverToBoxAdapter(child: _buildZone(state)),
                SliverToBoxAdapter(child: _buildProInfo(state)),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        }
        return const Center(child: Text('Initialisation…'));
      },
    );

    if (widget.embeddedInTab) {
      return ColoredBox(color: SDColors.white, child: body);
    }

    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: SDWhiteAppBar.appBar(
        title: 'Profil',
        actions: [
          IconButton(
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit_outlined, color: SDColors.neutral900),
            onPressed: openEdit,
          ),
          IconButton(
            tooltip: 'Actualiser',
            icon:
                const Icon(Icons.refresh_rounded, color: SDColors.neutral900),
            onPressed: _refreshProfile,
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildErrorBody(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: SDColors.neutral900),
            const SizedBox(height: 12),
            Text(
              'Impossible de charger le profil',
              style: SDTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: SDColors.neutral900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
            ),
            const SizedBox(height: 16),
            TextButton(
                onPressed: _refreshProfile, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentity(ProviderProfileLoaded state) {
    final p = state.profile;
    final name = _displayName(state);
    final photo = (p['profileImage']?.toString().startsWith('http') ?? false)
        ? p['profileImage'].toString()
        : _authPhoto();
    final verified = p['verifier'] == true;
    final location = p['location']?.toString() ?? '';
    final note = _asNum(p['note']) ?? 0;
    final avis = _asNum(p['nbAvis'])?.toInt() ??
        _asNum(p['totalReviews'])?.toInt() ??
        0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: SDColors.neutral100,
                backgroundImage:
                    (photo != null && photo.startsWith('http'))
                        ? NetworkImage(photo)
                        : null,
                child: (photo == null || !photo.startsWith('http'))
                    ? const Icon(Icons.person_outline_rounded,
                        size: 36, color: SDColors.neutral900)
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: SDColors.primary600,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: openEdit,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.photo_camera_outlined,
                          size: 14, color: SDColors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: SDTypography.titleSmall.copyWith(
                          color: SDColors.neutral900,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (verified)
                      const Icon(Icons.verified,
                          color: SDColors.primary600, size: 18),
                  ],
                ),
                if (verified) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Profil vérifié',
                    style: SDTypography.labelSmall.copyWith(
                      color: SDColors.primary700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  _metier(state),
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.primary700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_border_rounded,
                        size: 14, color: SDColors.neutral900),
                    const SizedBox(width: 4),
                    Text(
                      '${note.toStringAsFixed(1).replaceAll('.', ',')} ($avis avis)',
                      style: SDTypography.labelSmall
                          .copyWith(color: SDColors.neutral600),
                    ),
                  ],
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: SDColors.neutral900),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: SDTypography.labelSmall
                              .copyWith(color: SDColors.neutral600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletion(ProviderProfileLoaded state) {
    final pct = _completionPercent(state);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SDColors.neutral50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SDColors.neutral200),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: pct / 100,
                    strokeWidth: 3.5,
                    backgroundColor: SDColors.neutral200,
                    color: SDColors.primary600,
                  ),
                  Text(
                    '$pct%',
                    style: SDTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: SDColors.neutral900,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profil complété à $pct%',
                    style: SDTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SDColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Plus le profil est complet, plus vous recevez de missions.',
                    style: SDTypography.labelSmall
                        .copyWith(color: SDColors.neutral500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: openEdit,
              style: TextButton.styleFrom(
                backgroundColor: SDColors.primary600,
                foregroundColor: SDColors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Compléter',
                style: SDTypography.labelSmall.copyWith(
                  color: SDColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbout(ProviderProfileLoaded state) {
    final bio = state.profile['bio'].toString().trim();
    final years = _asNum(state.profile['anneeExperience']);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('À propos', action: 'Modifier', onAction: openEdit),
          const SizedBox(height: 8),
          Text(
            bio,
            style: SDTypography.bodyMedium.copyWith(
              color: SDColors.neutral700,
              height: 1.4,
            ),
          ),
          if (years != null && years > 0) ...[
            const SizedBox(height: 10),
            _tag('${years.round()} ans d\'expérience'),
          ],
        ],
      ),
    );
  }

  Widget _buildServices(ProviderProfileLoaded state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Mes services'),
          const SizedBox(height: 10),
          if (state.services.isEmpty)
            Text(
              'Aucune spécialité renseignée',
              style:
                  SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.services
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: SDColors.neutral50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SDColors.neutral200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.handyman_outlined,
                              size: 16, color: SDColors.neutral900),
                          const SizedBox(width: 8),
                          Text(
                            s,
                            style: SDTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: SDColors.neutral900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildZone(ProviderProfileLoaded state) {
    final z = state.serviceZone;
    final addr =
        z['address']?.toString() ?? state.profile['location']?.toString() ?? '—';
    final radius = z['radius'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Zone d\'intervention'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SDColors.neutral50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SDColors.neutral200),
            ),
            child: Row(
              children: [
                const Icon(Icons.map_outlined,
                    size: 28, color: SDColors.neutral900),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        addr,
                        style: SDTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: SDColors.neutral900,
                        ),
                      ),
                      if (radius != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Rayon d\'intervention : $radius km',
                          style: SDTypography.bodySmall
                              .copyWith(color: SDColors.neutral500),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProInfo(ProviderProfileLoaded state) {
    final phone = state.profile['phone']?.toString().trim();
    final email = state.profile['email']?.toString().trim();
    final verified = state.profile['verifier'] == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Informations pro'),
          const SizedBox(height: 10),
          if (phone != null && phone.isNotEmpty)
            _proRow(Icons.phone_outlined, phone, verified ? 'Vérifié' : null),
          if (phone != null && phone.isNotEmpty) const SizedBox(height: 8),
          if (email != null && email.isNotEmpty)
            _proRow(Icons.mail_outline_rounded, email, null),
          if (email != null && email.isNotEmpty) const SizedBox(height: 8),
          _proRow(
            Icons.badge_outlined,
            verified
                ? 'Identité vérifiée'
                : 'Identité en attente de vérification',
            verified ? 'Vérifié' : 'En cours',
          ),
        ],
      ),
    );
  }

  Widget _proRow(IconData icon, String text, String? badge) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: SDColors.neutral900),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: SDTypography.bodyMedium.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (badge != null)
            Text(
              badge,
              style: SDTypography.labelSmall.copyWith(
                color: SDColors.primary700,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, {String? action, VoidCallback? onAction}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: SDTypography.titleSmall.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (action != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: SDColors.primary700,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  action,
                  style: SDTypography.labelMedium.copyWith(
                    color: SDColors.primary700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.edit_outlined, size: 14),
              ],
            ),
          ),
      ],
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: SDColors.neutral100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Text(
        label,
        style: SDTypography.labelSmall.copyWith(
          color: SDColors.neutral800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
