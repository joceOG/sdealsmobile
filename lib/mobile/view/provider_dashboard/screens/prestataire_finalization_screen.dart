import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../data/services/authCubit.dart';
import '../../../../design_system/design_system.dart';
import '../bloc/prestataire_finalization_bloc.dart';

/// Finalisation du dossier professionnel (KYC) — sans exposition publique des pièces.
class PrestataireFinalizationScreen extends StatefulWidget {
  final String? prestataireId;

  const PrestataireFinalizationScreen({super.key, this.prestataireId});

  @override
  State<PrestataireFinalizationScreen> createState() =>
      _PrestataireFinalizationScreenState();
}

class _PrestataireFinalizationScreenState
    extends State<PrestataireFinalizationScreen> {
  final ImagePicker _picker = ImagePicker();
  String? _pendingLocationLabel;
  Map<String, dynamic>? _pendingLocationMaps;
  bool _locating = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) {
        final bloc = PrestataireFinalizationBloc();
        final auth = ctx.read<AuthCubit>().state;
        final id = widget.prestataireId;
        if (auth is AuthAuthenticated && id != null && id.isNotEmpty) {
          bloc.add(
            LoadDossierEvent(prestataireId: id, authToken: auth.token),
          );
        }
        return bloc;
      },
      child: BlocConsumer<PrestataireFinalizationBloc,
          PrestataireFinalizationState>(
        listener: (context, state) {
          if (state is PrestataireFinalizationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: SDColors.primary600,
              ),
            );
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/homepage');
            }
          } else if (state is PrestataireFinalizationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: SDColors.error500,
              ),
            );
          } else if (state is DocumentUploadFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
          }
        },
        builder: (context, state) {
          final dossier = state is DossierLoaded ? state : _lastDossier(state);

          return Scaffold(
            backgroundColor: SDColors.white,
            appBar: SDWhiteAppBar.appBar(
              title: 'Finaliser mon dossier',
              titleStyle: SDTypography.titleLarge,
            ),
            body: state is PrestataireFinalizationLoading && dossier == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Complétez les éléments de vérification.',
                          style: SDTypography.bodyMedium
                              .copyWith(color: SDColors.neutral500),
                        ),
                        const SizedBox(height: 16),
                        _statusBanner(dossier),
                        const SizedBox(height: 20),
                        _sectionTitle('Pièce d’identité'),
                        const SizedBox(height: 10),
                        _docTile(
                          dossier: dossier,
                          fieldKey: 'cni_recto',
                          title: 'CNI — recto',
                          subtitleProvided: 'Document enregistré',
                          subtitleMissing: 'Photo lisible du document',
                          icon: Icons.badge_outlined,
                          onAdd: () => _pickAndUpload(
                            documentType: 'cni_recto',
                            source: ImageSource.gallery,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _docTile(
                          dossier: dossier,
                          fieldKey: 'cni_verso',
                          title: 'CNI — verso',
                          subtitleProvided: 'Document enregistré',
                          subtitleMissing: 'Photo lisible du document',
                          icon: Icons.badge_outlined,
                          onAdd: () => _pickAndUpload(
                            documentType: 'cni_verso',
                            source: ImageSource.gallery,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _sectionTitle('Selfie de vérification'),
                        const SizedBox(height: 10),
                        _docTile(
                          dossier: dossier,
                          fieldKey: 'selfie',
                          title: 'Photo de vérification',
                          subtitleProvided: 'Selfie enregistré',
                          subtitleMissing:
                              'Suivez les instructions de prise de photo.',
                          icon: Icons.face_outlined,
                          actionLabel: 'Prendre un selfie',
                          onAdd: () => _pickAndUpload(
                            documentType: 'selfie',
                            source: ImageSource.camera,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ce selfie ne remplace pas votre photo de profil.',
                          style: SDTypography.caption
                              .copyWith(color: SDColors.neutral500),
                        ),
                        const SizedBox(height: 20),
                        _sectionTitle('Localisation du dossier'),
                        const SizedBox(height: 10),
                        _locationTile(dossier),
                        const SizedBox(height: 6),
                        Text(
                          'Distincte de votre zone d’intervention.',
                          style: SDTypography.caption
                              .copyWith(color: SDColors.neutral500),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _missingSummary(dossier),
                          style: SDTypography.bodySmall
                              .copyWith(color: SDColors.neutral600),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _canSubmit(dossier)
                                ? () => _finalize(dossier)
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: SDColors.primary700,
                              disabledBackgroundColor: SDColors.neutral300,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Finaliser mon dossier'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _canSubmit(dossier)
                              ? '« Fourni » indique un document enregistré, pas une validation par l’équipe.'
                              : 'Complétez les éléments requis pour continuer.',
                          textAlign: TextAlign.center,
                          style: SDTypography.caption
                              .copyWith(color: SDColors.neutral500),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  DossierLoaded? _lastDossier(PrestataireFinalizationState state) {
    if (state is DossierLoaded) return state;
    return null;
  }

  Widget _statusBanner(DossierLoaded? dossier) {
    final complete = dossier?.canFinalize ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SDColors.primary50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SDColors.primary200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fact_check_outlined, color: SDColors.primary700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: SDColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    complete ? 'Prêt à envoyer' : 'À compléter',
                    style: SDTypography.labelSmall.copyWith(
                      color: SDColors.primary700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  complete
                      ? 'Vous pouvez soumettre votre dossier. La vérification reste distincte.'
                      : 'Ajoutez les éléments manquants avant de finaliser.',
                  style: SDTypography.bodySmall
                      .copyWith(color: SDColors.neutral700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: SDTypography.titleSmall.copyWith(
        fontWeight: FontWeight.w800,
        color: SDColors.neutral900,
      ),
    );
  }

  bool _isProvided(DossierLoaded? dossier, String fieldKey) {
    if (dossier == null) return false;
    switch (fieldKey) {
      case 'cni_recto':
        return dossier.hasCniRecto;
      case 'cni_verso':
        return dossier.hasCniVerso;
      case 'selfie':
        return dossier.hasSelfie;
      default:
        return false;
    }
  }

  bool _isUploading(DossierLoaded? dossier, String fieldKey) {
    return dossier?.uploadingFields.contains(fieldKey) ?? false;
  }

  bool _isSelectedLocal(DossierLoaded? dossier, String fieldKey) {
    return dossier?.pendingLocalFiles.containsKey(fieldKey) ?? false;
  }

  Widget _docTile({
    required DossierLoaded? dossier,
    required String fieldKey,
    required String title,
    required String subtitleProvided,
    required String subtitleMissing,
    required IconData icon,
    required VoidCallback onAdd,
    String actionLabel = 'Ajouter',
  }) {
    final provided = _isProvided(dossier, fieldKey);
    final uploading = _isUploading(dossier, fieldKey);
    final selected = _isSelectedLocal(dossier, fieldKey);

    String subtitle;
    if (uploading) {
      subtitle = 'Transfert en cours…';
    } else if (selected && !provided) {
      subtitle = 'Fichier sélectionné — en attente d’envoi';
    } else if (provided) {
      subtitle = subtitleProvided;
    } else {
      subtitle = subtitleMissing;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: provided ? SDColors.primary50 : SDColors.neutral100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: provided ? SDColors.primary700 : SDColors.neutral600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SDTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: SDTypography.caption
                      .copyWith(color: SDColors.neutral500),
                ),
              ],
            ),
          ),
          if (uploading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (provided)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    color: SDColors.primary600, size: 20),
                const SizedBox(width: 4),
                Text(
                  'Fourni',
                  style: SDTypography.labelMedium.copyWith(
                    color: SDColors.primary700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          else
            OutlinedButton(
              onPressed: onAdd,
              style: OutlinedButton.styleFrom(
                foregroundColor: SDColors.primary700,
                side: const BorderSide(color: SDColors.primary600),
              ),
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }

  Widget _locationTile(DossierLoaded? dossier) {
    final hasServer = dossier?.hasDossierLocation ?? false;
    final hasPending = _pendingLocationMaps != null;
    final provided = hasServer || hasPending;
    final label = _pendingLocationLabel ??
        (dossier?.locationLabel.isNotEmpty == true
            ? dossier!.locationLabel
            : '');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: provided ? SDColors.primary50 : SDColors.neutral100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.place_outlined,
                color: SDColors.primary700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provided ? 'Position renseignée' : 'Position du dossier',
                  style: SDTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _locating
                      ? 'Localisation en cours…'
                      : (provided && label.isNotEmpty
                          ? label
                          : 'Indiquez où se situe votre dossier'),
                  style: SDTypography.caption
                      .copyWith(color: SDColors.neutral500),
                ),
              ],
            ),
          ),
          if (_locating)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (provided)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    color: SDColors.primary600, size: 20),
                const SizedBox(width: 4),
                Text(
                  'Fourni',
                  style: SDTypography.labelMedium.copyWith(
                    color: SDColors.primary700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          else
            OutlinedButton(
              onPressed: _captureDossierLocation,
              style: OutlinedButton.styleFrom(
                foregroundColor: SDColors.primary700,
                side: const BorderSide(color: SDColors.primary600),
              ),
              child: const Text('Localiser'),
            ),
        ],
      ),
    );
  }

  String _missingSummary(DossierLoaded? dossier) {
    if (!(dossier?.hasDossierLocation ?? false) &&
        _pendingLocationMaps == null) {
      return 'À ajouter : localisation du dossier.';
    }
    if (dossier != null && !dossier.canGetBadge) {
      final opt = <String>[];
      if (!dossier.hasCniRecto) opt.add('CNI recto');
      if (!dossier.hasCniVerso) opt.add('CNI verso');
      if (!dossier.hasSelfie) opt.add('selfie');
      if (opt.isNotEmpty) {
        return 'Pour le badge vérifié (optionnel) : ${opt.join(' et ')}.';
      }
    }
    return 'Éléments obligatoires renseignés.';
  }

  bool _canSubmit(DossierLoaded? dossier) {
    final hasLoc =
        (dossier?.hasDossierLocation ?? false) || _pendingLocationMaps != null;
    final uploading = dossier?.uploadingFields.isNotEmpty ?? false;
    return hasLoc && !uploading && !_locating;
  }

  Future<void> _pickAndUpload({
    required String documentType,
    required ImageSource source,
  }) async {
    final auth = context.read<AuthCubit>().state;
    final id = widget.prestataireId;
    if (auth is! AuthAuthenticated || id == null) return;

    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (file == null) return;
      context.read<PrestataireFinalizationBloc>().add(
            UploadDocumentEvent(
              documentType: documentType,
              file: File(file.path),
              prestataireId: id,
              authToken: auth.token,
            ),
          );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sélection impossible: $e')),
      );
    }
  }

  Future<void> _captureDossierLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Permission de localisation refusée');
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _pendingLocationMaps = {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
        _pendingLocationLabel =
            'Lat ${position.latitude.toStringAsFixed(4)}, Lng ${position.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _finalize(DossierLoaded? dossier) {
    final auth = context.read<AuthCubit>().state;
    final id = widget.prestataireId;
    if (auth is! AuthAuthenticated || id == null) return;

    context.read<PrestataireFinalizationBloc>().add(
          FinalizeDossierEvent(
            prestataireId: id,
            authToken: auth.token,
            locationMaps: _pendingLocationMaps,
            locationLabel: _pendingLocationLabel,
          ),
        );
  }
}
