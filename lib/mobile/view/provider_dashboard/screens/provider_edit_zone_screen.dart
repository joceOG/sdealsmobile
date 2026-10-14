import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/services/authCubit.dart';
import '../../../../design_system/design_system.dart';
import '../bloc/provider_profile_bloc.dart';
import '../bloc/provider_profile_event.dart';
import '../bloc/provider_profile_state.dart';

/// Édition ville/commune + rayon (`localisation`, `rayonIntervention`) — hors KYC.
/// Ne modifie pas `localisationmaps` ni la géolocalisation GPS.
class ProviderEditZoneScreen extends StatefulWidget {
  const ProviderEditZoneScreen({
    super.key,
    required this.prestataireId,
    required this.initialLocation,
    this.initialRadiusKm,
  });

  final String prestataireId;
  final String initialLocation;
  final double? initialRadiusKm;

  @override
  State<ProviderEditZoneScreen> createState() => _ProviderEditZoneScreenState();
}

class _ProviderEditZoneScreenState extends State<ProviderEditZoneScreen> {
  late final TextEditingController _locationController;
  late final TextEditingController _radiusController;
  bool _saving = false;
  bool _awaitingSave = false;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.initialLocation);
    final r = widget.initialRadiusKm;
    _radiusController = TextEditingController(
      text: r != null && r > 0 ? '${r.round()}' : '',
    );
    _locationController.addListener(_onFieldsChanged);
    _radiusController.addListener(_onFieldsChanged);
  }

  @override
  void dispose() {
    _locationController.removeListener(_onFieldsChanged);
    _radiusController.removeListener(_onFieldsChanged);
    _locationController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  void _onFieldsChanged() {
    if (mounted) setState(() {});
  }

  String get _previewLocation {
    final loc = _locationController.text.trim();
    return loc.isEmpty ? '—' : loc;
  }

  String get _previewRadiusLabel {
    final n = int.tryParse(_radiusController.text.trim());
    if (n == null || n <= 0) return '—';
    return '$n km';
  }

  void _save() {
    final loc = _locationController.text.trim();
    if (loc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indiquez une ville ou une commune')),
      );
      return;
    }
    final radius = int.tryParse(_radiusController.text.trim());
    if (radius == null || radius <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saisissez une distance valide en kilomètres'),
        ),
      );
      return;
    }

    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return;

    final body = <String, dynamic>{
      'localisation': loc,
      'rayonIntervention': radius,
    };

    setState(() => _saving = true);
    final bloc = context.read<ProviderProfileBloc>();
    bloc.setToken(auth.token);
    _awaitingSave = true;
    bloc.add(UpdateProviderProfile(widget.prestataireId, body));
  }

  void _onProfileUpdateState(ProviderProfileState state) {
    if (!_awaitingSave) return;
    if (state is ProviderProfileError) {
      setState(() {
        _saving = false;
        _awaitingSave = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    } else if (state is ProviderProfileLoaded) {
      final loc = _locationController.text.trim();
      final radius = int.tryParse(_radiusController.text.trim())?.toDouble();
      setState(() {
        _saving = false;
        _awaitingSave = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zone d\'intervention enregistrée'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, (loc, radius));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProviderProfileBloc, ProviderProfileState>(
      listener: (context, state) => _onProfileUpdateState(state),
      child: Scaffold(
        backgroundColor: SDColors.white,
        appBar: SDWhiteAppBar.appBar(title: 'Zone d\'intervention'),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Text(
                    'Indiquez où vous proposez vos services.',
                    style: SDTypography.bodyMedium.copyWith(
                      color: SDColors.neutral600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Localisation',
                    style: SDTypography.labelSmall.copyWith(
                      color: SDColors.neutral500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _locationController,
                    enabled: !_saving,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Ville ou commune',
                      prefixIcon: const Icon(Icons.place_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: SDColors.neutral200),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Exemple : Port-Bouët, Abidjan.',
                    style: SDTypography.labelSmall.copyWith(
                      color: SDColors.neutral500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Rayon d\'intervention',
                    style: SDTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: SDColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Distance indicative autour de votre localisation.',
                    style: SDTypography.bodySmall.copyWith(
                      color: SDColors.neutral500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _radiusController,
                    enabled: !_saving,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: SDColors.neutral200),
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 1,
                              height: 24,
                              color: SDColors.neutral200,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'km',
                              style: SDTypography.bodyMedium.copyWith(
                                color: SDColors.neutral600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Saisissez une distance en kilomètres.',
                    style: SDTypography.labelSmall.copyWith(
                      color: SDColors.neutral500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildPreviewCard(),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: SDColors.neutral500,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cette zone indique votre périmètre d\'intervention. '
                          'Elle ne garantit pas votre disponibilité.',
                          style: SDTypography.bodySmall.copyWith(
                            color: SDColors.neutral500,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
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
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: Text(
                        'Annuler',
                        style: SDTypography.bodyMedium.copyWith(
                          color: SDColors.primary700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SDColors.primary50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SDColors.primary100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: SDColors.primary700,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.map_outlined,
              color: SDColors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aperçu sur votre profil',
                  style: SDTypography.labelSmall.copyWith(
                    color: SDColors.neutral600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _previewLocation,
                  style: SDTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: SDColors.neutral900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _previewRadiusLabel == '—'
                      ? 'Rayon d\'intervention : —'
                      : 'Rayon d\'intervention : $_previewRadiusLabel',
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
}
